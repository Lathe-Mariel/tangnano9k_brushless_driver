module duty_slew #(
    parameter int WIDTH = 10,
    parameter int STEP  = 4
)(
    input  logic [WIDTH-1:0] target,
    input  logic             clk,
    output logic [WIDTH-1:0] current
);

    always_ff @(posedge clk) begin
        if (current < target) begin
            if (target - current > STEP)
                current <= current + STEP;
            else
                current <= target;
        end else if (current > target) begin
            if (current - target > STEP)
                current <= current - STEP;
            else
                current <= target;
        end
    end

endmodule