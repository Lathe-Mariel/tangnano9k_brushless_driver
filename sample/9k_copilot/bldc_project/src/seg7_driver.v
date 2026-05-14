module seg7_driver (
    input  logic        clk,
    input  logic [15:0] value,   // 4桁のBCDを想定 or 0〜9999
    output logic [7:0]  anode,   // {A,B,C,D,E,F,G,DP} の順など
    output logic [3:0]  cathode
);

    // クロック分周して桁切り替え
    logic [15:0] div;
    always_ff @(posedge clk) begin
        div <= div + 1;
    end

    logic [1:0] digit_sel;
    always_ff @(posedge clk) begin
        digit_sel <= div[15:14]; // 適当なビットで多重化
    end

    // value を4桁のBCDに分解（簡易：10進変換は省略し、上位4bitずつをそのまま表示）
    logic [3:0] d0, d1, d2, d3;
    assign d0 = value[3:0];
    assign d1 = value[7:4];
    assign d2 = value[11:8];
    assign d3 = value[15:12];

    logic [3:0] cur_digit;
    always_comb begin
        case (digit_sel)
            2'd0: cur_digit = d0;
            2'd1: cur_digit = d1;
            2'd2: cur_digit = d2;
            2'd3: cur_digit = d3;
        endcase
    end

    // 7セグパターン（0〜F）
    function automatic logic [7:0] seg_pattern (input logic [3:0] x);
        case (x)
            4'h0: seg_pattern = 8'b01111110;
            4'h1: seg_pattern = 8'b00001100;
            4'h2: seg_pattern = 8'b10110110;
            4'h3: seg_pattern = 8'b10011110;
            4'h4: seg_pattern = 8'b11001100;
            4'h5: seg_pattern = 8'b11011010;
            4'h6: seg_pattern = 8'b11111010;
            4'h7: seg_pattern = 8'b00001110;
            4'h8: seg_pattern = 8'b11111110;
            4'h9: seg_pattern = 8'b11011110;
            4'hA: seg_pattern = 8'b11101110;
            4'hB: seg_pattern = 8'b11111000;
            4'hC: seg_pattern = 8'b01110010;
            4'hD: seg_pattern = 8'b10111100;
            4'hE: seg_pattern = 8'b11110010;
            4'hF: seg_pattern = 8'b11100010;
            default: seg_pattern = 8'b00000000;
        endcase
    endfunction

    always_ff @(posedge clk) begin
        anode <= seg_pattern(cur_digit); // 極性は実機に合わせて反転
    end

    always_ff @(posedge clk) begin
        cathode <= 4'b1111;
        case (digit_sel)
            2'd0: cathode[0] <= 1'b0;
            2'd1: cathode[1] <= 1'b0;
            2'd2: cathode[2] <= 1'b0;
            2'd3: cathode[3] <= 1'b0;
        endcase
    end

endmodule