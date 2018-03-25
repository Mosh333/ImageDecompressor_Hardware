

# add waves to waveform

add wave -divider {Top-level signals}
add wave Clock_50
add wave -decimal uut/top_state
add wave -decimal uut/M1_finish
#add wave -decimal num_mismatches
add wave -unsigned uut/SRAM_address
add wave -unsigned uut/M1_unit/M1_state
add wave -unsigned uut/SRAM_read_data
add wave -hexadecimal uut/SRAM_write_data
add wave uut/SRAM_we_n

add wave -hexadecimal uut/M1_unit/R_clip_even
add wave -hexadecimal uut/M1_unit/G_clip_even
add wave -hexadecimal uut/M1_unit/B_clip_even

#add wave -hexadecimal uut/M1_unit/finishedHere


add wave -hexadecimal uut/M1_unit/R_clip_odd
add wave -hexadecimal uut/M1_unit/G_clip_odd
add wave -hexadecimal uut/M1_unit/B_clip_odd


add wave -hexadecimal uut/M1_unit/RGB_MAC_Buf_Even_RED
add wave -hexadecimal uut/M1_unit/RGB_MAC_Buf_Odd_RED


#add wave -hexadecimal uut/M1_unit/RGB_MAC_Buf_Even_GREEN
#add wave -hexadecimal uut/M1_unit/RGB_MAC_Buf_Odd_GREEN


#add wave -hexadecimal uut/M1_unit/RGB_MAC_Buf_Even_BLUE
#add wave -hexadecimal uut/M1_unit/RGB_MAC_Buf_Odd_BLUE


add wave -divider {Milestone signals}
#add wave -unsigned uut/M1_unit/M1_start
#add wave -unsigned uut/M1_unit/M1_finish
add wave -unsigned uut/M1_unit/pixel_counter
add wave -unsigned uut/M1_unit/row_counter
add wave -unsigned uut/M1_unit/commonCaseIter
#add wave -unsigned uut/M1_unit/M1_SRAM_address
#add wave -unsigned uut/M1_unit/M1_SRAM_write_data
#add wave uut/M1_unit/M1_SRAM_we_n
#add wave -unsigned uut/M1_unit/SRAM_read_data
add wave -divider {RGB Signals Being Accumulated}
#add wave -hexadecimal uut/M1_unit/RGB_MAC_EVEN_ACCUM
#add wave -hexadecimal uut/M1_unit/RGB_MAC_ODD_ACCUM

add wave -divider {RGB Signals To Write}


#add wave -divider {U Prime and V Prime Buffers}
#add wave -hexadecimal uut/M1_unit/U_Prime_Accum
#add wave -hexadecimal uut/M1_unit/V_Prime_Accum

add wave -unsigned uut/M1_unit/U_Prime_odd_buf
add wave -unsigned uut/M1_unit/V_Prime_odd_buf

#add wave -unsigned uut/M1_unit/M1_result
#add wave -unsigned uut/M1_unit/M2_result
#add wave -unsigned uut/M1_unit/M3_result
#add wave -unsigned uut/M1_unit/M4_result

add wave -divider {M1 State}
add wave -unsigned uut/M1_unit/M1_state

add wave -divider {Lead Out Flags}
add wave -decimal uut/M1_unit/lead_Out_Y_flag
add wave -decimal uut/M1_unit/lead_Out_Interpolation_flag
add wave -decimal uut/M1_unit/lead_Out_START_NEW_ROW
add wave -decimal uut/M1_unit/lead_Out_HARD_flag

#add wave -divider {Multiplier Operands}
#add wave -unsigned uut/M1_unit/M1_op1;
#add wave -unsigned uut/M1_unit/M1_op2;
#add wave -unsigned uut/M1_unit/M2_op1;
#add wave -unsigned uut/M1_unit/M2_op2;
#add wave -unsigned uut/M1_unit/M3_op1;
#add wave -unsigned uut/M1_unit/M3_op2;
#add wave -unsigned uut/M1_unit/M4_op1;
#add wave -unsigned uut/M1_unit/M4_op2;

add wave -divider {U Value Shift Registers}
add wave -hexadecimal uut/M1_unit/U_0;
add wave -hexadecimal uut/M1_unit/U_1;
add wave -hexadecimal uut/M1_unit/U_2;
add wave -hexadecimal uut/M1_unit/U_3;
add wave -hexadecimal uut/M1_unit/U_4;
add wave -hexadecimal uut/M1_unit/U_5;

add wave -divider {V Value Shift Registers}
add wave -hexadecimal uut/M1_unit/V_0;
add wave -hexadecimal uut/M1_unit/V_1;
add wave -hexadecimal uut/M1_unit/V_2;
add wave -hexadecimal uut/M1_unit/V_3;
add wave -hexadecimal uut/M1_unit/V_4;
add wave -hexadecimal uut/M1_unit/V_5;


add wave -divider {Y Values}
add wave -hexadecimal uut/M1_unit/Y_even;
add wave -hexadecimal uut/M1_unit/Y_odd;
add wave -hexadecimal uut/M1_unit/Y_even_buf;
add wave -hexadecimal uut/M1_unit/Y_odd_buf;

add wave -divider {U and V Values}
add wave -hexadecimal uut/M1_unit/U_even;
add wave -hexadecimal uut/M1_unit/U_even_buf;
add wave -hexadecimal uut/M1_unit/U_odd;
add wave -hexadecimal uut/M1_unit/U_odd_buf;
add wave -hexadecimal uut/M1_unit/V_even;
add wave -hexadecimal uut/M1_unit/V_even_buf;
add wave -hexadecimal uut/M1_unit/V_odd;
add wave -hexadecimal uut/M1_unit/V_odd_buf;

#add wave -hexadecimal uut/M1_unit/M1_result_long
#add wave -hexadecimal uut/M1_unit/M2_result_long
#add wave -hexadecimal uut/M1_unit/M3_result_long
#add wave -hexadecimal uut/M1_unit/M4_result_long

add wave -decimal uut/M1_unit/Y_16_Buf_Even
add wave -decimal uut/M1_unit/Y_16_Buf_Odd



add wave -divider {Mismatch}
#add wave -decimal num_mismatches

add wave -hexadecimal uut/M1_unit/G_clip_even_buf

