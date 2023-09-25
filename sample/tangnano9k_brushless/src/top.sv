`default_nettype none

module top (
  input  wire       clk,

  input  wire sw1,
  input  wire sw2,
  input wire[3:0] tacSW,
  input wire[2:0] toggleSW,
  input  wire[2:0] HS,  //HallSensor
  output wire AD_CLK,
  output logic CS,
  output logic DIN,
  input reg DOUT,
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
  logic[6:0] forcedRotationCounter;  //強制転流用インターバルカウンタ
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

  logic[15:0] display7seg; //0000-9999
  logic[1:0] disp_digit;

  logic[9:0] recieveADC;
  logic[9:0] accel;


  timer #(
    .COUNT_MAX()
  ) inst_1 (
    .clk (clk),
    .overflow(controlCLK)
  );

  always @(posedge controlCLK)begin

    if(isRotate == 0)begin
      if(forcedRotationCounter == 7'd110)begin
        rotateState <= (rotateState + 1) % 6;
        forcedRotationCounter <= 5'd0;
      end else begin
        forcedRotationCounter <= forcedRotationCounter + 1;
      end
    end else begin
//changing rotateState by hall sensor
      if(toggleSW[0])begin   //CW
        case(HS)
          3'd1: rotateState = 3'd4;
          3'd2: rotateState = 3'd0;
          3'd3: rotateState = 3'd5;
          3'd4: rotateState = 3'd2;
          3'd5: rotateState = 3'd3;
          3'd6: rotateState = 3'd1;
        endcase
      end else begin         //CCW
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

// measure speed
    processCounter <= processCounter + 1;
    if(processCounter % 2024 == 0)begin
//      anode[2] <= ~anode[2];  // pilot lamp blink
      if(HSCounter > 1)begin
        isRotate <= 'b1;
      end else begin
        isRotate <= 'b0;
      end
      HSCounter <= 0;
    end else begin
      if(oldHS != HS)begin
        HSCounter <= HSCounter + 1;
        oldHS <= HS;
      end
    end

//ADC
    if(processCounter[4:0] == 5'd0)begin
      CS <= 0;
      DIN <= 0;
    end else if(processCounter[4:0] < 5'd9)begin
      CS <=0;
    end else if(processCounter[4:0] == 5'd9)begin  // START(always: 1)
      DIN <= 1;
      CS <= 0;
    end else if(processCounter[4:0] == 5'd10)begin  //SINGLE or DIFFERENTIAL(SGL: 1)
      DIN <= 1;
      CS <= 0;
    end else if(processCounter[4:0] == 5'd11)begin  // D2
      DIN <= 1;
      CS <= 0;
    end else if(processCounter[4:0] == 5'd12)begin  // D1
      DIN <= 0;
      CS <= 0;
    end else if(processCounter[4:0] == 5'd13)begin  // D0
      DIN <= 0;
      CS <= 0;
    end else if(processCounter[4:0] < 5'd15)begin  // D0
      CS <= 0;
    end else if(processCounter[4:0] > 5'd14 && processCounter[4:0] < 25)begin
      recieveADC[9 - processCounter[2:0]] <= DOUT;
      DIN <= 0;
      CS <= 0;
    end else begin
      accel <= (recieveADC - 'd280) / 'd32;  // for Mini Cart Accel     //origin 270 - 780  to 0 - 16
      DIN <= 0;
      CS <= 1;
    end

//duty control
    if(dutyCounter[3:0] < accel)begin
      duty <= 'b1;
    end else begin
      duty <= 'b0;
    end
    dutyCounter <= dutyCounter + 'd1;

  end

  //7seg control
  logic[9:0] divider;
  always @(posedge processCounter[3])begin
    if(tacSW[3] == 0)begin
      display7seg <= recieveADC;
    end else begin
      display7seg <= 0;
    end

    disp_digit <= disp_digit + 1;
    cathode <= 4'b0001 << disp_digit;

    case(disp_digit)
      2'd0: divider = 1;
      2'd1: divider = 10;
      2'd2: divider = 100;
      2'd3: divider = 1000;
    endcase

    anode <= decode7seg((display7seg/divider) % 10);
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

  assign AD_CLK = controlCLK;
  assign boardLED[2:0] = HS;
  assign boardLED[5] = toggleSW[0];
  assign boardLED[4] = toggleSW[1];
  assign boardLED[3] = toggleSW[2];
//  assign anode[0] = isRotate;

  assign _LIN_R = ~(~_LR * duty);
  assign _LIN_S = ~(~_LS * duty);
  assign _LIN_T = ~(~_LT * duty);

//test
//  assign anode = 8'b00010100;
//  assign anode[6] = HIN_R;
//  assign anode[7] = HIN_S;
//  assign anode[5] = HIN_T;
//  assign anode[1] = tacSW[0];
//  assign cathode = 4'b0001;

  function [7:0] decode7seg;
  input [3:0] in;
    case(in)
      4'h0:  decode7seg = 8'b00000011;
      4'h1:  decode7seg = 8'b10011111;
      4'h2:  decode7seg = 8'b00100101;
      4'h3:  decode7seg = 8'b00001101;
      4'h4:  decode7seg = 8'b10011001;
      4'h5:  decode7seg = 8'b01001001;
      4'h6:  decode7seg = 8'b01000001;
      4'h7:  decode7seg = 8'b00011111;
      4'h8:  decode7seg = 8'b00000001;
      4'h9:  decode7seg = 8'b00001001;
      4'ha:  decode7seg = 8'b00010001;
      4'hb:  decode7seg = 8'b11000001;
      4'hc:  decode7seg = 8'b01100011;
      4'hd:  decode7seg = 8'b10000101;
      4'he:  decode7seg = 8'b01100001;
      4'hf:  decode7seg = 8'b01110001;
      default:decode7seg = 8'b11111111;
    endcase
  endfunction
endmodule

module timer #(
  parameter COUNT_MAX = 2700  //100us
) (
  input  wire  clk,
  output logic overflow
);

  logic [$clog2(COUNT_MAX+1)-1:0] counter = 'd0;

  always_ff @ (posedge clk) begin
    if(counter == COUNT_MAX)begin
      counter  <= 'd0;
    end else if (counter < COUNT_MAX/2) begin
      overflow <= 'd1;
      counter  <= counter + 'd1;
    end else begin
      counter  <= counter + 'd1;
      overflow <= 'd0;
    end
  end

endmodule

`default_nettype wire
