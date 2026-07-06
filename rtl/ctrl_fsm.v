module ctrl_fsm (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    input  wire        mode,          // 0: FC, 1: Conv
    input  wire [7:0]  img_rows,
    input  wire [7:0]  img_cols,
    input  wire [7:0]  num_kernels,   // Number of output channels
    input  wire [7:0]  kernel_size,   // 1, 2, 3
    output reg         load_w,
    output reg         compute_en,
    output reg         relu_en,
    output reg         pool_en,
    output reg         store_en,
    output reg         done,
    output reg         busy,
    output reg  [3:0]  state_debug
);
    localparam [3:0]
        IDLE       = 4'd0,
        WGT_LOAD   = 4'd1,
        COMPUTE    = 4'd2,
        ACTIVATE   = 4'd3,
        POOL_INIT  = 4'd4,
        POOL_DRAIN = 4'd5,
        STORE      = 4'd6,
        DONE_ST    = 4'd7;

    reg [3:0] st;
    reg [7:0] kernel_cnt;
    reg [7:0] row_cnt;
    reg [7:0] col_cnt;
    reg [7:0] wgt_cnt;
    reg [7:0] comp_cnt;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            st        <= IDLE;
            load_w    <= 1'b0;
            compute_en<= 1'b0;
            relu_en   <= 1'b0;
            pool_en   <= 1'b0;
            store_en  <= 1'b0;
            done      <= 1'b0;
            busy      <= 1'b0;
            kernel_cnt<= 8'd0;
            row_cnt   <= 8'd0;
            col_cnt   <= 8'd0;
            wgt_cnt   <= 8'd0;
            comp_cnt  <= 8'd0;
        end else begin
            case (st)
                IDLE: begin
                    load_w    <= 1'b0;
                    compute_en<= 1'b0;
                    relu_en   <= 1'b0;
                    pool_en   <= 1'b0;
                    store_en  <= 1'b0;
                    done      <= 1'b0;
                    busy      <= 1'b0;
                    kernel_cnt<= 8'd0;
                    row_cnt   <= 8'd0;
                    col_cnt   <= 8'd0;
                    wgt_cnt   <= 8'd0;
                    comp_cnt  <= 8'd0;
                    if (start) begin
                        busy <= 1'b1;
                        st   <= WGT_LOAD;
                    end
                end

                WGT_LOAD: begin
                    load_w <= 1'b1;
                    if (wgt_cnt == kernel_size * kernel_size * num_kernels / 4 - 1) begin
                        wgt_cnt <= 8'd0;
                        load_w  <= 1'b0;
                        st      <= COMPUTE;
                    end else begin
                        wgt_cnt <= wgt_cnt + 8'd1;
                    end
                end

                COMPUTE: begin
                    compute_en <= 1'b1;
                    if (comp_cnt == img_cols + 3) begin
                        comp_cnt   <= 8'd0;
                        compute_en <= 1'b0;
                        if (mode == 1'b0) begin
                            st <= STORE;
                        end else begin
                            st <= ACTIVATE;
                        end
                    end else begin
                        comp_cnt <= comp_cnt + 8'd1;
                    end
                end

                ACTIVATE: begin
                    relu_en <= 1'b1;
                    st      <= POOL_INIT;
                end

                POOL_INIT: begin
                    relu_en <= 1'b0;
                    pool_en <= 1'b1;
                    st      <= POOL_DRAIN;
                end

                POOL_DRAIN: begin
                    if (col_cnt == img_cols / 2) begin
                        col_cnt <= 8'd0;
                        pool_en <= 1'b0;
                        st      <= STORE;
                    end else begin
                        col_cnt <= col_cnt + 8'd1;
                    end
                end

                STORE: begin
                    store_en <= 1'b1;
                    if (row_cnt == img_rows - 1) begin
                        row_cnt   <= 8'd0;
                        kernel_cnt<= kernel_cnt + 8'd1;
                        store_en  <= 1'b0;
                        if (kernel_cnt == num_kernels - 1) begin
                            st <= DONE_ST;
                        end else begin
                            st <= WGT_LOAD;
                        end
                    end else if (col_cnt == img_cols - 1) begin
                        col_cnt <= 8'd0;
                        row_cnt <= row_cnt + 8'd1;
                    end else begin
                        col_cnt <= col_cnt + 8'd1;
                    end
                end

                DONE_ST: begin
                    done <= 1'b1;
                    busy <= 1'b0;
                    st   <= IDLE;
                end

                default: st <= IDLE;
            endcase
        end
    end

    assign state_debug = st;
endmodule
