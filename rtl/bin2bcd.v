// Binary to BCD converter (16-bit input, 5 decimal digits output)
// Uses double-dabble algorithm, purely combinational

module bin2bcd
(
	input  [15:0] bin,
	output [19:0] bcd  // 5 BCD digits
);

integer i;
reg [35:0] shift; // 20 bits BCD + 16 bits binary

always @(*) begin
	shift = {20'd0, bin};
	for (i = 0; i < 16; i = i + 1) begin
		if (shift[19:16] >= 5) shift[19:16] = shift[19:16] + 3;
		if (shift[23:20] >= 5) shift[23:20] = shift[23:20] + 3;
		if (shift[27:24] >= 5) shift[27:24] = shift[27:24] + 3;
		if (shift[31:28] >= 5) shift[31:28] = shift[31:28] + 3;
		if (shift[35:32] >= 5) shift[35:32] = shift[35:32] + 3;
		shift = shift << 1;
	end
end

assign bcd = shift[35:16];

endmodule

// 24-bit input, 7 decimal digits output (up to 16,777,215)
module bin2bcd24
(
	input  [23:0] bin,
	output [27:0] bcd  // 7 BCD digits
);

integer i;
reg [51:0] shift; // 28 bits BCD + 24 bits binary

always @(*) begin
	shift = {28'd0, bin};
	for (i = 0; i < 24; i = i + 1) begin
		if (shift[27:24] >= 5) shift[27:24] = shift[27:24] + 3;
		if (shift[31:28] >= 5) shift[31:28] = shift[31:28] + 3;
		if (shift[35:32] >= 5) shift[35:32] = shift[35:32] + 3;
		if (shift[39:36] >= 5) shift[39:36] = shift[39:36] + 3;
		if (shift[43:40] >= 5) shift[43:40] = shift[43:40] + 3;
		if (shift[47:44] >= 5) shift[47:44] = shift[47:44] + 3;
		if (shift[51:48] >= 5) shift[51:48] = shift[51:48] + 3;
		shift = shift << 1;
	end
end

assign bcd = shift[51:24];

endmodule
