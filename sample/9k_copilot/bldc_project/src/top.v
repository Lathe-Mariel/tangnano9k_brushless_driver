module top (
    input  logic        clk,      // 物理制約ファイルの "clk"
    input  logic        sw1,      // 正転/逆転
    input  logic        sw2,      // 駆動ON/OFF

    input  logic [2:0]  HS,       // ホールセンサ

    // SPI to MCP3008
    output logic        AD_CLK,
    output logic        CS,
    output logic        DIN,
    input  logic        DOUT,

    // Gate driver outputs
    output logic        HIN_R,
    output logic        HIN_S,
    output logic        HIN_T,
    output logic        _LIN_R,
    output logic        _LIN_S,
    output logic        _LIN_T,

    // 7seg
    output logic [7:0]  anode,
    output logic [3:0]  cathode,

    // debug LEDs
    output logic [5:0]  boardLED
);

    //============================================================
    // クロック・リセット（ここでは簡易にリセット無し）
    //============================================================
    // Tang Nano 9K の内部PLLを使うなら別途インスタンス
    // ここでは clk をそのまま使用

    //============================================================
    // ADC (MCP3008) インタフェース
    //============================================================
    logic [9:0] adc_data;
    logic       adc_valid;

    mcp3008_if #(
        .CLK_DIV(16)   // SPIクロック分周（要調整）
    ) u_adc (
        .clk      (clk),
        .start    (1'b1),     // 常時サンプリング
        .channel  (3'd4),     // ch4
        .miso     (DOUT),
        .mosi     (DIN),
        .sclk     (AD_CLK),
        .cs_n     (CS),
        .data_out (adc_data),
        .data_valid(adc_valid)
    );

    //============================================================
    // アクセル値 → 目標デューティ
    //============================================================
    // adc_data: 0〜1023 を 0〜PWM_MAX にマッピング
    localparam int PWM_BITS = 10;
    localparam int PWM_MAX  = (1<<PWM_BITS) - 1;

    logic [PWM_BITS-1:0] duty_target;

    always_ff @(posedge clk) begin
        if (adc_valid) begin
            // そのままスケーリング（必要ならオフセットやデッドゾーンを追加）
            duty_target <= adc_data;
        end
    end

    //============================================================
    // デューティのスルーレート制御（なめらかな加減速）
    //============================================================
    logic [PWM_BITS-1:0] duty_smooth;

    duty_slew #(
        .WIDTH(PWM_BITS),
        .STEP (4)          // 1クロックあたり最大変化量（要調整）
    ) u_slew (
        .clk       (clk),
        .target    (duty_target),
        .current   (duty_smooth)
    );

    //============================================================
    // PWM生成
    //============================================================
    logic pwm_carrier;

    pwm_gen #(
        .WIDTH(PWM_BITS)
    ) u_pwm (
        .clk     (clk),
        .duty    (duty_smooth),
        .pwm_out (pwm_carrier)
    );

    //============================================================
    // BLDC 120°矩形波通電パターン
    //============================================================
    logic dir;   // 1: 正転, 0: 逆転
    assign dir = sw1;  // sw1で方向切り替え

    logic enable_drive;
    assign enable_drive = ~sw2; // sw2=0でON, 1でOFF とする例

    logic phase_u_hi, phase_u_lo;
    logic phase_v_hi, phase_v_lo;
    logic phase_w_hi, phase_w_lo;

    bldc_commutation u_comm (
        .clk        (clk),
        .hs         (HS),
        .dir        (dir),
        .enable     (enable_drive & (duty_smooth != 0)),
        .pwm        (pwm_carrier),
        .u_hi       (phase_u_hi),
        .u_lo       (phase_u_lo),
        .v_hi       (phase_v_hi),
        .v_lo       (phase_v_lo),
        .w_hi       (phase_w_hi),
        .w_lo       (phase_w_lo)
    );

    // ゲートドライバへの割り当て
    assign HIN_R  = phase_u_hi;
    assign _LIN_R = phase_u_lo;
    assign HIN_S  = phase_v_hi;
    assign _LIN_S = phase_v_lo;
    assign HIN_T  = phase_w_hi;
    assign _LIN_T = phase_w_lo;

    //============================================================
    // 回転数カウンタ（簡易）
    //============================================================
    logic [15:0] rpm_value;

    rpm_counter u_rpm (
        .clk      (clk),
        .hs       (HS),
        .rpm_out  (rpm_value)
    );

    //============================================================
    // 7セグ表示（rpm_valueの上位4桁など）
    //============================================================
    logic [15:0] disp_value;

    always_ff @(posedge clk) begin
        disp_value <= rpm_value; // 必要ならスケーリング
    end

    seg7_driver u_seg (
        .clk      (clk),
        .value    (disp_value),
        .anode    (anode),
        .cathode  (cathode)
    );

    //============================================================
    // デバッグ用LED
    //============================================================
    assign boardLED[0] = enable_drive;
    assign boardLED[1] = dir;
    assign boardLED[2] = pwm_carrier;
    assign boardLED[5:3] = HS;

endmodule