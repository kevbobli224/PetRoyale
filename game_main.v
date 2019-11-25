module game_main(input CLOCK_50, input [3:0] KEY, input[9:0] SW,
	inout PS2_CLK, inout PS2_DAT, 
	output [9:0] LEDR, 
	output [6:0] HEX5, output [6:0] HEX4, output [6:0] HEX0, output [6:0] HEX1, 
	output VGA_CLK, output VGA_HS, output VGA_VS, output VGA_BLANK_N, output VGA_SYNC_N,
	output [9:0] VGA_R, output [9:0] VGA_G, output [9:0] VGA_B);
	
	// 128 available states
	wire [6:0] game_states;
	
	wire [4:0] key_states;
	
	keyboard_tracker #(.PULSE_OR_HOLD(0)) t1(.clock(CLOCK_50), .reset(KEY[0]), 
	.PS2_CLK(PS2_CLK), .PS2_DAT(PS2_DAT), .keypress_out(key_states));
	
	game_datapath main_datapath(key_states, CLOCK_50, KEY[3], KEY[2], game_states);
	game_control  main_control(key_states, CLOCK_50, KEY[2], game_states, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, SW[9:0]);
	
endmodule

module game_control(kstates, clk, reset, control_states, 
	debughex1, debughex2, debughex3, debughex4, debughex5, debughex6, switches);
	input clk, reset;
	input [4:0] kstates;
	input [9:0] switches;
	output reg [6:0] control_states;
	output [6:0] debughex1, debughex2, debughex3, debughex4, debughex5, debughex6;
	
	reg [7:0] random_number;
	
	// 128 states
	reg [6:0] next_states;
	
	localparam 	S_RNG_INIT = 4'd0,
					S_GEN_PETS = 4'd1,	
					S_GEN_PETS_WAIT = 4'd2,
					S_GEN_DONE = 4'd3,
					S_PETS_COMBAT_SELECT_PLAYER1 = 4'd4,
					S_PETS_COMBAT_SELECT_PLAYER1_WAIT = 4'd5,
					S_PETS_COMBAT_SELECT_PLAYER2 = 4'd6,
					S_PETS_COMBAT_SELECT_PLAYER2_WAIT = 4'd7,
					S_PETS_COMBAT_PLAYER1_TURN = 4'd8,
					S_PETS_COMBAT_PLAYER1_WAIT = 4'd9,
					S_PETS_COMBAT_PLAYER1_PROCESS = 4'd10,
					S_PETS_COMBAT_PLAYER2_TURN = 4'd11,
					S_PETS_COMBAT_PLAYER2_WAIT = 4'd12,
					S_PETS_COMBAT_PLAYER2_PROCESS = 4'd13,
					S_PETS_COMBAT_PLAYER1_SWAP = 4'd14,
					S_PETS_COMBAT_PLAYER1_SWAP_PROCESS = 4'd15,
					S_PETS_COMBAT_PLAYER2_SWAP = 4'd16,
					S_PETS_COMBAT_PLAYER2_SWAP_PROCESS = 4'd17,
					S_VICTORY = 4'd18;
	
	// Player 1 on the right, player 2 on the left.
	// Debugging(SW):
	// 0 - Current game's states, refer to localparam's state table
	// 1 - Check key states, what key is being pressed
	// 2 - Check 8-bit generated random number
	// 4,5,6,7 - Player 1's pet [Def][Health], Atk damage is not shown.
	// 8 - Both player's selected pet
	
	ssg h1(debughex1, (switches == 0 ? control_states[3:0] : 
							(switches == 1 ? {3'b000, kstates[4]} : 
							(switches == 4 ? {1'b0, player1_pet1[2:0]} : 
							(switches == 5 ? {1'b0, player1_pet2[2:0]} : 
							(switches == 6 ? {1'b0, player1_pet3[2:0]} : 
							(switches == 7 ? {1'b0, player1_pet4[2:0]} : 
							(switches == 8 ? {1'b0, player1_pet[2:0]} : 5'b11111))))))));
							
	ssg h2(debughex2, (switches == 1 ? kstates[3:0] : 
							(switches == 4 ? {1'b0, player1_pet1[5:3]} : 
							(switches == 5 ? {1'b0, player1_pet2[5:3]} : 
							(switches == 6 ? {1'b0, player1_pet3[5:3]} : 
							(switches == 7 ? {1'b0, player1_pet4[5:3]} : 
							(switches == 8 ? {1'b0, player1_pet[5:3]} : 5'b11111)))))));
							
	ssg h5(debughex5, (switches == 2 ? random_number[3:0] : 
							(switches == 4 ? {1'b0, player2_pet1[2:0]} : 
							(switches == 5 ? {1'b0, player2_pet2[2:0]} : 
							(switches == 6 ? {1'b0, player2_pet3[2:0]} : 
							(switches == 7 ? {1'b0, player2_pet4[2:0]} : 
							(switches == 8 ? {1'b0, player2_pet[2:0]} : 5'b11111)))))));
	
	ssg h6(debughex6, (switches == 2 ? random_number[7:4] : 							
							(switches == 4 ? {1'b0, player2_pet1[5:3]} : 
							(switches == 5 ? {1'b0, player2_pet2[5:3]} : 
							(switches == 6 ? {1'b0, player2_pet3[5:3]} : 
							(switches == 7 ? {1'b0, player2_pet4[5:3]} : 
							(switches == 8 ? {1'b0, player2_pet[5:3]} : 5'b11111)))))));
							
	ssg h3(debughex3, (switches == 8 ? {1'b0, combat_selection} : 5'b11111));
							
	ssg h4(debughex4, (switches == 2 ? {1'b0, combat_selection} : 
							(switches == 8 ? {1'b0, player2_pet[5:3]} : 5'b11111)));
							
	
	
		
	reg rng_en, reset_n;
	reg [2:0] rng_init_counter;
	RNG r0(clk, rng_en, (reset_n && ~rng_en), random_number);

	// Each pet stats occupy 3-bit value (Min 1 Max 8)
	// HP: 2:0, DEF: 5:3, ATK: 8:6
	reg [8:0] player1_pet1;
	reg [8:0] player1_pet2;
	reg [8:0] player1_pet3;
	reg [8:0] player1_pet4;
	
	reg [8:0] player2_pet1;
	reg [8:0] player2_pet2;
	reg [8:0] player2_pet3;
	reg [8:0] player2_pet4;
	
	reg [2:0] counter_generate;
	
	reg [2:0] player1_current, player2_current;
	reg [8:0] player1_pet, player2_pet;
	

	
	always @(*) begin
		case (control_states)
			S_RNG_INIT:									next_states = rng_init_counter == 3'b111 ? S_GEN_PETS : S_RNG_INIT;
			S_GEN_PETS: 								next_states = kstates == 'd14 ? S_GEN_PETS_WAIT : S_GEN_PETS;
			S_GEN_PETS_WAIT: 							next_states = (kstates == 'd14 && counter_generate != 3'b111) ? S_GEN_PETS : S_GEN_DONE;
			S_GEN_DONE:									next_states = (kstates <= 'd4 && kstates >= 'd1) ? S_PETS_COMBAT_SELECT_PLAYER1 : S_GEN_DONE;
			S_PETS_COMBAT_SELECT_PLAYER1:			next_states = (kstates <= 'd4 && kstates >= 'd1) ? S_PETS_COMBAT_SELECT_PLAYER1_WAIT : S_PETS_COMBAT_SELECT_PLAYER1;
			S_PETS_COMBAT_SELECT_PLAYER1_WAIT: 	next_states = (kstates <= 'd4 && kstates >= 'd1) ? S_PETS_COMBAT_SELECT_PLAYER1_WAIT : 
															(player1_current == 0) ? ((player1_pet1[2:0] <= 0) ? S_PETS_COMBAT_SELECT_PLAYER1 : S_PETS_COMBAT_SELECT_PLAYER2) : 
															(player1_current == 1) ? ((player1_pet2[2:0] <= 0) ? S_PETS_COMBAT_SELECT_PLAYER1 : S_PETS_COMBAT_SELECT_PLAYER2) : 
															(player1_current == 2) ? ((player1_pet3[2:0] <= 0) ? S_PETS_COMBAT_SELECT_PLAYER1 : S_PETS_COMBAT_SELECT_PLAYER2) : 
															((player1_pet4[2:0] <= 0) ? S_PETS_COMBAT_SELECT_PLAYER1 : S_PETS_COMBAT_SELECT_PLAYER2) ;
			S_PETS_COMBAT_SELECT_PLAYER2:			next_states = (kstates <= 'd8 && kstates >= 'd5) ? S_PETS_COMBAT_SELECT_PLAYER2_WAIT : S_PETS_COMBAT_SELECT_PLAYER2;
			S_PETS_COMBAT_SELECT_PLAYER2_WAIT: 	next_states = (kstates <= 'd8 && kstates >= 'd5) ? S_PETS_COMBAT_SELECT_PLAYER2_WAIT : 
															(player2_current == 0) ? ((player2_pet1[2:0] <= 0) ? S_PETS_COMBAT_SELECT_PLAYER2 : S_PETS_COMBAT_PLAYER1_TURN) : 
															(player2_current == 1) ? ((player2_pet2[2:0] <= 0) ? S_PETS_COMBAT_SELECT_PLAYER2 : S_PETS_COMBAT_PLAYER1_TURN) : 
															(player2_current == 2) ? ((player2_pet3[2:0] <= 0) ? S_PETS_COMBAT_SELECT_PLAYER2 : S_PETS_COMBAT_PLAYER1_TURN) : 
															((player2_pet4[2:0] <= 0) ? S_PETS_COMBAT_SELECT_PLAYER2 : S_PETS_COMBAT_PLAYER1_TURN) ;
															
			S_PETS_COMBAT_PLAYER1_TURN:			next_states = (kstates == 'd9 || kstates == 'd10 || kstates == 'd13) ? S_PETS_COMBAT_PLAYER1_WAIT : S_PETS_COMBAT_PLAYER1_TURN;
			S_PETS_COMBAT_PLAYER1_WAIT: 			next_states = (kstates == 'd9 || kstates == 'd10 || kstates == 'd13) ? S_PETS_COMBAT_PLAYER1_WAIT : 
															(kstates == 'd13) ? S_PETS_COMBAT_PLAYER1_PROCESS : S_PETS_COMBAT_PLAYER1_WAIT;
			S_PETS_COMBAT_PLAYER1_PROCESS:		next_states = combat_player2_lives == 0 ? S_VICTORY : (combat_player1_lives > 1 && combat_player1_swap == 1'b1) ? S_PETS_COMBAT_PLAYER1_SWAP : S_PETS_COMBAT_PLAYER1_TURN;
			S_PETS_COMBAT_PLAYER1_SWAP:			next_states = (kstates <= 'd4 && kstates >= 'd1) ? S_PETS_COMBAT_PLAYER1_PROCESS : S_PETS_COMBAT_PLAYER1_SWAP;
			S_PETS_COMBAT_PLAYER1_SWAP_PROCESS:	next_states = (player1_pet[2:0] <= 0) ? S_PETS_COMBAT_PLAYER1_SWAP : S_PETS_COMBAT_PLAYER2_TURN;
																	
			
			
			S_PETS_COMBAT_PLAYER2_TURN:			next_states = (kstates == 'd9 || kstates == 'd10 || kstates == 'd13) ? S_PETS_COMBAT_PLAYER2_WAIT : S_PETS_COMBAT_PLAYER2_TURN;
			S_PETS_COMBAT_PLAYER2_WAIT: 			next_states = (kstates == 'd9 || kstates == 'd10 || kstates == 'd13) ? S_PETS_COMBAT_PLAYER2_WAIT : 
															(kstates == 'd13) ? S_PETS_COMBAT_PLAYER2_PROCESS : S_PETS_COMBAT_PLAYER2_WAIT;
			S_PETS_COMBAT_PLAYER2_PROCESS:		next_states = combat_player1_lives == 0 ? S_VICTORY : (combat_player1_lives > 1 && combat_player1_swap == 1'b1) ? S_PETS_COMBAT_PLAYER1_SWAP : S_PETS_COMBAT_PLAYER1_TURN;
			S_PETS_COMBAT_PLAYER2_SWAP:			next_states = (kstates <= 'd8 && kstates >= 'd5) ? S_PETS_COMBAT_PLAYER2_PROCESS : S_PETS_COMBAT_PLAYER2_SWAP;
			S_PETS_COMBAT_PLAYER2_SWAP_PROCESS:	next_states = (player2_pet[2:0] <= 0) ? S_PETS_COMBAT_PLAYER1_SWAP : S_PETS_COMBAT_PLAYER1_TURN;
			
			S_VICTORY:									next_states = S_VICTORY;
															
			default: 									next_states = S_GEN_PETS;
		endcase
	end
	
	wire [2:0] player1_atk, player2_atk, player1_def, player2_def;
	assign player1_atk = player1_pet[8:6];
	assign player2_atk = player2_pet[8:6];
	assign player1_def = player1_pet[5:3];
	assign player2_def = player2_pet[5:3];
	
	reg player1_is_blocking, player2_is_blocking;
	reg [1:0] combat_selection1, combat_selection2;
	reg [1:0] combat_player1_lives, combat_player2_lives;
	reg combat_player1_swap, combat_player2_swap;
	
	// game_victor is only accurate when the game had ended, otherwise player 1 "wins"
	wire game_victor;
	assign game_victor = (combat_player1_lives == 0 ? 1 : 0);
	
	always @(posedge clk) begin
		if(~reset) begin
			control_states <= S_GEN_PETS;
		end
		case(control_states)
			S_RNG_INIT: begin
				if(rng_init_counter == 0) begin
					reset_n <= 1;
					rng_init_counter <= rng_init_counter + 3'b001;
				end 
				else begin
					reset_n <= 0;
					rng_en <= 1;
					rng_init_counter <= rng_init_counter + 3'b001;
				end
			end
			S_GEN_PETS_WAIT: begin
				if(counter_generate == 3'b111) begin
					player2_pet4 <= {
							{(random_number[6:3] == 0) ? 3'b001: random_number[5:3]},
							{(random_number[2:0] == 0) ? 3'b001: random_number[2:0]},
							{1'b1, random_number[7:6]}};
							counter_generate <= counter_generate + 3'b001;
				end
				else begin
					case(counter_generate)
						3'b000: begin
							player1_pet1 <= { 
							{(random_number[6:3] == 0) ? 3'b001: random_number[5:3]},
							{(random_number[2:0] == 0) ? 3'b001: random_number[2:0]},
							{1'b1, random_number[7:6]}};
							counter_generate <= counter_generate + 3'b001;
						end
						3'b001: begin
							player1_pet2 <= { 
							{(random_number[6:3] == 0) ? 3'b001: random_number[5:3]},
							{(random_number[2:0] == 0) ? 3'b001: random_number[2:0]},
							{1'b1, random_number[7:6]}};
							counter_generate <= counter_generate + 3'b001;
						end
						3'b010: begin
							player1_pet3 <= {
							{(random_number[6:3] == 0) ? 3'b001: random_number[5:3]},
							{(random_number[2:0] == 0) ? 3'b001: random_number[2:0]},
							{1'b1, random_number[7:6]}};
							counter_generate <= counter_generate + 3'b001;
						end
						3'b011: begin
							player1_pet4 <= {
							{(random_number[6:3] == 0) ? 3'b001: random_number[5:3]},
							{(random_number[2:0] == 0) ? 3'b001: random_number[2:0]},
							{1'b1, random_number[7:6]}};
							counter_generate <= counter_generate + 3'b001;
						end
						3'b100: begin
							player2_pet1 <= {
							{(random_number[6:3] == 0) ? 3'b001: random_number[5:3]},
							{(random_number[2:0] == 0) ? 3'b001: random_number[2:0]},
							{1'b1, random_number[7:6]}};
							counter_generate <= counter_generate + 3'b001;
						end
						3'b101: begin
							player2_pet2 <= {
							{(random_number[6:3] == 0) ? 3'b001: random_number[5:3]},
							{(random_number[2:0] == 0) ? 3'b001: random_number[2:0]},
							{1'b1, random_number[7:6]}};
							counter_generate <= counter_generate + 3'b001;
						end
						3'b110: begin
							player2_pet3 <= { 
							{(random_number[6:3] == 0) ? 3'b001: random_number[5:3]},
							{(random_number[2:0] == 0) ? 3'b001: random_number[2:0]},
							{1'b1, random_number[7:6]}};
							counter_generate <= counter_generate + 3'b001;
						end
					endcase
				end
			end
			S_GEN_DONE: begin
				rng_en <= 0;
				combat_player1_lives <= 2'b11;
				combat_player2_lives <= 2'b11;
			end
			S_PETS_COMBAT_SELECT_PLAYER1: begin
				case(kstates)
					1: player1_current <= 0;
					2:	player1_current <= 1;
					3:	player1_current <= 2;
					4:	player1_current <= 3;
				endcase
			end
			S_PETS_COMBAT_SELECT_PLAYER2: begin
				player1_pet <= player1_current == 0 ? player1_pet1 :
									player1_current == 1 ? player1_pet2 :
									player1_current == 2 ? player1_pet3 : player1_pet4;
				case(kstates)
					5: player2_current <= 0;
					6:	player2_current <= 1;
					7:	player2_current <= 2;
					8:	player2_current <= 3;
				endcase
			end
			S_PETS_COMBAT_PLAYER1_TURN: begin
				player2_pet <= player2_current == 0 ? player2_pet1 :
									player2_current == 1 ? player2_pet2 :
									player2_current == 2 ? player2_pet3 : player2_pet4;
									
				if(kstates == 'd10) begin
					if(combat_selection1 == 2'b11)
						combat_selection1 <= 2'b00;
					else
						combat_selection1 <= combat_selection1 + 2'b01;
				end
				else if (kstates == 'd9) begin
					if(combat_selection1 == 2'b00)
						combat_selection1 <= 2'b111;
					else
						combat_selection1 <= combat_selection1 - 2'b01;
				end
			end
			S_PETS_COMBAT_PLAYER1_PROCESS: begin
				// 0 = Attack, 1 = Defend, 2 = Swap, stat boost should be scrapped
				case(combat_selection1)
					2'b00: begin
						case(player2_current)
							0: player2_pet1[2:0] <= (player2_pet1[2:0] - (player2_is_blocking ? ((player2_def - player1_atk) < 0) ? 0 : (player2_def - player1_atk) : player1_atk));
							1: player2_pet2[2:0] <= (player2_pet2[2:0] - (player2_is_blocking ? ((player2_def - player1_atk) < 0) ? 0 : (player2_def - player1_atk) : player1_atk));
							2:	player2_pet3[2:0] <= (player2_pet3[2:0] - (player2_is_blocking ? ((player2_def - player1_atk) < 0) ? 0 : (player2_def - player1_atk) : player1_atk));
							3:	player2_pet4[2:0] <= (player2_pet4[2:0] - (player2_is_blocking ? ((player2_def - player1_atk) < 0) ? 0 : (player2_def - player1_atk) : player1_atk));
						endcase
						combat_player1_lives <= (player1_pet1[2:0] > 0) + (player1_pet2[2:0] > 0) + (player1_pet3[2:0] > 0) + (player1_pet4[2:0] > 0);
					end
					2'b01: player1_is_blocking <= 1'b1;
					2'b10: combat_player1_swap <= 1'b1;
					default: player1_is_blocking <= 1'b1;
					
				endcase
			end
			S_PETS_COMBAT_PLAYER1_SWAP: begin
				case(kstates)
					1: player1_current <= 0;
					2:	player1_current <= 1;
					3:	player1_current <= 2;
					4:	player1_current <= 3;
				endcase
			end
			S_PETS_COMBAT_PLAYER1_SWAP_PROCESS: begin
				player1_pet <= player1_current == 0 ? player1_pet1 :
									player1_current == 1 ? player1_pet2 :
									player1_current == 2 ? player1_pet3 : player1_pet4;
			end
			S_PETS_COMBAT_PLAYER2_TURN: begin
				if (combat_player1_swap == 1'b1)
					combat_player1_swap <= 1'b0;
				if(kstates == 'd10) begin
					if(combat_selection2 == 2'b11)
						combat_selection2 <= 2'b00;
					else
						combat_selection2 <= combat_selection2 + 2'b01;
				end
				else if (kstates == 'd9) begin
					if(combat_selection2 == 2'b00)
						combat_selection2 <= 2'b111;
					else
						combat_selection2 <= combat_selection2 - 2'b01;
				end
			end
			S_PETS_COMBAT_PLAYER2_PROCESS: begin
				case(combat_selection2)
					2'b00: begin
						case(player1_current)
							0: player1_pet1[2:0] <= (player1_pet1[2:0] - (player1_is_blocking ? ((player1_def - player2_atk) < 0) ? 0 : (player1_def - player2_atk) : player2_atk));
							1: player1_pet2[2:0] <= (player1_pet2[2:0] - (player1_is_blocking ? ((player1_def - player2_atk) < 0) ? 0 : (player1_def - player2_atk) : player2_atk));
							2:	player1_pet3[2:0] <= (player1_pet3[2:0] - (player1_is_blocking ? ((player1_def - player2_atk) < 0) ? 0 : (player1_def - player2_atk) : player2_atk));
							3:	player1_pet4[2:0] <= (player1_pet4[2:0] - (player1_is_blocking ? ((player1_def - player2_atk) < 0) ? 0 : (player1_def - player2_atk) : player2_atk));
						endcase
						combat_player2_lives <= (player2_pet1[2:0] > 0) + (player2_pet2[2:0] > 0) + (player2_pet3[2:0] > 0) + (player2_pet4[2:0] > 0);
					end
					2'b01: player2_is_blocking <= 1'b1;
					2'b10: combat_player2_swap <= 1'b1;
					default: player2_is_blocking <= 1'b1;
				endcase
			end
			S_PETS_COMBAT_PLAYER1_SWAP: begin
				case(kstates)
					5: player2_current <= 0;
					6:	player2_current <= 1;
					7:	player2_current <= 2;
					8:	player2_current <= 3;
				endcase
			end
			S_PETS_COMBAT_PLAYER2_SWAP_PROCESS: begin
				player2_pet <= player2_current == 0 ? player2_pet2 :
									player2_current == 1 ? player2_pet2 :
									player2_current == 2 ? player2_pet3 : player2_pet4;
			end
//			S_VICTORY: begin
//			
//			end
		endcase
		control_states <= next_states;
	end
endmodule

module game_datapath(key_states, clk, en, reset, cstates);
	input [4:0] key_states;
	input clk, en, reset;
	output reg [6:0] cstates;
	
	always @(posedge clk) begin
		if(reset) begin
			cstates <= 7'b0000000;
		end
		case(key_states)
			'd14, 'he: begin
				if(cstates == 7'b0000000 || cstates == 7'b0010010)
					cstates <= 7'b0000001;
			end
		endcase
	end
endmodule