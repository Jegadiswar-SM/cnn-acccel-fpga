module systolic_array (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         load_w,
    input  wire [7:0]   w_in_0, w_in_1, w_in_2, w_in_3,
    input  wire [7:0]   data_in_0, data_in_1, data_in_2, data_in_3,
    output wire [31:0]  acc_out_0, acc_out_1, acc_out_2, acc_out_3
);
    wire [7:0]  w_0_0, w_0_1, w_0_2, w_0_3;
    wire [7:0]  w_1_0, w_1_1, w_1_2, w_1_3;
    wire [7:0]  w_2_0, w_2_1, w_2_2, w_2_3;
    wire [7:0]  w_3_0, w_3_1, w_3_2, w_3_3;

    wire [7:0]  d_0_0, d_0_1, d_0_2, d_0_3;
    wire [7:0]  d_1_0, d_1_1, d_1_2, d_1_3;
    wire [7:0]  d_2_0, d_2_1, d_2_2, d_2_3;
    wire [7:0]  d_3_0, d_3_1, d_3_2, d_3_3;

    wire [31:0] a_0_0, a_0_1, a_0_2, a_0_3;
    wire [31:0] a_1_0, a_1_1, a_1_2, a_1_3;
    wire [31:0] a_2_0, a_2_1, a_2_2, a_2_3;
    wire [31:0] a_3_0, a_3_1, a_3_2, a_3_3;

    pe pe_0_0 (.*, .w_in(w_in_0),     .data_in(data_in_0), .acc_in(32'd0),  .w_out(w_0_0), .data_out(d_0_0), .acc_out(a_0_0));
    pe pe_0_1 (.*, .w_in(w_0_0),      .data_in(data_in_1), .acc_in(a_0_0),  .w_out(w_0_1), .data_out(d_0_1), .acc_out(a_0_1));
    pe pe_0_2 (.*, .w_in(w_0_1),      .data_in(data_in_2), .acc_in(a_0_1),  .w_out(w_0_2), .data_out(d_0_2), .acc_out(a_0_2));
    pe pe_0_3 (.*, .w_in(w_0_2),      .data_in(data_in_3), .acc_in(a_0_2),  .w_out(w_0_3), .data_out(d_0_3), .acc_out(a_0_3));

    pe pe_1_0 (.*, .w_in(w_in_1),     .data_in(d_0_0),     .acc_in(32'd0),  .w_out(w_1_0), .data_out(d_1_0), .acc_out(a_1_0));
    pe pe_1_1 (.*, .w_in(w_1_0),      .data_in(d_0_1),     .acc_in(a_1_0),  .w_out(w_1_1), .data_out(d_1_1), .acc_out(a_1_1));
    pe pe_1_2 (.*, .w_in(w_1_1),      .data_in(d_0_2),     .acc_in(a_1_1),  .w_out(w_1_2), .data_out(d_1_2), .acc_out(a_1_2));
    pe pe_1_3 (.*, .w_in(w_1_2),      .data_in(d_0_3),     .acc_in(a_1_2),  .w_out(w_1_3), .data_out(d_1_3), .acc_out(a_1_3));

    pe pe_2_0 (.*, .w_in(w_in_2),     .data_in(d_1_0),     .acc_in(32'd0),  .w_out(w_2_0), .data_out(d_2_0), .acc_out(a_2_0));
    pe pe_2_1 (.*, .w_in(w_2_0),      .data_in(d_1_1),     .acc_in(a_2_0),  .w_out(w_2_1), .data_out(d_2_1), .acc_out(a_2_1));
    pe pe_2_2 (.*, .w_in(w_2_1),      .data_in(d_1_2),     .acc_in(a_2_1),  .w_out(w_2_2), .data_out(d_2_2), .acc_out(a_2_2));
    pe pe_2_3 (.*, .w_in(w_2_2),      .data_in(d_1_3),     .acc_in(a_2_2),  .w_out(w_2_3), .data_out(d_2_3), .acc_out(a_2_3));

    pe pe_3_0 (.*, .w_in(w_in_3),     .data_in(d_2_0),     .acc_in(32'd0),  .w_out(w_3_0), .data_out(d_3_0), .acc_out(a_3_0));
    pe pe_3_1 (.*, .w_in(w_3_0),      .data_in(d_2_1),     .acc_in(a_3_0),  .w_out(w_3_1), .data_out(d_3_1), .acc_out(a_3_1));
    pe pe_3_2 (.*, .w_in(w_3_1),      .data_in(d_2_2),     .acc_in(a_3_1),  .w_out(w_3_2), .data_out(d_3_2), .acc_out(a_3_2));
    pe pe_3_3 (.*, .w_in(w_3_2),      .data_in(d_2_3),     .acc_in(a_3_2),  .w_out(w_3_3), .data_out(d_3_3), .acc_out(a_3_3));

    assign acc_out_0 = a_0_3;
    assign acc_out_1 = a_1_3;
    assign acc_out_2 = a_2_3;
    assign acc_out_3 = a_3_3;
endmodule
