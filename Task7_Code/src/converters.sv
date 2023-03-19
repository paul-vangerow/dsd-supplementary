// Combinatorial Float to Fixed Converter
module fl_f ( input wire[31:0] fl, output wire[21:0] f ); 

  wire [21:0] shift_wire[6];

  assign shift_wire[0] = {2'b01, fl[22:3]};
  assign shift_wire[1] = fl[23] ? (shift_wire[0]) : (shift_wire[0] >> 1);
  assign shift_wire[2] = fl[24] ? (shift_wire[1]) : (shift_wire[1] >> 2);
  assign shift_wire[3] = fl[25] ? (shift_wire[2]) : (shift_wire[2] >> 4);
  assign shift_wire[4] = fl[26] ? (shift_wire[3]) : (shift_wire[3] >> 8);
  assign shift_wire[5] = fl[27] ? (shift_wire[4]) : (shift_wire[4] >> 16);

  assign f = fl[30] ? 22'h200000 : (fl[31] ? (~shift_wire[5] + 1) : shift_wire[5]);
  
endmodule 

// Floating Point Divide by 2 ( mult by 0.5 )
module fl_div_2 ( input wire[31:0] in_fl, output wire[31:0] out_fl ); 

  assign out_fl = { in_fl[31], in_fl[30:23] - 8'b1, in_fl[22:0] };

endmodule

// Combinatorial Fixed to Float converter
module f_fl (input wire[21:0] f, output wire[31:0] fl);
  
  wire [24:0] mant_in = (f[21] ? (~f + 1) : f) << 3; // Move Decimal Place to Correct Place <-- 25 bit value.. Need to check bits [23:3] for ones
  wire [24:0] shift_wire[22];
  wire [7:0]  exp [22];
  wire        disable_wire[22];
  wire [24:0] out_mant;

  genvar i;
  generate
    for (i = 0; i <= 20; i=i+1) begin
      if (i == 0) begin
        assign shift_wire[0] = 0;
        assign exp[0] = 0;
        assign disable_wire[0] = 0;
      end
      assign shift_wire[i+1] = (~disable_wire[i] && mant_in[23-i]) ? (mant_in << i) : shift_wire[i]; // If not disabled + theres a 1. shift_wire[i] is value
      assign exp[i+1] = (~disable_wire[i] && mant_in[23-i]) ? i : exp[i];
      assign disable_wire[i+1] = mant_in[23-i] | disable_wire[i];
    end
  endgenerate

  assign fl = (f == 22'h200000) ? (32'hC0000000) : { f[21], (8'd127 ^ exp[21]), shift_wire[21][22:0] };

endmodule