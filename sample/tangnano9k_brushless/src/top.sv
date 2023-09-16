`default_nettype none

module top (
  input  wire       clk,

  input  wire sw1,
  input  wire sw2,
  output  wire HIN_R,
  output  wire HIN_S,
  output  wire HIN_T,
  input  wire H_U,
  input  wire H_V,
  input  wire H_W,
  output wire[5:0] boardLED
);

  logic       oneSecondCLK;
  logic       oneSecondOverflow;


  timer #(
    .COUNT_MAX(27000000/2)
  ) inst_1 (
    .clk (clk),
    .overflow(oneSecondOverflow)
  );

  always @(posedge oneSecondOverflow)begin
    oneSecondCLK = oneSecondCLK + 1;
  end

endmodule

module timer #(
  parameter COUNT_MAX = 27000000
) (
  input  wire  clk,
  output logic overflow
);

  logic [$clog2(COUNT_MAX+1)-1:0] counter = 'd0;

  always_ff @ (posedge clk) begin
    if (counter == COUNT_MAX) begin
      counter  <= 'd0;
      overflow <= 'd1;
    end else begin
      counter  <= counter + 'd1;
      overflow <= 'd0;
    end
  end

endmodule

`default_nettype wire
