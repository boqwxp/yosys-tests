`include "defines.vh"

module top(input clk, input [`N-1:0] a, input e, r, input [$clog2(`N)-1:0] l, output [`N-1:0] z);
generate 
    genvar i;
`ifdef TEST1
    for (i = 0; i < `N; i=i+1) begin : pos_clk_no_enable_no_init_not_inferred
        shift_reg #(.depth(i+1)) sr(clk, a[i], 1'b1, /*l*/, z[i], /* state0 */);
    end
`elsif TEST2
    for (i = 0; i < `N; i=i+1) begin : pos_clk_with_enable_no_init_not_inferred
        shift_reg #(.depth(i+1)) sr(clk, a[i], e, /*l*/, z[i], /* state0 */);
    end
`elsif TEST3
    for (i = 0; i < `N; i=i+1) begin : pos_clk_with_enable_with_init_inferred
        shift_reg #(.depth(i+1), .inferred(1), .init(1)) sr(clk, a[i], e, /*l*/, z[i], /* state0 */);
    end
`elsif TEST4
    for (i = 0; i < `N; i=i+1) begin : neg_clk_no_enable_no_init_not_inferred
        shift_reg #(.depth(i+1), .neg_clk(1)) sr(clk, a[i], 1'b1, /*l*/, z[i], /* state0 */);
    end
`elsif TEST5
    for (i = 0; i < `N; i=i+1) begin : neg_clk_no_enable_no_init_inferred
        shift_reg #(.depth(i+1), .neg_clk(1), .inferred(1)) sr(clk, a[i], 1'b1, /*l*/, z[i], /* state0 */);
    end
`elsif TEST6
    for (i = 0; i < `N; i=i+1) begin : neg_clk_with_enable_with_init_inferred
        shift_reg #(.depth(i+1), .neg_clk(1), .inferred(1), .init(1)) sr(clk, a[i], e, /*l*/, z[i], /* state0 */);
    end
`elsif TEST7
    // Check that use of resets block shreg
    shift_reg #(.depth(129), .er_is_reset(1)) pos_clk_no_enable_no_init_not_inferred_with_reset(clk, a[1], r, /*l*/, z[0], /* state0 */);
    // FIXME: YosysHQ/yosys#873
    shift_reg #(.depth(129), .neg_clk(1), .inferred(1), .init(1), .er_is_reset(1)) neg_clk_no_enable_with_init_with_inferred_with_reset(clk, a[2], r, /*l*/, FIXME1 /*z[1]*/, /* state0 */);
    shift_reg #(.depth(128), .er_is_reset(1)) pos_clk_no_enable_no_init_not_inferred_with_reset_var_len(clk, a[2], r, l, z[2], /* state0 */);
    // FIXME: YosysHQ/yosys#873
    shift_reg #(.depth(129), .neg_clk(1), .inferred(1), .init(1), .er_is_reset(1)) neg_clk_no_enable_with_init_with_inferred_with_reset_var_len(clk, a[3], r, l, FIXME2 /*z[3]*/, /* state0 */);
    assign z[`N-1:4] = 'b0; // Suppress no driver warning
`elsif TEST8
    // Check multi-bit works
    (* keep *)
    shift_reg #(.depth(`N), .width(`N)) pos_clk_no_enable_no_init_not_inferred_N_width(clk, a, r, /*l*/, z, /* state0 */);
`elsif TEST9
    (* keep *)
    shift_reg #(.depth(`N), .width(`N), .neg_clk(1), .inferred(1), .init(1)) neg_clk_no_enable_with_init_with_inferred_N_width(clk, a, r, /*l*/, z, /* state0 */);
`elsif TEST10
    // FIXME: YosysHQ/yosys#873
    for (i = /*0*/1; i < `N; i=i+1) begin : pos_clk_no_enable_no_init_not_inferred_var_len
        shift_reg #(.depth(i+1), .fixed_length(0)) sr(clk, a[i], 1'b1, l[$clog2(i+1)-1:0], z[i], /* state0 */);
    end
    assign z[0] = 'b0; // Suppress no driver warning
`elsif TEST11
    // FIXME: YosysHQ/yosys#873
    for (i = /*0*/1; i < `N; i=i+1) begin : neg_clk_with_enable_with_init_inferred_var_len
        shift_reg #(.depth(i+1), .neg_clk(1), .inferred(1), .init(1), .fixed_length(0)) sr(clk, a[i], e, l[$clog2(i+1)-1:0], z[i], /* state0 */);
    end
    assign z[0] = 'b0; // Suppress no driver warning
