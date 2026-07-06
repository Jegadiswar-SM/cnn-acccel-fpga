module weight_buffer (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         load,
    input  wire [1:0]   col_sel,       // Which column to load (0-3)
    input  wire [31:0]  wdata,         // 4 rows packed: {row3, row2, row1, row0}
    output wire [7:0]   w_out_0,       // Column output: w_out_0 = row0, w_out_1 = row1, etc.
    output wire [7:0]   w_out_1,
    output wire [7:0]   w_out_2,
    output wire [7:0]   w_out_3
);
    reg [7:0] w_buf [0:3][0:3];  // [row][col]

    integer r, c;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (r = 0; r < 4; r = r + 1)
                for (c = 0; c < 4; c = c + 1)
                    w_buf[r][c] <= 8'd0;
        end else if (load) begin
            w_buf[0][col_sel] <= wdata[7:0];
            w_buf[1][col_sel] <= wdata[15:8];
            w_buf[2][col_sel] <= wdata[23:16];
            w_buf[3][col_sel] <= wdata[31:24];
        end
    end

    // Output current column (selected by col_sel)
    assign w_out_0 = w_buf[0][col_sel];
    assign w_out_1 = w_buf[1][col_sel];
    assign w_out_2 = w_buf[2][col_sel];
    assign w_out_3 = w_buf[3][col_sel];
endmodule
