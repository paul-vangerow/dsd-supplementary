module cordic(clk, dataa, result);

	input clk;
	input[31:0] dataa;
	output signed [31:0] result;
	reg signed [31:0] x,y,z,xshift,yshift;
	
	reg signed [31:0] result;
	wire[7:0] dataa;
	wire signed [31:0] arctan_table[39:0];
	wire signed [31:0] k_table[39:0];
	integer i;	
	
	assign arctan_table[0] = 32'b00110010010000111111011011000000;
	assign k_table[0] = 32'b00110010010000111111011011000000;
	assign arctan_table[1] = 32'b00011101101011000110011100000000;
	assign k_table[1] = 32'b00011101101011000110011100000000;
	assign arctan_table[2] = 32'b00001111101011011011101100000000;
	assign k_table[2] = 32'b00001111101011011011101100000000;
	assign arctan_table[3] = 32'b00000111111101010110111010101000;
	assign k_table[3] = 32'b00000111111101010110111010101000;
	assign arctan_table[4] = 32'b00000011111111101010101101111000;
	assign k_table[4] = 32'b00000011111111101010101101111000;
	assign arctan_table[5] = 32'b00000001111111111101010101011100;
	assign k_table[5] = 32'b00000001111111111101010101011100;
	assign arctan_table[6] = 32'b00000000111111111111101010101011;
	assign k_table[6] = 32'b00000000111111111111101010101011;
	assign arctan_table[7] = 32'b00000000011111111111111101010101;
	assign k_table[7] = 32'b00000000011111111111111101010101;
	assign arctan_table[8] = 32'b00000000001111111111111111101010;
	assign k_table[8] = 32'b00000000001111111111111111101010;
	assign arctan_table[9] = 32'b00000000000111111111111111111101;
	assign k_table[9] = 32'b00000000000111111111111111111101;
	assign arctan_table[10] = 32'b00000000000011111111111111111111;
	assign k_table[10] = 32'b00000000000011111111111111111111;
	assign arctan_table[11] = 32'b00000000000001111111111111111111;
	assign k_table[11] = 32'b00000000000001111111111111111111;
	assign arctan_table[12] = 32'b00000000000001000000000000000000;
	assign k_table[12] = 32'b00000000000001000000000000000000;
	assign arctan_table[13] = 32'b00000000000000100000000000000000;
	assign k_table[13] = 32'b00000000000000100000000000000000;
	assign arctan_table[14] = 32'b00000000000000010000000000000000;
	assign k_table[14] = 32'b00000000000000010000000000000000;
	assign arctan_table[15] = 32'b00000000000000001000000000000000;
	assign k_table[15] = 32'b00000000000000001000000000000000;
	assign arctan_table[16] = 32'b00000000000000000100000000000000;
	assign k_table[16] = 32'b00000000000000000100000000000000;
	assign arctan_table[17] = 32'b00000000000000000010000000000000;
	assign k_table[17] = 32'b00000000000000000010000000000000;
	assign arctan_table[18] = 32'b00000000000000000001000000000000;
	assign k_table[18] = 32'b00000000000000000001000000000000;
	assign arctan_table[19] = 32'b00000000000000000000100000000000;
	assign k_table[19] = 32'b00000000000000000000100000000000;
	
	
	function signed [31:0] inv_sign;
		input signed [31:0] a;
		input en;
		begin
			if (en == 1'b1) inv_sign = ~a + 1;
			else inv_sign = a;
		end
	endfunction
			
	function[95:0] cordic_stage;
		input[7:0] i;
		input signed [31:0] thetai;
		input signed [31:0] xin, yin, zin, xshift, yshift;
		reg signed [31:0] xout, yout, zout;
		
		begin
//			yout = yin + inv_sign(xin >>> i , zin[31]);
//			xout = xin - inv_sign(yin >>> i , zin[31]);
			xout = xin - inv_sign(yshift , zin[31]);
			yout = yin + inv_sign(xshift , zin[31]);
			zout = zin - inv_sign(thetai, zin[31]);
			
			cordic_stage = {xout, yout, zout};
		end
	endfunction
	
	
	parameter n = 20;
	
	initial x = 32'b00100110110111010011101101010011;
	initial y = 32'b0;
	initial z = 32'b00100000000000000000000000000000;
	
	initial xshift = 32'b00100110110111010011101101010011;
	initial yshift = 32'b0;

		
	reg[7:0] counter;
	initial counter = 0;
	reg en;
	
	always @ (dataa) begin
		en = 1'b1;
	end
	
	always @ (posedge clk, negedge clk) begin
		if (counter < n && en) begin
			{x,y,z} <= cordic_stage(counter, arctan_table[counter], x, y, z, x >>> counter, y >>> counter);
			counter <= counter + 1'b1;
		end
		else begin
			result <= x;
			en = 1'b0;
			counter = 8'b0;
		end
	end

endmodule