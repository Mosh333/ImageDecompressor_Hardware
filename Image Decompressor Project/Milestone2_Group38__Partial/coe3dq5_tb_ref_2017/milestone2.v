/*
Copyright by Henry Ko and Nicola Nicolici
Developed for the Digital Systems Design course (COE3DQ4)
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/

`timescale 1ns/100ps
`default_nettype none

`include "define_state.h"

// This is the top module
// It connects the UART, SRAM and VGA together.
// It gives access to the SRAM for UART and VGA

module milestone2 (
   input  logic            CLOCK_50_I,
   input  logic            Resetn,

   input  logic            M2_start,
   output  logic           M2_finish,

   output logic   [17:0]   M2_SRAM_address,
   output logic   [15:0]   M2_SRAM_write_data,
   output logic            M2_SRAM_we_n,
   input logic [15:0]	   SRAM_read_data
);

M2_state_type M2_state;

logic [6:0] RAM_0_address_A;  //ADDRESS A LOCATION FOR DP-RAM 0
logic [6:0] RAM_1_address_A;
logic [6:0] RAM_2_address_A;
logic [6:0] RAM_0_address_B;
logic [6:0] RAM_1_address_B;
logic [6:0] RAM_2_address_B;

logic signed [31:0] write_data_a_0;
logic signed [31:0] write_data_a_1;
logic signed [31:0] write_data_a_2;
logic signed [31:0] write_data_b_0;
logic signed [31:0] write_data_b_1;
logic signed [31:0] write_data_b_2;

//DPRAM 0 - FOR S' MATRIX STORAGE
logic write_enable_a_0;
logic write_enable_b_0;

//DPRAM 1 - TBD
logic write_enable_a_1;
logic write_enable_b_1;


//DPRAM 2 - T MATRIX STORAGE (T=S'*C)
logic write_enable_a_2;
logic write_enable_b_2;

logic signed[31:0] read_data_a_0;
logic signed [31:0] read_data_a_1;
logic signed [31:0] read_data_a_2;
logic signed [31:0] read_data_b_0;
logic signed [31:0] read_data_b_1;
logic signed [31:0] read_data_b_2;

logic [6:0] MS_B_Count;
logic [10:0] S_FETCH_ITERATION;
logic [5:0] T_Values_Written;



// SET PARAMETERS that define structure of the sram YUV locations to be read
parameter 	Y_ADDRESS = 18'd0, //0 TO 38,399
				U_ADDRESS = 18'd38400, // 38,400 TO 57,599
				V_ADDRESS = 18'd57600, //57,600 TO 76,799
				PRE_IDCT_ADDRESS = 18'd76800,//--> 76,800  TO 146,943
				DPRAM_0_ADDRESS = 7'd0,
				DPRAM_1_ADDRESS = 7'd0,
				DPRAM_2_ADDRESS = 7'd0,
				
				
				DCT_0_0=1448,
				DCT_1_0=1448,
				DCT_2_0=1448,
				DCT_3_0=1448,
				DCT_4_0=1448,
				DCT_5_0=1448,
				DCT_6_0=1448,
				DCT_7_0=1448,

				DCT_0_1=2008,
				DCT_1_1=1702,
				DCT_2_1=1137,
				DCT_3_1=399,
				DCT_4_1=-399,
				DCT_5_1=-1137,
				DCT_6_1=-1702,
				DCT_7_1=-2008,
				DCT_0_2=1892,
				DCT_1_2=783,
				DCT_2_2=-783,
				DCT_3_2=-1892,
				DCT_4_2=-1892,
				DCT_5_2=-783,
				DCT_6_2=783,
				DCT_7_2=1892,
				DCT_0_3=1702,
				DCT_1_3=-399,
				DCT_2_3=-2008,
				DCT_3_3=-1137,
				DCT_4_3=1137,
				DCT_5_3=2008,
				DCT_6_3=399,
				DCT_7_3=-1702,
				DCT_0_4=1448,
				DCT_1_4=-1448,
				DCT_2_4=-1448,
				DCT_3_4=1448,
				DCT_4_4=1448,
				DCT_5_4=-1448,
				DCT_6_4=-1448,
				DCT_7_4=1448,
				DCT_0_5=1137,
				DCT_1_5=-2008,
				DCT_2_5=399,
				DCT_3_5=1702,
				DCT_4_5=-1702,
				DCT_5_5=-399,
				DCT_6_5=2008,
				DCT_7_5=-1137,
				DCT_0_6=783,
				DCT_1_6=-1892,
				DCT_2_6=1892,
				DCT_3_6=-783,
				DCT_4_6=-783,
				DCT_5_6=892,
				DCT_6_6=-1892,
				DCT_7_6=783,
				DCT_0_7=399,
				DCT_1_7=-1137,
				DCT_2_7=1702,
				DCT_3_7=-2008,
				DCT_4_7=2008,
				DCT_5_7=-1702,
				DCT_6_7=1137,
				DCT_7_7=-399;



				//define cosine matrix constants here:
				//------------------
				
				
				
				
				
				//---------------------
				

logic [6:0] DPRAM_0_ADDRESS_COUNTER;
logic [6:0] DPRAM_1_ADDRESS_COUNTER;
logic [6:0] DPRAM_2_ADDRESS_COUNTER;

logic signed [15:0] Y_buf_0;
logic signed [15:0] Y_buf_1;
logic signed [15:0] Y_buf_2;
logic signed [15:0] Y_buf_3;


logic [15:0] U_buf_0;
logic [15:0] U_buf_1;
logic [15:0] U_buf_2;
logic [15:0] U_buf_3;


logic [15:0] V_buf_0;
logic [15:0] V_buf_1;
logic [15:0] V_buf_2;
logic [15:0] V_buf_3;

//Storing and accumulating for final intermediate T values to be stored in the DPRAM for T
logic signed  [31:0] T_accum_0;
logic signed [31:0] T_accum_1;
logic signed [31:0] T_accum_2;
logic signed [31:0] T_accum_3;

logic signed [31:0] T_accum_0_buf;
logic signed [31:0] T_accum_1_buf;
logic signed [31:0] T_accum_2_buf;
logic signed [31:0] T_accum_3_buf;

logic signed [31:0] T_0;  //sign extended T value
logic signed [31:0] T_1;
logic signed [31:0] T_2;
logic signed [31:0] T_3;

//S is post-IDCT data, S' is pre-IDCT data
//all these data represent Y U or V values
//check which pre_IDCT values we are reading to compute post-IDCT (S) values
logic reading_Y_flag;
logic reading_U_flag;
logic reading_V_flag;
logic lead_In_flag;
logic lead_Out_flag;
logic C_matrix_half_flag;
logic T_Accum_Write_Flag;

//Book Keeping for the iteration of the 320 or 160 x 240 blocks of Y U or V values (pre_IDCT), these Y U V values are 16 bits,

logic [5:0] SAMPLE_COUNTER; //keep track of number of read sample data from S' has been fetched, up to 64 samples per matrix

//for 8x8 matrix, 64 values
logic [2:0] row_index;  //every time SAMPLE_COUNTER[2:0] rolls overs, 8 elements iterated so increment row count for 8x8 block
logic [2:0] column_index;

logic [8:0] column_address; //increment from base row address
logic [8:0] row_address;  //row base address for 320x240 or 160x240 matrix

//for 320x240 or 160x240 matrix, 76800 values or 38400 values
//keep track of 


logic [5:0] column_block;  //values from 
logic [4:0] row_block;  //values from 0 to 29

//cct from lecture
//assign row_index=SAMPLE_COUNTER[5:3];  //every time SAMPLE_COUNTER[2:0] rolls overs, 8 elements iterated so increment row count for 8x8 block
//assign column_index=SAMPLE_COUNTER[2:0];  //the 3 lsb contains the column count of the mini 8x8 block inside the 320x240 or 160x240 matrix
//
////compute column address (C_a)
//assign column_address={column_block,column_index};
////compute row address (R_a)
//assign row_address={row_block,row_index};

//total address= 320*R_a +C_a------> 320= 2^8 +2^6=====R_a*2^8 +R_a*2^6 + C_a

//					M2_SRAM_address<=row_address<<8+row_address<<6+column_address;
//					column_address<=column_address+'d1;	


logic [32:0] Y_OFFSET_COUNTER;
logic [32:0] U_OFFSET_COUNTER;
logic [32:0] V_OFFSET_COUNTER;
logic [32:0] IDCT_OFFSET_COUNTER;



//define end storage register that will store MAC accumulator results

//accumulator units for upsampled data post CSC

//buffers to store S Prime values from DP RAM 0

logic signed [31:0] M1_op1;
logic  signed[31:0] M1_op2;

logic signed [31:0] M2_op1;
logic signed[31:0] M2_op2;

logic signed [31:0] M3_op1;
logic signed[31:0] M3_op2;

logic signed [31:0] M4_op1;
logic signed [31:0] M4_op2;

logic signed [63:0] M1_result_long;
logic signed [63:0] M1_result;
logic signed [63:0] M2_result_long;
logic signed [63:0] M2_result;
logic signed [63:0] M3_result_long;
logic signed [63:0] M3_result;
logic signed [63:0] M4_result_long;
logic signed [63:0] M4_result;


//multiplying
//assign M1_result_long=M1_op1*M1_op2;
assign M1_result = M1_op1*M1_op2;
assign M2_result = M2_op1*M2_op2;
assign M3_result = M3_op1*M3_op2;
assign M4_result = M4_op1*M4_op2;

logic finishedHere;


// Instantiate S Prime RAM
dual_port_RAM0 dual_port_RAM_inst0 (
	.address_a ( RAM_0_address_A ),
	.address_b ( RAM_0_address_B ),
	.clock ( CLOCK_50_I ),
	.data_a ( write_data_a_0 ),
	.data_b ( write_data_b_0 ),
	.wren_a ( write_enable_a_0 ),
	.wren_b ( write_enable_b_0 ),
	.q_a ( read_data_a_0 ),
	.q_b ( read_data_b_0 )
);
	
	
// Instantiate T RAM
dual_port_RAM1 dual_port_RAM_inst1 (
	.address_a ( RAM_1_address_A ),
	.address_b ( RAM_1_address_B ),
	.clock ( CLOCK_50_I ),
	.data_a ( write_data_a_1 ),
	.data_b ( write_data_b_1 ),
	.wren_a ( write_enable_a_1 ),
	.wren_b ( write_enable_b_1 ),
	.q_a ( read_data_a_1 ),
	.q_b ( read_data_b_1 )
);


// Instantiate S Prime RAM, may not need this
dual_port_RAM2 dual_port_RAM_inst2 (
	.address_a ( RAM_2_address_A ),
	.address_b ( RAM_2_address_B ),
	.clock ( CLOCK_50_I ),
	.data_a ( write_data_a_2 ),
	.data_b ( write_data_b_2 ),
	.wren_a ( write_enable_a_2 ),
	.wren_b ( write_enable_b_2 ),
	.q_a ( read_data_a_2 ),
	.q_b ( read_data_b_2 )
);

assign row_index=SAMPLE_COUNTER[5:3];
assign column_index=SAMPLE_COUNTER[2:0];


assign column_address={column_block,column_index};
assign row_address={row_block,row_index};

assign C_matrix_half_flag= T_Values_Written>28?1'b0:1'b1; //lower flag if amount of T values written is gr8r than 32, to switch operands to tother half of matrix
//assign T_Accum_Write_Flag= T_Values_Written>60?1'b1:1'b0; //we need to keep accumulating until, end case for end of matrix


//do clipping with assign statements

assign T_0 = {{8{T_accum_0_buf[31]}}, T_accum_0_buf[31:8]}; //store sign extend T value
assign T_1 = {{8{T_accum_1_buf[31]}}, T_accum_1_buf[31:8]};
assign T_2 = {{8{T_accum_2_buf[31]}}, T_accum_2_buf[31:8]};
assign T_3 = {{8{T_accum_3_buf[31]}}, T_accum_3_buf[31:8]};



always_ff @ (posedge CLOCK_50_I or negedge Resetn) begin
if (Resetn == 1'b0) begin
		M2_SRAM_we_n<=1'b0;
		M2_SRAM_address<=18'd0;
		Y_OFFSET_COUNTER <= 16'd0;
		U_OFFSET_COUNTER <= 15'd0;
		V_OFFSET_COUNTER <= 15'd0;
		RAM_0_address_A <= 7'd0;
		DPRAM_0_ADDRESS_COUNTER <= 7'd0;
      DPRAM_1_ADDRESS_COUNTER <= 7'd0;
      DPRAM_2_ADDRESS_COUNTER <= 7'd0;
		
		T_accum_0 <= 32'd0;
		T_accum_1 <= 32'd0;
		T_accum_2 <= 32'd0;
		T_accum_3 <= 32'd0;
		
		SAMPLE_COUNTER <= 6'd0;
		T_Accum_Write_Flag<='d0;
		
		Y_buf_0 <= 16'd0;
		Y_buf_1 <= 16'd0;
		Y_buf_2 <= 16'd0;
		Y_buf_3 <= 16'd0;
		
		U_buf_0 <= 16'd0;
		U_buf_1 <= 16'd0;
		U_buf_2 <= 16'd0;
		U_buf_3 <= 16'd0;
		T_Values_Written<=6'd0;
		

		M2_SRAM_address<= 18'd0;
		M2_SRAM_write_data<= 16'd0;
		M2_SRAM_we_n<= 1'd1;
		//SRAM_read_data<=16'b0;
		
		
		V_buf_0 <= 16'd0;
		V_buf_1 <= 16'd0;
		V_buf_2 <= 16'd0;
		V_buf_3 <= 16'd0;
		row_block<=5'd0;
		column_block<=6'd0;		
//		write_data_a_0<=7'd0; this is not OK
//		read_data_a_0<=7'd0;
		
		reading_Y_flag <= 1'b0;
		reading_U_flag <= 1'b0;
		reading_V_flag <= 1'b0;
		lead_In_flag <= 1'b0;
		lead_Out_flag <= 1'b0;
		
		write_data_a_0<=32'd0;
		write_enable_a_0<=1'b0;
		//read_data_a_0<=32'b0;
		
		write_data_a_1<=32'd0;
		write_enable_a_1<=1'b0;
		//read_data_a_1<=32'b0;
		
		write_data_a_2<=32'd0;
		write_enable_a_2<=1'b0;
		//read_data_a_2<=32'b0;
		
		write_data_b_0<=32'd0;
		write_enable_b_0<=1'b0;
		//read_data_a_0<=32'b0;
		
		write_data_b_1<=32'd0;
		write_enable_b_1<=1'b0;
		//read_data_a_1<=32'b0;
		
		write_data_b_2<=32'd0;
		write_enable_b_2<=1'b0;
		//read_data_a_2<=32'b0;
		RAM_0_address_A<='d0;
		RAM_0_address_B<='d0;
		write_data_a_0<='d0;
		write_data_b_0<='d0;
		
		RAM_1_address_A<='d0;
		RAM_1_address_B<='d0;
		write_data_a_1<='d0;
		write_data_b_1<='d0;
		
		RAM_2_address_A<='d0;
		RAM_2_address_B<='d0;
		write_data_a_2<='d0;
		write_data_b_2<='d0;

		M2_finish <= 1'b0;
		finishedHere <= 1'b0;
		S_FETCH_ITERATION <= 'd0;
		MS_B_Count <= 'd0;
		
		M2_state <= S_M2_IDLE;
				
 end else begin
 case (M2_state)
S_M2_IDLE: begin
			//M1_finish <= 1'b0;  //do not assert this signal
			if(M2_start && !finishedHere) begin
				lead_In_flag <= 1'b1;
				M2_state <= S_M2_LEAD_IN_STALL;
			end
end
S_M2_LEAD_IN_STALL: begin //get Y0 here, then 2 cc later store in DP RAM0
			M2_state <= S_Fetch_S_Prime0;
		end
S_Fetch_S_Prime0: begin 

		//A) Compute S Steps (S=(Ct*T))
		
				//1. Increment Addresses, Counters, set next CC addressing
				
				//2. Fetch T from DP-RAM
					//write_enable_a_1 <= 1'b0;
					//RAM_0_address_A <= DPRAM_1_ADDRESS + DPRAM_1_ADDRESS_COUNTER;
					//DPRAM_1_ADDRESS_COUNTER<=DPRAM_1_ADDRESS_COUNTER+16'd1;
				
				//3. Assign relevant Cosine MUX values (in always_comb)
				
				//4. Accumulate S values (4 partial products per clock cycle)
					
				//5. Write S values to DP-RAM
				

		//B) Fetch S Prime Steps aka pre_IDCT data
				
					//1. Increment Addresses, Counters, set next CC addressing
					//
					M2_SRAM_we_n<=1'b1;
					M2_SRAM_address<=PRE_IDCT_ADDRESS+(row_address<<8)+(row_address<<6)+column_address;
					SAMPLE_COUNTER <= SAMPLE_COUNTER + 'd1;
					
					//2. Store 1 read into a buffer

					
					//3. Write 1 buffer value and 1 straight "read_data" into the DP-RAM

			M2_state <= S_Fetch_S_Prime1;
		end
S_Fetch_S_Prime1: begin 
		
		//A) Compute S Steps (S=(Ct*T))
		
				//1. Increment Addresses, Counters, set next CC addressing
				
				//2. Fetch T from DP-RAM
//					write_enable_a_1 <= 1'b0;
//					DPRAM_1_ADDRESS <= DPRAM_1_ADDRESS + DPRAM_1_ADDRESS_COUNTER;
//					DPRAM_1_ADDRESS_COUNTER<=DPRAM_1_ADDRESS_COUNTER+16'd1;
				
				//3. Assign relevant Cosine MUX values (in always_comb)
				
				//4. Accumulate S values (4 partial products per clock cycle)
				
				//5. Write S values to DP-RAM
				

		//B) Fetch S Prime Steps
				
					//1. Increment Addresses, Counters, set next CC addressing
					M2_SRAM_we_n<=1'b1;
					M2_SRAM_address<=PRE_IDCT_ADDRESS+(row_address<<8)+(row_address<<6)+column_address;
					SAMPLE_COUNTER <= SAMPLE_COUNTER + 'd1;
					//column_index<=column_index+'d1;		

					
					//2. Store 1 read into a buffer
					
					//3. Write 1 buffer value and 1 straight "read_data" into the DP-RAM
			M2_state <= S_Fetch_S_Prime2;
		end
S_Fetch_S_Prime2: begin 
		
		//A) Compute S Steps (S=(Ct*T))
		
				//1. Increment Addresses, Counters, set next CC addressing
				
				//2. Fetch T from DP-RAM
//						Sp_0<=read_data_a_0[31:16];
//						Sp_1<=read_data_a_0[15:0];
				//3. Assign relevant Cosine MUX values (in always_comb)
				
				//4. Accumulate S values (4 partial products per clock cycle)
				
				//5. Write S values to DP-RAM
				

		//B) Fetch S Prime Steps
				
					//1. Increment Addresses, Counters, set next CC addressing
					M2_SRAM_we_n<=1'b1;
					M2_SRAM_address<=PRE_IDCT_ADDRESS+(row_address<<8)+(row_address<<6)+column_address;
					SAMPLE_COUNTER <= SAMPLE_COUNTER + 'd1;

					//2. Store 1 read into a buffer
					
					//3. Write 1 buffer value and 1 straight "read_data" into the DP-RAM

		
			M2_state <= S_Fetch_S_Prime3;
		end
S_Fetch_S_Prime3: begin //Y0 data ready here
		
		//A) Compute S Steps (S=(Ct*T))
		
				//1. Increment Addresses, Counters, set next CC addressing
				
				//2. Fetch T from DP-RAM
				
				//3. Assign relevant Cosine MUX values (in always_comb)
				
				//4. Accumulate S values (4 partial products per clock cycle)
				
				//5. Write S values to DP-RAM
				

		//B) Fetch S Prime Steps
				
					//1. Increment Addresses, Counters, set next CC addressing
					M2_SRAM_we_n<=1'b1;
					M2_SRAM_address<=PRE_IDCT_ADDRESS+(row_address<<8)+(row_address<<6)+column_address;
					SAMPLE_COUNTER <= SAMPLE_COUNTER + 'd1;		
					
					//2. Store 1 read into a buffer
					Y_buf_0 <= SRAM_read_data[15:0]; //
					//3. Write 1 buffer value and 1 straight "read_data" into the DP-RAM

			M2_state <= S_Fetch_S_Prime4;
		end
S_Fetch_S_Prime4: begin //Y1
		//A) Compute S Steps (S=(Ct*T))
		
				//1. Increment Addresses, Counters, set next CC addressing
				
				//2. Fetch T from DP-RAM
				
				//3. Assign relevant Cosine MUX values (in always_comb)
				
				//4. Accumulate S values (4 partial products per clock cycle)
				
				//5. Write S values to DP-RAM
				

		//B) Fetch S Prime Steps
				
					//1. Increment Addresses, Counters, set next CC addressing
					M2_SRAM_we_n<=1'b1;
					M2_SRAM_address<=PRE_IDCT_ADDRESS+(row_address<<8)+(row_address<<6)+column_address;
					SAMPLE_COUNTER <= SAMPLE_COUNTER + 'd1;
				
					//2. Store 1 read into a buffer
					
					//3. Write 1 buffer value and 1 straight "read_data" into the DP-RAM
					RAM_0_address_A <= DPRAM_0_ADDRESS + DPRAM_0_ADDRESS_COUNTER;
					DPRAM_0_ADDRESS_COUNTER <= DPRAM_0_ADDRESS_COUNTER + 'd1;
					write_data_a_0 <= {Y_buf_0,SRAM_read_data[15:0]}; //Y0Y1 is written into DP RAM for S
					write_enable_a_0<=1'b1;

				M2_state <= S_Fetch_S_Prime5;
		end
S_Fetch_S_Prime5: begin //Y2
		
		//A) Compute S Steps (S=(Ct*T))
		
				//1. Increment Addresses, Counters, set next CC addressing
				
				//2. Fetch T from DP-RAM
				
				//3. Assign relevant Cosine MUX values (in always_comb)
				
				//4. Accumulate S values (4 partial products per clock cycle)
				
				//5. Write S values to DP-RAM
				

		//B) Fetch S Prime Steps
				
					//1. Increment Addresses, Counters, set next CC addressing
					M2_SRAM_we_n<=1'b1;
					M2_SRAM_address<=PRE_IDCT_ADDRESS+(row_address<<8)+(row_address<<6)+column_address;
					SAMPLE_COUNTER <= SAMPLE_COUNTER + 'd1;

					
					//2. Store 1 read into a buffer
					Y_buf_0 <=SRAM_read_data[15:0];
					//3. Write 1 buffer value and 1 straight "read_data" into the DP-RAM
					write_enable_a_0 <= 1'b0;

				M2_state <= S_Fetch_S_Prime6;
		end
S_Fetch_S_Prime6: begin //Y3
		//A) Compute S Steps (S=(Ct*T))
		
				//1. Increment Addresses, Counters, set next CC addressing
				
				//2. Fetch T from DP-RAM
				
				//3. Assign relevant Cosine MUX values (in always_comb)
				
				//4. Accumulate S values (4 partial products per clock cycle)
				
				//5. Write S values to DP-RAM
				

		//B) Fetch S Prime Steps
				
					//1. Increment Addresses, Counters, set next CC addressing
					M2_SRAM_we_n<=1'b1;
					M2_SRAM_address<=PRE_IDCT_ADDRESS+(row_address<<8)+(row_address<<6)+column_address;
					SAMPLE_COUNTER <= SAMPLE_COUNTER + 'd1;
					
					//2. Store 1 read into a buffer
					
					//3. Write 1 buffer value and 1 straight "read_data" into the DP-RAM
					RAM_0_address_A <= DPRAM_0_ADDRESS + DPRAM_0_ADDRESS_COUNTER;
					DPRAM_0_ADDRESS_COUNTER <= DPRAM_0_ADDRESS_COUNTER + 'd1;
					write_enable_a_0 <= 1'b1;
					write_data_a_0 <= {Y_buf_0,SRAM_read_data[15:0]}; //Y0Y1 is written into DP RAM for S

			M2_state <= S_Fetch_S_Prime7;
		end
S_Fetch_S_Prime7: begin //Y4
		//A) Compute S Steps (S=(Ct*T))
		
				//1. Increment Addresses, Counters, set next CC addressing
				
				//2. Fetch T from DP-RAM
				
				//3. Assign relevant Cosine MUX values (in always_comb)
				
				//4. Accumulate S values (4 partial products per clock cycle)
				
				//5. Write S values to DP-RAM
				

		//B) Fetch S Prime Steps

					//1. Increment Addresses, Counters, set next CC addressing
					M2_SRAM_we_n<=1'b1;
					M2_SRAM_address<=PRE_IDCT_ADDRESS+(row_address<<8)+(row_address<<6)+column_address;
					SAMPLE_COUNTER <= SAMPLE_COUNTER + 'd1;		
					//2. Store 1 read into a buffer
					Y_buf_0 <=SRAM_read_data[15:0];
					//3. Write 1 buffer value and 1 straight "read_data" into the DP-RAM
					write_enable_a_0 <= 1'b0;
					M2_state <= S_Fetch_S_Prime8;
			
		end
S_Fetch_S_Prime8: begin //y5
		//A) Compute S Steps (S=(Ct*T))
		
				//1. Increment Addresses, Counters, set next CC addressing
				
				//2. Fetch T from DP-RAM
				
				//3. Assign relevant Cosine MUX values (in always_comb)
				
				//4. Accumulate S values (4 partial products per clock cycle)
				
				//5. Write S values to DP-RAM
				

		//B) Fetch S Prime Steps
				
					//1. Increment Addresses, Counters, set next CC addressing
					
					
					//2. Store 1 read into a buffer
					
					//3. Write 1 buffer value and 1 straight "read_data" into the DP-RAM
					RAM_0_address_A <= DPRAM_0_ADDRESS + DPRAM_0_ADDRESS_COUNTER;
					DPRAM_0_ADDRESS_COUNTER <= DPRAM_0_ADDRESS_COUNTER + 'd1;
					write_enable_a_0 <= 1'b1;
					write_data_a_0 <= {Y_buf_0,SRAM_read_data[15:0]}; //Y0Y1 is written into DP RAM for S
					
					
			if(SAMPLE_COUNTER=='d00)begin  //done fetching 8x8 block, computer T now
					
					M2_state <= S_MS_B_STALL_0;
					//column_block <= column_block + 'd1;
					
					
					//RAM_0_address_A <= 7'd0; //DPRAM_0_ADDRESS + DPRAM_0_ADDRESS_COUNTER;
					//DPRAM_0_ADDRESS_COUNTER <= 'd1 ;
				
					//write_enable_a_0<=1'b0;
					
					///if(column_block == 'd39) begin
					
					
					//M2_state <= S_MS_B_STALL;
			end
			 else begin

				M2_state <= S_Fetch_S_Prime9;
				end
		end
S_Fetch_S_Prime9: begin //Y6

		//A) Compute S Steps (S=(Ct*T))
		
				//1. Increment Addresses, Counters, set next CC addressing
				
				//2. Fetch T from DP-RAM
				
				//3. Assign relevant Cosine MUX values (in always_comb)
				
				//4. Accumulate S values (4 partial products per clock cycle)
				
				//5. Write S values to DP-RAM
				

		//B) Fetch S Prime Steps
				
					//1. Increment Addresses, Counters, set next CC addressing
					
					//2. Store 1 read into a buffer
					Y_buf_0 <=SRAM_read_data[15:0];
					//3. Write 1 buffer value and 1 straight "read_data" into the DP-RAM
					write_enable_a_0 <= 1'b0;
					
				M2_state <= S_Fetch_S_Prime10;
				
				end
	
S_Fetch_S_Prime10: begin //Y7
		//A) Compute S Steps (S=(Ct*T))
		
				//1. Increment Addresses, Counters, set next CC addressing
				
				//2. Fetch T from DP-RAM
				
				//3. Assign relevant Cosine MUX values (in always_comb)
				
				//4. Accumulate S values (4 partial products per clock cycle)
				
				//5. Write S values to DP-RAM
				

		//B) Fetch S Prime Steps
					M2_SRAM_we_n<=1'b1;
					M2_SRAM_address<=PRE_IDCT_ADDRESS+(row_address<<8)+(row_address<<6)+column_address;
					SAMPLE_COUNTER <= SAMPLE_COUNTER + 'd1;
				
					//1. Increment Addresses, Counters, set next CC addressing

					//DPRAM_0_ADDRESS<=DPRAM_0_ADDRESS+DPRAM_0_ADDRESS_COUNTER;
					//DPRAM_0_ADDRESS_COUNTER<= DPRAM_0_ADDRESS_COUNTER + 'd1;
					
					//2. Store 1 read into a buffer
					
					//3. Write 1 buffer value and 1 straight "read_data" into the DP-RAM
					RAM_0_address_A <= DPRAM_0_ADDRESS + DPRAM_0_ADDRESS_COUNTER;
					DPRAM_0_ADDRESS_COUNTER <= DPRAM_0_ADDRESS_COUNTER + 'd1;
					write_enable_a_0 <= 1'b1;
					write_data_a_0 <= {Y_buf_0,SRAM_read_data[15:0]}; //Y0Y1 is written into DP RAM for S
					S_FETCH_ITERATION<= S_FETCH_ITERATION + 'd1;
			//if(column_index == 3'b111) begin
			//	M2_state <= S_M2_IDLE;
		//	if(SAMPLE_COUNTER < 'd63) begin
				M2_state <= S_Fetch_S_Prime1;
		//	end
//		else if(SAMPLE_COUNTER>'d62)begin
//
//				M2_state <= S_MS_B_STALL;
//		end
			//end else begin
			//	M2_state <= S_Fetch_S_Prime0;
			//end
		end
		
		//BEGIN MEGASTATE B ---> 
		
		//WRITE S
		//COMPUTE T 
					//CONCURRENTLY!!!!! (TO OPTIMIZE MULT USAGE)
		S_MS_B_STALL_0: begin
		write_enable_a_0<=1'b0;
		RAM_0_address_A <= 'd0;
		write_enable_a_1<=1'b0;
		
					
		
		    M2_state <= S_MS_B_STALL_1;
		end
		S_MS_B_STALL_1: begin
		write_enable_a_0<=1'b0;
		DPRAM_0_ADDRESS_COUNTER<='d1;
		
					
		
		    M2_state <= S_MS_B_0;
		end
		S_MS_B_0: begin
				//this is a stall state for the DPRAM to read the first set of data
				//A) Write back S Steps
				
				//B) Compute T = S' x C, we are at RAM_0_address_A == 0,
				
					//1. Increment Addresses, Counters, set next CC addressing
					
					if(T_Values_Written<60)
					begin
						RAM_0_address_A <= DPRAM_0_ADDRESS + DPRAM_0_ADDRESS_COUNTER;
						write_enable_a_0<=1'b0;
						DPRAM_0_ADDRESS_COUNTER <= DPRAM_0_ADDRESS_COUNTER + 'd1;
					
						//2. Store 1 read into a buffer
						T_accum_0 <= M1_result;
						T_accum_1 <= M2_result;
						T_accum_2 <= M3_result;
						T_accum_3 <= M4_result;
					end

					
					//3. Write 1 buffer value and 1 straight "read_data" into the DP-RA
					
					if(T_Accum_Write_Flag) // T_Accum_Write_Flag
					begin
						write_data_a_1 <= {T_0}; //Y0Y1 is written into DP RAM for S
						write_enable_a_1<=1'b1;
						RAM_1_address_A <= DPRAM_1_ADDRESS + DPRAM_1_ADDRESS_COUNTER;

						
						
						write_data_b_1 <= {T_1}; //Y0Y1 is written into DP RAM for S
						write_enable_b_1<=1'b1;
						RAM_1_address_B <= DPRAM_1_ADDRESS + DPRAM_1_ADDRESS_COUNTER+'d1;
						
						DPRAM_1_ADDRESS_COUNTER <= DPRAM_1_ADDRESS_COUNTER + 'd2;
					end
					
		
		
		
			M2_state <= S_MS_B_1;	
		end
		S_MS_B_1: begin
				//A) Write back S Steps
				
				//B) Fetch S Prime Steps, we are at RAM_0_address_A == 0,
				
					//1. Increment Addresses, Counters, set next CC addressing
					
					//2. Store 1 read into a buffer
						
					
					//3. Write 1 buffer value and 1 straight "read_data" into the DP-RAM
			if(T_Values_Written<60)
			begin
					T_accum_0 <= T_accum_0 + M1_result;
					T_accum_1 <= T_accum_1 + M2_result;
					T_accum_2 <= T_accum_2 + M3_result;
					T_accum_3 <= T_accum_3 + M4_result;
			end
					
			if (T_Accum_Write_Flag) //T_Accum_Write_Flag MS_B_Count  MS_B_Count=='d16
			begin
				write_data_a_1 <= {T_2};
				RAM_1_address_A <= DPRAM_1_ADDRESS + DPRAM_1_ADDRESS_COUNTER;
				write_enable_a_1<=1'b1;

				write_data_b_1 <= {T_3};
				RAM_1_address_B <= DPRAM_1_ADDRESS + DPRAM_1_ADDRESS_COUNTER+'d1;
				write_enable_b_1<=1'b1;
			
				DPRAM_1_ADDRESS_COUNTER <= DPRAM_1_ADDRESS_COUNTER + 'd2;
			
				//RAM_0_address_A <= DPRAM_0_ADDRESS + DPRAM_0_ADDRESS_COUNTER;
				//DPRAM_0_ADDRESS_COUNTER <= DPRAM_0_ADDRESS_COUNTER +'d1;
				//write_enable_a_0<=1'b0;
				T_Accum_Write_Flag<='d0;
				T_Values_Written<=T_Values_Written+'d4;

			end
			
			
			if(T_Accum_Write_Flag &&(T_Values_Written==60))
			begin
				M2_state <= S_M2_IDLE;
				M2_finish<=1'b1;
				finishedHere<=1'b1;
				
				
			end else if(T_Values_Written=='d28)
				begin
				
					M2_state <= S_MS_B_STALL_0;
				end
			M2_state <= S_MS_B_2;	
		end
		S_MS_B_2: begin
				//A) Write back S Steps
				
				//B) Fetch S Prime Steps, we are at RAM_0_address_A == 0,
				
					//1. Increment Addresses, Counters, set next CC addressing
					RAM_0_address_A <= DPRAM_0_ADDRESS + DPRAM_0_ADDRESS_COUNTER;
					write_enable_a_0<=1'b0;
					DPRAM_0_ADDRESS_COUNTER <= DPRAM_0_ADDRESS_COUNTER + 'd1;
					write_enable_a_1<=1'b0;

					
					//2. Store 1 read into a buffer
					
					//3. Write 1 buffer value and 1 straight "read_data" into the DP-RAM

					T_accum_0 <= T_accum_0 + M1_result;
					T_accum_1 <= T_accum_1 + M2_result;
					T_accum_2 <= T_accum_2 + M3_result;
					T_accum_3 <= T_accum_3 + M4_result;
		
		
		
			M2_state <= S_MS_B_3;	
		end
		S_MS_B_3: begin
				//A) Write back S Steps
				
				//B) Fetch S Prime Steps, we are at RAM_0_address_A == 0,
				
					//1. Increment Addresses, Counters, set next CC addressing
					
					
					//2. Store 1 read into a buffer
					
					//3. Write 1 buffer value and 1 straight "read_data" into the DP-RAM

					
					T_accum_0 <= T_accum_0 + M1_result;
					T_accum_1 <= T_accum_1 + M2_result;
					T_accum_2 <= T_accum_2 + M3_result;
					T_accum_3 <= T_accum_3 + M4_result;
		
		
		
			M2_state <= S_MS_B_4;	
		end
		S_MS_B_4: begin
				//A) Write back S Steps
				
				//B) Fetch S Prime Steps, we are at RAM_0_address_A == 0,
				
					//1. Increment Addresses, Counters, set next CC addressing
					RAM_0_address_A <= DPRAM_0_ADDRESS + DPRAM_0_ADDRESS_COUNTER;
					write_enable_a_0<=1'b0;
					DPRAM_0_ADDRESS_COUNTER <= DPRAM_0_ADDRESS_COUNTER + 'd1;
					
					//2. Store 1 read into a buffer
					
					//3. Write 1 buffer value and 1 straight "read_data" into the DP-RAM

					T_accum_0 <= T_accum_0 + M1_result;
					T_accum_1 <= T_accum_1 + M2_result;
					T_accum_2 <= T_accum_2 + M3_result;
					T_accum_3 <= T_accum_3 + M4_result;
		
		
		
			M2_state <= S_MS_B_5;	
		end
		S_MS_B_5: begin
				//A) Write back S Steps
				
				//B) Fetch S Prime Steps, we are at RAM_0_address_A == 0,
				
					//1. Increment Addresses, Counters, set next CC addressing

					//2. Store 1 read into a buffer
					
					//3. Write 1 buffer value and 1 straight "read_data" into the DP-RAM

					T_accum_0 <= T_accum_0 + M1_result;
					T_accum_1 <= T_accum_1 + M2_result;
					T_accum_2 <= T_accum_2 + M3_result;
					T_accum_3 <= T_accum_3 + M4_result;
		
		
		
			M2_state <= S_MS_B_6;	
		end
S_MS_B_6: begin
				//A) Write back S Steps
				
				//B) Fetch S Prime Steps, we are at RAM_0_address_A == 0,
				
					//1. Increment Addresses, Counters, set next CC addressing
					RAM_0_address_A <= DPRAM_0_ADDRESS + DPRAM_0_ADDRESS_COUNTER;
					write_enable_a_0<=1'b0;
					DPRAM_0_ADDRESS_COUNTER <= DPRAM_0_ADDRESS_COUNTER + 'd1;


					//2. Store 1 read into a buffer
					
					//3. Write 1 buffer value and 1 straight "read_data" into the DP-RAM
					T_accum_0 <= T_accum_0 + M1_result;
					T_accum_1 <= T_accum_1 + M2_result;
					T_accum_2 <= T_accum_2 + M3_result;
					T_accum_3 <= T_accum_3 + M4_result;
		
		
		
			M2_state <= S_MS_B_7;	
		end
		S_MS_B_7: begin
				//A) Write back S Steps
				
				//B) Fetch S Prime Steps, we are at RAM_0_address_A == 0,
				
					//1. Increment Addresses, Counters, set next CC addressing
					
					//2. Store 1 read into a buffer
					
					//3. Write 1 buffer value and 1 straight "read_data" into the DP-RAM
					T_accum_0_buf<= T_accum_0 + M1_result;
					T_accum_1_buf <= T_accum_1 + M2_result;
					T_accum_2_buf <= T_accum_2 + M3_result;
					T_accum_3_buf <= T_accum_3 + M4_result;
					
						T_accum_0 <= 'd0;
						T_accum_1 <= 'd0;
						T_accum_2 <= 'd0;
						T_accum_3 <= 'd0;
					
					T_Accum_Write_Flag<=1'b1;
					MS_B_Count <= MS_B_Count +'d1;
		
			M2_state <= S_MS_B_0;	
		end
S_MS_A_0: begin
				//A) Compute S Steps
				
				//B) Fetch S Steps
				
			

			M2_state <= S_MS_A_1;	
end





 endcase
 








 
		//default: M2_state <= S_IDLE_M2;	
end
end 

//do mux for the COS coeffiecients
always_comb begin
  M1_op1='d0;
  M1_op2='d0;

  M2_op1='d0;
  M2_op2='d0;

  M3_op1='d0;
  M3_op2='d0;

  M4_op1='d0;
  M4_op2='d0;
 
 
//we need some kind of muxing for the coef matrix

  
  
  
case(M2_state)
//					read_data_a_0[31:16];
		//       read_data_a_0[15:0];
//
	S_MS_B_0: begin
		M1_op1 = C_matrix_half_flag? 16'd1448: 16'd1448;
		M2_op1 = C_matrix_half_flag? 16'd1448: 16'd1448; 
		M3_op1 = C_matrix_half_flag? 16'd1448: 16'd1448; 
		M4_op1 = C_matrix_half_flag? 16'd1448: 16'd1448; 
	
	
	M1_op2 = {{16{read_data_a_0[31]}}, read_data_a_0[31:16]};
	M2_op2 = {{16{read_data_a_0[31]}}, read_data_a_0[31:16]};
	M3_op2 = {{16{read_data_a_0[31]}}, read_data_a_0[31:16]};
	M4_op2 = {{16{read_data_a_0[31]}}, read_data_a_0[31:16]};
	
	end
	S_MS_B_1: begin
	M1_op1 = C_matrix_half_flag? 16'd2008: -16'd399;
	M2_op1 = C_matrix_half_flag? 16'd1702: -16'd1137; 
	M3_op1 = C_matrix_half_flag? 16'd1137: -16'd1702; 
	M4_op1 = C_matrix_half_flag? 16'd399: -16'd2008;
	
	M1_op2 = {{16{read_data_a_0[15]}}, read_data_a_0[15:0]};
	M2_op2 = {{16{read_data_a_0[15]}}, read_data_a_0[15:0]};
	M3_op2 = {{16{read_data_a_0[15]}}, read_data_a_0[15:0]};
	M4_op2 = {{16{read_data_a_0[15]}}, read_data_a_0[15:0]};

	
	end
	S_MS_B_2: begin
	M1_op1 = C_matrix_half_flag? 16'd1892: -16'd1892;
	M2_op1 = C_matrix_half_flag? 16'd783: -16'd783; 
	M3_op1 = C_matrix_half_flag? -16'd783: 16'd783; 
	M4_op1 = C_matrix_half_flag? -16'd1892: 16'd1892; 
	
	M1_op2 = {{16{read_data_a_0[31]}}, read_data_a_0[31:16]};
	M2_op2 = {{16{read_data_a_0[31]}}, read_data_a_0[31:16]};
	M3_op2 = {{16{read_data_a_0[31]}}, read_data_a_0[31:16]};
	M4_op2 = {{16{read_data_a_0[31]}}, read_data_a_0[31:16]};
	end
	S_MS_B_3: begin
	M1_op1 = C_matrix_half_flag? 16'd1702: 16'd1137;
	M2_op1 = C_matrix_half_flag? -16'd399: 16'd2008; 
	M3_op1 = C_matrix_half_flag? -16'd2008: 16'd399; 
	M4_op1 = C_matrix_half_flag? -16'd1137: -16'd1702; 
	
	M1_op2 = {{16{read_data_a_0[15]}}, read_data_a_0[15:0]};
	M2_op2 = {{16{read_data_a_0[15]}}, read_data_a_0[15:0]};
	M3_op2 = {{16{read_data_a_0[15]}}, read_data_a_0[15:0]};
	M4_op2 = {{16{read_data_a_0[15]}}, read_data_a_0[15:0]};
	end
	S_MS_B_4: begin
	M1_op1 = C_matrix_half_flag? 16'd1448: 16'd1448;
	M2_op1 = C_matrix_half_flag? -16'd1448: -16'd1448; 
	M3_op1 = C_matrix_half_flag? -16'd1448: -16'd1448; 
	M4_op1 = C_matrix_half_flag? 16'd1448: 16'd399; 
	
	M1_op2 = {{16{read_data_a_0[31]}}, read_data_a_0[31:16]};
	M2_op2 = {{16{read_data_a_0[31]}}, read_data_a_0[31:16]};
	M3_op2 = {{16{read_data_a_0[31]}}, read_data_a_0[31:16]};
	M4_op2 = {{16{read_data_a_0[31]}}, read_data_a_0[31:16]};
	end
	S_MS_B_5: begin
	M1_op1 = C_matrix_half_flag? 16'd1137: -16'd1702;
	M2_op1 = C_matrix_half_flag? -16'd2008: -16'd399; 
	M3_op1 = C_matrix_half_flag? 16'd399: 16'd2008; 
	M4_op1 = C_matrix_half_flag? 16'd1702: -16'd1137; 
	
	M1_op2 = {{16{read_data_a_0[15]}}, read_data_a_0[15:0]};
	M2_op2 = {{16{read_data_a_0[15]}}, read_data_a_0[15:0]};
	M3_op2 = {{16{read_data_a_0[15]}}, read_data_a_0[15:0]};
	M4_op2 = {{16{read_data_a_0[15]}}, read_data_a_0[15:0]};
	end
	S_MS_B_6: begin
	M1_op1 = C_matrix_half_flag? 16'd783: -16'd783;
	M2_op1 = C_matrix_half_flag? -16'd1892: 16'd1892; 
	M3_op1 = C_matrix_half_flag? 16'd1892: -16'd1892; 
	M4_op1 = C_matrix_half_flag? -16'd783: 16'd783; 
	
	M1_op2 = {{16{read_data_a_0[31]}}, read_data_a_0[31:16]};
	M2_op2 = {{16{read_data_a_0[31]}}, read_data_a_0[31:16]};
	M3_op2 = {{16{read_data_a_0[31]}}, read_data_a_0[31:16]};
	M4_op2 = {{16{read_data_a_0[31]}}, read_data_a_0[31:16]};
	end
	S_MS_B_7: begin
	M1_op1 = C_matrix_half_flag? 16'd399: 16'd2008;
	M2_op1 = C_matrix_half_flag? -16'd1137: -16'd1702; 
	M3_op1 = C_matrix_half_flag? 16'd1702: 16'd1137; 
	M4_op1 = C_matrix_half_flag? -16'd2008: -16'd399; 
	
	M1_op2 = {{16{read_data_a_0[15]}}, read_data_a_0[15:0]};
	M2_op2 = {{16{read_data_a_0[15]}}, read_data_a_0[15:0]};
	M3_op2 = {{16{read_data_a_0[15]}}, read_data_a_0[15:0]};
	M4_op2 = {{16{read_data_a_0[15]}}, read_data_a_0[15:0]};
	end

endcase
end


//
//
//always_comb begin
////perform multiplication here
//  M1_op1='d0;
//  M1_op2='d0;
//
//  M2_op1='d0;
//  M2_op2='d0;
//
//  M3_op1='d0;
//  M3_op2='d0;
//
//  M4_op1='d0;
//  M4_op2='d0;
//  
////	lead_Out_Interpolation_flag= pixel_counter>'d304 ? 1'b1:1'b0; //if pixel counter gr8r than 302 raise flag to not read more interpolation vals
//
//
//case(M2_state)
//
//S_IDLE: begin
//
//end
//
//
//
//
//endcase
//
//
//
//
//

endmodule
