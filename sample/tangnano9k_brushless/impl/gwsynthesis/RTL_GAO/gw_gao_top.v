module gw_gao(
    duty,
    \rotateState[2] ,
    \rotateState[1] ,
    \rotateState[0] ,
    HIN_R,
    HIN_S,
    HIN_T,
    _LIN_R,
    _LIN_S,
    _LIN_T,
    \processCounter[2] ,
    \anode[7] ,
    \anode[6] ,
    \anode[5] ,
    \anode[4] ,
    \anode[3] ,
    \anode[2] ,
    \anode[1] ,
    \anode[0] ,
    \disp_digit[1] ,
    \disp_digit[0] ,
    \divider[9] ,
    \divider[8] ,
    \divider[7] ,
    \divider[6] ,
    \divider[5] ,
    \divider[4] ,
    \divider[3] ,
    \divider[2] ,
    \divider[1] ,
    \divider[0] ,
    \inst_1/counter[10] ,
    tms_pad_i,
    tck_pad_i,
    tdi_pad_i,
    tdo_pad_o
);

input duty;
input \rotateState[2] ;
input \rotateState[1] ;
input \rotateState[0] ;
input HIN_R;
input HIN_S;
input HIN_T;
input _LIN_R;
input _LIN_S;
input _LIN_T;
input \processCounter[2] ;
input \anode[7] ;
input \anode[6] ;
input \anode[5] ;
input \anode[4] ;
input \anode[3] ;
input \anode[2] ;
input \anode[1] ;
input \anode[0] ;
input \disp_digit[1] ;
input \disp_digit[0] ;
input \divider[9] ;
input \divider[8] ;
input \divider[7] ;
input \divider[6] ;
input \divider[5] ;
input \divider[4] ;
input \divider[3] ;
input \divider[2] ;
input \divider[1] ;
input \divider[0] ;
input \inst_1/counter[10] ;
input tms_pad_i;
input tck_pad_i;
input tdi_pad_i;
output tdo_pad_o;

wire duty;
wire \rotateState[2] ;
wire \rotateState[1] ;
wire \rotateState[0] ;
wire HIN_R;
wire HIN_S;
wire HIN_T;
wire _LIN_R;
wire _LIN_S;
wire _LIN_T;
wire \processCounter[2] ;
wire \anode[7] ;
wire \anode[6] ;
wire \anode[5] ;
wire \anode[4] ;
wire \anode[3] ;
wire \anode[2] ;
wire \anode[1] ;
wire \anode[0] ;
wire \disp_digit[1] ;
wire \disp_digit[0] ;
wire \divider[9] ;
wire \divider[8] ;
wire \divider[7] ;
wire \divider[6] ;
wire \divider[5] ;
wire \divider[4] ;
wire \divider[3] ;
wire \divider[2] ;
wire \divider[1] ;
wire \divider[0] ;
wire \inst_1/counter[10] ;
wire tms_pad_i;
wire tck_pad_i;
wire tdi_pad_i;
wire tdo_pad_o;
wire tms_i_c;
wire tck_i_c;
wire tdi_i_c;
wire tdo_o_c;
wire [9:0] control0;
wire gao_jtag_tck;
wire gao_jtag_reset;
wire run_test_idle_er1;
wire run_test_idle_er2;
wire shift_dr_capture_dr;
wire update_dr;
wire pause_dr;
wire enable_er1;
wire enable_er2;
wire gao_jtag_tdi;
wire tdo_er1;

IBUF tms_ibuf (
    .I(tms_pad_i),
    .O(tms_i_c)
);

IBUF tck_ibuf (
    .I(tck_pad_i),
    .O(tck_i_c)
);

IBUF tdi_ibuf (
    .I(tdi_pad_i),
    .O(tdi_i_c)
);

OBUF tdo_obuf (
    .I(tdo_o_c),
    .O(tdo_pad_o)
);

GW_JTAG  u_gw_jtag(
    .tms_pad_i(tms_i_c),
    .tck_pad_i(tck_i_c),
    .tdi_pad_i(tdi_i_c),
    .tdo_pad_o(tdo_o_c),
    .tck_o(gao_jtag_tck),
    .test_logic_reset_o(gao_jtag_reset),
    .run_test_idle_er1_o(run_test_idle_er1),
    .run_test_idle_er2_o(run_test_idle_er2),
    .shift_dr_capture_dr_o(shift_dr_capture_dr),
    .update_dr_o(update_dr),
    .pause_dr_o(pause_dr),
    .enable_er1_o(enable_er1),
    .enable_er2_o(enable_er2),
    .tdi_o(gao_jtag_tdi),
    .tdo_er1_i(tdo_er1),
    .tdo_er2_i(1'b0)
);

gw_con_top  u_icon_top(
    .tck_i(gao_jtag_tck),
    .tdi_i(gao_jtag_tdi),
    .tdo_o(tdo_er1),
    .rst_i(gao_jtag_reset),
    .control0(control0[9:0]),
    .enable_i(enable_er1),
    .shift_dr_capture_dr_i(shift_dr_capture_dr),
    .update_dr_i(update_dr)
);

ao_top u_ao_top(
    .control(control0[9:0]),
    .data_i({duty,\rotateState[2] ,\rotateState[1] ,\rotateState[0] ,HIN_R,HIN_S,HIN_T,_LIN_R,_LIN_S,_LIN_T,\processCounter[2] ,\anode[7] ,\anode[6] ,\anode[5] ,\anode[4] ,\anode[3] ,\anode[2] ,\anode[1] ,\anode[0] ,\disp_digit[1] ,\disp_digit[0] ,\divider[9] ,\divider[8] ,\divider[7] ,\divider[6] ,\divider[5] ,\divider[4] ,\divider[3] ,\divider[2] ,\divider[1] ,\divider[0] }),
    .clk_i(\inst_1/counter[10] )
);

endmodule
