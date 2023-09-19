`default_nettype none

module top (
  input  wire       clk,

  input  wire sw1,
  input  wire sw2,
  input wire[3:0] tacSW,
  input wire[2:0] toggleSW,
  input  wire[2:0] HS,  //HallSensor
  output logic HIN_R,
  output logic HIN_S,
  output logic HIN_T,
  output logic _LIN_R,
  output logic _LIN_S,
  output logic _LIN_T,
  output logic[7:0] anode,
  output logic[3:0] cathode,
  output wire[5:0] boardLED
);

  logic  controlCLK;
  logic rotateCLK;
  logic[3:0] rotateCounter;
  logic[2:0]  rotateState;
  logic duty;
  logic _LR;
  logic _LS;
  logic _LT;


  timer #(
    .COUNT_MAX()
  ) inst_1 (
    .clk (clk),
    .overflow(controlCLK)
  );

  always @(posedge controlCLK)begin
    if(rotateCounter == 0)begin
      rotateCLK <= ~rotateCLK;
    end
    rotateCounter <= rotateCounter + 'b1;

    if(rotateCounter[2:0] == 3'b111)begin
      duty <= 'b1;
    end else begin
      duty <= 'b0;
    end

  end

  always @(posedge rotateCLK)begin
    if(toggleSW[2])begin
      case(rotateState)
        3'd0: begin HIN_R <= 1; _LR <= 1; HIN_S <= 0; _LS <= 0; HIN_T <= 0; _LT <= 1; end
        3'd1: begin HIN_R <= 1; _LR <= 1; HIN_S <= 0; _LS <= 1; HIN_T <= 0; _LT <= 0; end
        3'd2: begin HIN_R <= 0; _LR <= 1; HIN_S <= 1; _LS <= 1; HIN_T <= 0; _LT <= 0; end
        3'd3: begin HIN_R <= 0; _LR <= 0; HIN_S <= 1; _LS <= 1; HIN_T <= 0; _LT <= 1; end
        3'd4: begin HIN_R <= 0; _LR <= 0; HIN_S <= 0; _LS <= 1; HIN_T <= 1; _LT <= 1; end
        3'd5: begin HIN_R <= 0; _LR <= 1; HIN_S <= 0; _LS <= 0; HIN_T <= 1; _LT <= 1; end
      endcase
    end else begin
      HIN_R <= 0; _LR <= 1; HIN_S <= 0; _LS <= 1; HIN_T <= 0; _LT <= 1;
    end
    if(rotateState == 3'd5)begin
      rotateState <= 3'd0;
    end else begin
      rotateState <= rotateState + 3'd1;
    end

  end

  assign boardLED[2:0] = HS;
  assign boardLED[5:3] = toggleSW;

  assign _LIN_R = ~(~_LR * duty);
  assign _LIN_S = ~(~_LS * duty);
  assign _LIN_T = ~(~_LT * duty);

//test
//  assign anode = 8'b00010100;
  assign anode[6] = HIN_R;
  assign anode[7] = HIN_S;
  assign anode[5] = HIN_T;
  assign cathode = 4'b0001;

endmodule

module timer #(
  parameter COUNT_MAX = 27000
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
