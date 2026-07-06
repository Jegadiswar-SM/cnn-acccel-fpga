module pe (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        clr,
    input  wire        load_w,
    input  wire        en,
    input  wire [31:0] wdata,      // 4 weights packed: {w3,w2,w1,w0}
    input  wire [31:0] idata,      // 4 inputs packed:  {i3,i2,i1,i0}
    output reg  [31:0] result
);
    reg signed [7:0]  wr [0:3];
    reg [1:0]         step;
    reg signed [31:0] acc;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            step   <= 2'd0;
            acc    <= 32'd0;
            result <= 32'd0;
            for (int i = 0; i < 4; i++) wr[i] <= 8'd0;
        end else begin
            if (clr) begin
                step   <= 2'd0;
                acc    <= 32'd0;
                result <= 32'd0;
            end else begin
                if (load_w) begin
                    wr[0] <= wdata[7:0];
                    wr[1] <= wdata[15:8];
                    wr[2] <= wdata[23:16];
                    wr[3] <= wdata[31:24];
                    step  <= 2'd0;
                    acc   <= 32'd0;
                end else if (en) begin
                    case (step)
                        2'd0: acc <= $signed(wr[0]) * $signed(idata[7:0]);
                        2'd1: acc <= acc + $signed(wr[1]) * $signed(idata[15:8]);
                        2'd2: acc <= acc + $signed(wr[2]) * $signed(idata[23:16]);
                        2'd3: begin
                            acc    <= acc + $signed(wr[3]) * $signed(idata[31:24]);
                            result <= acc + $signed(wr[3]) * $signed(idata[31:24]);
                        end
                    endcase
                    step <= step + 2'd1;
                end
            end
        end
    end
endmodule
