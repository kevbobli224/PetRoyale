// Part 2 skeleton

module pet_royale2
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
        SW,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B,   //	VGA Blue[9:0]
		PS2_CLK, 
		PS2_DAT
	);

	input			CLOCK_50;				//	50 MHz
	input   [9:0]   SW;
	input   [3:0]   KEY;
	inout PS2_CLK;
	inout PS2_DAT;
	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	wire resetn;
	assign resetn = KEY[0];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;

	wire [7:0] x1, x2, x3, x4;
	wire [6:0] y1, y2, y3, y4;
	wire [4:0] w1, w2, w3, w4;
	wire [4:0] h1, h2, h3, h4;
	
	
	wire [7:0] character1;
	
//	assign x2 = 120;
//	assign y2 = 40;
//	assign w2 = 8;
//	assign h2 = 8;
	
//	assign x3 = 10;
//	assign y3 = 70;
	assign w3 = 4;
	assign h3 = 4;

//	assign x4 = 110;
//	assign y4 = 80;
//	assign w4 = 8;
//	assign h4 = 8;
	
	wire [4:0] key_states;
	wire [1:0] ball_states;
	
	wire [1:0] l1, l2;
	
	//keyboard_tracker #(.PULSE_OR_HOLD(0)) t1(.clock(CLOCK_50), .reset(KEY[0]), 
	//.PS2_CLK(PS2_CLK), .PS2_DAT(PS2_DAT), .keypress_out(key_states));
	
	//character_controller char1(x1, y1, w1, h1, key_states, CLOCK_50, KEY);
	
	gameplay gp(CLOCK_50, resetn, x3, y3, w3, h3, x1, y1, w1, h1, x2, y2, w2, h2, ball_states, l1, l2);
	
	vga_driver vga_d1(x, y, colour, writeEn, CLOCK_50, resetn, 
	                  x1, y1, w1, h1, x2, y2, w2, h2, x3, y3, w3, h3, x4, y4, w4, h4, KEY, key_states, ball_states, l1, l2);
							
	
	

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
			
	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.
    
    // Instansiate datapath
	// datapath d0(...);

    // Instansiate FSM control
    // control c0(...);
    
endmodule

//module character_controller(char_x, char_y, char_w, char_h, key_states, clk, debug_key);
//	output reg [7:0] char_x; 
//	output reg [6:0] char_y;
//	input [3:0] char_w, char_h;
//	input clk;
//	input [3:0] debug_key;
//	input [4:0] key_states;
//	
////	always @(clk) begin
////		case(key_states)
////			'd9: char_x <= char_x - 1;
////			'd10: char_x <= char_x + 1;
////			'd11: char_y <= char_y - 1;
////			'd12: char_y <= char_y - 1;
////		endcase
////	end
//	always @(*) begin
//		if(debug_key[0] == 1)
//			if (char_x > 0)
//				char_x <= char_x - 1;
//		else if(debug_key[1] == 1)
//			if (char_x < (160 - char_w))
//				char_x <= char_x + 1;
//		else if(debug_key[2] == 1)
//			if (char_y > 0)
//				char_y <= char_y - 1;
//		else if(debug_key[3] == 1)
//			if (char_y < (120 - char_h))
//				char_y <= char_y + 1;
//	end
//	
//endmodule

