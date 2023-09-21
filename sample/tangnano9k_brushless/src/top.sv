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
  logic[6:0] rotateCounter;
  logic[2:0]  rotateState;
  logic duty;
  logic[3:0] dutyCounter;
  logic _LR;
  logic _LS;
  logic _LT;
  logic[15:0] processCounter;
  logic[7:0] HSCounter;
  logic isRotate;
  logic[2:0] oldHS;

  timer #(
    .COUNT_MAX()
  ) inst_1 (
    .clk (clk),
    .overflow(controlCLK)
  );

  always @(posedge controlCLK)begin

    if(isRotate == 0)begin
      if(rotateCounter == 7'd90)begin
        rotateState <= (rotateState + 1) % 6;
        rotateCounter <= 5'd0;
      end else begin
        rotateCounter <= rotateCounter + 1;
      end
    end else begin
//changing rotateState by hall sensor
      if(toggleSW[0])begin 
        case(HS)
          3'd1: rotateState = 3'd4;
          3'd2: rotateState = 3'd0;
          3'd3: rotateState = 3'd5;
          3'd4: rotateState = 3'd2;
          3'd5: rotateState = 3'd3;
          3'd6: rotateState = 3'd1;
        endcase
      end else begin
        case(HS)
          3'd1: rotateState = 3'd1;
          3'd2: rotateState = 3'd3;
          3'd3: rotateState = 3'd2;
          3'd4: rotateState = 3'd5;
          3'd5: rotateState = 3'd0;
          3'd6: rotateState = 3'd4;
        endcase
      end
    end

    if(processCounter == 'd1024)begin
      anode[2] <= ~anode[2];
      if(HSCounter > 1)begin
        isRotate <= 'b1;
      end else begin
        isRotate <= 'b0;
      end
      HSCounter <= 0;
      processCounter <= 0;
    end else begin
      processCounter <= processCounter + 1;
      if(oldHS != HS)begin
        HSCounter <= HSCounter + 1;
        oldHS <= HS;
      end
    end

    if(dutyCounter[1:0] == 3'b11)begin
      duty <= 'b1;
    end else if(tacSW[0] == 0 && dutyCounter[0] == 1)begin
      duty <= 'b1;
    end else begin
      duty <= 'b0;
    end
    dutyCounter <= dutyCounter + 1;

  end

  always @(rotateState)begin
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
  end

  assign boardLED[2:0] = HS;
  assign boardLED[5] = toggleSW[0];
  assign boardLED[4] = toggleSW[1];
  assign boardLED[3] = toggleSW[2];
  assign anode[0] = isRotate;

  assign _LIN_R = ~(~_LR * duty);
  assign _LIN_S = ~(~_LS * duty);
  assign _LIN_T = ~(~_LT * duty);

//test
//  assign anode = 8'b00010100;
  assign anode[6] = HIN_R;
  assign anode[7] = HIN_S;
  assign anode[5] = HIN_T;
  assign anode[1] = tacSW[0];
  assign cathode = 4'b0001;

  function [7:0] decode7seg;
  input [3:0] in;
    case(in)
      4'h0:  decode7seg = 8'b00000000;
      4'h1:  decode7seg = 8'b01100000;
      4'h2:  decode7seg = 8'b11011010;
      4'h3:  decode7seg = 8'b11110010;
      4'h4:  decode7seg = 8'b01100110;
      4'h5:  decode7seg = 8'b10110110;
      4'h6:  decode7seg = 8'b10111110;
      4'h7:  decode7seg = 8'b11100000;
      4'h8:  decode7seg = 8'b11111110;
      4'h9:  decode7seg = 8'b11110110;
      4'ha:  decode7seg = 8'b11101110;
      4'hb:  decode7seg = 8'b00111110;
      4'hc:  decode7seg = 8'b10011100;
      4'hd:  decode7seg = 8'b01111010;
      4'he:  decode7seg = 8'b10011110;
      4'hf:  decode7seg = 8'b10001110;
      default:decode7seg = 8'b00000000;
    endcase
  endfunction
endmodule

module timer #(
  parameter COUNT_MAX = 2700
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
