// Code your testbench here
// or browse Examples

module main_testbench;
  
  wire[31:0] in;
  wire[31:0] out;

  wire[21:0] inter;

  reg[31:0] input_val;
  reg clk;

  assign in = input_val;
  
  initial begin 
    clk = 0;
    input_val = 32'h3f400000;
    repeat(20) begin
      #10;
      clk = ~clk;
    end
  end
  
  always @ (posedge clk) begin

    // $display("%0d --- in == %0h, out = %0h", $time, in, out);
  end 

  cordic_stage_multi_stage_latency #(
    .NUM_STAGES(16)
  ) dut (
    .float_in(in),
    .float_out(out),
    .clk(clk)
  );
  
endmodule 
  