module vga_driver(x_out, y_out, color, writeEn, clk, resetn, 
                  x1, y1, w1, h1, x2, y2, w2, h2, x3, y3, w3, h3, x4, y4, w4, h4, debug_key, key_states, ball_states, lives1, lives2);
	
	output reg [7:0] x_out;
	output reg [6:0] y_out;
	input [3:0] debug_key;
	output reg [2:0] color;
	output writeEn;
	input clk;
	input resetn;
	input [4:0] key_states;
	input [1:0] ball_states;
	
	input [1:0] lives1, lives2;
	
	output reg [7:0] x1, x2, x4;
	initial x1 = 50;
	initial y1 = 100;
	initial w1 = 8;
	initial h1 = 8;
	initial x2 = 120;
	initial y2 = 40;
	initial w2 = 8;
	initial h2 = 8;
	input [7:0] x3;
	output reg [6:0] y1, y2, y4;
	input [6:0] y3;
	output reg [4:0] w1, w2, w4;
	input [4:0] w3, h3;
	output reg [4:0] h1, h2, h4;
	
	reg [7:0] lives1_x, lives2_x;
	reg [6:0] lives1_y, lives2_y;
	initial lives1_x = 10; initial lives1_y = 105;
	initial lives2_x = 130; initial lives2_y = 105;
	
	reg [26:0] counter;
	wire vga_en;
	
	reg [7:0] row_data1 ,row_data2, row_data4;
	wire col_pixel1, col_pixel2, col_pixel4;
	reg [2:0] color1, color2, color4;
	wire [2:0] x_indx1, x_indx2, x_indx4;
	wire [2:0] y_indx1, y_indx2, y_indx4;
	
	wire [2:0] lives_indx1, lives_indx2;
	wire [2:0] lives_indy1, lives_indy2;
	reg [7:0] row_data_lives1, row_data_lives2;
	wire col_pixel_lives1, col_pixel_lives2;
	reg [2:0] color_l1, color_l2;
	
	localparam 	S_DEFAULT = 'd0, 
					S_CHAR_INIT = 'd1,
					S_CHAR_DONE_INIT = 'd2;
	
	reg [5:0] current_state, next_state;
	reg done_init;
	
	always @(*) begin
		case(current_state)
			S_DEFAULT: next_state = S_CHAR_INIT;
			S_CHAR_INIT: next_state = done_init ? S_CHAR_DONE_INIT : S_CHAR_INIT;
			S_CHAR_DONE_INIT: next_state = S_CHAR_DONE_INIT;
			default: next_state = S_DEFAULT;
		endcase
	end
	
	always@ (posedge clk)
	begin
//		case(current_state)
//			S_DEFAULT: begin
//				done_init <= 1'b0;
//			end
//			S_CHAR_INIT: begin
//				x2 <= 'd120;
//				y2 <= 'd40;
//				w2 <= 'd8;
//				h2 <= 'd8;
//			end
//			S_CHAR_DONE_INIT: done_init <= 1'b1;
//		endcase
		if (!resetn)
			begin
				current_state <= S_CHAR_INIT;
				done_init <= 1'b0;
				counter <= 0;
				x_out <= 0;
				y_out <= 0;
			end
		else
			begin
				if(counter >= 12_500_000) begin
					// Uncomment for keyboard only
