module rpm_counter (
    input  logic       clk,
    input  logic [2:0] hs,
    output logic [15:0] rpm_out
);

    // パルス源として HS[0] を使用
    logic hs0_d;
    logic hs0_rise;

    always_ff @(posedge clk) begin
        hs0_d <= hs[0];
    end

    assign hs0_rise = (hs[0] & ~hs0_d);

    // 計測窓
    localparam int WINDOW_BITS = 20; // 要調整
    logic [WINDOW_BITS-1:0] win_cnt;
    logic [15:0] pulse_cnt;

    always_ff @(posedge clk) begin
        win_cnt <= win_cnt + 1;

        if (hs0_rise)
            pulse_cnt <= pulse_cnt + 1;

        if (&win_cnt) begin
            // 窓終了時にrpm_out更新（ここでは単純にパルス数をそのまま出す）
            rpm_out   <= pulse_cnt;
            pulse_cnt <= 0;
        end
    end

endmodule