module bldc_commutation (
    input  logic       clk,
    input  logic [2:0] hs,
    input  logic       dir,
    input  logic       enable,
    input  logic       pwm,

    output logic       u_hi,
    output logic       u_lo,
    output logic       v_hi,
    output logic       v_lo,
    output logic       w_hi,
    output logic       w_lo
);

    // 6ステップ番号（1〜6）にマッピング
    logic [2:0] step;

    always_comb begin
        unique case (hs)
            3'b001: step = 3'd1;
            3'b101: step = 3'd2;
            3'b100: step = 3'd3;
            3'b110: step = 3'd4;
            3'b010: step = 3'd5;
            3'b011: step = 3'd6;
            default: step = 3'd0; // 無効
        endcase
    end

    // 正転/逆転でステップ順を反転
    logic [2:0] step_dir;
    always_comb begin
        if (step == 0) begin
            step_dir = 0;
        end else if (dir) begin
            step_dir = step;
        end else begin
            step_dir = 7 - step; // 1↔6, 2↔5, 3↔4
        end
    end

    // 各相のON/OFF
    always_comb begin
        u_hi = 0; u_lo = 0;
        v_hi = 0; v_lo = 0;
        w_hi = 0; w_lo = 0;

        if (!enable || step_dir == 0) begin
            // 全OFF
        end else begin
            unique case (step_dir)
                3'd1: begin // U+ V-
                    u_hi = pwm; v_lo = 1;
                end
                3'd2: begin // U+ W-
                    u_hi = pwm; w_lo = 1;
                end
                3'd3: begin // V+ W-
                    v_hi = pwm; w_lo = 1;
                end
                3'd4: begin // V+ U-
                    v_hi = pwm; u_lo = 1;
                end
                3'd5: begin // W+ U-
                    w_hi = pwm; u_lo = 1;
                end
                3'd6: begin // W+ V-
                    w_hi = pwm; v_lo = 1;
                end
            endcase
        end
    end

endmodule