module cnn_regs (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        psel,
    input  wire        penable,
    input  wire        pwrite,
    input  wire [31:0] paddr,
    input  wire [31:0] pwdata,
    output reg  [31:0] prdata,
    output wire        pready,

    output reg         start,
    input  wire        busy,
    input  wire        done,
    output reg         mode,
    output reg  [7:0]  img_rows,
    output reg  [7:0]  img_cols,
    output reg  [15:0] img_base,
    output reg  [15:0] wgt_base,
    output reg  [15:0] res_base
);
    // verilator lint_off UNUSEDSIGNAL
    assign pready = 1'b1;
    // verilator lint_on UNUSEDSIGNAL

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            start    <= 1'b0;
            mode     <= 1'b0;
            img_rows <= 8'd4;
            img_cols <= 8'd4;
            img_base <= 16'd0;
            wgt_base <= 16'd0;
            res_base <= 16'd256;
        end else begin
            // APB write
            if (psel && penable && pwrite) begin
                case (paddr[7:0])
                    8'h00: start <= pwdata[0];
                    8'h04: ; // STATUS read-only
                    8'h08: begin
                        mode     <= pwdata[0];
                        img_rows <= pwdata[15:8];
                        img_cols <= pwdata[23:16];
                    end
                    8'h10: img_base <= pwdata[15:0];
                    8'h14: wgt_base <= pwdata[15:0];
                    8'h18: res_base <= pwdata[15:0];
                    default: ;
                endcase
            end

            // Clear start when done
            if (done) start <= 1'b0;
        end
    end

    // Read mux
    always_comb begin
        case (paddr[7:0])
            8'h00: prdata = {31'd0, start};
            8'h04: prdata = {30'd0, done, busy};
            8'h08: prdata = {8'd0, img_cols, img_rows, 7'd0, mode};
            8'h10: prdata = {16'd0, img_base};
            8'h14: prdata = {16'd0, wgt_base};
            8'h18: prdata = {16'd0, res_base};
            default: prdata = 32'h0;
        endcase
    end
endmodule
