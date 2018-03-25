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

module milestone1 (
   input  logic            CLOCK_50_I,
   input  logic            Resetn,

   input  logic            M1_start,
   output  logic           M1_finish,

   output logic   [17:0]   M1_SRAM_address,
   output logic   [15:0]   M1_SRAM_write_data,
   output logic            M1_SRAM_we_n,
   input logic [15:0]	   SRAM_read_data
);

// SET PARAMETERS that define structure of the sram YUV locations to be read
parameter 	Y_ADDRESS = 18'd0, //0 TO 38,399
				U_ADDRESS = 18'd38400, // 38,400 TO 57,599
				V_ADDRESS = 18'd57600, //57,600 TO 76,799
				//UNUSED MEMORY SEGMENT --> 76,800  TO 146,943
				RGB_ADDRESS = 18'd146944, // 146,944 TO 262,143

				//constants for interpolation
				FIR_const1 = 5'd21,
				FIR_const2 = 5'd52,
				FIR_const3 = 5'd159,

				//constants for interpolation
				CSC_const1 = 'd76284,
				CSC_const2 = 'd25624,
				CSC_const3 = 'd132251,
				CSC_const4 = 'd104595,
				CSC_const5 = 'd53281;

// define data counters to traverse the entire SRAM ----> Y, U, V AND THEN RGB

logic [32:0] Y_OFFSET_COUNTER;
logic [32:0] U_OFFSET_COUNTER;
logic [32:0] V_OFFSET_COUNTER;
logic [32:0] RGB_OFFSET_COUNTER;
logic [32:0] commonCaseIter;

logic [10:0] row_counter;
logic [9:0] pixel_counter;

logic lead_Out_Interpolation_flag; //if asserted, no reading new U's and V's
logic lead_Out_Y_flag; //if asserted, no reading new Y's
logic lead_Out_HARD_flag;
logic lead_Out_START_NEW_ROW;



// LET US IMPLEMENT M1_STATES----------

//CHECK ALL LOGIC BITWIDTHS ---> ROUGH
//define registers to hold YUV values red from SRAM

//hold YUV vals
logic [7:0] Y_even;
logic [7:0] U_even;
logic [7:0] V_even;

logic [7:0] Y_even_buf;
logic [7:0] Y_odd_buf;

logic [7:0] Y_odd;
logic [7:0] U_odd;
logic [7:0] V_odd;

logic [7:0] U_odd_buf;
logic [7:0] V_odd_buf;
logic [7:0] U_even_buf;
logic [7:0] V_even_buf;


//define registers to be used in interpolation
logic [64:0] U_Prime_Accum;
logic [64:0] V_Prime_Accum;


logic [64:0] U_Prime_odd_buf;
logic [64:0] V_Prime_odd_buf;

//define U operands for interpolation computations
logic [7:0] U_0; //U[(j-5)/2]
logic [7:0] U_1;
logic [7:0] U_2;
logic [7:0] U_3;
logic [7:0] U_4;
logic [7:0] U_5;

logic [7:0] U_Prime_even_buf;

//define V operands for interpolation computations
logic [7:0] V_0;
logic [7:0] V_1;
logic [7:0] V_2;
logic [7:0] V_3;
logic [7:0] V_4;
logic [7:0] V_5;

//define end storage register that will store MAC accumulator results

//accumulator units for upsampled data post CSC
logic [63:0] RGB_MAC_EVEN_ACCUM;
logic [63:0] RGB_MAC_ODD_ACCUM;

//these store YUV' multiplied values for CSC()
logic [63:0] RGB_MAC_Buf_Even_RED; // stores R even
logic [63:0] RGB_MAC_Buf_Even_GREEN; // stores R odd
logic [63:0] RGB_MAC_Buf_Even_BLUE; // stores R odd
logic [63:0] RGB_MAC_Buf_Odd_RED; // stores G even
logic [63:0] RGB_MAC_Buf_Odd_GREEN;	// stores G odd
logic [63:0] RGB_MAC_Buf_Odd_BLUE; // stores R odd

logic [63:0] RGB_RED_Even; // stores R even
logic [63:0] RGB_GREEN_Even; // stores R odd
logic [63:0] RGB_BLUE_Even; // stores R odd

logic [63:0] RGB_RED_Odd; // stores G even
logic [63:0] RGB_GREEN_Odd;	// stores G odd
logic [63:0] RGB_BLUE_Odd; // stores R odd

logic [7:0] U_Buf_Even;
logic [7:0] V_Buf_Even;


logic [7:0] U_Buf_Odd;
logic [7:0] V_Buf_Odd;

logic [31:0] M1_op1;
logic [31:0] M1_op2;
logic [31:0] M2_op1;
logic [31:0] M2_op2;
logic [31:0] M3_op1;
logic [31:0] M3_op2;
logic [31:0] M4_op1;
logic [31:0] M4_op2;

logic [63:0] M1_result_long;
logic [63:0] M1_result;
logic [63:0] M2_result_long;
logic [63:0] M2_result;
logic [63:0] M3_result_long;
logic [63:0] M3_result;
logic [63:0] M4_result_long;
logic [63:0] M4_result;


//multiplying
//assign M1_result_long=M1_op1*M1_op2;
assign M1_result = M1_op1*M1_op2;//M1_result_long[31:0];

//assign M2_result_long=M2_op1*M2_op2;
assign M2_result = M2_op1*M2_op2;//M2_result_long[31:0];

//assign M3_result_long=M3_op1*M3_op2;
assign M3_result = M3_op1*M3_op2;//M3_result_long[31:0];

//assign M4_result_long=M4_op1*M4_op2;
assign M4_result = M4_op1*M4_op2;//M4_result_long[31:0];

//Clipping starts

logic [7:0] R_clip_even;
logic [7:0] R_clip_odd;

logic [7:0] G_clip_even;
logic [7:0] G_clip_odd;

logic [7:0] B_clip_even;
logic [7:0] B_clip_odd;

logic [7:0] R_clip_even_buf; //always ff has memory
logic [7:0] R_clip_odd_buf;

logic [7:0] G_clip_even_buf;
logic [7:0] G_clip_odd_buf;

logic [7:0] B_clip_even_buf;
logic [7:0] B_clip_odd_buf;



assign R_clip_even = RGB_RED_Even[31]? 8'b0 : (|RGB_RED_Even[30:24] ? 8'hFF : RGB_RED_Even[23:16]);
assign R_clip_odd = RGB_RED_Odd[31]? 8'b0 : |RGB_RED_Odd[30:24] ? 8'hFF : RGB_RED_Odd[23:16];

assign G_clip_even = RGB_GREEN_Even[31]? 8'b0 : (|RGB_GREEN_Even[30:24] ? 8'hFF : RGB_GREEN_Even[23:16]);
assign G_clip_odd = RGB_GREEN_Odd[31]? 8'b0 : |RGB_GREEN_Odd[30:24] ? 8'hFF : RGB_GREEN_Odd[23:16];

assign B_clip_even = RGB_BLUE_Even[31]? 8'b0 : |RGB_BLUE_Even[30:24] ? 8'hFF : RGB_BLUE_Even[23:16];
assign B_clip_odd = RGB_BLUE_Odd[31]? 8'b0 : |RGB_BLUE_Odd[30:24] ? 8'hFF : RGB_BLUE_Odd[23:16];
 
 
//buffers to avoid redundant mults for CSC first products in matrix
logic [63:0] Y_16_Buf_Even;
logic [63:0] Y_16_Buf_Odd;
M1_state_type M1_state;


