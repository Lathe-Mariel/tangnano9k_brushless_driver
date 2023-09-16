`default_nettype none

module top (
  input  wire       clk,

  input  wire sw1,
  input  wire sw2,
  input  wire rotary1_a,
  input  wire rotary1_b,
  input  wire rotary1_SW,
  input  wire rotary2_a,
  input  wire rotary2_b,
  input  wire rotary2_SW,
  output wire boardLED1,

  output wire [7:0] anode,
  output wire [7:0] cathode
);

  logic       oneSecondCLK;
  logic       oneSecondOverflow;

  logic [7:0] row_p, col_p;

// for Board ver0.2 - ver0.3
//  assign cathode[0] = ~col_p[7];
//  assign cathode[1] = ~col_p[6];
//  assign cathode[2] = ~col_p[5];
//  assign cathode[3] = ~col_p[4];
//  assign cathode[4] = ~col_p[3];
//  assign cathode[5] = ~col_p[2];
//  assign cathode[6] = ~col_p[1];
//  assign cathode[7] = ~col_p[0];
//  assign anode = row_p;  

// for Board ver 0.1
  assign cathode[7] = row_p[0];
  assign cathode[6] = row_p[1];
  assign cathode[5] = row_p[2];
  assign cathode[4] = row_p[3];
  assign cathode[3] = row_p[4];
  assign cathode[2] = row_p[5];
  assign cathode[1] = row_p[6];
  assign cathode[0] = row_p[7];
  assign anode = ~col_p;

  LEDMatrixAB_m inst_2 (
    .clk(clk),
    .rst(1'b0),
    .boardLED1(boardLED1),
    .oneSecondCLK(oneSecondCLK),

    .swA(sw1),
    .swB(sw2),
    .rotary1_a(rotary1_a),
    .rotary1_b(rotary1_b),

    .col(col_p),
    .row(row_p)
  );

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
