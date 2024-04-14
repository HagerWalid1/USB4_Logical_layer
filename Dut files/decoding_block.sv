/* 

Author: Ahmed Tarek Shafik Mohamed
Date: 29/2/2024
Block: Transactions FSM
Project: USB4 Logical layer Human based VS AI based code
sponsered by: Siemens EDA

Description:

- The following block is responsible of decoidng the lanes data to a 
64b/66b or 128b/132b data decoding scheme

- the block is generic, depending on the gen_speed signal the block adapts itself
to one of the decoding schemes

- for more information please refer to the spec document.

*/



module decoding_block (

	input             enc_clk,
	input             rst,     
	input             enable_dec,     

	input [ 131 : 0 ] lane_0_rx_enc,
	input [ 131 : 0 ] lane_1_rx_enc,

	input [ 1   : 0 ] gen_speed,
	input [ 3   : 0 ] d_sel,


	output reg [ 7 : 0 ] lane_0_rx,
	output reg [ 7 : 0 ] lane_1_rx,

	output reg           data_os,
	output reg           enable_deskew

	);




reg [7:0] mem_0  [17];
reg [7:0] mem_1  [17];

reg [3:0] byte_numb;	

reg [3:0] max_byte_num;

reg flag;


	localparam GEN4 = 'b00,
               GEN3 = 'b01,
		       GEN2 = 'b10;
	
	always @(*)
	  begin
	    case(gen_speed)
		GEN4: max_byte_num = 0;
		GEN3: max_byte_num = 15;
		GEN2: max_byte_num = 7;
		default: max_byte_num = 1;
		endcase
	  end


	always @(posedge enc_clk or negedge rst) begin 
		if(~rst) begin
			byte_numb <= max_byte_num;
		end else if(~enable_dec) begin
			byte_numb <= max_byte_num;
		end else if (byte_numb != max_byte_num) begin
			byte_numb <= byte_numb + 1;
		end else begin
			byte_numb <= 0;
		end
	end


	always @(posedge enc_clk or negedge rst) begin 

		if(~rst) begin

			lane_0_rx <= 0;
			lane_1_rx <= 0;
			enable_deskew <= 0;
			lane_0_rx <= 'h0;
			lane_1_rx <= 'h0;
			flag <= 0;
			
		end else if(~enable_dec) begin

			enable_deskew <= 0;
			flag <= 0;
			lane_0_rx <= mem_0[byte_numb];
			lane_1_rx <= mem_1[byte_numb];

		end else begin
		
			lane_0_rx <= mem_0[byte_numb];
			lane_1_rx <= mem_1[byte_numb];
			
			if(byte_numb == 0) 
			  begin
			    flag <= 1;
			    enable_deskew <= (gen_speed == GEN4)? flag : 1;
			  end
			
			if (byte_numb == max_byte_num) begin

				mem_0 [0] <= lane_0_rx_enc[7 : 0];
				mem_0 [1] <= lane_0_rx_enc[15 : 8];
				mem_0 [2] <= lane_0_rx_enc[23 : 16];
				mem_0 [3] <= lane_0_rx_enc[31 : 24];
				mem_0 [4] <= lane_0_rx_enc[39 : 32];
				mem_0 [5] <= lane_0_rx_enc[47 : 40];
				mem_0 [6] <= lane_0_rx_enc[55 : 48];
				mem_0 [7] <= lane_0_rx_enc[63 : 56];
				mem_0 [8] <= lane_0_rx_enc[71 : 64];
				mem_0 [9] <= lane_0_rx_enc[79 : 72];
				mem_0 [10] <= lane_0_rx_enc[87 : 80];
				mem_0 [11] <= lane_0_rx_enc[95 : 88];
				mem_0 [12] <= lane_0_rx_enc[103 : 96];
				mem_0 [13] <= lane_0_rx_enc[111 : 104];
				mem_0 [14] <= lane_0_rx_enc[119 : 112];
				mem_0 [15] <= lane_0_rx_enc[127 : 120];
				mem_0 [16] <= lane_0_rx_enc[131 : 128];
				
				mem_1 [0] <= lane_1_rx_enc[7 : 0];
				mem_1 [1] <= lane_1_rx_enc[15 : 8];
				mem_1 [2] <= lane_1_rx_enc[23 : 16];
				mem_1 [3] <= lane_1_rx_enc[31 : 24];
				mem_1 [4] <= lane_1_rx_enc[39 : 32];
				mem_1 [5] <= lane_1_rx_enc[47 : 40];
				mem_1 [6] <= lane_1_rx_enc[55 : 48];
				mem_1 [7] <= lane_1_rx_enc[63 : 56];
				mem_1 [8] <= lane_1_rx_enc[71 : 64];
				mem_1 [9] <= lane_1_rx_enc[79 : 72];
				mem_1 [10] <= lane_1_rx_enc[87 : 80];
				mem_1 [11] <= lane_1_rx_enc[95 : 88];
				mem_1 [12] <= lane_1_rx_enc[103 : 96];
				mem_1 [13] <= lane_1_rx_enc[111 : 104];
				mem_1 [14] <= lane_1_rx_enc[119 : 112];
				mem_1 [15] <= lane_1_rx_enc[127 : 120];
				mem_1 [16] <= lane_1_rx_enc[131 : 128];
				
				end

			
			case (gen_speed)

				GEN2: begin 
					
					case (mem_0 [8][1:0])

							'b10: begin 
								data_os <= 0;

							end
							'b01: begin 
								data_os <=1;
							end

						endcase
					
				end



				GEN3: begin 

						case (mem_0 [16][3:0])

							'b1010: begin 
								data_os <= 0;

							end
							'b0101: begin 
								data_os <=1;
							end

						endcase

				end

				GEN4: begin 

					data_os <= (d_sel == 'h8);

				end

			endcase

		end 

	end

endmodule