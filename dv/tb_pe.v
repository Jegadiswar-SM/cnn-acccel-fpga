`timescale 1ns/1ps

module tb_pe;
    reg        clk, rst_n, clr, load_w, en;
    reg [31:0] wdata, idata;
    wire [31:0] result;

    pe u_pe (.*);

    initial begin
        $dumpfile("tb_pe.fst");
        $dumpvars(0, tb_pe);

        clk = 0; rst_n = 0; clr = 0; load_w = 0; en = 0;
        wdata = 0; idata = 0;

        #100 rst_n = 1;
        #20;

        // Load weights: wr = [0, 0, 0, 2]
        @(posedge clk); load_w = 1; wdata = 32'h00000002;
        @(posedge clk); load_w = 0;

        // Load inputs: idata = [5, 4, 3, 2]
        @(posedge clk); idata = 32'h05040302;

        // Compute 4 cycles
        @(posedge clk); en = 1;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk); en = 0;

        #10;

        $display("[PE] result = %h (expected %h = 2*2=4)", result, 32'd4);

        #500 $finish;
    end

    always #5 clk = ~clk;

    always @(posedge clk) begin
        $display("[PE] step=%d acc=%d result=%d ld=%b en=%b",
            u_pe.step, u_pe.acc, result, load_w, en);
    end
endmodule
