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

	wire [7:0] x1, x2, x3;
	wire [6:0] y1, y2, y3;
	wire [4:0] w1, w2, w3;
	wire [4:0] h1, h2, h3;
	
	wire [7:0] character1;
	
	assign x2 = 120;
	assign y2 = 40;
	assign w2 = 6;
	assign h2 = 4;
	
//	assign x3 = 10;
//	assign y3 = 70;
	assign w3 = 4;
	assign h3 = 4;
	
	//gameplay gp();
	
	wire [4:0] key_states;
	
	
	keyboard_tracker #(.PULSE_OR_HOLD(0)) t1(.clock(CLOCK_50), .reset(KEY[0]), 
	.PS2_CLK(PS2_CLK), .PS2_DAT(PS2_DAT), .keypress_out(key_states));
	
	//character_controller char1(x1, y1, w1, h1, key_states, CLOCK_50, KEY);
	
	gameplay gp(CLOCK_50, resetn, x3, y3, w3, h3, x1, y1, w1, h1);
	
	vga_driver vga_d1(x, y, colour, writeEn, CLOCK_50, resetn, 
	                  x1, y1, w1, h1, x2, y2, w2, h2, x3, y3, w3, h3, character1);
							
	
	

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
                  x1, y1, w1, h1, x2, y2, w2, h2, x3, y3, w3, h3, debug_key);
	
	output reg [7:0] x_out;
	output reg [6:0] y_out;
	input [3:0] debug_key;
	output reg [2:0] color;
	output writeEn;
	input clk;
	input resetn;
	
	output reg [7:0] x1, x2;
	input [7:0] x3;
	output reg [6:0] y1, y2;
	input [6:0] y3;
	output reg [4:0] w1, w2;
	input [4:0] w3, h3;
	output reg [4:0] h1, h2;
		
	reg [26:0] counter;
	wire vga_en;
	
	reg [7:0] row_data1;
	
	wire col_pixel1;
	reg [2:0] color1;
	wire [2:0] x_indx1;
	wire [2:0] y_indx1;
	
	localparam S_CHAR_INIT = 'd0,
					S_CHAR_DONE_INIT = 'd1;
	
	reg [5:0] current_state, next_state;
	reg done_init;
	
	always @(*) begin
		case(current_state)
			S_CHAR_INIT: next_state = done_init ? S_CHAR_DONE_INIT : S_CHAR_INIT;
		endcase
	end
	
	always@ (posedge clk)
	begin
		case(current_state)
			S_CHAR_INIT: begin
				x1 <= 50;
				y1 <= 100;
				w1 <= 8;
				h1 <= 8;
				done_init <= 1'b1;
			end
		endcase
		current_state <= next_state;
		if(debug_key[0] != 1)
			if (x1 > 0)
				x1 <= x1 - 1;
		else if(debug_key[1] != 1)
			if (x1 < (160 - w1))
				x1 <= x1 + 1;
		else if(debug_key[2] != 1)
			if (y1 > 0)
				y1 <= y1 - 1;
		else if(debug_key[3] != 1)
			if (y1 < (120 - h1))
				y1 <= y1 + 1;
		if (!resetn)
			begin
				counter <= 0;
				x_out <= 0;
				y_out <= 0;
			end
		else
			begin
				if(counter >= 12_500_000)
					counter <= 0;
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
	end
	assign vga_en = (counter == 12_500_000);
	assign writeEn = 1;
	always@ (*)
	begin
		if ((x1 <= x_out) && (x_out < x1 + w1) && 
		    (y1 <= y_out) && (y_out < y1 + h1))
			color = color1;
		else if ((x2 <= x_out) && (x_out < x2 + w2) && 
		         (y2 <= y_out) && (y_out < y2 + h2))
			color = 3'b010;
		else if ((x3 <= x_out) && (x_out < x3 + w3) && 
		         (y3 <= y_out) && (y_out < y3 + h3))
			color = 3'b001;
		else
			color = 3'b0;

	end	
	
	assign x_indx1 = (x_out - x1) & 3'b111;
	assign y_indx1 = (y_out - y1) & 3'b111;
	
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
		
	assign col_pixel1 = row_data1[x_indx1];

	always @(*)
	begin
		if ((y_indx1 == 4) && ((x_indx1 == 2) || (x_indx1 == 5)))
			color1 = col_pixel1 ? 3'b001 : 3'b0;
		else
			color1 = col_pixel1 ? 3'b100 : 3'b0;
	end
endmodule


module gameplay(clk, resetn, ball_x, ball_y, ball_w, ball_h, char1_x, char1_y, char1_w, char1_h);

	input clk;
	input resetn;
	output reg [7:0] ball_x;
	output reg [6:0] ball_y;
	input [4:0] ball_w;
	input [4:0] ball_h;
	
	input [7:0] char1_x;
	input [6:0] char1_y;
	input [3:0] char1_w, char1_h; // 8x8 -> 4'b1000
	
	reg [26:0] counter;
	wire update_en;
	
	reg dir_x;
	reg dir_y;

	always@ (posedge clk)
	begin
		if (!resetn)
			begin
				counter <= 0;
			end
		else
			begin
				if(counter >= 6_250_000)
					counter <= 0;
				else 
					counter <= counter + 1;
			end
	end
	assign update_en = (counter == 6_250_000);
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
				if ((ball_x == char1_x || ball_x == char1_x + char1_w) && (ball_y >= char1_y && ball_y <= char1_y + char1_h))
					dir_x <= ~dir_x;
				else if ((ball_y == char1_y || ball_y == char1_y + char1_y + char1_h) && ball_x >= char1_x && ball_x <= char1_x + char1_w)
					dir_y <= ~dir_y;
			end
	end // always


endmodule

