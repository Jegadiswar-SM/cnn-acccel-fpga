module line_buffer (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        en,
    input  wire [7:0]  data_in,
    input  wire [7:0]  rows,        // Number of rows in feature map
    input  wire [7:0]  cols,        // Number of cols in feature map
    output wire [7:0]  window_00, window_01, window_02,
    output wire [7:0]  window_10, window_11, window_12,
    output wire [7:0]  window_20, window_21, window_22
);
    reg [7:0] line0 [0:255];
    reg [7:0] line1 [0:255];
    reg [7:0] line2 [0:255];
    reg [7:0] r_ptr;

    wire [7:0] max_cols = cols;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_ptr <= 8'd0;
        end else if (en) begin
            if (r_ptr == max_cols - 1)
                r_ptr <= 8'd0;
            else
                r_ptr <= r_ptr + 8'd1;
        end
    end

    integer i;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 256; i = i + 1) begin
                line0[i] <= 8'd0;
                line1[i] <= 8'd0;
                line2[i] <= 8'd0;
            end
        end else if (en) begin
            line0[r_ptr] <= data_in;
            line1[r_ptr] <= line0[r_ptr];
            line2[r_ptr] <= line1[r_ptr];
        end
    end

    wire [7:0] rp0 = r_ptr;
    wire [7:0] rp1 = (r_ptr == 0) ? max_cols - 1 : r_ptr - 1;
    wire [7:0] rp2 = (r_ptr <= 1) ? max_cols - (2 - r_ptr) : r_ptr - 2;

    assign window_00 = line0[rp2];
    assign window_01 = line0[rp1];
    assign window_02 = line0[rp0];
    assign window_10 = line1[rp2];
    assign window_11 = line1[rp1];
    assign window_12 = line1[rp0];
    assign window_20 = line2[rp2];
    assign window_21 = line2[rp1];
    assign window_22 = line2[rp0];
endmodule
