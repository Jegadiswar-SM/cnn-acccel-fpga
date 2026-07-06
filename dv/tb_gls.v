`timescale 1ns/1ps

module tb_gls;
    reg         clk, rst_n;
    reg         psel, penable, pwrite;
    reg  [31:0] paddr, pwdata;
    wire [31:0] prdata;
    wire        pready;

    reg         mem_gnt, mem_rvalid;
    reg  [31:0] mem_rdata;
    wire        mem_req, mem_we;
    wire [31:0] mem_addr, mem_wdata;

    wire        done_o, busy_o;
    wire [3:0]  fsm_state_o;

    cnn_top u_dut (
        .clk(clk), .rst_n(rst_n),
        .psel(psel), .penable(penable), .pwrite(pwrite),
        .paddr(paddr), .pwdata(pwdata),
        .prdata(prdata), .pready(pready),
        .mem_req(mem_req), .mem_gnt(mem_gnt),
        .mem_addr(mem_addr), .mem_we(mem_we),
        .mem_wdata(mem_wdata),
        .mem_rvalid(mem_rvalid), .mem_rdata(mem_rdata),
        .done_o(done_o), .busy_o(busy_o), .fsm_state_o(fsm_state_o)
    );

    reg [31:0] memory [0:4095];
    integer errors;

    initial begin
        $dumpfile("tb_cnn_gls.fst");
        $dumpvars(0, tb_gls);

        clk = 0; rst_n = 0;
        psel = 0; penable = 0; pwrite = 0;
        paddr = 0; pwdata = 0;
        mem_gnt = 0; mem_rvalid = 0; mem_rdata = 0;
        errors = 0;

        for (int i = 0; i < 4096; i++) memory[i] = 32'h0;

        run_tests;

        if (errors == 0)
            $display("[TB] \033[1;32mALL TESTS PASSED\033[0m");
        else
            $display("[TB] \033[1;31m%d TESTS FAILED\033[0m", errors);

        #500 $finish;
    end

    always #5 clk = ~clk;

    always @(posedge clk) begin
        mem_gnt    <= 1'b0;
        mem_rvalid <= 1'b0;
        if (mem_req) begin
            mem_gnt <= 1'b1;
            if (!mem_we) begin
                mem_rvalid <= 1'b1;
                mem_rdata  <= memory[mem_addr[13:2]];
            end else begin
                memory[mem_addr[13:2]] <= mem_wdata;
            end
        end
    end

    task apb_write(input [7:0] addr, input [31:0] data);
        begin
            @(posedge clk);
            psel    <= 1'b1; pwrite <= 1'b1;
            paddr   <= {24'd0, addr}; pwdata <= data;
            @(posedge clk); penable <= 1'b1;
            @(posedge clk); psel <= 1'b0; penable <= 1'b0; pwrite <= 1'b0;
            @(posedge clk);
        end
    endtask

    task run_tests;
        begin
            #100 rst_n = 1;
            #200;

            $display("[TB] === TEST 1: Identity * [2,3,4,5] ===");
            memory[0] = 32'h00000001;
            memory[1] = 32'h00000100;
            memory[2] = 32'h00010000;
            memory[3] = 32'h01000000;
            memory[64] = 32'h05040302;

            set_config_and_run(256, 0, 2048);
            check_result(512, 32'h05040302, "identity * [2,3,4,5] = [2,3,4,5]");

            $display("[TB] === TEST 2: Scale by 2 ===");
            memory[0] = 32'h00000002;
            memory[1] = 32'h00000200;
            memory[2] = 32'h00020000;
            memory[3] = 32'h02000000;

            set_config_and_run(256, 0, 2048);
            check_result(512, 32'h0A080604, "2I * [2,3,4,5] = [4,6,8,10]");

            $display("[TB] === TEST 3: ReLU on negative ===");
            memory[0] = 32'h000000FF;
            memory[1] = 32'h0000FF00;
            memory[2] = 32'h00FF0000;
            memory[3] = 32'hFF000000;

            set_config_and_run(256, 0, 2048);
            check_result(512, 32'h00000000, "ReLU(-I * [2,3,4,5]) = [0,0,0,0]");
        end
    endtask

    task set_config_and_run(input [31:0] img_b, input [31:0] wgt_b, input [31:0] res_b);
        begin
            apb_write(8'h10, img_b);
            apb_write(8'h14, wgt_b);
            apb_write(8'h18, res_b);
            apb_write(8'h00, 32'd1);
            wait (done_o);
            @(posedge clk);
            #1;
        end
    endtask

    task check_result(input [31:0] addr, input [31:0] expected, input [255:0] desc);
        begin
            if (memory[addr] == expected) begin
                $display("[TB]   \033[1;32mPASSED\033[0m  (got 0x%08h)", memory[addr]);
            end else begin
                errors = errors + 1;
                $display("[TB]   \033[1;31mFAILED\033[0m  got 0x%08h, expected 0x%08h  (%s)",
                         memory[addr], expected, desc);
            end
        end
    endtask
endmodule
