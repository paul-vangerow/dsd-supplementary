module cordic_stage_basic #(
    parameter I       =     22'h0,
    parameter THETA_I =     22'h2243f
) (
    input  wire[21:0] x_i, 
    input  wire[21:0] y_i, 
    input  wire[21:0] z_i,
    output wire[21:0] xi_p, 
    output wire[21:0] yi_p, 
    output wire[21:0] zi_p
);

// Single Cordic Stage

assign xi_p = x_i - $signed( z_i[21] != 0 ? ( ~( $signed(y_i) >>> I ) + 1) : ( $signed(y_i) >>> I ) );
assign yi_p = y_i + ( z_i[21] != 0 ? ( -($signed(x_i) >>> I )) : ( $signed(x_i) >>> I ) );
assign zi_p = z_i - $signed( z_i[21] != 0 ? ( -($signed(THETA_I)) ) : ( $signed(THETA_I) ) );

endmodule

module cordic_stage_basic_l #(
    parameter I       =     22'h0,
    parameter THETA_I0 =     22'h2243f,
    parameter THETA_I1 =     22'h2243f,
    parameter THETA_I2 =     22'h2243f,
    parameter THETA_I3 =     22'h2243f
) (
    input  wire[21:0] x_i, 
    input  wire[21:0] y_i, 
    input  wire[21:0] z_i,
    input  wire[2:0] count,
    output wire[21:0] xi_p, 
    output wire[21:0] yi_p, 
    output wire[21:0] zi_p
);

// Single Cordic Stage

wire [21:0] I_VAL;
wire [21:0] THETA_I;

assign I_VAL = (count > 1) ? ((count == 2) ? (I+8) : (I+12)) : ((count == 0) ? (I) : (I+4));
assign THETA_I = (count > 1) ? ((count == 2) ? (THETA_I2) : (THETA_I3)) : ((count == 0) ? (THETA_I0) : (THETA_I1));

assign xi_p = x_i + ~( z_i[21] != 0 ? ( ~( y_i >> I_VAL ) + 1) : ( y_i >> I_VAL ) ) + 1;
assign yi_p = y_i + ( z_i[21] != 0 ? ( ~( x_i >> I_VAL ) + 1) : ( x_i >> I_VAL ) );
assign zi_p = z_i + ~( z_i[21] != 0 ? ( ~( THETA_I ) + 1) : ( THETA_I ) ) + 1;

endmodule

// Multi Cordic with CLK
module cordic_stage_multi_stage_latency #( 
    parameter NUM_STAGES = 22'h1
) (
    input  wire[31:0] float_in,
    input  wire       clk,
    output wire[31:0] float_out
);
    parameter [(20*22)-1:0] atan_table = {22'h2, 22'h4, 22'h8, 22'h10, 22'h20, 22'h40, 22'h80, 22'h100, 22'h1ff, 22'h3ff, 22'h7ff, 
                                          22'hfff, 22'h1fff, 22'h3ffe, 22'h7ff5, 22'hffaa, 22'h1fd5b, 22'h3eb6e, 22'h76b19, 22'hc90fd};

    parameter [(20*22)-1:0] k_table = {22'h9b74e, 22'h9b74e, 22'h9b74e, 22'h9b74e, 22'h9b74e, 22'h9b74e, 22'h9b74e, 22'h9b74e, 22'h9b74e,
                                       22'h9b74e, 22'h9b74f, 22'h9b750, 22'h9b755, 22'h9b768, 22'h9b7b6, 22'h9b8ed, 22'h9bdc8, 22'h9d130,
                                       22'ha1e89, 22'hb504f};

    // Converter Wires
    wire [21:0] fixed_in;
    wire [21:0] fixed_out;

    // Stage Wires
    wire [21:0] x_in[3:0];
    wire [21:0] y_in[3:0];
    wire [21:0] z_in[3:0];

    wire [21:0] x_out[3:0];
    wire [21:0] y_out[3:0];
    wire [21:0] z_out[3:0];

    // Decoder Output Wire
    wire [31:0] out_wire;

    // Pipeline Registers
    reg [21:0] pipeline_reg_x;
    reg [21:0] pipeline_reg_y;
    reg [21:0] pipeline_reg_z;

    // Output Register
    reg [31:0] out_reg;

    // Counter Register
    reg [2:0] counter;

    initial begin
        counter = 0;
        out_reg = 22'hxxxxx;
    end

    integer j;
    always @ (posedge clk) begin
        // Clocked Logic
        pipeline_reg_x <= x_out[2];
        pipeline_reg_y <= y_out[2];
        pipeline_reg_z <= z_out[2];

        counter <= (counter == 4) ? 0 : counter + 1;
        
        if (counter == 4) begin
            out_reg <= out_wire;
        end
    end

    wire[31:0] tmp;
    assign tmp = counter << 2;

    // Wire Connections For CORDIC
    assign x_in[3] = pipeline_reg_x;
    assign x_in[0] = (counter == 0) ? k_table[(NUM_STAGES-1)*22+:22] : x_out[3];
    assign x_in[1] = x_out[0];
    assign x_in[2] = (counter == 4) ? 22'hx : x_out[1];

    assign y_in[3] = pipeline_reg_y;
    assign y_in[0] = (counter == 0) ? 22'h0 : y_out[3];
    assign y_in[1] = y_out[0];
    assign y_in[2] = (counter == 4) ? 22'hx : y_out[1];

    assign z_in[3] = pipeline_reg_z;
    assign z_in[0] = (counter == 0) ? fixed_in : z_out[3];
    assign z_in[1] = z_out[0];
    assign z_in[2] = (counter == 4) ? 22'hx : z_out[1];

    assign fixed_out = (counter == 4) ? x_out[1] : 22'hx;
    assign float_out = out_reg;

    // Cordic Stages
    genvar n;
    generate 
        for (n = 0; n < 4; n=n+1) begin : LatencyCordicStages
            cordic_stage_basic_l #(
                .I          (n), 
                .THETA_I0    (atan_table[(n)*22+:22]), // 0 1 2 3
                .THETA_I1    (atan_table[(n+4)*22+:22]), // 4 5 6 7
                .THETA_I2    (atan_table[(n+8)*22+:22]), // 8 9 10 11
                .THETA_I3    (atan_table[(n+12)*22+:22]) // 12 13 14 15 
            ) istage ( 
                .x_i        (x_in[n]),
                .y_i        (y_in[n]),
                .z_i        (z_in[n]),
                .xi_p       (x_out[n]),
                .yi_p       (y_out[n]),
                .zi_p       (z_out[n]),
                .count      (counter)
            ); 
        end
    endgenerate

    // Type Converters
    fl_f converter1( .fl(float_in), .f(fixed_in));
    f_fl converter2( .f(fixed_out), .fl(out_wire));

