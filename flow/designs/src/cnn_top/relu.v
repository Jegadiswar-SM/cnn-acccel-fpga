module relu (
    input  wire [31:0] data_in,
    output wire [7:0]  data_out
);
    assign data_out = ($signed(data_in) < 32'sd0) ? 8'd0 :
                      (|data_in[31:8])             ? 8'd255 :
                                                      data_in[7:0];
endmodule
