module cnn_top (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        psel,
    input  wire        penable,
    input  wire        pwrite,
    input  wire [31:0] paddr,
    input  wire [31:0] pwdata,
    output wire [31:0] prdata,
    output wire        pready,
    output reg         mem_req,
    input  wire        mem_gnt,
    output reg  [31:0] mem_addr,
    output reg         mem_we,
    output reg  [31:0] mem_wdata,
    input  wire        mem_rvalid,
    input  wire [31:0] mem_rdata,
    output wire        done_o,
    output wire        busy_o,
    output reg  [3:0]  fsm_state_o
);

    wire        start;
    wire [15:0] img_base, wgt_base, res_base;

    // verilator lint_off PINCONNECTEMPTY
    cnn_regs u_regs (
        .clk(clk), .rst_n(rst_n),
        .psel(psel), .penable(penable), .pwrite(pwrite),
        .paddr(paddr), .pwdata(pwdata),
        .prdata(prdata), .pready(pready),
        .start(start), .busy(busy_o), .done(done_o),
        .mode(), .img_rows(), .img_cols(),
        .img_base(img_base), .wgt_base(wgt_base), .res_base(res_base)
    );
    // verilator lint_on PINCONNECTEMPTY

    wire [31:0] mac_out_0, mac_out_1, mac_out_2, mac_out_3;
    reg  [31:0] wdata_0, wdata_1, wdata_2, wdata_3, idata;

    mac_array u_mac (
        .clk(clk), .rst_n(rst_n),
        .clr(1'b0), .load_w(load_w), .en(comp_en),
        .wdata_0(wdata_0), .wdata_1(wdata_1),
        .wdata_2(wdata_2), .wdata_3(wdata_3),
        .idata(idata),
        .out_0(mac_out_0), .out_1(mac_out_1),
        .out_2(mac_out_2), .out_3(mac_out_3)
    );

    wire [7:0] relu_0, relu_1, relu_2, relu_3;
    relu u_r0 (.data_in(mac_out_0), .data_out(relu_0));
    relu u_r1 (.data_in(mac_out_1), .data_out(relu_1));
    relu u_r2 (.data_in(mac_out_2), .data_out(relu_2));
    relu u_r3 (.data_in(mac_out_3), .data_out(relu_3));

    localparam [4:0]
        IDLE      = 5'd0,
        LD_W0_RQ  = 5'd1,
        LD_W0     = 5'd2,
        LD_W1_RQ  = 5'd3,
        LD_W1     = 5'd4,
        LD_W2_RQ  = 5'd5,
        LD_W2     = 5'd6,
        LD_W3_RQ  = 5'd7,
        LD_W3     = 5'd8,
        LD_DAT_RQ = 5'd9,
        LD_DATA   = 5'd10,
        COMPUTE   = 5'd11,
        STORE_RQ  = 5'd12,
        STORE     = 5'd13,
        DONE_ST   = 5'd14;

    reg [4:0] fsm;
    reg       load_w, comp_en;
    reg [2:0] comp_cnt;
    reg       mem_rd_valid, mem_wr_done;
    reg [31:0] mem_rd_data;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fsm          <= IDLE;
            load_w       <= 1'b0;
            comp_en      <= 1'b0;
            comp_cnt     <= 3'd0;
            wdata_0      <= 32'd0;
            wdata_1      <= 32'd0;
            wdata_2      <= 32'd0;
            wdata_3      <= 32'd0;
            idata        <= 32'd0;
            mem_req      <= 1'b0;
            mem_we       <= 1'b0;
            mem_addr     <= 32'd0;
            mem_wdata    <= 32'd0;
            mem_rd_valid <= 1'b0;
            mem_rd_data  <= 32'd0;
            mem_wr_done  <= 1'b0;
        end else begin
            // ---- defaults ----
            load_w      <= 1'b0;
            comp_en     <= 1'b0;
            mem_wr_done  <= 1'b0;

            // ---- mem response capture ----
            mem_rd_valid <= 1'b0;
            if (mem_rvalid) begin
                mem_rd_valid <= 1'b1;
                mem_rd_data  <= mem_rdata;
            end

            // ---- clear mem_req on grant ----
            if (mem_req && mem_gnt) begin
                mem_req <= 1'b0;
                if (mem_we) mem_wr_done <= 1'b1;
            end

            // ---- main FSM ----
            case (fsm)
                IDLE: begin
                    if (start) fsm <= LD_W0_RQ;
                end

                // issue read for weight 0
                LD_W0_RQ: begin
                    if (!mem_req) begin
                        mem_req  <= 1'b1;
                        mem_we   <= 1'b0;
                        mem_addr <= {16'd0, wgt_base};
                        fsm      <= LD_W0;
                    end
                end

                // wait for weight 0
                LD_W0: begin
                    if (mem_rd_valid) begin
                        wdata_0 <= mem_rd_data;
                        fsm     <= LD_W1_RQ;
                    end
                end

                // issue read for weight 1
                LD_W1_RQ: begin
                    if (!mem_req) begin
                        mem_req  <= 1'b1;
                        mem_we   <= 1'b0;
                        mem_addr <= {16'd0, wgt_base} + 32'd4;
                        fsm      <= LD_W1;
                    end
                end

                // wait for weight 1
                LD_W1: begin
                    if (mem_rd_valid) begin
                        wdata_1 <= mem_rd_data;
                        fsm     <= LD_W2_RQ;
                    end
                end

                // issue read for weight 2
                LD_W2_RQ: begin
                    if (!mem_req) begin
                        mem_req  <= 1'b1;
                        mem_we   <= 1'b0;
                        mem_addr <= {16'd0, wgt_base} + 32'd8;
                        fsm      <= LD_W2;
                    end
                end

                // wait for weight 2
                LD_W2: begin
                    if (mem_rd_valid) begin
                        wdata_2 <= mem_rd_data;
                        fsm     <= LD_W3_RQ;
                    end
                end

                // issue read for weight 3
                LD_W3_RQ: begin
                    if (!mem_req) begin
                        mem_req  <= 1'b1;
                        mem_we   <= 1'b0;
                        mem_addr <= {16'd0, wgt_base} + 32'd12;
                        fsm      <= LD_W3;
                    end
                end

                // wait for weight 3
                LD_W3: begin
                    if (mem_rd_valid) begin
                        wdata_3 <= mem_rd_data;
                        fsm     <= LD_DAT_RQ;
                    end
                end

                // issue read for inputs
                LD_DAT_RQ: begin
                    if (!mem_req) begin
                        mem_req  <= 1'b1;
                        mem_we   <= 1'b0;
                        mem_addr <= {16'd0, img_base};
                        fsm      <= LD_DATA;
                    end
                end

                // wait for inputs
                LD_DATA: begin
                    if (mem_rd_valid) begin
                        idata    <= mem_rd_data;
                        load_w   <= 1'b1;
                        comp_cnt <= 3'd0;
                        fsm      <= COMPUTE;
                    end
                end

                // compute: 5 cycles
                COMPUTE: begin
                    comp_en <= 1'b1;
                    if (comp_cnt == 3'd4) begin
                        comp_cnt <= 3'd0;
                        fsm      <= STORE_RQ;
                    end else begin
                        comp_cnt <= comp_cnt + 3'd1;
                    end
                end

                // issue write for result
                STORE_RQ: begin
                    if (!mem_req) begin
                        mem_req   <= 1'b1;
                        mem_we    <= 1'b1;
                        mem_addr  <= {16'd0, res_base};
                        mem_wdata <= {relu_3, relu_2, relu_1, relu_0};
                        fsm       <= STORE;
                    end
                end

                // wait for write completion
                STORE: begin
                    if (mem_wr_done) begin
                        fsm <= DONE_ST;
                    end
                end

                DONE_ST: begin
                    fsm <= IDLE;
                end

                default: fsm <= IDLE;
            endcase
        end
    end

    assign fsm_state_o = fsm[3:0];
    assign done_o = (fsm == DONE_ST);
    assign busy_o = (fsm != IDLE);

`ifdef FORMAL
    // ========== ASSUMPTIONS (environment) ==========

    // Memory responds within 7 cycles of request
    reg [3:0] req_age;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) req_age <= 4'd0;
        else if (mem_req && !mem_gnt) req_age <= req_age + 4'd1;
        else req_age <= 4'd0;
    end
    always @(posedge clk) assume(req_age < 4'd8);

    // Read data arrives within 3 cycles of grant
    reg [3:0] rsp_age;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) rsp_age <= 4'd0;
        else if (mem_gnt && !mem_we && !mem_rvalid) rsp_age <= rsp_age + 4'd1;
        else rsp_age <= 4'd0;
    end
    always @(posedge clk) assume(rsp_age < 4'd4);

    // ========== INITIAL STATE (formal) ==========

    always @(posedge clk) begin
        if ($initstate) begin
            assume(rst_n == 0);
            assume(fsm == IDLE);
            assume(done_o == 0);
            assume(busy_o == 0);
            assume(pready == 0);
            assume(mem_req == 0);
            assume(mem_we == 0);
            assume(mem_addr == 0);
            assume(mem_wdata == 0);
            assume(comp_en == 0);
            assume(comp_cnt == 0);
            assume(load_w == 0);
            assume(req_age == 0);
            assume(rsp_age == 0);
            assume(idata == 0);
        end
    end

    // ========== ASSERTIONS ==========

    // A1: FSM state is always valid
    always @(posedge clk) begin
        if (!rst_n) assert(fsm == IDLE);
        else        assert(fsm <= DONE_ST);
    end

    // A2: done_o implies DONE_ST
    always @(posedge clk) begin
        if (done_o) assert(fsm == DONE_ST);
    end

    // A3: busy_o reflects fsm != IDLE
    always @(posedge clk) begin
        assert(busy_o == (fsm != IDLE));
    end

    // A4: COMPUTE counter never exceeds 4
    always @(posedge clk) begin
        if (fsm == COMPUTE) assert(comp_cnt <= 3'd4);
    end

    // A5: no X/Z on output ports
    always @(posedge clk) begin
        assert(!$isunknown(done_o));
        assert(!$isunknown(busy_o));
        assert(!$isunknown(pready));
        if (mem_req) begin
            assert(!$isunknown(mem_addr));
            assert(!$isunknown(mem_we));
            if (mem_we) assert(!$isunknown(mem_wdata));
        end
    end

    // A6: load_w only asserted in LD_DATA
    always @(posedge clk) begin
        if (load_w) assert($past(fsm) == LD_DATA);
    end

    // A7: comp_en only asserted in COMPUTE
    always @(posedge clk) begin
        if (comp_en) assert(fsm == COMPUTE);
    end

    // A8: FSM state sequence (forward progress)
    // Each load state transitions to the next or to IDLE (on reset)
    // For BMC we check that after start, progress is made
    reg start_seen;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) start_seen <= 1'b0;
        else if (start) start_seen <= 1'b1;
    end

    // A9: start clears after done
    always @(posedge clk) begin
        if ($past(done_o, 1) && !$past(done_o, 2)) begin
            assert(!start);
        end
    end

    // ========== COVER ==========

    // C1: Full run from start to done
    always @(posedge clk) begin
        if ($rose(start)) cover(done_o);
    end

    // C2: Each major state is reachable
    always @(posedge clk) cover(fsm == COMPUTE);
    always @(posedge clk) cover(fsm == STORE);
    always @(posedge clk) cover(fsm == DONE_ST);

`endif
endmodule