endmodule

module cordic_stage_multi_stage_throughput #( 
    parameter NUM_STAGES = 22'h1
) (
    input  wire[31:0] float_in,
    input  wire       clk,
    output wire[31:0] float_out
);
    parameter [(20*22)-1:0] atan_table = {22'h2, 22'h4, 22'h8,
                                           22'h10, 22'h20, 22'h40,
                                           22'h80, 22'h100, 22'h1ff,
                                           22'h3ff, 22'h7ff, 22'hfff,
                                           22'h1fff, 22'h3ffe, 22'h7ff5,
                                           22'hffaa, 22'h1fd5b, 22'h3eb6e,
                                           22'h76b19, 22'hc90fd};

    parameter [(20*22)-1:0] k_table = {22'h9b74e, 22'h9b74e, 22'h9b74e,
                                       22'h9b74e, 22'h9b74e, 22'h9b74e,
                                       22'h9b74e, 22'h9b74e, 22'h9b74e,
                                       22'h9b74e, 22'h9b74f, 22'h9b750,
                                       22'h9b755, 22'h9b768, 22'h9b7b6,
                                       22'h9b8ed, 22'h9bdc8, 22'h9d130,
                                       22'ha1e89, 22'hb504f};

    wire [21:0] fixed_in;
    wire [21:0] fixed_out;

    wire  [21:0] x_in[0:NUM_STAGES];
    wire  [21:0] y_in[0:NUM_STAGES];
    wire  [21:0] z_in[0:NUM_STAGES];

    wire  [21:0] x_out[0:NUM_STAGES-1];
    wire  [21:0] y_out[0:NUM_STAGES-1];
    wire  [21:0] z_out[0:NUM_STAGES-1];

    wire  [31:0] out_wire;

    reg  [21:0] pipeline_reg_x[0:4];
    reg  [21:0] pipeline_reg_y[0:4];
    reg  [21:0] pipeline_reg_z[0:4];

    reg  [31:0] out_reg;

    assign x_in[0] = k_table[(NUM_STAGES-1)*22+:22];
    assign y_in[0] = 0;
    assign z_in[0] = fixed_in;

    assign float_out = out_reg;

    // always @ (*) begin
    //     $display("I_VAL: %0d xi_p: %0h x_i: %0h THETA_I: %0h", I, xi_p, x_i, THETA_I);
    // end

    integer j;
    always @ (posedge clk) begin
			
        for (j = 0; j < NUM_STAGES; j=j+1) begin
            if ( j % 4 == 2 ) begin
                // $display("J: %0d, J/4: %0d, x_out[j] = %0h", j, (j/4), x_out[j]);
                pipeline_reg_x[ j / 4] <= x_out[j];
                pipeline_reg_y[ j / 4] <= y_out[j];
                pipeline_reg_z[ j / 4] <= z_out[j];
            end
        end
        
        out_reg <= out_wire;

    end

    assign fixed_out = x_in[NUM_STAGES];

    // Cordic Stages
    genvar n;
    generate 
        for (n = 0; n < NUM_STAGES; n=n+1) begin :name2
            cordic_stage_basic #(
                .I          (n), 
                .THETA_I    (atan_table[n*22+:22])
            ) istage ( 
                .x_i        (x_in[n]),
                .y_i        (y_in[n]),
                .z_i        (z_in[n]),
                .xi_p       (x_out[n]),
                .yi_p       (y_out[n]),
                .zi_p       (z_out[n])
            ); 

            if ( n % 4 == 2 ) begin
                assign x_in[n+1] = pipeline_reg_x[ n / 4];
                assign y_in[n+1] = pipeline_reg_y[ n / 4];
                assign z_in[n+1] = pipeline_reg_z[ n / 4];
            end else begin
                assign x_in[n+1] = x_out[n];
                assign y_in[n+1] = y_out[n];
                assign z_in[n+1] = z_out[n];
            end
        end
    endgenerate

    // Type Converters
    fl_f converter1( .fl(float_in), .f(fixed_in));
    f_fl converter2( .f(fixed_out), .fl(out_wire));

endmodule

module cordic_stage(clk, dataa, result);
//
	input clk;
	input[31:0] dataa;
	output signed [31:0] result;
endmodule