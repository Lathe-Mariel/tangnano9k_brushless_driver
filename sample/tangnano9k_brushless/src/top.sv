`default_nettype none

module top (
  input  wire       clk,

  input  wire sw1,
  input  wire sw2,
  output logic HIN_R,
  output logic HIN_S,
  output logic HIN_T,
  input  wire[2:0] HS,  //HallSensor
  output wire[5:0] boardLED
);

  logic       controlCLK;
  logic  rotateState;


  timer #(
    .COUNT_MAX()
  ) inst_1 (
    .clk (clk),
    .overflow(controlCLK)
  );

  always @(posedge controlCLK)begin
    case(rotateState)
      3'd0: begin HIN_R <= 1; HIN_S <= 0; HIN_T <= 0; end
      3'd1: begin HIN_R <= 1; HIN_S <= 0; HIN_T <= 0; end
      3'd2: begin HIN_R <= 0; HIN_S <= 1; HIN_T <= 0; end
      3'd3: begin HIN_R <= 0; HIN_S <= 1; HIN_T <= 0; end
      3'd4: begin HIN_R <= 0; HIN_S <= 0; HIN_T <= 1; end
      3'd5: begin HIN_R <= 0; HIN_S <= 0; HIN_T <= 1; end
    endcase
    if(rotateState == 3'd5)begin
      rotateState <= 3'd0;
    end else begin
      rotateState <= rotateState + 3'd1;
    end


  end

  assign boardLED[0] = HS[0];
  assign boardLED[1] = HS[1];
  assign boardLED[2] = HS[2];

endmodule

module timer #(
  parameter COUNT_MAX = 270000
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