//					if(key_states >= 'd1 && key_states <= 'd4) begin
					// Left
					if(!debug_key[0] || key_states == 'd1) begin
						if (x1 > 0)
							x1 <= x1 - 1;
					end
					// Right
					if(!debug_key[1] || key_states == 'd3) begin
						if (x1 < (160 - w1))
							x1 <= x1 + 1;
					end
					// Up
					if(!debug_key[2] || key_states == 'd4) begin
						if (y1 > 0)
							y1 <= y1 - 1;
					end
					// Down
					if(!debug_key[3] || key_states == 'd2) begin
						if (y1 < (120 - h1))
							y1 <= y1 + 1;
					end
//					end
					else if (key_states >= 'd9 && key_states <= 'd12) begin
						case(key_states) // l r u d
							9: begin 
								if (x2 > 0)
									x2 <= x2 - 1;
							end
							10: begin
								if (x2 < (160 - w2))
									x2 <= x2 + 1;
							end
							11: begin
								if (y2 > 0)
									y2 <= y2 - 1;
							end
							12: begin
								if (y2 < (120 - h2))
									y2 <= y2 + 1;
							end
						
						endcase
					end
					counter <= 0;
				end
				else 
					counter <= counter + 1;
					
				if (x_out >= 159)
					begin
						x_out <= 0;
						if(y_out >= 119)
							y_out <= 0;
						else
							y_out <= y_out + 1;
					end
				else
					x_out <= x_out + 1;
			end
		current_state <= next_state;
	end
	assign vga_en = (counter == 12_500_000);
	assign writeEn = 1;
	
	wire [2:0] c_red, c_blue, c_green;
	assign c_red = 3'b100;
	assign c_blue = 3'b001;
	assign c_green = 3'b010;
	
	always@ (*)
	begin
		if ((x1 <= x_out) && (x_out < x1 + w1) && 
		    (y1 <= y_out) && (y_out < y1 + h1))
			color = color1;
		else if ((x2 <= x_out) && (x_out < x2 + w2) && 
		         (y2 <= y_out) && (y_out < y2 + h2))
			color = color2;
		else if ((x3 <= x_out) && (x_out < x3 + w3) && 
		         (y3 <= y_out) && (y_out < y3 + h3))
			color = ball_states == 2'b01 ? c_red : ball_states == 2'b10 ? c_blue : c_green;
//		else if ((x4 <= x_out) && (x_out < x4 + w4) && 
//		         (y4 <= y_out) && (y_out < y4 + h4))
//			color = color4;
		else if ((lives1_x <= x_out) && (x_out < lives1_x + 8) && 
					(lives1_y <= y_out) && (y_out < lives1_y + 8))
			color = color_l1;
		
		else if ((lives2_x <= x_out) && (x_out < lives2_x + 8) && 
					(lives2_y <= y_out) && (y_out < lives2_y + 8))
			color = color_l2;
		
		else
			color = 3'b0;

	end	
	
	assign x_indx1 = (x_out - x1) & 3'b111;
	assign y_indx1 = (y_out - y1) & 3'b111;
	assign x_indx2 = (x_out - x2) & 3'b111;
	assign y_indx2 = (y_out - y2) & 3'b111;
	assign lives_indx1 = (x_out - lives1_x) & 3'b111;
	assign lives_indy1 = (y_out - lives1_y) & 3'b111;
	assign lives_indx2 = (x_out - lives2_x) & 3'b111;
	assign lives_indy2 = (y_out - lives2_y) & 3'b111;
//	assign x_indx4 = (x_out - x4) & 3'b111;
//	assign y_indx4 = (y_out - y4) & 3'b111;
	
	// character 1
	always @(*) 
		case (y_indx1) 
			3'h0: row_data1 = 8'b11000011; //  **    ** 
			3'h1: row_data1 = 8'b11100111; //  ***  ***
			3'h2: row_data1 = 8'b01111110; //   ******
			3'h3: row_data1 = 8'b01111110; //   ****** 
			3'h4: row_data1 = 8'b11111111; //  **D**D** 
			3'h5: row_data1 = 8'b11111111; //  ******** 
			3'h6: row_data1 = 8'b01111110; //   ****** 
			3'h7: row_data1 = 8'b00000000; //
	endcase
		// character 2
	always @(*)
		case (y_indx2)
			3'h0: row_data2 = 8'b01000010; //   *    * 
			3'h1: row_data2 = 8'b01100110; //   **  **
			3'h2: row_data2 = 8'b01111110; //   ******
			3'h3: row_data2 = 8'b01111110; //   ****** 
			3'h4: row_data2 = 8'b11111111; //  **D**D** 
			3'h5: row_data2 = 8'b01111110; //   ****** 
			3'h6: row_data2 = 8'b00011000; //    ****
			3'h7: row_data2 = 8'b00000000; //     **
			//x2, y4 left eye x5, y4 right eye
	endcase
	//character 4 (ball is x3)
//	always @(*)
//		case (y_indx4)
//			3'h0: row_data4 = 8'b11100111; //  ***  *** 
//			3'h1: row_data4 = 8'b11100111; //  ***  ***
//			3'h2: row_data4 = 8'b01111110; //   ******
//			3'h3: row_data4 = 8'b11111111; //  ********
//			3'h4: row_data4 = 8'b11111111; //  **D**D** 
//			3'h5: row_data4 = 8'b11111111; //  ********
//			3'h6: row_data4 = 8'b01111110; //   ****** 
//			3'h7: row_data4 = 8'b00000000; //
//			//x2, y4 left eye x2, y4 right eye
//	endcase
	always @(*) begin
		case (lives_indy1)
			3'h0: row_data_lives1 = lives1 == 2'b11 ? 8'b11011011 : lives1 == 2'b10 ? 8'b11011000 : lives1 == 2'b01 ? 8'b11000000 : 8'b10000001 ; 
			3'h1: row_data_lives1 = lives1 == 2'b11 ? 8'b11011011 : lives1 == 2'b10 ? 8'b11011000 : lives1 == 2'b01 ? 8'b11000000 : 8'b01000010 ;  
			3'h2: row_data_lives1 = lives1 == 2'b11 ? 8'b11011011 : lives1 == 2'b10 ? 8'b11011000 : lives1 == 2'b01 ? 8'b11000000 : 8'b00100100 ; 
			3'h3: row_data_lives1 = lives1 == 2'b11 ? 8'b11011011 : lives1 == 2'b10 ? 8'b11011000 : lives1 == 2'b01 ? 8'b11000000 : 8'b00011000 ; 
			3'h4: row_data_lives1 = lives1 == 2'b11 ? 8'b11011011 : lives1 == 2'b10 ? 8'b11011000 : lives1 == 2'b01 ? 8'b11000000 : 8'b00011000 ;  
			3'h5: row_data_lives1 = lives1 == 2'b11 ? 8'b11011011 : lives1 == 2'b10 ? 8'b11011000 : lives1 == 2'b01 ? 8'b11000000 : 8'b00100100 ; 
			3'h6: row_data_lives1 = lives1 == 2'b11 ? 8'b11011011 : lives1 == 2'b10 ? 8'b11011000 : lives1 == 2'b01 ? 8'b11000000 : 8'b01000010 ; 
			3'h7: row_data_lives1 = lives1 == 2'b11 ? 8'b11011011 : lives1 == 2'b10 ? 8'b11011000 : lives1 == 2'b01 ? 8'b11000000 : 8'b10000001 ; 
		endcase
		case (lives_indy2)
			3'h0: row_data_lives2 = lives2 == 2'b11 ? 8'b11011011 : lives2 == 2'b10 ? 8'b11011000 : lives2 == 2'b01 ? 8'b11000000 : 8'b10000001 ; 
			3'h1: row_data_lives2 = lives2 == 2'b11 ? 8'b11011011 : lives2 == 2'b10 ? 8'b11011000 : lives2 == 2'b01 ? 8'b11000000 : 8'b01000010 ;  
			3'h2: row_data_lives2 = lives2 == 2'b11 ? 8'b11011011 : lives2 == 2'b10 ? 8'b11011000 : lives2 == 2'b01 ? 8'b11000000 : 8'b00100100 ; 
			3'h3: row_data_lives2 = lives2 == 2'b11 ? 8'b11011011 : lives2 == 2'b10 ? 8'b11011000 : lives2 == 2'b01 ? 8'b11000000 : 8'b00011000 ; 
			3'h4: row_data_lives2 = lives2 == 2'b11 ? 8'b11011011 : lives2 == 2'b10 ? 8'b11011000 : lives2 == 2'b01 ? 8'b11000000 : 8'b00011000 ;  
			3'h5: row_data_lives2 = lives2 == 2'b11 ? 8'b11011011 : lives2 == 2'b10 ? 8'b11011000 : lives2 == 2'b01 ? 8'b11000000 : 8'b00100100 ; 
			3'h6: row_data_lives2 = lives2 == 2'b11 ? 8'b11011011 : lives2 == 2'b10 ? 8'b11011000 : lives2 == 2'b01 ? 8'b11000000 : 8'b01000010 ; 
			3'h7: row_data_lives2 = lives2 == 2'b11 ? 8'b11011011 : lives2 == 2'b10 ? 8'b11011000 : lives2 == 2'b01 ? 8'b11000000 : 8'b10000001 ; 
		endcase
	end
	assign col_pixel1 = row_data1[x_indx1];
	assign col_pixel2 = row_data2[x_indx2];
	assign col_pixel_lives1 = row_data_lives1[lives_indx1];
	assign col_pixel_lives2 = row_data_lives2[lives_indx2];
//	assign col_pixel4 = row_data4[x_indx4];
	always @(*)
	begin
		if ((y_indx1 == 4) && ((x_indx1 == 2) || (x_indx1 == 5)))
			color1 = col_pixel1 ? 3'b001 : 3'b0;
		else
			color1 = col_pixel1 ? 3'b100 : 3'b0;
		if ((y_indx2 == 4) && ((x_indx2 == 2) || (x_indx2 == 5)))
			color2 = col_pixel2 ? 3'b001 : 3'b0;
		else
			color2 = col_pixel2 ? 3'b100 : 3'b0;
		color_l1 = col_pixel_lives1 ? c_red : 3'b0;
		color_l2 = col_pixel_lives2 ? c_red : 3'b0;
//		if ((y_indx4 == 4) && ((x_indx4 == 2) || (x_indx4 == 5)))
//			color4 = col_pixel4 ? 3'b001 : 3'b0;
//		else
//			color4 = col_pixel4 ? 3'b100 : 3'b0;
	end
	
endmodule


module gameplay(clk, resetn, ball_x, ball_y, ball_w, ball_h, char1_x, char1_y, char1_w, char1_h, char2_x, char2_y, char2_w, char2_h, ball_states, lives1, lives2);

	input clk;
	input resetn;
	output reg [7:0] ball_x;
	output reg [6:0] ball_y;
	input [4:0] ball_w;
	input [4:0] ball_h;
	output reg [1:0] ball_states, lives1, lives2;

	
	reg [3:0] invincibility_counter = 15;
	reg is_invincible;
	
	input [7:0] char1_x, char2_x;
	input [6:0] char1_y, char2_y;
	input [3:0] char1_w, char1_h, char2_w, char2_h; // 8x8 -> 4'b1000
	
	reg [26:0] counter;
	wire update_en;
	
	reg dir_x;
	reg dir_y;

	always@ (posedge clk)
	begin
		if (!resetn)
			begin
				lives1 <= 3;
				lives2 <= 3;
				counter <= 0;
			end
		else
			begin
			if (is_q)
				is_invincible <= 1'b1;
				
				if(counter >= 3_250_000) begin
					if (is_invincible == 1'b1) begin
						invincibility_counter <= 1;
						if (invincibility_counter == 0) begin
							invincibility_counter <= 15;
							is_invincible <= 1'b0;
						end
					end
					counter <= 0;
				end
				else 
					counter <= counter + 1;
			end
		
	end
	assign update_en = (counter == 3_250_000);
	always@ (posedge clk)
	begin
		if (!resetn)
			begin
				ball_x <= 0;
				ball_y <= 0;
				dir_x <= 1;
				dir_y <= 1;
			end
		else if (update_en)
			begin
				if(dir_x)
				begin
					if(ball_x >= 159 - ball_w)
					begin
						dir_x <= 0;
						ball_x <= ball_x - 1;
					end
					else
						ball_x <= ball_x + 1;
				end
				else
				begin
					if(ball_x == 1)
					begin
						dir_x <= 1;
						ball_x <= ball_x + 1;
					end
					else
						ball_x <= ball_x - 1;
				end
				if(dir_y)
				begin
					if(ball_y >= 119 - ball_h)
					begin
						dir_y <= 0;
						ball_y <= ball_y - 1;
					end
					else
						ball_y <= ball_y + 1;
				end
				else
				begin
					if(ball_y == 1)
					begin
						dir_y <= 1;
						ball_y <= ball_y + 1;
					end
					else
						ball_y <= ball_y - 1;
				end
				if (((ball_x == char1_x || ball_x == char1_x + char1_w) && (ball_y >= char1_y && ball_y <= char1_y + char1_h)) || 
				((ball_x == char2_x || ball_x == char2_x + char2_w) && (ball_y >= char2_y && ball_y <= char2_y + char2_h))) begin
					dir_x <= ~dir_x;
					if (ball_x == char1_x || ball_x == char1_x + char1_w) begin
						if (ball_states == 2'b10 && ~is_invincible)
							lives1 <= lives1 - 1;
						ball_states <= 2'b01;
					end
					else begin
						if (ball_states == 2'b01 && ~is_invincible)
							lives2 <= lives2 - 1;
						ball_states <= 2'b10;
					end
					is_q <= 1'b1;
				end
				else if (((ball_y == char1_y || ball_y == char1_y + char1_h) && (ball_x >= char1_x && ball_x <= char1_x + char1_w)) ||
				((ball_y == char2_y || ball_y == char2_y + char2_h) && (ball_x >= char2_x && ball_x <= char2_x + char2_w))) begin
					dir_y <= ~dir_y;
					if (ball_y == char1_y || ball_y == char1_y + char1_h) begin
						if (ball_states == 2'b10 && ~is_invincible)
							lives1 <= lives1 - 1;
						ball_states <= 2'b01;
					end
					else begin
						if (ball_states == 2'b01 && ~is_invincible)
							lives2 <= lives2 - 1;
						ball_states <= 2'b10;
					end
					is_q <= 1'b1;
				end
			end
			if(is_invincible)
				is_q <= 1'b0;
	end // always
reg is_q;

endmodule

