module mac_array (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         clr,
    input  wire         load_w,
    input  wire         en,
    input  wire [31:0]  wdata_0,
    input  wire [31:0]  wdata_1,
    input  wire [31:0]  wdata_2,
    input  wire [31:0]  wdata_3,
    input  wire [31:0]  idata,
    output wire [31:0]  out_0,
    output wire [31:0]  out_1,
    output wire [31:0]  out_2,
    output wire [31:0]  out_3
);
    pe u0 (
        .clk(clk), .rst_n(rst_n), .clr(clr),
        .load_w(load_w), .en(en),
        .wdata(wdata_0), .idata(idata),
        .result(out_0)
    );
    pe u1 (
        .clk(clk), .rst_n(rst_n), .clr(clr),
        .load_w(load_w), .en(en),
        .wdata(wdata_1), .idata(idata),
        .result(out_1)
    );
    pe u2 (
        .clk(clk), .rst_n(rst_n), .clr(clr),
        .load_w(load_w), .en(en),
        .wdata(wdata_2), .idata(idata),
        .result(out_2)
    );
    pe u3 (
        .clk(clk), .rst_n(rst_n), .clr(clr),
        .load_w(load_w), .en(en),
        .wdata(wdata_3), .idata(idata),
        .result(out_3)
    );
endmodule
