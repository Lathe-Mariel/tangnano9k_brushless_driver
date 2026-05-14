module mcp3008_if #(
    parameter int CLK_DIV = 16
)(
    input  logic       clk,
    input  logic       start,
    input  logic [2:0] channel,
    input  logic       miso,
    output logic       mosi,
    output logic       sclk,
    output logic       cs_n,
    output logic [9:0] data_out,
    output logic       data_valid
);

    typedef enum logic [2:0] {
        IDLE,
        START_CONV,
        TRANSFER,
        DONE
    } state_t;

    state_t state, next_state;

    logic [$clog2(CLK_DIV)-1:0] div_cnt;
    logic sclk_int;
    logic sclk_en;

    // SPIクロック生成
    always_ff @(posedge clk) begin
        if (!sclk_en) begin
            div_cnt <= '0;
            sclk_int <= 1'b0;
        end else begin
            if (div_cnt == CLK_DIV-1) begin
                div_cnt  <= '0;
                sclk_int <= ~sclk_int;
            end else begin
                div_cnt <= div_cnt + 1;
            end
        end
    end

    assign sclk = sclk_int;

    // シフトレジスタ
    logic [4+3+10+2-1:0] shift_reg; // start + single/diff + D2..D0 + null + 10bit + dummy
    logic [5:0] bit_cnt;

    // 状態遷移
    always_ff @(posedge clk) begin
        state <= next_state;
    end

    always_comb begin
        next_state  = state;
        sclk_en     = 1'b0;
        cs_n        = 1'b1;
        data_valid  = 1'b0;

        case (state)
            IDLE: begin
                if (start) next_state = START_CONV;
            end
            START_CONV: begin
                next_state = TRANSFER;
            end
            TRANSFER: begin
                sclk_en = 1'b1;
                cs_n    = 1'b0;
                if (bit_cnt == (4+3+10+2-1)) begin
                    next_state = DONE;
                end
            end
            DONE: begin
                data_valid = 1'b1;
                next_state = IDLE;
            end
        endcase
    end

    // ビットカウンタ・シフト
    always_ff @(posedge clk) begin
        if (state == START_CONV) begin
            // MCP3008: 1(start) + 1(single) + 3(channel) + 1(null) + 10(data) + 1(dummy)
            shift_reg <= {2'b00, 10'd0, 1'b0, channel, 1'b1}; // MSB側にstart
            bit_cnt   <= 0;
        end else if (state == TRANSFER && sclk_en && div_cnt == CLK_DIV-1) begin
            // 立ち上がり/立ち下がりどちらでシフトするかは要調整
            shift_reg <= {shift_reg[4+3+10+2-2:0], miso};
            bit_cnt   <= bit_cnt + 1;
        end
    end

    // MOSIはMSBから
    assign mosi = shift_reg[4+3+10+2-1];

    // データ取り出し（位置は要確認）
    always_ff @(posedge clk) begin
        if (state == DONE) begin
            // ここでは仮にシフトレジスタの中間に10bitがあるとする
            data_out <= shift_reg[10+2-1:2]; // 要実機で確認
        end
    end

endmodule