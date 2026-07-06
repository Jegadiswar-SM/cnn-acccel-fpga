module pooling (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        en,
    input  wire [7:0]  data_in,
    output reg  [7:0]  data_out,
    output reg         valid
);
    reg [7:0] p00, p01, p10, p11;
    reg [1:0] phase;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            p00 <= 8'd0; p01 <= 8'd0;
            p10 <= 8'd0; p11 <= 8'd0;
            phase <= 2'd0;
            valid <= 1'b0;
            data_out <= 8'd0;
        end else if (en) begin
            case (phase)
                2'd0: begin p00 <= data_in; valid <= 1'b0; phase <= 2'd1; end
                2'd1: begin p01 <= data_in;                      phase <= 2'd2; end
                2'd2: begin p10 <= data_in;                      phase <= 2'd3; end
                2'd3: begin
                    p11 <= data_in;
                    phase <= 2'd0;
                    data_out <= max4(p00, p01, p10, p11, data_in);
                    valid <= 1'b1;
                end
            endcase
        end else begin
            valid <= 1'b0;
        end
    end

    function [7:0] max4(input [7:0] a, b, c, d, e);
        reg [7:0] t;
        begin
            t = (a > b) ? a : b;
            t = (t > c) ? t : c;
            t = (t > d) ? t : d;
            t = (t > e) ? t : e;
            max4 = t;
        end
    endfunction
endmodule
