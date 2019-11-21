// External modules specifications

// Random Number Generator: 	RNG 							(clk, en, reset, data_out)
//										RNGOnce 						(data_out)
// Seven Segment Decoder:		ssg 							(HEX, SW[3:0])
// 4x4 Tile Drawer:				draw_4x4						(mx, my, cx, cy, colour, out_colour);
// Splash mem:						splash_mem 					(address,clock,data,wren,q);
// VGA Address Translator:		vga_address_translator	(x, y, mem_address)

// Key Bindings
// KEY[3] = Generate Dungeon and Draw
// KEY[0] = Reset
	 
// keyboard_interface_test_mode1 k1(CLOCK_50,KEY,PS2_CLK,PS2_DAT,LEDR);

module petroyale(
	input CLOCK_50, input [3:0] KEY, input[9:0] SW,
	inout PS2_CLK, inout PS2_DAT, 
	output [9:0] LEDR, 
	output [6:0] HEX5, output [6:0] HEX4, output [6:0] HEX0, output [6:0] HEX1,
	output VGA_CLK, output VGA_HS, output VGA_VS, output VGA_BLANK_N, output VGA_SYNC_N,
	output [9:0] VGA_R, output [9:0] VGA_G, output [9:0] VGA_B);

	wire [7:0] random_number;
	
	// 160x120
	wire [7:0] vga_x;
	wire [6:0] vga_y;
	// 2*3 - 1. Each channel covers 2-bit
	wire [8:0] colour;
	
	wire plot_ready;
	assign plot_ready = 1'b1;
	
	
	vga_adapter VGA(.resetn(~LEDR[0]),.clock(CLOCK_50),.colour(colour),
			.x(vga_x),.y(vga_y),.plot(plot_ready),
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
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 3;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
		defparam VGA.USING_DE1 = "TRUE";
	
	// States Specification
	// 0 		- Dungeon Generate # Rooms
	// 1  		-> Generating Rooms
	// 2  		-> 4x4 Tile Colouring
	// 3  		-> Generating Rooms Wait
	// 4			-> Done Generating
	// 244	- Plot Ready
	// 255 	- Reset
	wire [7:0] inner_states;
	// 0		- Splash screen
	reg [4:0] main_states;
	
	// Character Position
	reg [7:0] tx;
	reg [6:0] ty;
	
	// VGA cursor
	reg [7:0] cx;
	reg [6:0] cy;
	
	//	Sw[0], KEY[0]:	VGA resetn signal
	assign LEDR[0] = SW[0] && ~KEY[0];
	// Sw[1], KEY[3]:	Generates Dungeon
	assign LEDR[1] = SW[1] && ~KEY[3];
	// Sw[1], KEY[0]:	Reset Dungeon
	assign LEDR[2] = SW[1] && ~KEY[0];
	
	// Random Number Generator, all switches off, KEY[3] generates, KEY[0] resets to 0F
	wire should_generate;
	assign should_generate = (inner_states == 8'b0000_0000 || inner_states == 8'b0000_0011 || (SW == 8'b0000_0000 && ~KEY[3]));
	
	
	wire [14:0] splash_address;
	wire [8:0]	splash_colour;
//	vga_address_translator a_splash(cx, cy, splash_address);
//	splash_mem mem_spash(splash_address,CLOCK_50,{9{1'b0}},1'b0,splash_colour);
	
	ssg h5(HEX5, random_number[7:4]);
	ssg h4(HEX4, random_number[3:0]);
	ssg h0(HEX0, inner_states[3:0]);
	ssg h1(HEX1, {3'b000, KEY[1]});
	
	// 160x120
	wire [7:0] dungeon_x;
	wire [6:0] dungeon_y;
	dungeon_generator(.clk(CLOCK_50), .go(LEDR[1]), .reset(LEDR[2]), 
	.mx(dungeon_x), .my(dungeon_y), .rng(random_number),
	.states(inner_states), .out_colour(colour));
	
	reg [8:0] state_colour;
	
	always @ (posedge CLOCK_50) begin
		if(~KEY[0]) begin
			main_states <= 5'b00000;
		end
		else begin
			if (cx > 160) begin
				cx <= 0;
				if (cy > 120) begin
					cy <= 0;
				end 
				else begin
					cy <= cy + 1;
				end
			end 
			else begin
				cx <= cx + 1;
				case(main_states)
					5'b00000: begin
						state_colour = splash_colour;
					end
				endcase
			end
		end
	end

	assign vga_x = dungeon_x;
	assign vga_y = dungeon_y;
//	reg [3:0] offset;
//	always @(posedge CLOCK_50) begin 
//		if(~KEY[0]) begin
//			cx 		<= 8'b00000000;
//			cy 		<= 7'b0000000;
//			offset 		<= 4'b0000;
//		end
//		else begin
//			if(offset == 4'b1111)
//				offset <= 4'b0000;
//			else
//				offset <= offset + 4'b0001;
//				cx 	<= {1'b0, 6'b001000};
//				cy 	<= 6'b001000;
//		end
//	end
//	
//	assign vga_x = cx + offset[1:0];
//	assign vga_y = cy + offset[3:2];
//	assign colour = {{3'b111}, {3'b000}, {3'b000}};
	
endmodule

module dungeon_generator(clk, go, reset, mx, my, rng, states, out_colour);
	input clk, go, reset;
	
	inout [7:0] rng;
	
	output reg [7:0] states;
	
	output [7:0] mx;
	output [6:0] my;
	output [8:0] out_colour;
	
	reg [7:0] tx;
	reg [6:0] ty;
	
	// Max 8 total states
	reg [2:0] current_state, next_state;
	
	// 0-15 rooms to be generated
	reg [3:0] number_rooms;
	
	
	// Module states
	localparam 	S_GEN_ROOM = 4'd0,
					S_GEN_ROOM_WAIT = 4'd1,
					S_DRAW = 4'd2,
					S_DRAW_END = 4'd3,
					S_RESET = 4'd4;
					
	always@(*)
		begin: state_table 
            case (current_state)
               S_GEN_ROOM: 		next_state = go ? S_GEN_ROOM_WAIT : S_GEN_ROOM;
					S_GEN_ROOM_WAIT:  next_state = (~go&&states == 'd5) ? S_DRAW : S_GEN_ROOM_WAIT ;
					S_DRAW: 				next_state = (go&&~number_rooms) ? S_DRAW_END : S_DRAW;
					S_DRAW_END:			next_state = (go&&~number_rooms) ? S_DRAW_END : S_RESET;
					S_RESET:				next_state = reset ? S_GEN_ROOM : S_RESET;
					default:     		next_state = S_GEN_ROOM;
				endcase
    end
	// Random coord (0-34, 0-24)
	reg [5:0] rx;
	reg [4:0] ry;
	// Random dimension (Min: 3x3, Max: 5x5)
	reg [2:0] sx, sy;
	// Size counter
	reg [2:0] scx, scy;
	// 4x4 tiles
	reg [3:0] offset;
	
	wire state_feedback;
	// add en and coord
	draw_4x4(.mx(mx), .my(my), .tx(tx), .ty(ty), .out_colour(out_colour), .clk(clk), .fb(state_feedback));

	
	always@(posedge clk) begin
		if (reset == 1'b1) begin
			current_state <= S_GEN_ROOM;
			states <= 8'b0000_0000;
		end
		else begin
			case(current_state)
				S_GEN_ROOM_WAIT: begin
					if (states == 'd0) begin
						if(rng[3:0] <= 5)
							number_rooms <= 'd5;
						else
							number_rooms <= rng[3:0];
						states <= 8'b0000_0001;
					end
					if(number_rooms > 0 && (states=='d1) && state_feedback) begin
						rx <= {rng[0], rng[2], rng[4], rng[6]};
						rx <= rng[7] ? (rx + {rng[1], rng[3], rng[5]}) : (rx + {rng[2], rng[4], rng[6]});
						
						ry <= {rng[1], rng[3], rng[5], rng[6]};
						ry <= rng[0] ? (ry + {rng[1], rng[3], rng[5]}) : (ry + {rng[2], rng[4], rng[6]});
							
						sx <= {rng[1], rng[2], rng[3]};
						sx <= (sx > 5) ? ((sx < 3) ? sx : 3) : 5;
							
						sy <= {rng[4], rng[5], rng[6]};
						sy <= (sy > 5) ? ((sy < 3) ? sy : 3) : 5;
		
						scx = sx;
						scy = sy;
						
						number_rooms <= number_rooms - 1;
						states <= 8'b0000_0010;
					end
					if (states == 'd2) begin
						if(scx > 0) begin
							tx <= rx * 4 + scx * 4;
							scx <= scx - 1;
						end
						else if(scy > 0) begin
							ty <= ry * 4 + scy * 4;
							scy <= scy - 1;
						end
						else
							states <= 8'b0000_0011;
					end
					else if(number_rooms && states == 'd3) begin
						states <= 8'b0000_0001;
					end
					else
						states <= 8'b0000_0101;
				end
				S_DRAW: begin
					states <= 8'b000_0110;
				end
			endcase
			current_state = next_state;
		end
	end

endmodule

module draw_4x4(mx, my, tx, ty, out_colour, clk, fb);
	input		clk;
	input 	[7:0] tx;
	input 	[6:0] ty;
	
	output 	[7:0] mx;
	output 	[6:0] my;
	output 	[8:0] out_colour;
	
	output reg		fb;
	
	// 4x4 tiles
	reg [3:0] offset;
	reg [8:0] colour;
	// Valid 9-bit colour hexs:
	// 31, 63, 95, 127, 159, 192, 223, 255
	always @(posedge clk) begin 
		if(offset == 4'b1111) begin
			offset <= 4'b0000;
			fb <= 1'b0;
			end
		else
			case(offset)
				// Top + Right Shading (Light: 159, 95, 95)
				1'd0, 'd1, 1'd2, 1'd3, 'd7, 'd11: colour = 9'b101_010_010;
				// Left + Bottom Shading (Dark: 95, 0, 0)
				1'd4, 1'd8, 'd12, 'd13, 'd14, 'd15: colour = 9'b010_000_000;
				// Middle Shading (Normal: 159, 95, 0)
				1'd5, 1'd6, 1'd9, 1'd10: colour = 9'b101_010_000;
			endcase
			offset <= offset + 4'b0001;
			fb <= 1'b1;
	end
	
	assign mx 			= tx + offset[1:0];
	assign my 			= ty + offset[3:2];
	assign out_colour	= colour;
endmodule