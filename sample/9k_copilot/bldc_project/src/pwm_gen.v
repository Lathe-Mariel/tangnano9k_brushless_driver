module pwm_gen #(
    parameter int WIDTH = 10
)(
    input  logic             clk,
    input  logic [WIDTH-1:0] duty,
    output logic             pwm_out
);

    logic [WIDTH-1:0] cnt;

    always_ff @(posedge clk) begin
        cnt <= cnt + 1;
    end

    always_ff @(posedge clk) begin
        pwm_out <= (cnt < duty);
    end

endmodule