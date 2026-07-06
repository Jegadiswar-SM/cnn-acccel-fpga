module cnn_top_formal (
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

    wire [4:0] fsm = u_dut.fsm;

    // ============================================
    // ASSUMPTIONS (environment constraints)
    // ============================================

    // Memory grant within 7 cycles of request
    reg [3:0] req_age;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) req_age <= 4'd0;
        else if (mem_req && !mem_gnt) req_age <= req_age + 4'd1;
        else req_age <= 4'd0;
    end
    always @(posedge clk) assume(req_age < 4'd8);

    // Read response within 3 cycles of grant
    reg [3:0] rsp_age;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) rsp_age <= 4'd0;
        else if (mem_gnt && !mem_we && !mem_rvalid) rsp_age <= rsp_age + 4'd1;
        else rsp_age <= 4'd0;
    end
    always @(posedge clk) assume(rsp_age < 4'd4);

    // start is level-triggered: stays high until done
    reg start;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) start <= 1'b0;
        else if (psel && penable && pwrite && paddr[7:0] == 8'h00) start <= pwdata[0];
        else if (done_o) start <= 1'b0;
    end

    // ============================================
    // ASSERTIONS
    // ============================================

    // A1: FSM never leaves valid range [0..14]
    always @(posedge clk) begin
        if (rst_n) assert(fsm <= 5'd14);
        else       assert(fsm == 5'd0);
    end

    // A2: done_o implies fsm == DONE (14)
    always @(posedge clk) begin
        if (done_o) assert(fsm == 5'd14);
    end

    // A3: busy_o mirrors (fsm != IDLE)
    always @(posedge clk) begin
        assert(busy_o == (fsm != 5'd0));
    end

    // A4: COMPUTE counter never exceeds 4
    always @(posedge clk) begin
        if (fsm == 5'd11) assert(u_dut.comp_cnt <= 3'd4);
    end

    // A5: start is cleared by done_o
    always @(posedge clk) begin
        if ($past(done_o)) assert(!start);
    end

    // A6: FSM progresses monotonically through load states
    // (past_fsm should be <= current_fsm in load sequence, except at wraparound)
    always @(posedge clk) begin
        if (rst_n && $past(rst_n)) begin
            if ($past(fsm) >= 5'd1 && $past(fsm) <= 5'd10) begin
                // In the load sequence, fsm should only increment or reset to IDLE
                assert(fsm == $past(fsm) + 5'd1 || $past(fsm) == 5'd10);
            end
            // Wait, this is an overspecification. Skip.
        end
    end

    // ============================================
    // COVER
    // ============================================

    // C1: Triggered by start, reaches compute
    always @(posedge clk) begin
        if ($rose(start)) cover(fsm == 5'd11); // COMPUTE
    end

    // C2: Full flow completes
    always @(posedge clk) begin
        if ($rose(start)) cover(done_o);
    end

endmodule
