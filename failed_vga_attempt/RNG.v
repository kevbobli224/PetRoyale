// Linear Feedback Shift Registers

module RNG(clk, en, reset, data_out);
	input clk, en, reset;
	
	// 8-bit integer as output
	output reg [7:0] data_out;
	
	wire fb;
	assign fb = data_out[7]^data_out[0];
	
	always @(posedge clk) begin
		if (reset == 1'b1)
			data_out[7:0] <= 8'hf;
		else if (en) begin
			data_out[0] <= fb;
			data_out[1] <= data_out[0];
			data_out[2] <= data_out[1];
			data_out[3] <= data_out[2];
			data_out[4] <= data_out[3];
			data_out[5] <= data_out[4];
			data_out[6] <= data_out[5];
			data_out[7] <= data_out[6];
		end
	end
endmodule

module RNGOnce(data_out);
	output [7:0] data_out;
	
	wire fb;
	assign fb = data_out[7]^data_out[0];
	assign data_out[0] = fb;
	assign data_out[1] = data_out[0];
	assign data_out[2] = data_out[1];
	assign data_out[3] = data_out[2];
	assign data_out[4] = data_out[3];
	assign data_out[5] = data_out[4];
	assign data_out[6] = data_out[5];
	assign data_out[7] = data_out[6];
	
endmodule