logic finishedHere;


always_ff @ (posedge CLOCK_50_I or negedge Resetn) begin
if (Resetn == 1'b0) begin
		M1_state <= S_IDLE_M1;

		M1_SRAM_we_n <= 1'b1;
		U_Prime_Accum <= 32'd0;
		V_Prime_Accum <= 32'd0;
		Y_OFFSET_COUNTER <= 16'd0;
		U_OFFSET_COUNTER <= 15'd0;
		V_OFFSET_COUNTER <= 15'd0;
		RGB_OFFSET_COUNTER <= 15'd0;
		row_counter <= 8'd0;
		commonCaseIter <= 16'd0;
		pixel_counter <= 10'd0;
		M1_SRAM_write_data <= 16'd0;
		M1_SRAM_address <= 18'd0;
		
		Y_16_Buf_Even <= 64'd0;
		Y_16_Buf_Odd <= 64'd0;
		
		Y_even_buf<= 16'd0;
		Y_odd_buf<= 16'd0;
		
		Y_even <= 16'd0;
		Y_odd <= 16'd0;
		U_even <= 16'd0;
		U_odd <= 16'd0;
		V_even <= 16'd0;
		V_odd <= 16'd0;
		
		U_Prime_even_buf<='d0;
		
		RGB_RED_Even<=64'd0; // stores R even
		RGB_GREEN_Even<=64'd0; // stores R odd
		RGB_BLUE_Even<=64'd0; // stores R odd

		RGB_RED_Odd<=64'd0; // stores G even
		RGB_GREEN_Odd<=64'd0;	// stores G odd
		RGB_BLUE_Odd<=64'd0; // stores R odd

		
		U_odd_buf<= 16'd0;
		V_odd_buf<= 16'd0;
		U_even_buf<= 16'd0;
		V_even_buf<= 16'd0;

		U_Buf_Even <= 16'd0;
		G_clip_even_buf <= 8'd0;
		
		U_Prime_odd_buf<=64'd0;
		V_Prime_odd_buf<=64'd0;
		
		RGB_MAC_Buf_Even_RED<= 64'd0;// stores R even
		RGB_MAC_Buf_Even_GREEN<= 64'd0; // stores R odd    U_Prime_Accum<=U_Prime_Accum-M1_result;
		RGB_MAC_Buf_Even_BLUE<= 64'd0; // stores R odd
		RGB_MAC_Buf_Odd_RED<= 64'd0; // stores G even
		RGB_MAC_Buf_Odd_GREEN<= 64'd0;	// stores G odd
		RGB_MAC_Buf_Odd_BLUE<= 64'd0; // stores R odd
		
		RGB_MAC_EVEN_ACCUM<= 64'd0;
		RGB_MAC_ODD_ACCUM<= 64'd0;
		RGB_RED_Even<=64'd0; // stores R even
		RGB_GREEN_Even<=64'd0; // stores R odd
		RGB_BLUE_Even<=64'd0; // stores R odd

		RGB_RED_Odd<=64'd0; // stores G even
		RGB_GREEN_Odd<=64'd0;	// stores G odd
		RGB_BLUE_Odd<=64'd0; // stores R odd
		
		U_0<= 'd0;  
	   U_1<= 'd0;  
	   U_2<= 'd0;	
	   U_3<= 'd0;  	
	   U_4<= 'd0;	
	   U_5<= 'd0;  
		
		V_0<= 'd0; 
	   V_1<= 'd0;	
	   V_2<= 'd0;	
	   V_3<= 'd0;  
	   V_4<= 'd0;	
	   V_5<= 'd0;  
		
		//lead_Out_Interpolation_flag<=1'b0;
		//lead_Out_Y_flag<=1'b0;

		M1_finish <= 1'b0; //for top level project
		
		finishedHere <= 1'b0;  //for local finish signal

		end else begin
		case (M1_state)
		S_IDLE_M1: begin
			//M1_finish <= 1'b0;  //do not assert this signal
			if(M1_start && !finishedHere)
				M1_state <= S_LEAD_IN_STALL;
		end
		
		S_LEAD_IN_STALL: begin //state -1

		
		
		if(row_counter==8'd240 && pixel_counter==1'd0) begin
			M1_SRAM_we_n <= 1'b1;
			finishedHere <= 1'b1;
			M1_finish <= 1'b1;
			M1_state <= S_IDLE_M1;
		end else begin
			//Currently in Memory Location:
				// none
			//Next State Addressing, Write Enable, Address Offset Counter Incrementing

				M1_SRAM_address <= Y_ADDRESS + Y_OFFSET_COUNTER; //stay in same sram address of Y location
				Y_OFFSET_COUNTER <= Y_OFFSET_COUNTER + 16'd1;
			
			//Current Memory Address Location Reading, Writing, Register Loading, Shifting & Resetting
				//reset counters  for lead out conditions
				pixel_counter <= 10'd0;
				
				
		M1_SRAM_we_n <= 1'b1;
		U_Prime_Accum <= 32'd0;
		V_Prime_Accum <= 32'd0;

		
		//commonCaseIter <= 16'd0;
		
	//	M1_SRAM_write_data <= 16'd0;
		//M1_SRAM_address <= 18'd0;
		
		Y_16_Buf_Even <= 64'd0;
		Y_16_Buf_Odd <= 64'd0;
		
		Y_even_buf<= 16'd0;
		Y_odd_buf<= 16'd0;
		
		Y_even <= 16'd0;
		Y_odd <= 16'd0;
		U_even <= 16'd0;
		U_odd <= 16'd0;
		V_even <= 16'd0;
		V_odd <= 16'd0;
		
		U_Prime_even_buf<='d0;
		
		RGB_RED_Even<=64'd0; // stores R even
		RGB_GREEN_Even<=64'd0; // stores R odd
		RGB_BLUE_Even<=64'd0; // stores R odd

		RGB_RED_Odd<=64'd0; // stores G even
		RGB_GREEN_Odd<=64'd0;	// stores G odd
		RGB_BLUE_Odd<=64'd0; // stores R odd

		
		U_odd_buf<= 16'd0;
		V_odd_buf<= 16'd0;
		U_even_buf<= 16'd0;
		V_even_buf<= 16'd0;

		U_Buf_Even <= 16'd0;
		G_clip_even_buf <= 8'd0;
		
		U_Prime_odd_buf<=64'd0;
		V_Prime_odd_buf<=64'd0;
		
		RGB_MAC_Buf_Even_RED<= 64'd0;// stores R even
		RGB_MAC_Buf_Even_GREEN<= 64'd0; // stores R odd    U_Prime_Accum<=U_Prime_Accum-M1_result;
		RGB_MAC_Buf_Even_BLUE<= 64'd0; // stores R odd
		RGB_MAC_Buf_Odd_RED<= 64'd0; // stores G even
		RGB_MAC_Buf_Odd_GREEN<= 64'd0;	// stores G odd
		RGB_MAC_Buf_Odd_BLUE<= 64'd0; // stores R odd
		
		RGB_MAC_EVEN_ACCUM<= 64'd0;
		RGB_MAC_ODD_ACCUM<= 64'd0;
		RGB_RED_Even<=64'd0; // stores R even
		RGB_GREEN_Even<=64'd0; // stores R odd
		RGB_BLUE_Even<=64'd0; // stores R odd

		RGB_RED_Odd<=64'd0; // stores G even
		RGB_GREEN_Odd<=64'd0;	// stores G odd
		RGB_BLUE_Odd<=64'd0; // stores R odd
		
		U_0<= 'd0;  
	   U_1<= 'd0;  
	   U_2<= 'd0;	
	   U_3<= 'd0;  	
	   U_4<= 'd0;	
	   U_5<= 'd0;  
		
		V_0<= 'd0; 
	   V_1<= 'd0;	
	   V_2<= 'd0;	
	   V_3<= 'd0;  
	   V_4<= 'd0;	
	   V_5<= 'd0;  
		
		//lead_in
				

						
					
			//MULTIPLICATION 1 -> PERFORM INTERPOLATION COMPUTATIONS
				//NONE
			//MULTIPLICATION 2 -> PERFORM CSC COMPUTATIONS
				//NONE
			M1_state <= S_LEAD_IN_0;
			end
		end
		
		S_LEAD_IN_0: begin //column B of state table3
		//Currently in Memory Location:
				// none
			//Next State Addressing, Write Enable, Address Offset Counter Incrementing
				M1_SRAM_address <= U_ADDRESS + U_OFFSET_COUNTER;
				U_OFFSET_COUNTER <= U_OFFSET_COUNTER + 16'd1;
			
			//Current Memory Address Location Reading, Writing, Register Loading, Shifting & Resetting //save sram values to registers. available 2 CC later
				//NONE
			//MULTIPLICATION 1 -> PERFORM INTERPOLATION COMPUTATIONS
				//NONE
			//MULTIPLICATION 2 -> PERFORM CSC COMPUTATIONS
				//NONE
			M1_state <= S_LEAD_IN_1;
		end
		
		S_LEAD_IN_1: begin //column C
		//Currently in Memory Location:
				// none
			//Next State Addressing, Write Enable, Address Offset Counter Incrementing
				M1_SRAM_address <= V_ADDRESS + V_OFFSET_COUNTER;
				V_OFFSET_COUNTER <= V_OFFSET_COUNTER + 15'd1;
			//Current Memory Address Location Reading, Writing, Register Loading, Shifting & Resetting
				//NONE
			//MULTIPLICATION 1 -> PERFORM INTERPOLATION COMPUTATIONS
				//NONE
			//MULTIPLICATION 2 -> PERFORM CSC COMPUTATIONS
				//NONE

			M1_state <= S_LEAD_IN_2;

		end
		
		S_LEAD_IN_2: begin //column D
		//Currently in Memory Location:
				// y address +0-> y0y1 addr
			//Next State Addressing, Write Enable, Address Offset Counter Incrementing
				M1_SRAM_address <= U_ADDRESS + U_OFFSET_COUNTER;
				U_OFFSET_COUNTER <= U_OFFSET_COUNTER + 15'd1;
			//Current Memory Address Location Reading, Writing, Register Loading, Shifting & Resetting	
				Y_even <= SRAM_read_data[15:8];  //Y0
				Y_odd <= SRAM_read_data[7:0];    //Y1

			//MULTIPLICATION 1 -> PERFORM INTERPOLATION COMPUTATIONS
				///NONE
			//MULTIPLICATION 2 -> PERFORM CSC COMPUTATIONS
				//NONE

				M1_state <= S_LEAD_IN_3;

		end
		S_LEAD_IN_3: begin //column E
		//Currently in Memory Location:
				// u address + 0-> u0u1 addr
			//Next State Addressing, Write Enable, Address Offset Counter Incrementing
				M1_SRAM_address <= V_ADDRESS + V_OFFSET_COUNTER;
				V_OFFSET_COUNTER<= V_OFFSET_COUNTER + 'd1;
			//Current Memory Address Location Reading, Writing, Register Loading, Shifting & Resetting
				U_even <= SRAM_read_data[15:8];  //U_0
				U_odd <= SRAM_read_data[7:0];    //U_1
				
				U_Buf_Even<= SRAM_read_data[15:8];  //U_0 store in LSB of register
				U_Buf_Odd<= SRAM_read_data[7:0];    //U_1 store in LSB of register
				//set U registers with U[0] and U[1] because we are at those locations in sram
				U_0<= SRAM_read_data[15:8]; 	 //U0
				U_1<= SRAM_read_data[15:8];	//U0
				U_2<= SRAM_read_data[15:8]; 	//U0
				U_3<= SRAM_read_data[7:0];  	//U1
			//MULTIPLICATION 1 -> PERFORM INTERPOLATION COMPUTATIONS
			
				
			//MULTIPLICATION 2 -> PERFORM CSC COMPUTATIONS
				//NONE

			M1_state <= S_LEAD_IN_4;

		end
		S_LEAD_IN_4: begin //column F
		//Currently in Memory Location:
				// v address + 0 -> v0v1 addr
			//Next State Addressing, Write Enable, Address Offset Counter Incrementing
				M1_SRAM_address <= U_ADDRESS + U_OFFSET_COUNTER;
				U_OFFSET_COUNTER<= U_OFFSET_COUNTER + 'd1;			
			//Current Memory Address Location Reading, Writing, Register Loading, Shifting & Resetting
				V_0<= SRAM_read_data[15:8];//V0  //set V_1,V_2,V_3 ETC registers with V[0] and V[1] because we are at those locations in sram
				V_1<= SRAM_read_data[15:8];//V0
				V_2<= SRAM_read_data[15:8];//V0
				V_3<= SRAM_read_data[7:0];//V1
			     //save sram values to registers
				V_even <= SRAM_read_data[15:8];//V0
				V_odd <= SRAM_read_data[7:0]; //V1

				V_Buf_Even<= SRAM_read_data[15:8];  //V_0 store in LSB of register
				V_Buf_Odd<= SRAM_read_data[7:0];    //V_1 store in LSB of register
			//MULTIPLICATION 1 -> PERFORM INTERPOLATION COMPUTATIONS
				//note the U content will be available 2 CC later, so from column C
				U_Prime_Accum <=  M1_result - M2_result + M3_result + M4_result;  //COMPUTING U_PRIME 0-----_____21*U0 - 52*U0  + 159*U0  + 159*U1
			//MULTIPLICATION 2 -> PERFORM CSC COMPUTATIONS
				//NONE
			M1_state <= S_LEAD_IN_5;

		end
		S_LEAD_IN_5:begin //column G
		//Currently in Memory Location:
				// u address +1 -> u2u3 address
			//Next State Addressing, Write Enable, Address Offset Counter Incrementing
				M1_SRAM_address <= V_ADDRESS + V_OFFSET_COUNTER;
				V_OFFSET_COUNTER<= V_OFFSET_COUNTER + 'd1;
			//Current Memory Address Location Reading, Writing, Register Loading, Shifting & Resetting
				  U_4<= SRAM_read_data[15:8];	//U2
				  U_5<= SRAM_read_data[7:0];  	//U3
			//MULTIPLICATION 1 -> PERFORM INTERPOLATION COMPUTATIONS
				V_Prime_Accum <=  M1_result - M2_result + M3_result + M4_result;

			//MULTIPLICATION 2 -> PERFORM CSC COMPUTATIONS
				//none

				M1_state <= S_LEAD_IN_6;
		end
		S_LEAD_IN_6: begin //column H
		//Currently in Memory Location:
				// v address +1 -> v2v3 address
			//Next State Addressing, Write Enable, Address Offset Counter Incrementing

			//Current Memory Address Location Reading, Writing, Register Loading, Shifting & Resetting
				V_even <= SRAM_read_data[15:8];
				V_odd <= SRAM_read_data[7:0];

				V_4<= SRAM_read_data[15:8];//V2
				V_5<= SRAM_read_data[7:0];//V3

			//MULTIPLICATION 1 -> PERFORM INTERPOLATION COMPUTATIONS
				U_Prime_odd_buf <= (U_Prime_Accum - M1_result + M2_result + 'd128) >> 8; //COMPUTED U PRIME 0 --->-52 + 21, compute U'[1]
				U_Prime_Accum<=1'd0;
				 
			//MULTIPLICATION 2 -> PERFORM CSC COMPUTATIONS
				//NONE
			
				M1_state <= S_LEAD_IN_7;
		end
		S_LEAD_IN_7: begin// COLUMN I
		//Currently in Memory Location:
				// uaddr+ 2-> u4 u5 addr
			//Next State Addressing, Write Enable, Address Offset Counter Incrementing
				//NONE
			//Current Memory Address Location Reading, Writing, Register Loading, Shifting & Resetting
				U_even <= SRAM_read_data[15:8];//U4
				U_odd <= SRAM_read_data[7:0]; //U5
			//MULTIPLICATION 1 -> PERFORM INTERPOLATION COMPUTATIONS
				V_Prime_odd_buf<=(V_Prime_Accum-M1_result+M2_result + 'd128) >> 8; 
				V_Prime_Accum<=1'd0;	
			//MULTIPLICATION 2 -> PERFORM CSC COMPUTATIONS
				M1_state <= S_LEAD_IN_8;

		end

		///UP TO HERE GOOD
		S_LEAD_IN_8: begin // COLUMN J
		//Currently in Memory Location:
				// v addr+ 2-> v4v5 addr
			//Next State Addressing, Write Enable, Address Offset Counter Incrementing
				//none
			//Current Memory Address Location Reading, Writing, Register Loading, Shifting & Resetting
      		V_even <= SRAM_read_data[15:8];//V4
				V_odd <= SRAM_read_data[7:0];//V5
			//MULTIPLICATION 1 -> PERFORM INTERPOLATION COMPUTATIONS
				//none
			//MULTIPLICATION 2 -> PERFORM CSC COMPUTATIONS
			RGB_MAC_Buf_Even_RED <= M1_result + M2_result; // R0
			RGB_MAC_Buf_Odd_RED<= M3_result + M4_result;  //R1
			
			RGB_MAC_EVEN_ACCUM<=64'd0;
			RGB_MAC_ODD_ACCUM<=64'd0;
					
			Y_16_Buf_Even<=M1_result; //store r,g,b vector first value to be used later even and odd
			Y_16_Buf_Odd<=M3_result;
			
 
				M1_state <= S_LEAD_IN_9;
		end
		S_LEAD_IN_9: begin //COLUMN K
		//Currently in Memory Location:
				M1_SRAM_address <= U_ADDRESS + U_OFFSET_COUNTER; 
				U_OFFSET_COUNTER <= U_OFFSET_COUNTER + 15'd1;
			//Next State Addressing, Write Enable, Address Offset Counter Incrementing
					//none
			//Current Memory Address Location Reading, Writing, Register Loading, Shifting & Resetting
				//Y_even <= SRAM_read_data[15:8];//Y2
				//Y_odd <= SRAM_read_data[7:0];//Y3
				
				U_0<=U_1; //u0
				U_1<=U_2; //u0
				U_2<=U_3; //U1
				U_3<=U_4;//U2
				U_4<=U_5; //U3
				U_5<=U_even; //u4
				
				V_0<=V_1; //V0
				V_1<=V_2; //V0
				V_2<=V_3; //V1
				V_3<=V_4;//V2
				V_4<=V_5; //V3
				V_5<=V_even; //V4
			//MULTIPLICATION 1 -> PERFORM INTERPOLATION COMPUTATIONS
			//MULTIPLICATION 2 -> PERFORM CSC COMPUTATIONS
				M1_state <= S_LEAD_IN_10;
			//----- NOW WE HAVE TO FINISH INTERPOLATION FOR PIXEL 3 U,V PRIME
		end

		S_LEAD_IN_10: begin //column N
					//Next State Addressing, Write Enable, Address Offset Counter Incrementing
				M1_SRAM_address <= V_ADDRESS + V_OFFSET_COUNTER; 
				V_OFFSET_COUNTER <= V_OFFSET_COUNTER + 15'd1;
			//Current Memory Address Location Reading, Writing, Register Loading, Shifting & Resetting
		
			//MULTIPLICATION 1 -> PERFORM INTERPOLATION COMPUTATIONS
			//MULTIPLICATION 2 -> PERFORM CSC COMPUTATIONS
			RGB_MAC_Buf_Even_GREEN <=Y_16_Buf_Even- M1_result - M2_result; //G0
			RGB_MAC_Buf_Odd_GREEN<= Y_16_Buf_Odd- M3_result - M4_result;  //G1
				M1_state <= S_LEAD_IN_11;

		end
		
		S_LEAD_IN_11: begin //column O
		
			//Next State Addressing, Write Enable, Address Offset Counter Incrementing
				M1_SRAM_address <= Y_ADDRESS + Y_OFFSET_COUNTER; //stay in same sram address of Y location
				Y_OFFSET_COUNTER <= Y_OFFSET_COUNTER + 16'd1;
			//Current Memory Address Location Reading, Writing, Register Loading, Shifting & Resetting
		
			//MULTIPLICATION 1 -> PERFORM INTERPOLATION COMPUTATIONS
			//MULTIPLICATION 2 -> PERFORM CSC COMPUTATIONS

			M1_state <= S_LEAD_IN_12;

		end
		
		S_LEAD_IN_12: begin //column P
			//MULTIPLICATION 1 -> PERFORM INTERPOLATION COMPUTATIONS
			
			U_even_buf<=SRAM_read_data[15:8];//U6
			U_odd_buf<=SRAM_read_data[7:0];//U7
			U_Prime_Accum <= M1_result - M2_result + M3_result + M4_result; //start U'3 calculation

			M1_state <= S_LEAD_IN_13;

		end
		
		S_LEAD_IN_13: begin //column Q
		
				V_even_buf<=SRAM_read_data[15:8];//V6
				V_odd_buf<=SRAM_read_data[7:0];//V7
				

				//M1_SRAM_address <= V_ADDRESS + V_OFFSET_COUNTER;
			//	V_OFFSET_COUNTER <= V_OFFSET_COUNTER + 15'd1;
			
				V_Prime_Accum <=  M1_result - M2_result + M3_result + M4_result;
				M1_state <= S_LEAD_IN_14;	

		end
				
		S_LEAD_IN_14: begin //column Q
				Y_even_buf<=SRAM_read_data[15:8];//y2
				Y_odd_buf<=SRAM_read_data[7:0];//Y3
				
				U_Prime_even_buf<=U_2;
				
				U_Prime_Accum<=U_Prime_Accum-M1_result; //V PRIME 3 CALCULATING
				
				V_Prime_Accum<=V_Prime_Accum-M2_result; //V PRIME 3 CALCULATING
				
			RGB_RED_Even<=RGB_MAC_Buf_Even_RED;
			RGB_GREEN_Even<=RGB_MAC_Buf_Even_GREEN;

			RGB_RED_Odd<=RGB_MAC_Buf_Odd_RED;
			RGB_GREEN_Odd<=RGB_MAC_Buf_Odd_GREEN;
			
			U_Prime_even_buf<=U_0;
			//V_Prime_even_buf<=V_0;
				
				
			M1_state <= S_COMMON_CASE_STALL;
	

		end
				
S_COMMON_CASE_STALL: begin //column Q /// lead in 17(have to set up common 0)

				M1_SRAM_address <= RGB_ADDRESS + RGB_OFFSET_COUNTER;
				RGB_OFFSET_COUNTER <= RGB_OFFSET_COUNTER + 'd1;
			//Current Memory Address Location Reading, Writing, Register Loading, Shifting & Resetting
				M1_SRAM_we_n<=1'b0;
				M1_SRAM_write_data <= {R_clip_even, G_clip_even}; //STORE R0 G0
				
				//from lead in we are in V address
				//address

				//
		  		U_0<=U_1; //u0
				U_1<=U_2; //u1
				U_2<=U_3; //U2
				U_3<=U_4;//U3
				U_4<=U_5; //U4
				U_5<=U_odd; //u5
				
				V_0<=V_1; //V0
				V_1<=V_2; //V1
				V_2<=V_3; //V2
				V_3<=V_4; //V3
				V_4<=V_5; //V4
				V_5<=V_odd; //V5
				
				if(!lead_Out_Interpolation_flag)
				begin
				U_even<=U_even_buf;//new values are stored in U/V even/odd buf. They must replace old values once shifting is complete
				U_odd<=U_odd_buf;
				
				V_even<=V_even_buf;
				V_odd<=V_odd_buf;
				end
				
				//shift y's again 
			//	if(!lead_Out_Y_flag)
				//begin
				Y_even<=Y_even_buf;
				Y_odd<=Y_odd_buf;
				//end
				
				

		//finish U prime and V prime calcs here
				
			U_Prime_odd_buf <= (U_Prime_Accum + M1_result + 'd128) >> 8; //U'3 computed and saved
			U_Prime_Accum<='0;

			V_Prime_odd_buf<=(V_Prime_Accum + M2_result + 'd128) >> 8; //V'3 computed and saved
			V_Prime_Accum<='0;	

			RGB_MAC_Buf_Even_BLUE<=(Y_16_Buf_Even+M3_result);//B0 DONE, then B4
			RGB_MAC_Buf_Odd_BLUE<=(Y_16_Buf_Odd+M4_result); //B1 DONE. then B5
			
			RGB_BLUE_Even<=(Y_16_Buf_Even+M3_result);
			RGB_BLUE_Odd<=(Y_16_Buf_Odd+M4_result);


			M1_state <= S_COMMON_CASE_0;

		end
		 
S_COMMON_CASE_0: begin //column AE  //State 0, sets up for State 1
		 //Currently in Memory Location:
				// NONE
			//Next State Addressing, Write Enable, Address Offset Counter Incrementing
				//addressing is ok
			if(!lead_Out_START_NEW_ROW)
			begin
				M1_SRAM_address <= RGB_ADDRESS + RGB_OFFSET_COUNTER;
				RGB_OFFSET_COUNTER <= RGB_OFFSET_COUNTER + 'd1;
			//Current Memory Address Location Reading, Writing, Register Loading, Shifting & Resetting
				M1_SRAM_write_data <= {B_clip_even, R_clip_odd}; //STORE B0 R1, B4 R5, B8 R9
				pixel_counter <= pixel_counter + 10'd1;
				M1_SRAM_we_n<=1'b0;
			end
			//MULTIPLICATION 1 -> PERFORM INTERPOLATION COMPUTATIONS
				U_Prime_Accum <= M1_result; //U[-1]=U0 START NEW INTERPOLATION FOR U PRIME
				V_Prime_Accum <= M2_result; //V[-1]=U0 START NEW INTERPOLATION FOR V PRIME
			//MULTIPLICATION 2 -> PERFORM CSC COMPUTATIONS
				//pre-load all registers with same value
				RGB_MAC_EVEN_ACCUM <= M3_result; //76284*(y-16)' even
				RGB_MAC_ODD_ACCUM <= M4_result; //76284*y' odd

				Y_16_Buf_Even <= M3_result;//buffer for first product
				Y_16_Buf_Odd <= M4_result;
			if(lead_Out_START_NEW_ROW)
			begin
				pixel_counter<='d0;
				row_counter<=row_counter+'d1;
				M1_SRAM_we_n<=1'b1;
            M1_state <=S_LEAD_IN_STALL;
			end
				
				M1_state <= S_COMMON_CASE_1;

		end
		
S_COMMON_CASE_1: begin //State 1, sets up for State 2
		//Currently in Memory Location:
				// RGB +0
			//Next State Addressing, Write Enable, Address Offset Counter Incrementing
			//addressing is ok
				M1_SRAM_address <= RGB_ADDRESS + RGB_OFFSET_COUNTER;
				RGB_OFFSET_COUNTER <= RGB_OFFSET_COUNTER + 'd1;
				M1_SRAM_we_n<=1'b0;

    //Current Memory Address Location Reading, Writing, Register Loading, Shifting & Resetting
				M1_SRAM_write_data <= {G_clip_odd, B_clip_odd}; //STORE G1B1
				pixel_counter <= pixel_counter + 10'd1;
				

			//MULTIPLICATION 1 -> PERFORM INTERPOLATION COMPUTATIONS
				U_Prime_Accum <= U_Prime_Accum - M1_result; //U1
				V_Prime_Accum <= V_Prime_Accum - M2_result; //V1

			//MULTIPLICATION 2 -> PERFORM CSC COMPUTATIONS
				RGB_MAC_EVEN_ACCUM<= 64'd0;
				RGB_MAC_ODD_ACCUM<= 64'd0;

				RGB_MAC_Buf_Even_RED<= (RGB_MAC_EVEN_ACCUM + M3_result); //R2
				RGB_MAC_Buf_Odd_RED<= (RGB_MAC_ODD_ACCUM + M4_result);  //R3

				M1_state <= S_COMMON_CASE_2;

		end
		
S_COMMON_CASE_2: begin //State 2, sets up for State 3
		//Currently in Memory Location:
				// RGB+1
    //Next State Addressing, Write Enable, Address Offset Counter Incrementing
	 if(!lead_Out_Y_flag)
		begin
				M1_SRAM_address <= Y_ADDRESS + Y_OFFSET_COUNTER;
				Y_OFFSET_COUNTER <= Y_OFFSET_COUNTER + 16'd1;
				
		end
		M1_SRAM_we_n<=1'b1;
    //MULTIPLICATION 1 -> PERFORM INTERPOLATION COMPUTATIONS
				U_Prime_Accum <= U_Prime_Accum + M1_result; //trying to accum U2' via U2
				V_Prime_Accum <= V_Prime_Accum + M2_result; //trying to accum V2' via V2
    //MULTIPLICATION 2 -> PERFORM CSC COMPUTATIONS
				RGB_MAC_EVEN_ACCUM<= Y_16_Buf_Even - M3_result;  //R2 then R6          76284*y'- 25624*U' even
				RGB_MAC_ODD_ACCUM<= Y_16_Buf_Odd - M4_result;  //R3 then R7                      76284*y'- 25624*U' odd
				M1_state <= S_COMMON_CASE_3;
		end
S_COMMON_CASE_3: begin //State 3, sets up for State 4
		//Currently in Memory Location:
				// RGB+2
    //Current Memory Address Location Reading, Writing, Register Loading, Shifting & Resetting
	 if (!lead_Out_Interpolation_flag)
			begin
	 			M1_SRAM_address <= U_ADDRESS + U_OFFSET_COUNTER;
				U_OFFSET_COUNTER <= U_OFFSET_COUNTER + 15'd1;
			end
    //MULTIPLICATION 1 -> PERFORM INTERPOLATION COMPUTATIONS
			U_Prime_Accum <= U_Prime_Accum + M1_result; //trying to accum U3' via U3
			V_Prime_Accum <= V_Prime_Accum + M2_result; //trying to accum V3' via V3
			M1_SRAM_we_n<=1'b1;

    //MULTIPLICATION 2 -> PERFORM CSC COMPUTATIONS
			RGB_MAC_EVEN_ACCUM<= 64'd0;
			RGB_MAC_ODD_ACCUM<= 64'd0;

			RGB_MAC_Buf_Even_GREEN <= (RGB_MAC_EVEN_ACCUM - M3_result); //G2 then G6
			RGB_MAC_Buf_Odd_GREEN <= (RGB_MAC_ODD_ACCUM - M4_result) ;  //G3 then G7
			
			M1_state <= S_COMMON_CASE_4;

		end
S_COMMON_CASE_4: begin //State 4, sets up for State 5
		//Currently in Memory Location:
		if (!lead_Out_Interpolation_flag)
			begin
				M1_SRAM_address <= V_ADDRESS + V_OFFSET_COUNTER;
				V_OFFSET_COUNTER <= V_OFFSET_COUNTER + 15'd1;
			end
			
//		if(lead_Out_Interpolation_flag)
//			 begin
//					U_even<=U_odd;
//					V_even<=V_odd;//shift in SAME END VALUE if flag on ---aslways last read u and v's
//						
//			end
			
    //Current Memory Address Location Reading, Writing, Register Loading, Shifting & Resetting
	 
	 

    //MULTIPLICATION 1 -> PERFORM INTERPOLATION COMPUTATIONS
      U_Prime_Accum <= U_Prime_Accum - M1_result; //U4
      V_Prime_Accum <= V_Prime_Accum - M2_result; //V4

    //MULTIPLICATION 2 -> PERFORM CSC COMPUTATIONS
      RGB_MAC_Buf_Even_BLUE<= Y_16_Buf_Even + M3_result;  //B2, then B6    76284*y'-132251*U' even
      RGB_MAC_Buf_Odd_BLUE<= Y_16_Buf_Odd + M4_result;  //B3 then B7       76284*y'- 132251*U' odd

      M1_state <= S_COMMON_CASE_5;

    end
S_COMMON_CASE_5: begin //State 5, sets up for State 6
	 //Currently in Memory Location:
	 	 if(!lead_Out_Y_flag)
			begin
				M1_SRAM_address <= Y_ADDRESS + Y_OFFSET_COUNTER;
				Y_OFFSET_COUNTER <= Y_OFFSET_COUNTER + 16'd1;
    //Next State Addressing, Write Enable, Address Offset Counter Incrementing
	 			Y_even<=SRAM_read_data[15:8];//Y4
				Y_odd=SRAM_read_data[7:0];//Y5
			end
    //Current Memory Address Location Reading, Writing, Register Loading, Shifting & Resetting
				U_0<=U_1; //u1
				U_1<=U_2; //u2
				U_2<=U_3; //U3
				U_3<=U_4;//U4
				U_4<=U_5; //U5
				
				if(pixel_counter<310)
				begin
					U_5<=U_even; //u6
					V_5<=V_even; //V6
				end
				else 
				begin
					U_5<=U_odd; //u6
					V_5<=V_odd; //V6
				end
				//always shift in odd endpixel values when flag asserted (159 159 159...)
				
				V_0<=V_1; //V1
				V_1<=V_2; //V2
				V_2<=V_3; //V3
				V_3<=V_4; //V4
				V_4<=V_5; //V5
				
				
				//Y_even<=Y_even_buf; //shift down buffered vals into registers used in computation
				//Y_odd<=Y_odd_buf;
			//shift in new rgb values to be written:
			RGB_RED_Even<=RGB_MAC_Buf_Even_RED;
			RGB_GREEN_Even<=RGB_MAC_Buf_Even_GREEN;
			RGB_BLUE_Even<=RGB_MAC_Buf_Even_BLUE;

			RGB_RED_Odd<=RGB_MAC_Buf_Odd_RED;
			RGB_GREEN_Odd<=RGB_MAC_Buf_Odd_GREEN;
			RGB_BLUE_Odd<=RGB_MAC_Buf_Odd_BLUE;

			
    //MULTIPLICATION 1 -> PERFORM INTERPOLATION COMPUTATIONS
      U_Prime_odd_buf <= (U_Prime_Accum + M1_result + 'd128) >> 8; //U'5
      U_Prime_Accum<='0;

      V_Prime_odd_buf<=(V_Prime_Accum + M2_result + 'd128) >> 8; //V'5
      V_Prime_Accum<='0;
		
    //MULTIPLICATION 2 -> PERFORM CSC COMPUTATIONS
    //NONE
      M1_state <= S_COMMON_CASE_6;
    end
S_COMMON_CASE_6: begin //State 6, sets up for State 7
	 //Currently in Memory Location:	
		//rgb

    //Current Memory Address Location Reading, Writing, Register Loading, Shifting & Resetting	
if (!lead_Out_Interpolation_flag)
			begin
				U_even_buf<=SRAM_read_data[15:8];//Y4
				U_odd_buf<=SRAM_read_data[7:0];//Y5
			end
			
    //MULTIPLICATION 1 -> PERFORM INTERPOLATION COMPUTATIONS
			U_Prime_Accum<= M1_result - M2_result;
			V_Prime_Accum<= M3_result-M4_result;
    //MULTIPLICATION 2 -> PERFORM CSC COMPUTATIONS
      //NONE

			M1_state <= S_COMMON_CASE_7;

		end
S_COMMON_CASE_7: begin //State 7, sets up for State 8
	 //Currently in Memory Location:


				M1_SRAM_we_n<=1'b1;
    //Next State Addressing, Write Enable, Address Offset Counter Incrementing
	 if (!lead_Out_Interpolation_flag)
			begin
	 			V_even_buf<=SRAM_read_data[15:8];//Y4
				V_odd_buf<=SRAM_read_data[7:0];//Y5
			end

    //Current Memory Address Location Reading, Writing, Register Loading, Shifting & Resetting

    //MULTIPLICATION 1 -> PERFORM INTERPOLATION COMPUTATIONS

    //MULTIPLICATION 2 -> PERFORM CSC COMPUTATIONS
			RGB_MAC_EVEN_ACCUM<=M3_result;
			RGB_MAC_ODD_ACCUM<=M4_result;
			Y_16_Buf_Even<=M3_result; //Store 76284*(Y4' - 16) to recycle
			Y_16_Buf_Odd<=M4_result;  //Store 76284*(Y5' - 16) to recycle
			M1_state <= S_COMMON_CASE_8;

		end
S_COMMON_CASE_8: begin //State 8, sets up for State 9
	 //Currently in Memory Location:
	 if (!lead_Out_Y_flag)
			begin
				Y_even_buf<=SRAM_read_data[15:8];
				Y_odd_buf<=SRAM_read_data[7:0];
			end

    //Next State Addressing, Write Enable, Address Offset Counter Incrementing
	 
	 			M1_SRAM_address <= RGB_ADDRESS + RGB_OFFSET_COUNTER;
				RGB_OFFSET_COUNTER <= RGB_OFFSET_COUNTER + 'd1;
				M1_SRAM_we_n<=1'b0;
				M1_SRAM_write_data <= {R_clip_even, G_clip_even}; //STORE R2 G2

    //Current Memory Address Location Reading, Writing, Register Loading, Shifting & Resetting
				
    //MULTIPLICATION 1 -> PERFORM INTERPOLATION COMPUTATIONS
			U_Prime_Accum<=U_Prime_Accum+M1_result;
			V_Prime_Accum<=V_Prime_Accum+M2_result;
    //MULTIPLICATION 2 -> PERFORM CSC COMPUTATIONS
			RGB_MAC_EVEN_ACCUM<= 64'd0;
			RGB_MAC_Buf_Even_RED<=Y_16_Buf_Even+M3_result;//R4
			RGB_MAC_ODD_ACCUM<= 64'd0;
			RGB_MAC_Buf_Odd_RED <= Y_16_Buf_Odd+M4_result;//R5
      M1_state <= S_COMMON_CASE_9;
		end
S_COMMON_CASE_9: begin //State 9, sets up for State 10
	 //Currently in Memory Location:
	
      //Next State Addressing, Write Enable, Address Offset Counter Incrementing
				
     
				M1_SRAM_address <= RGB_ADDRESS + RGB_OFFSET_COUNTER;
				RGB_OFFSET_COUNTER <= RGB_OFFSET_COUNTER + 'd1;
			//Current Memory Address Location Reading, Writing, Register Loading, Shifting & Resetting
				M1_SRAM_write_data <= {B_clip_even, R_clip_odd}; //STORE B0 R1, B4 R5, B8 R9
				M1_SRAM_we_n<=1'b0;
				pixel_counter <= pixel_counter + 10'd1;


      //MULTIPLICATION 2 -> PERFORM CSC COMPUTATIONS
			U_Prime_Accum<=U_Prime_Accum+M1_result;
			V_Prime_Accum<=V_Prime_Accum+M2_result;
      //MULTIPLICATION 1 -> PERFORM INTERPOLATION COMPUTATIONS
		RGB_MAC_EVEN_ACCUM<=Y_16_Buf_Even-M3_result;
		RGB_MAC_ODD_ACCUM<=Y_16_Buf_Odd-M4_result;

  			M1_state <= S_COMMON_CASE_10;

        end
S_COMMON_CASE_10: begin //State 10, sets up for Lead-In 17
		  //Currently in Memory Location:

        //Next State Addressing, Write Enable, Address Offset Counter Incrementing
		  		M1_SRAM_address <= RGB_ADDRESS + RGB_OFFSET_COUNTER;
				RGB_OFFSET_COUNTER <= RGB_OFFSET_COUNTER + 'd1;
    //Next State Addressing, Write Enable, Address Offset Counter Incrementing
				M1_SRAM_we_n<=1'b0;
				M1_SRAM_write_data <= {G_clip_odd, B_clip_odd}; //STORE G3B3, G7B7	
				pixel_counter <= pixel_counter + 10'd1;

        //Current Memory Address Location Reading, Writing, Register Loading, Shifting & Resetting
			U_Prime_even_buf<=U_1;//MATCH WITH LEAD IN because we have a diff shift register arrangement (u_2 vs u_1) for u even/ v even primes

        //MULTIPLICATION 1 -> PERFORM INTERPOLATION COMPUTATIONS
			U_Prime_Accum<=U_Prime_Accum-M1_result;
			V_Prime_Accum<=V_Prime_Accum-M2_result;
			//NEED TO STORE IN REGISTERS STILL
        //MULTIPLICATION 2 -> PERFORM CSC COMPUTATIONS

			RGB_MAC_Buf_Even_GREEN<=RGB_MAC_EVEN_ACCUM-M3_result;  //G4
			RGB_MAC_Buf_Odd_GREEN<=RGB_MAC_ODD_ACCUM-M4_result;    //G5
			RGB_MAC_EVEN_ACCUM<= 64'd0;
			RGB_MAC_EVEN_ACCUM<= 64'd0;
			
			RGB_RED_Even<=RGB_MAC_Buf_Even_RED;
			RGB_GREEN_Even<=RGB_MAC_EVEN_ACCUM-M3_result;

			RGB_RED_Odd<=RGB_MAC_Buf_Odd_RED;
			RGB_GREEN_Odd<=RGB_MAC_ODD_ACCUM-M4_result;  

			commonCaseIter <= commonCaseIter + 'd1;
			
		
			if(lead_Out_START_NEW_ROW) begin
				pixel_counter<='d0;
				row_counter<=row_counter+'d1;
            M1_state <=S_LEAD_IN_STALL;
			end else 
				M1_state <= S_COMMON_CASE_STALL;
				
				
 end

		  
		default: M1_state <= S_IDLE_M1;
		
		endcase;
	end
	
	
end
//ultimate finesse

always_comb begin
//perform multiplication here
  M1_op1='d0;
  M1_op2='d0;

  M2_op1='d0;
  M2_op2='d0;

  M3_op1='d0;
  M3_op2='d0;

  M4_op1='d0;
  M4_op2='d0;
  
	lead_Out_Interpolation_flag= pixel_counter>'d304 ? 1'b1:1'b0; //if pixel counter gr8r than 302 raise flag to not read more interpolation vals
	lead_Out_Y_flag= pixel_counter>'d314 ? 1'b1:1'b0; //if pixel counter gr8r than 314 raise flag not to load more y vals
	lead_Out_START_NEW_ROW= pixel_counter>'d318 ? 1'b1:1'b0; 
	
	lead_Out_HARD_flag= row_counter>'d238 ? 1'b1:1'b0; 
	//not reading vals means same values will stay in buffers for end case


//lets make different multiplication cases for diff kinds of M1_states--->
case(M1_state)

S_IDLE: begin

end

S_LEAD_IN_STALL: begin //state -1

//NONE
end

S_LEAD_IN_0: begin //column B of state table

//NONE
end
S_LEAD_IN_1: begin //column C
//NONE

end
S_LEAD_IN_2: begin //column D
//NONE
end
S_LEAD_IN_3: begin //column E



end
S_LEAD_IN_4: begin //column F

	M1_op1=32'd21;
	M1_op2=U_0;

	M2_op1=32'd52;
	M2_op2=U_1;

	M3_op1=32'd159;
	M3_op2=U_2;

	M4_op1=32'd159;
	M4_op2=U_3;

end

S_LEAD_IN_5:begin //column G
//
	M1_op1=32'd21;
	M1_op2=V_0;

	M2_op1=32'd52;
	M2_op2=V_1;

	M3_op1=32'd159;
	M3_op2=V_2;

	M4_op1=32'd159;
	M4_op2=V_3;
//---

end
S_LEAD_IN_6: begin //column H

	M1_op1=32'd52;
	M1_op2=U_4;

	M2_op1=32'd21;
	M2_op2=U_5;
//-----



end
S_LEAD_IN_7: begin// COLUMN I

	M1_op1=32'd52;
	M1_op2=V_4;

	M2_op1=32'd21;
	M2_op2=V_5;



end

S_LEAD_IN_8: begin // COLUMN J

   M1_op1=32'd76284;
	M1_op2=Y_even-8'd16;
	
	M2_op1=32'd104595;
	M2_op2=V_0-32'd128; //R0

	M3_op1=32'd76284;
	M3_op2=Y_odd-8'd16;

	M4_op1=32'd104595;
	M4_op2=V_Prime_odd_buf-32'd128; //R1

end
S_LEAD_IN_9: begin //COLUMN K



end
S_LEAD_IN_10: begin  //COLUMN L
 	M1_op1=32'd25624;
  	M1_op2=U_0- 32'd128;

  	M2_op1=32'd53281;
  	M2_op2=V_0-32'd128;
	
	M3_op1=32'd25624;
  	M3_op2=U_Prime_odd_buf- 32'd128;

 	M4_op1=32'd53281;
  	M4_op2=V_Prime_odd_buf-32'd128;
//----



end
S_LEAD_IN_11: begin //column M
 	 M1_op1=32'd132251;
  	M1_op2=U_2-32'd128;

 	 M2_op1=32'd132251;
  	M2_op2=U_Prime_odd_buf-32'd128;


end
S_LEAD_IN_12: begin //column N
	M1_op1=32'd21;
	M1_op2=U_0; //u0

	M2_op1=32'd52;
	M2_op2=U_1; //u0

	M3_op1=32'd159;
	M3_op2=U_2; //u1

	M4_op1=32'D159;
	M4_op2=U_3; //u2

end
S_LEAD_IN_13: begin //column O
	M1_op1=32'd21;
	M1_op2=V_0; //V0

	M2_op1=32'd52;
	M2_op2=V_1; //V0

	M3_op1=32'd159;
	M3_op2=V_2; //V0

	M4_op1=32'd159;
	M4_op2=V_3; //V1
end
S_LEAD_IN_14: begin //column P

	M1_op1=32'd52;
	M1_op2=U_4; //V0

	M2_op1=32'd52;
	M2_op2=V_4; //V0



end
S_COMMON_CASE_STALL: begin //column P
	M1_op1=32'd21;
	M1_op2=U_5; //V0

	M2_op1=32'd21;
	M2_op2=V_5; //V0

	M3_op1=32'd132251;
	M3_op2=U_1- 32'd128;; //V0

	M4_op1=32'd132251;
	M4_op2=U_Prime_odd_buf- 32'd128;; //V1

end


S_COMMON_CASE_0: begin //column AE
	M1_op1=32'd21;
	M1_op2=U_0; //u0

	M2_op1=32'd21;
	M2_op2=V_0; //v0

	M3_op1=32'd76284;
	M3_op2=Y_even-32'd16; //Y2

	M4_op1=32'd76284;
	M4_op2=Y_odd-32'd16;//Y3
end
S_COMMON_CASE_1: begin //column AF
	M1_op1=32'd52;
	M1_op2=U_1;

	M2_op1=32'd52;
	M2_op2=V_1;

	M3_op1=32'd104595;
	M3_op2=V_1 - 32'd128;

	M4_op1=32'd104595;
	M4_op2=V_Prime_odd_buf - 32'd128;

end
S_COMMON_CASE_2: begin //column AG
	M1_op1=32'd159;
	M1_op2=U_2;

	M2_op1=32'd159;
	M2_op2=V_2;

	M3_op1=32'd25624;
	M3_op2=U_1- 32'd128;

	M4_op1=32'd25624;
	M4_op2=U_Prime_odd_buf - 32'd128;

end
S_COMMON_CASE_3: begin //column AH
	M1_op1=32'd159;
	M1_op2=U_3;

	M2_op1=32'd159;
	M2_op2=V_3;

	M3_op1=32'd53281;
	M3_op2=V_1- 32'd128;

	M4_op1=32'd53281;
	M4_op2=V_Prime_odd_buf - 32'd128;

end
S_COMMON_CASE_4: begin //column AE
	M1_op1=32'd52;
	M1_op2=U_4;
	M2_op1=32'd52;
	M2_op2=V_4;

	M3_op1=32'd132251;
	M3_op2=U_1-32'd128;

	M4_op1=32'd132251;
	M4_op2=U_Prime_odd_buf-32'd128;

end
S_COMMON_CASE_5: begin //column AE
	M1_op1=32'd21;
	M1_op2=U_5;

	M2_op1=32'd21;
	M2_op2=V_5;


end
S_COMMON_CASE_6: begin //column AE
  M1_op1=32'd21;
  M1_op2=U_0;

  M2_op1=32'd52;
  M2_op2=U_1;

  M3_op1=32'd21;
  M3_op2=V_0;

  M4_op1=32'd52;
  M4_op2=V_1;

end
S_COMMON_CASE_7: begin //column AE
  M3_op1=32'd76284;
  M3_op2=Y_even -32'd16; //y4 prime

  M4_op1=32'd76284;
  M4_op2=Y_odd -32'd16; //y5 prime

end
S_COMMON_CASE_8: begin //column AE
  M1_op1=32'd159;
  M1_op2=U_2;

  M2_op1=32'd159;
  M2_op2=V_2;

  M3_op1=32'd104595;
  M3_op2=V_1-32'd128;

  M4_op1=32'd104595;
  M4_op2=V_Prime_odd_buf-32'd128;

end
S_COMMON_CASE_9: begin //column AE
  M1_op1=32'd159;
  M1_op2=U_3;

  M2_op1=32'd159;
  M2_op2=V_3;

  M3_op1=32'd25624;
  M3_op2=U_1-32'd128;

  M4_op1=32'd25624;
  M4_op2=U_Prime_odd_buf-32'd128;

end
S_COMMON_CASE_10: begin //column AE
  M1_op1=32'd52;
  M1_op2=U_4;

  M2_op1=32'd52;
  M2_op2=V_4;

  M3_op1=32'd53281;
  M3_op2=V_1-32'd128;

  M4_op1=32'd53281;
  M4_op2=V_Prime_odd_buf-32'd128;

end


endcase

end


endmodule