`ifndef DEFINE_STATE

// This defines the states
typedef enum logic [2:0] {
	S_IDLE,
	S_ENABLE_UART_RX,
	S_WAIT_UART_RX,
	S_M1_top,
	S_M2_top
} top_state_type;

typedef enum logic [1:0] {
	S_RXC_IDLE,
	S_RXC_SYNC,
	S_RXC_ASSEMBLE_DATA,
	S_RXC_STOP_BIT
} RX_Controller_state_type;

typedef enum logic [2:0] {
	S_US_IDLE,
	S_US_STRIP_FILE_HEADER_1,
	S_US_STRIP_FILE_HEADER_2,
	S_US_START_FIRST_BYTE_RECEIVE,
	S_US_WRITE_FIRST_BYTE,
	S_US_START_SECOND_BYTE_RECEIVE,
	S_US_WRITE_SECOND_BYTE
} UART_SRAM_state_type;

typedef enum logic [3:0] {
	S_VS_WAIT_NEW_PIXEL_ROW,
	S_VS_NEW_PIXEL_ROW_DELAY_1,
	S_VS_NEW_PIXEL_ROW_DELAY_2,
	S_VS_NEW_PIXEL_ROW_DELAY_3,
	S_VS_NEW_PIXEL_ROW_DELAY_4,
	S_VS_NEW_PIXEL_ROW_DELAY_5,
	S_VS_FETCH_PIXEL_DATA_0,
	S_VS_FETCH_PIXEL_DATA_1,
	S_VS_FETCH_PIXEL_DATA_2,
	S_VS_FETCH_PIXEL_DATA_3
} VGA_SRAM_state_type;

typedef enum logic [5:0] {
	S_IDLE_M1,
	S_LEAD_IN_STALL,
	S_LEAD_IN_0,
	S_LEAD_IN_1,
	S_LEAD_IN_2,
	S_LEAD_IN_3,
	S_LEAD_IN_4,
	S_LEAD_IN_5,
	S_LEAD_IN_6,
	S_LEAD_IN_7,
	S_LEAD_IN_8,
	S_LEAD_IN_9,
	S_LEAD_IN_10,
	S_LEAD_IN_11,
	S_LEAD_IN_12,
	S_LEAD_IN_13,
	S_LEAD_IN_14,
	S_LEAD_IN_15,
	S_LEAD_IN_16,
	S_LEAD_IN_17,
	S_COMMON_CASE_0,
	S_COMMON_CASE_1,
	S_COMMON_CASE_2,
	S_COMMON_CASE_3,
	S_COMMON_CASE_4,
	S_COMMON_CASE_5,
	S_COMMON_CASE_6,
	S_COMMON_CASE_7,
	S_COMMON_CASE_8,
	S_COMMON_CASE_9,
	S_COMMON_CASE_10,
	S_COMMON_CASE_11,
	S_HARD_LEAD_OUT_0,
	S_HARD_LEAD_OUT_1,
	S_HARD_LEAD_OUT_2,
	S_COMMON_CASE_STALL
} M1_state_type;  


typedef enum logic [7:0] {
	S_M2_IDLE,
	S_M2_LEAD_IN_STALL,
	S_Fetch_S_Prime0,
	S_Fetch_S_Prime1,
	S_Fetch_S_Prime2,
	S_Fetch_S_Prime3,
	S_Fetch_S_Prime4,
	S_Fetch_S_Prime5,
	S_Fetch_S_Prime6,
	S_Fetch_S_Prime7,
	S_Fetch_S_Prime8,
	S_Fetch_S_Prime9,
	S_Fetch_S_Prime10,
	S_Compute_T_STALL,
	S_Compute_T_0, 
	S_Compute_T_1,
	S_Compute_T_2,
	S_Compute_T_3, 
	S_Compute_T_4,
	S_Compute_T_5,
	S_Compute_T_6, 
	S_Compute_T_7,
	S_Compute_T_8,
	S_Compute_T_9,
	S_Compute_T_10,
	S_Compute_T_11,
	S_Compute_T_12,
	S_Compute_T_13,
	S_Compute_T_14,
	S_Compute_T_15,
	S_Compute_T_16,
	S_MS_A_0,
	S_MS_A_1,
	S_MS_A_2,
	S_MS_A_3,
	S_MS_A_4,
	S_MS_A_5,
	S_MS_A_6,
	S_MS_A_7,
	S_MS_A_8,
	S_MS_A_9,
	S_MS_A_10,
	S_MS_A_Stall,
	S_MS_B_0,
	S_MS_B_1,
	S_MS_B_2,
	S_MS_B_3,
	S_MS_B_4,
	S_MS_B_5,
	S_MS_B_6,
	S_MS_B_7,
	S_MS_B_8,
	S_MS_B_9,
	S_MS_B_10,
	S_MS_B_STALL,
	S_MS_B_STALL_0,
	S_MS_B_STALL_1,
	S_MS_B_STALL_2,
	S_MS_B_STALL_3,
	S_MS_B_STALL_4,
	S_MS_B_STALL_5
	
	
	
} M2_state_type;  


`define DEFINE_STATE 1
`endif