`elsif TEST12
    for (i = 0; i < `N; i=i+1) begin : lfsr
        lfsr #(.len(i+3)) sr(clk, z[i]);
    end
`elsif TEST13
    // Check that non chain users (i.e. output port, in non flattened case) block SRLs
    shift_reg #(.depth(128), .output_index(0)) sr_fixed_length_other_users(clk, a[0], r, /*l*/, z[0], /* state0 */);
    shift_reg #(.depth(128), .neg_clk(1), .inferred(1), .init(1), .fixed_length(0), .output_index(0)) sr_var_length_other_users(clk, a[1], e, l[$clog2(128)-1:0], z[1], /* state0 */);
    assign z[`N-1:2] = 'b0; // Suppress no driver warning
`endif
endgenerate
endmodule

module shift_reg #(parameter width=1, depth=1) (input clk, input [width-1:0] a, input er, input [$clog2(depth)-1:0] l, output [width-1:0] z, output [depth-1:0] state0);
parameter inferred = 0;
parameter init = 0;
parameter neg_clk = 0;
parameter er_is_reset = 0;
parameter fixed_length = depth;
parameter output_index = -1;
generate 
    if (inferred == 0) begin
        wire [depth:0] int [width-1:0];

        genvar j;
        for (j = 0; j < width; j=j+1) begin
            wire [depth-1:0] w;
            assign int[j][0] = a[j];
            genvar i;
            for (i = 0; i < depth; i=i+1) begin
                if (neg_clk)
                    if (!er_is_reset)
                        \$_DFFE_NP_ r(.C(clk), .D(int[j][i]), .E(er), .Q(int[j][i+1]));
                    else
                        \$_DFF_NP0_ r(.C(clk), .D(int[j][i]), .R(er), .Q(int[j][i+1]));
                else
                    if (!er_is_reset)
                        \$_DFFE_PP_ r(.C(clk), .D(int[j][i]), .E(er), .Q(int[j][i+1]));
                    else
                        \$_DFF_PP0_ r(.C(clk), .D(int[j][i]), .R(er), .Q(int[j][i+1]));
            end
            if (fixed_length > 0)
                assign z[j] = int[j][fixed_length];
            else begin
                //assign z[j] = int[j][l+1];
                assign w = int[j][depth:1];
                assign z[j] = w[l];
            end
        end
        if (output_index >= 0)
            assign state0 = int[output_index][depth:1];
        else
            assign state0 = {depth{1'b0}};
    end
    else begin
        reg [depth-1:0] int [width-1:0];

        genvar j;
        for (j = 0; j < width; j=j+1) begin
            if (init) begin
                genvar i;
                for (i = 0; i < depth; i=i+1)
                    initial int[j][i] = ~((i+j) % 2);
            end

            if (depth == 1) begin
                if (neg_clk) begin
                    if (!er_is_reset) begin
                        always @(negedge clk) if (er) int[j] <= a[j];
                    end
                    else begin
                        always @(negedge clk or posedge er) if (er) int[j] <= 1'b0; else int[j] <= a[j];
                    end
                end
                else begin
                    if (!er_is_reset) begin
                        always @(posedge clk) if (er) int[j] <= a[j];
                    end
                    else begin
                        always @(posedge clk or posedge er) if (er) int[j] <= 1'b0; else int[j] <= a[j];
                    end
                end
                assign z[j] = int[j];
            end
            else begin
                if (neg_clk) begin
                    if (!er_is_reset) begin
                        always @(negedge clk) if (er) int[j] <= { int[j][depth-2:0], a[j] };
                    end
                    else begin
                        always @(negedge clk or posedge er) if (er) int[j] <= {width{1'b0}}; else int[j] <= { int[j][depth-2:0], a[j] };
                    end
                end
                else begin
                    if (!er_is_reset) begin
                        always @(posedge clk) if (er) int[j] <= { int[j][depth-2:0], a[j] };
                    end
                    else begin
                        always @(posedge clk or posedge er) if (er) int[j] <= {width{1'b0}}; else int[j] <= { int[j][depth-2:0], a[j] };
                    end
                end
                if (fixed_length > 0)
                    assign z[j] = int[j][fixed_length-1];
                else
                    assign z[j] = int[j][l];
            end
        end
        if (output_index >= 0)
            assign state0 = int[output_index];
        else
            assign state0 = {depth{1'b0}};
    end
endgenerate
endmodule

`include "lfsr.v"
