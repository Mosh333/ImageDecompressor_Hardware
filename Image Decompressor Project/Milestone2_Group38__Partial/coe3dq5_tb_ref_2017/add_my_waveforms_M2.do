
#Add Milestone 2 Waves
# add waves to waveform
add wave -unsigned uut/M2_unit/CLOCK_50_I
add wave -divider {Top Level}
add wave -unsigned uut/M2_unit/M2_state

#SRAM SIGNALS------------------------------------------------------------
add wave -divider {SRAM Signals}
add wave -unsigned uut/M2_SRAM_address
add wave -unsigned uut/SRAM_read_data
add wave -hexadecimal uut/SRAM_write_data
add wave uut/SRAM_we_n

add wave -unsigned uut/M2_unit/T_Values_Written
add wave -unsigned uut/M2_unit/write_enable_a_1
add wave -decimal uut/M2_unit/T_0
add wave -decimal uut/M2_unit/T_1
add wave -decimal uut/M2_unit/T_2
add wave -decimal uut/M2_unit/T_3
#add wave -decimal uut/M2_unit/IterationsCt
#COUNTER SIGNALS-----------------------------------------------------------
add wave -divider {Counting}
add wave -unsigned uut/M2_unit/SAMPLE_COUNTER
add wave -unsigned uut/M2_unit/column_address
add wave -unsigned uut/M2_unit/column_block
add wave -unsigned uut/M2_unit/column_index
add wave -unsigned uut/M2_unit/row_address
add wave -unsigned uut/M2_unit/row_block
add wave -unsigned uut/M2_unit/row_index

#DPRAM 0 SIGNALS------------------------------------------------------------------------
add wave -divider {DPRAM 0 - STORES S'}
add wave -unsigned uut/M2_unit/RAM_0_address_A
add wave -hexadecimal uut/M2_unit/write_data_a_0
add wave -hexadecimal uut/M2_unit/write_enable_a_0
add wave -hexadecimal uut/M2_unit/read_data_a_0


add wave -unsigned  uut/M2_unit/RAM_0_address_B
add wave -hexadecimal uut/M2_unit/write_data_b_0
add wave -unsigned uut/M2_unit/write_enable_b_0
add wave -hexadecimal uut/M2_unit/read_data_b_0

add wave -hexadecimal uut/M2_unit/DPRAM_0_ADDRESS_COUNTER


#DPRAM 1 SIGNALS------------------------------------------------------------------------
add wave -divider {DPRAM 1 - STORES T}
add wave -unsigned uut/M2_unit/RAM_1_address_A
add wave -decimal uut/M2_unit/write_data_a_1
add wave -unsigned uut/M2_unit/write_enable_a_1

add wave -unsigned uut/M2_unit/RAM_1_address_B
add wave -decimal uut/M2_unit/write_data_b_1
add wave -unsigned uut/M2_unit/write_enable_b_1

add wave -unsigned uut/M2_unit/DPRAM_1_ADDRESS_COUNTER


#DPRAM 2 SIGNALS------------------------------------------------------------------------
add wave -divider {DPRAM 2 - STORES S}
add wave -unsigned uut/M2_unit/RAM_2_address_A
add wave -decimal uut/M2_unit/write_data_a_2
add wave -hexadecimal uut/M2_unit/write_enable_a_2

add wave -unsigned uut/M2_unit/RAM_2_address_B
add wave -decimal uut/M2_unit/write_data_b_2
add wave -hexadecimal uut/M2_unit/write_enable_b_2

add wave -unsigned uut/M2_unit/DPRAM_2_ADDRESS_COUNTER


#COMPUTE T SIGNALS------------------------------------------------------------------------
add wave -divider {Compute T Signals}
add wave uut/M2_unit/M2_state
add wave -unsigned uut/M2_unit/T_Values_Written
add wave -decimal uut/M2_unit/T_accum_0
add wave -decimal uut/M2_unit/T_accum_1
add wave -decimal uut/M2_unit/T_accum_2
add wave -decimal uut/M2_unit/T_accum_3
add wave -decimal uut/M2_unit/M1_result
add wave -decimal uut/M2_unit/M2_result
add wave -decimal uut/M2_unit/M3_result
add wave -decimal uut/M2_unit/M4_result
add wave -decimal uut/M2_unit/M1_op1
add wave -hexadecimal uut/M2_unit/M1_op2
add wave -decimal uut/M2_unit/M2_op1
add wave -hexadecimal uut/M2_unit/M2_op2
add wave -decimal uut/M2_unit/M3_op1
add wave -hexadecimal uut/M2_unit/M3_op2
add wave -decimal uut/M2_unit/M4_op1
add wave -hexadecimal uut/M2_unit/M4_op2
add wave -binary uut/M2_unit/C_matrix_half_flag
add wave -unsigned uut/M2_unit/M2_state


#COUNTING SIGNALS------------------------------------------------------------------------
add wave -divider {Counting}
add wave -unsigned uut/M2_unit/SAMPLE_COUNTER
add wave -unsigned uut/M2_unit/column_address
add wave -unsigned uut/M2_unit/column_block
add wave -unsigned uut/M2_unit/column_index
add wave -unsigned uut/M2_unit/row_address
add wave -unsigned uut/M2_unit/row_block
add wave -unsigned uut/M2_unit/row_index

#S PRIME BUFFER SIGNALS------------------------------------------------------------------------

#add wave -divider {S Prime Values From DP-RAM}
#add wave -decimal uut/M2_unit/Sp_0
#add wave -decimal uut/M2_unit/Sp_1
#add wave -decimal uut/M2_unit/Sp_2
#add wave -decimal uut/M2_unit/Sp_3
#add wave -decimal uut/M2_unit/Sp_4
#add wave -decimal uut/M2_unit/Sp_5
#add wave -decimal uut/M2_unit/Sp_6
#add wave -decimal uut/M2_unit/Sp_7

#TOP LEVEL SIGNALS------------------------------------------------------------------------
add wave -divider {Top-level signals}
add wave Clock_50
add wave -decimal uut/top_state
add wave -decimal uut/M2_finish
#add wave -unsigned num_mismatches
add wave -unsigned uut/SRAM_address
add wave -unsigned uut/M2_unit/M2_state
add wave uut/SRAM_we_n

add wave -unsigned uut/M2_unit/S_FETCH_ITERATION





