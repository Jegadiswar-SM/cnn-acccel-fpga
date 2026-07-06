`timescale 1ns/1ps

module tb_cnn;
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

    always @(posedge clk) begin
        if (u_dut.fsm != 4'd0 && u_dut.fsm != 4'd6 && u_dut.fsm != 4'd7 && u_dut.fsm != 4'd8) begin
            $display("[FSM] fsm=%d rd_vld=%b rd_data=%h w0=%h mr=%b addr=%h wgt=%h img=%h",
                u_dut.fsm, u_dut.mem_rd_valid, u_dut.mem_rd_data,
                u_dut.wdata_0, u_dut.mem_req, u_dut.mem_addr,
                u_dut.wgt_base, u_dut.img_base);
        end
        if (u_dut.fsm == 4'd6) begin
            $display("[CPU] cnt=%d en=%b step_0=%d out_0=%d acc_0=%d idata=%h",
                u_dut.comp_cnt, u_dut.comp_en,
                u_dut.u_mac.u0.step, u_dut.u_mac.u0.result, u_dut.u_mac.u0.acc,
                u_dut.idata);
        end
        if (u_dut.fsm == 4'd7) begin
            $display("[STO] out=%d %d %d %d  relu=%d %d %d %d",
                u_dut.mac_out_0, u_dut.mac_out_1, u_dut.mac_out_2, u_dut.mac_out_3,
                u_dut.relu_0, u_dut.relu_1, u_dut.relu_2, u_dut.relu_3);
        end
    end

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
        $dumpfile("tb_cnn.fst");
        $dumpvars(0, tb_cnn);

        clk = 0; rst_n = 0;
        psel = 0; penable = 0; pwrite = 0;
        paddr = 0; pwdata = 0;
        mem_gnt = 0; mem_rvalid = 0; mem_rdata = 0;
        errors = 0;

        // Initialize memory
        for (int i = 0; i < 4096; i++) memory[i] = 32'h0;

        run_tests;

        if (errors == 0)
            $display("[TB] \033[1;32mALL TESTS PASSED\033[0m");
        else
            $display("[TB] \033[1;31m%d TESTS FAILED\033[0m", errors);

        #500 $finish;
    end

    always #5 clk = ~clk;

    // Memory server: combinational response
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

            // ========= TEST 1: Identity =========
            $display("[TB] === TEST 1: Identity * [2,3,4,5] ===");
            // PE0 weights: {w3=0, w2=0, w1=0, w0=1}
            // PE1 weights: {w3=0, w2=0, w1=1, w0=0}
            // PE2 weights: {w3=0, w2=1, w1=0, w0=0}
            // PE3 weights: {w3=1, w2=0, w1=0, w0=0}
            memory[0] = 32'h00000001;  // PE0: w0=1, w1=0, w2=0, w3=0
            memory[1] = 32'h00000100;  // PE1: w0=0, w1=1, w2=0, w3=0
            memory[2] = 32'h00010000;  // PE2: w0=0, w1=0, w2=1, w3=0
            memory[3] = 32'h01000000;  // PE3: w0=0, w1=0, w2=0, w3=1

            // Inputs: {i3=5, i2=4, i1=3, i0=2}
            memory[64] = 32'h05040302;

            set_config_and_run(256, 0, 2048);
            check_result(512, 32'h05040302, "identity * [2,3,4,5] = [2,3,4,5]");

            // ========= TEST 2: Scale by 2 =========
            $display("[TB] === TEST 2: Scale by 2 ===");
            memory[0] = 32'h00000002;  // w0=2
            memory[1] = 32'h00000200;  // w1=2
            memory[2] = 32'h00020000;  // w2=2
            memory[3] = 32'h02000000;  // w3=2

            set_config_and_run(256, 0, 2048);
            check_result(512, 32'h0A080604, "2I * [2,3,4,5] = [4,6,8,10]");

            // ========= TEST 3: ReLU clamp =========
            $display("[TB] === TEST 3: ReLU on negative ===");
            memory[0] = 32'h000000FF;  // w0=-1
            memory[1] = 32'h0000FF00;  // w1=-1
            memory[2] = 32'h00FF0000;  // w2=-1
            memory[3] = 32'hFF000000;  // w3=-1

            set_config_and_run(256, 0, 2048);
            check_result(512, 32'h00000000, "ReLU(-I * [2,3,4,5]) = [0,0,0,0]");
        end
    endtask

    task set_config_and_run(input [31:0] img_b, input [31:0] wgt_b, input [31:0] res_b);
        begin
            $display("[DBG] wgt_base=%d, img_base=%d, res_base=%d", wgt_b, img_b, res_b);
            $display("[DBG] memory[0..3]=%h %h %h %h", memory[0], memory[1], memory[2], memory[3]);
            $display("[DBG] memory[%d]=%h", img_b/4, memory[img_b/4]);
            apb_write(8'h10, img_b);
            apb_write(8'h14, wgt_b);
            apb_write(8'h18, res_b);
            apb_write(8'h00, 32'd1);  // Start
            wait (done_o);
            @(posedge clk);
            #1;
            $display("[DBG] mac_out: %h %h %h %h",
                u_dut.mac_out_0, u_dut.mac_out_1, u_dut.mac_out_2, u_dut.mac_out_3);
            $display("[DBG] relu:    %h %h %h %h",
                u_dut.relu_0, u_dut.relu_1, u_dut.relu_2, u_dut.relu_3);
            $display("[DBG] memory[%d]=%h", res_b/4, memory[res_b/4]);
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
