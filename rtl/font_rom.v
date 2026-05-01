// 8x8 Bitmap Font ROM for ASCII characters 32-127
// Each character is 8 rows of 8 bits (MSB = leftmost pixel)
// Standard CP437-style glyphs

module font_rom
(
	input  [6:0] char_code,  // ASCII 0-127
	input  [2:0] row,        // row within character (0-7)
	output [7:0] pixels      // 8 pixel bits for this row (MSB = left)
);

reg [7:0] data;
assign pixels = data;

always @(*) begin
	data = 8'h00;
	case({char_code, row})
		// Space (32)
		{7'd32, 3'd0}: data = 8'h00; {7'd32, 3'd1}: data = 8'h00;
		{7'd32, 3'd2}: data = 8'h00; {7'd32, 3'd3}: data = 8'h00;
		{7'd32, 3'd4}: data = 8'h00; {7'd32, 3'd5}: data = 8'h00;
		{7'd32, 3'd6}: data = 8'h00; {7'd32, 3'd7}: data = 8'h00;

		// ! (33)
		{7'd33, 3'd0}: data = 8'h18; {7'd33, 3'd1}: data = 8'h18;
		{7'd33, 3'd2}: data = 8'h18; {7'd33, 3'd3}: data = 8'h18;
		{7'd33, 3'd4}: data = 8'h18; {7'd33, 3'd5}: data = 8'h00;
		{7'd33, 3'd6}: data = 8'h18; {7'd33, 3'd7}: data = 8'h00;

		// : (58)
		{7'd58, 3'd0}: data = 8'h00; {7'd58, 3'd1}: data = 8'h18;
		{7'd58, 3'd2}: data = 8'h18; {7'd58, 3'd3}: data = 8'h00;
		{7'd58, 3'd4}: data = 8'h18; {7'd58, 3'd5}: data = 8'h18;
		{7'd58, 3'd6}: data = 8'h00; {7'd58, 3'd7}: data = 8'h00;

		// > (62)
		{7'd62, 3'd0}: data = 8'h60; {7'd62, 3'd1}: data = 8'h30;
		{7'd62, 3'd2}: data = 8'h18; {7'd62, 3'd3}: data = 8'h0C;
		{7'd62, 3'd4}: data = 8'h18; {7'd62, 3'd5}: data = 8'h30;
		{7'd62, 3'd6}: data = 8'h60; {7'd62, 3'd7}: data = 8'h00;

		// / (47)
		{7'd47, 3'd0}: data = 8'h06; {7'd47, 3'd1}: data = 8'h0C;
		{7'd47, 3'd2}: data = 8'h18; {7'd47, 3'd3}: data = 8'h30;
		{7'd47, 3'd4}: data = 8'h60; {7'd47, 3'd5}: data = 8'h40;
		{7'd47, 3'd6}: data = 8'h00; {7'd47, 3'd7}: data = 8'h00;

		// \ (92)
		{7'd92, 3'd0}: data = 8'h60; {7'd92, 3'd1}: data = 8'h30;
		{7'd92, 3'd2}: data = 8'h18; {7'd92, 3'd3}: data = 8'h0C;
		{7'd92, 3'd4}: data = 8'h06; {7'd92, 3'd5}: data = 8'h02;
		{7'd92, 3'd6}: data = 8'h00; {7'd92, 3'd7}: data = 8'h00;

		// | (124)
		{7'd124, 3'd0}: data = 8'h18; {7'd124, 3'd1}: data = 8'h18;
		{7'd124, 3'd2}: data = 8'h18; {7'd124, 3'd3}: data = 8'h18;
		{7'd124, 3'd4}: data = 8'h18; {7'd124, 3'd5}: data = 8'h18;
		{7'd124, 3'd6}: data = 8'h18; {7'd124, 3'd7}: data = 8'h00;

		// + (43) plus
		{7'd43, 3'd0}: data = 8'h00; {7'd43, 3'd1}: data = 8'h18;
		{7'd43, 3'd2}: data = 8'h18; {7'd43, 3'd3}: data = 8'h7E;
		{7'd43, 3'd4}: data = 8'h18; {7'd43, 3'd5}: data = 8'h18;
		{7'd43, 3'd6}: data = 8'h00; {7'd43, 3'd7}: data = 8'h00;

		// - (45) dash/minus
		{7'd45, 3'd0}: data = 8'h00; {7'd45, 3'd1}: data = 8'h00;
		{7'd45, 3'd2}: data = 8'h00; {7'd45, 3'd3}: data = 8'h7E;
		{7'd45, 3'd4}: data = 8'h00; {7'd45, 3'd5}: data = 8'h00;
		{7'd45, 3'd6}: data = 8'h00; {7'd45, 3'd7}: data = 8'h00;

		// . (46)
		{7'd46, 3'd0}: data = 8'h00; {7'd46, 3'd1}: data = 8'h00;
		{7'd46, 3'd2}: data = 8'h00; {7'd46, 3'd3}: data = 8'h00;
		{7'd46, 3'd4}: data = 8'h00; {7'd46, 3'd5}: data = 8'h18;
		{7'd46, 3'd6}: data = 8'h18; {7'd46, 3'd7}: data = 8'h00;

		// 0 (48)
		{7'd48, 3'd0}: data = 8'h3C; {7'd48, 3'd1}: data = 8'h66;
		{7'd48, 3'd2}: data = 8'h6E; {7'd48, 3'd3}: data = 8'h76;
		{7'd48, 3'd4}: data = 8'h66; {7'd48, 3'd5}: data = 8'h66;
		{7'd48, 3'd6}: data = 8'h3C; {7'd48, 3'd7}: data = 8'h00;

		// 1 (49)
		{7'd49, 3'd0}: data = 8'h18; {7'd49, 3'd1}: data = 8'h38;
		{7'd49, 3'd2}: data = 8'h18; {7'd49, 3'd3}: data = 8'h18;
		{7'd49, 3'd4}: data = 8'h18; {7'd49, 3'd5}: data = 8'h18;
		{7'd49, 3'd6}: data = 8'h7E; {7'd49, 3'd7}: data = 8'h00;

		// 2 (50)
		{7'd50, 3'd0}: data = 8'h3C; {7'd50, 3'd1}: data = 8'h66;
		{7'd50, 3'd2}: data = 8'h06; {7'd50, 3'd3}: data = 8'h0C;
		{7'd50, 3'd4}: data = 8'h18; {7'd50, 3'd5}: data = 8'h30;
		{7'd50, 3'd6}: data = 8'h7E; {7'd50, 3'd7}: data = 8'h00;

		// 3 (51)
		{7'd51, 3'd0}: data = 8'h3C; {7'd51, 3'd1}: data = 8'h66;
		{7'd51, 3'd2}: data = 8'h06; {7'd51, 3'd3}: data = 8'h1C;
		{7'd51, 3'd4}: data = 8'h06; {7'd51, 3'd5}: data = 8'h66;
		{7'd51, 3'd6}: data = 8'h3C; {7'd51, 3'd7}: data = 8'h00;

		// 4 (52)
		{7'd52, 3'd0}: data = 8'h0C; {7'd52, 3'd1}: data = 8'h1C;
		{7'd52, 3'd2}: data = 8'h2C; {7'd52, 3'd3}: data = 8'h4C;
		{7'd52, 3'd4}: data = 8'h7E; {7'd52, 3'd5}: data = 8'h0C;
		{7'd52, 3'd6}: data = 8'h0C; {7'd52, 3'd7}: data = 8'h00;

		// 5 (53)
		{7'd53, 3'd0}: data = 8'h7E; {7'd53, 3'd1}: data = 8'h60;
		{7'd53, 3'd2}: data = 8'h7C; {7'd53, 3'd3}: data = 8'h06;
		{7'd53, 3'd4}: data = 8'h06; {7'd53, 3'd5}: data = 8'h66;
		{7'd53, 3'd6}: data = 8'h3C; {7'd53, 3'd7}: data = 8'h00;

		// 6 (54)
		{7'd54, 3'd0}: data = 8'h1C; {7'd54, 3'd1}: data = 8'h30;
		{7'd54, 3'd2}: data = 8'h60; {7'd54, 3'd3}: data = 8'h7C;
		{7'd54, 3'd4}: data = 8'h66; {7'd54, 3'd5}: data = 8'h66;
		{7'd54, 3'd6}: data = 8'h3C; {7'd54, 3'd7}: data = 8'h00;

		// 7 (55)
		{7'd55, 3'd0}: data = 8'h7E; {7'd55, 3'd1}: data = 8'h06;
		{7'd55, 3'd2}: data = 8'h0C; {7'd55, 3'd3}: data = 8'h18;
		{7'd55, 3'd4}: data = 8'h18; {7'd55, 3'd5}: data = 8'h18;
		{7'd55, 3'd6}: data = 8'h18; {7'd55, 3'd7}: data = 8'h00;

		// 8 (56)
		{7'd56, 3'd0}: data = 8'h3C; {7'd56, 3'd1}: data = 8'h66;
		{7'd56, 3'd2}: data = 8'h66; {7'd56, 3'd3}: data = 8'h3C;
		{7'd56, 3'd4}: data = 8'h66; {7'd56, 3'd5}: data = 8'h66;
		{7'd56, 3'd6}: data = 8'h3C; {7'd56, 3'd7}: data = 8'h00;

		// 9 (57)
		{7'd57, 3'd0}: data = 8'h3C; {7'd57, 3'd1}: data = 8'h66;
		{7'd57, 3'd2}: data = 8'h66; {7'd57, 3'd3}: data = 8'h3E;
		{7'd57, 3'd4}: data = 8'h06; {7'd57, 3'd5}: data = 8'h0C;
		{7'd57, 3'd6}: data = 8'h38; {7'd57, 3'd7}: data = 8'h00;

		// A (65)
		{7'd65, 3'd0}: data = 8'h18; {7'd65, 3'd1}: data = 8'h3C;
		{7'd65, 3'd2}: data = 8'h66; {7'd65, 3'd3}: data = 8'h66;
		{7'd65, 3'd4}: data = 8'h7E; {7'd65, 3'd5}: data = 8'h66;
		{7'd65, 3'd6}: data = 8'h66; {7'd65, 3'd7}: data = 8'h00;

		// B (66)
		{7'd66, 3'd0}: data = 8'h7C; {7'd66, 3'd1}: data = 8'h66;
		{7'd66, 3'd2}: data = 8'h66; {7'd66, 3'd3}: data = 8'h7C;
		{7'd66, 3'd4}: data = 8'h66; {7'd66, 3'd5}: data = 8'h66;
		{7'd66, 3'd6}: data = 8'h7C; {7'd66, 3'd7}: data = 8'h00;

		// C (67)
		{7'd67, 3'd0}: data = 8'h3C; {7'd67, 3'd1}: data = 8'h66;
		{7'd67, 3'd2}: data = 8'h60; {7'd67, 3'd3}: data = 8'h60;
		{7'd67, 3'd4}: data = 8'h60; {7'd67, 3'd5}: data = 8'h66;
		{7'd67, 3'd6}: data = 8'h3C; {7'd67, 3'd7}: data = 8'h00;

		// D (68)
		{7'd68, 3'd0}: data = 8'h78; {7'd68, 3'd1}: data = 8'h6C;
		{7'd68, 3'd2}: data = 8'h66; {7'd68, 3'd3}: data = 8'h66;
		{7'd68, 3'd4}: data = 8'h66; {7'd68, 3'd5}: data = 8'h6C;
		{7'd68, 3'd6}: data = 8'h78; {7'd68, 3'd7}: data = 8'h00;

		// E (69)
		{7'd69, 3'd0}: data = 8'h7E; {7'd69, 3'd1}: data = 8'h60;
		{7'd69, 3'd2}: data = 8'h60; {7'd69, 3'd3}: data = 8'h7C;
		{7'd69, 3'd4}: data = 8'h60; {7'd69, 3'd5}: data = 8'h60;
		{7'd69, 3'd6}: data = 8'h7E; {7'd69, 3'd7}: data = 8'h00;

		// F (70)
		{7'd70, 3'd0}: data = 8'h7E; {7'd70, 3'd1}: data = 8'h60;
		{7'd70, 3'd2}: data = 8'h60; {7'd70, 3'd3}: data = 8'h7C;
		{7'd70, 3'd4}: data = 8'h60; {7'd70, 3'd5}: data = 8'h60;
		{7'd70, 3'd6}: data = 8'h60; {7'd70, 3'd7}: data = 8'h00;

		// H (72)
		{7'd72, 3'd0}: data = 8'h66; {7'd72, 3'd1}: data = 8'h66;
		{7'd72, 3'd2}: data = 8'h66; {7'd72, 3'd3}: data = 8'h7E;
		{7'd72, 3'd4}: data = 8'h66; {7'd72, 3'd5}: data = 8'h66;
		{7'd72, 3'd6}: data = 8'h66; {7'd72, 3'd7}: data = 8'h00;

		// I (73)
		{7'd73, 3'd0}: data = 8'h3C; {7'd73, 3'd1}: data = 8'h18;
		{7'd73, 3'd2}: data = 8'h18; {7'd73, 3'd3}: data = 8'h18;
		{7'd73, 3'd4}: data = 8'h18; {7'd73, 3'd5}: data = 8'h18;
		{7'd73, 3'd6}: data = 8'h3C; {7'd73, 3'd7}: data = 8'h00;

		// L (76)
		{7'd76, 3'd0}: data = 8'h60; {7'd76, 3'd1}: data = 8'h60;
		{7'd76, 3'd2}: data = 8'h60; {7'd76, 3'd3}: data = 8'h60;
		{7'd76, 3'd4}: data = 8'h60; {7'd76, 3'd5}: data = 8'h60;
		{7'd76, 3'd6}: data = 8'h7E; {7'd76, 3'd7}: data = 8'h00;

		// M (77)
		{7'd77, 3'd0}: data = 8'h63; {7'd77, 3'd1}: data = 8'h77;
		{7'd77, 3'd2}: data = 8'h7F; {7'd77, 3'd3}: data = 8'h6B;
		{7'd77, 3'd4}: data = 8'h63; {7'd77, 3'd5}: data = 8'h63;
		{7'd77, 3'd6}: data = 8'h63; {7'd77, 3'd7}: data = 8'h00;

		// N (78)
		{7'd78, 3'd0}: data = 8'h66; {7'd78, 3'd1}: data = 8'h76;
		{7'd78, 3'd2}: data = 8'h7E; {7'd78, 3'd3}: data = 8'h7E;
		{7'd78, 3'd4}: data = 8'h6E; {7'd78, 3'd5}: data = 8'h66;
		{7'd78, 3'd6}: data = 8'h66; {7'd78, 3'd7}: data = 8'h00;

		// O (79)
		{7'd79, 3'd0}: data = 8'h3C; {7'd79, 3'd1}: data = 8'h66;
		{7'd79, 3'd2}: data = 8'h66; {7'd79, 3'd3}: data = 8'h66;
		{7'd79, 3'd4}: data = 8'h66; {7'd79, 3'd5}: data = 8'h66;
		{7'd79, 3'd6}: data = 8'h3C; {7'd79, 3'd7}: data = 8'h00;

		// P (80)
		{7'd80, 3'd0}: data = 8'h7C; {7'd80, 3'd1}: data = 8'h66;
		{7'd80, 3'd2}: data = 8'h66; {7'd80, 3'd3}: data = 8'h7C;
		{7'd80, 3'd4}: data = 8'h60; {7'd80, 3'd5}: data = 8'h60;
		{7'd80, 3'd6}: data = 8'h60; {7'd80, 3'd7}: data = 8'h00;

		// R (82)
		{7'd82, 3'd0}: data = 8'h7C; {7'd82, 3'd1}: data = 8'h66;
		{7'd82, 3'd2}: data = 8'h66; {7'd82, 3'd3}: data = 8'h7C;
		{7'd82, 3'd4}: data = 8'h6C; {7'd82, 3'd5}: data = 8'h66;
		{7'd82, 3'd6}: data = 8'h66; {7'd82, 3'd7}: data = 8'h00;

		// S (83)
		{7'd83, 3'd0}: data = 8'h3C; {7'd83, 3'd1}: data = 8'h66;
		{7'd83, 3'd2}: data = 8'h60; {7'd83, 3'd3}: data = 8'h3C;
		{7'd83, 3'd4}: data = 8'h06; {7'd83, 3'd5}: data = 8'h66;
		{7'd83, 3'd6}: data = 8'h3C; {7'd83, 3'd7}: data = 8'h00;

		// T (84)
		{7'd84, 3'd0}: data = 8'h7E; {7'd84, 3'd1}: data = 8'h18;
		{7'd84, 3'd2}: data = 8'h18; {7'd84, 3'd3}: data = 8'h18;
		{7'd84, 3'd4}: data = 8'h18; {7'd84, 3'd5}: data = 8'h18;
		{7'd84, 3'd6}: data = 8'h18; {7'd84, 3'd7}: data = 8'h00;

		// V (86)
		{7'd86, 3'd0}: data = 8'h66; {7'd86, 3'd1}: data = 8'h66;
		{7'd86, 3'd2}: data = 8'h66; {7'd86, 3'd3}: data = 8'h66;
		{7'd86, 3'd4}: data = 8'h66; {7'd86, 3'd5}: data = 8'h3C;
		{7'd86, 3'd6}: data = 8'h18; {7'd86, 3'd7}: data = 8'h00;

		// W (87)
		{7'd87, 3'd0}: data = 8'h63; {7'd87, 3'd1}: data = 8'h63;
		{7'd87, 3'd2}: data = 8'h63; {7'd87, 3'd3}: data = 8'h6B;
		{7'd87, 3'd4}: data = 8'h7F; {7'd87, 3'd5}: data = 8'h77;
		{7'd87, 3'd6}: data = 8'h63; {7'd87, 3'd7}: data = 8'h00;

		// Y (89)
		{7'd89, 3'd0}: data = 8'h66; {7'd89, 3'd1}: data = 8'h66;
		{7'd89, 3'd2}: data = 8'h66; {7'd89, 3'd3}: data = 8'h3C;
		{7'd89, 3'd4}: data = 8'h18; {7'd89, 3'd5}: data = 8'h18;
		{7'd89, 3'd6}: data = 8'h18; {7'd89, 3'd7}: data = 8'h00;

		// a (97)
		{7'd97, 3'd0}: data = 8'h00; {7'd97, 3'd1}: data = 8'h00;
		{7'd97, 3'd2}: data = 8'h3C; {7'd97, 3'd3}: data = 8'h06;
		{7'd97, 3'd4}: data = 8'h3E; {7'd97, 3'd5}: data = 8'h66;
		{7'd97, 3'd6}: data = 8'h3E; {7'd97, 3'd7}: data = 8'h00;

		// d (100)
		{7'd100, 3'd0}: data = 8'h06; {7'd100, 3'd1}: data = 8'h06;
		{7'd100, 3'd2}: data = 8'h3E; {7'd100, 3'd3}: data = 8'h66;
		{7'd100, 3'd4}: data = 8'h66; {7'd100, 3'd5}: data = 8'h66;
		{7'd100, 3'd6}: data = 8'h3E; {7'd100, 3'd7}: data = 8'h00;

		// e (101)
		{7'd101, 3'd0}: data = 8'h00; {7'd101, 3'd1}: data = 8'h00;
		{7'd101, 3'd2}: data = 8'h3C; {7'd101, 3'd3}: data = 8'h66;
		{7'd101, 3'd4}: data = 8'h7E; {7'd101, 3'd5}: data = 8'h60;
		{7'd101, 3'd6}: data = 8'h3C; {7'd101, 3'd7}: data = 8'h00;

		// h (104)
		{7'd104, 3'd0}: data = 8'h60; {7'd104, 3'd1}: data = 8'h60;
		{7'd104, 3'd2}: data = 8'h7C; {7'd104, 3'd3}: data = 8'h66;
		{7'd104, 3'd4}: data = 8'h66; {7'd104, 3'd5}: data = 8'h66;
		{7'd104, 3'd6}: data = 8'h66; {7'd104, 3'd7}: data = 8'h00;

		// i (105)
		{7'd105, 3'd0}: data = 8'h18; {7'd105, 3'd1}: data = 8'h00;
		{7'd105, 3'd2}: data = 8'h38; {7'd105, 3'd3}: data = 8'h18;
		{7'd105, 3'd4}: data = 8'h18; {7'd105, 3'd5}: data = 8'h18;
		{7'd105, 3'd6}: data = 8'h3C; {7'd105, 3'd7}: data = 8'h00;

		// l (108)
		{7'd108, 3'd0}: data = 8'h38; {7'd108, 3'd1}: data = 8'h18;
		{7'd108, 3'd2}: data = 8'h18; {7'd108, 3'd3}: data = 8'h18;
		{7'd108, 3'd4}: data = 8'h18; {7'd108, 3'd5}: data = 8'h18;
		{7'd108, 3'd6}: data = 8'h3C; {7'd108, 3'd7}: data = 8'h00;

		// m (109)
		{7'd109, 3'd0}: data = 8'h00; {7'd109, 3'd1}: data = 8'h00;
		{7'd109, 3'd2}: data = 8'h76; {7'd109, 3'd3}: data = 8'h7F;
		{7'd109, 3'd4}: data = 8'h6B; {7'd109, 3'd5}: data = 8'h6B;
		{7'd109, 3'd6}: data = 8'h63; {7'd109, 3'd7}: data = 8'h00;

		// o (111)
		{7'd111, 3'd0}: data = 8'h00; {7'd111, 3'd1}: data = 8'h00;
		{7'd111, 3'd2}: data = 8'h3C; {7'd111, 3'd3}: data = 8'h66;
		{7'd111, 3'd4}: data = 8'h66; {7'd111, 3'd5}: data = 8'h66;
		{7'd111, 3'd6}: data = 8'h3C; {7'd111, 3'd7}: data = 8'h00;

		// p (112)
		{7'd112, 3'd0}: data = 8'h00; {7'd112, 3'd1}: data = 8'h00;
		{7'd112, 3'd2}: data = 8'h7C; {7'd112, 3'd3}: data = 8'h66;
		{7'd112, 3'd4}: data = 8'h66; {7'd112, 3'd5}: data = 8'h7C;
		{7'd112, 3'd6}: data = 8'h60; {7'd112, 3'd7}: data = 8'h60;

		// r (114)
		{7'd114, 3'd0}: data = 8'h00; {7'd114, 3'd1}: data = 8'h00;
		{7'd114, 3'd2}: data = 8'h6C; {7'd114, 3'd3}: data = 8'h76;
		{7'd114, 3'd4}: data = 8'h60; {7'd114, 3'd5}: data = 8'h60;
		{7'd114, 3'd6}: data = 8'h60; {7'd114, 3'd7}: data = 8'h00;

		// s (115)
		{7'd115, 3'd0}: data = 8'h00; {7'd115, 3'd1}: data = 8'h00;
		{7'd115, 3'd2}: data = 8'h3E; {7'd115, 3'd3}: data = 8'h60;
		{7'd115, 3'd4}: data = 8'h3C; {7'd115, 3'd5}: data = 8'h06;
		{7'd115, 3'd6}: data = 8'h7C; {7'd115, 3'd7}: data = 8'h00;

		// t (116)
		{7'd116, 3'd0}: data = 8'h18; {7'd116, 3'd1}: data = 8'h18;
		{7'd116, 3'd2}: data = 8'h7E; {7'd116, 3'd3}: data = 8'h18;
		{7'd116, 3'd4}: data = 8'h18; {7'd116, 3'd5}: data = 8'h18;
		{7'd116, 3'd6}: data = 8'h0E; {7'd116, 3'd7}: data = 8'h00;

		// u (117)
		{7'd117, 3'd0}: data = 8'h00; {7'd117, 3'd1}: data = 8'h00;
		{7'd117, 3'd2}: data = 8'h66; {7'd117, 3'd3}: data = 8'h66;
		{7'd117, 3'd4}: data = 8'h66; {7'd117, 3'd5}: data = 8'h66;
		{7'd117, 3'd6}: data = 8'h3E; {7'd117, 3'd7}: data = 8'h00;

		// y (121)
		{7'd121, 3'd0}: data = 8'h00; {7'd121, 3'd1}: data = 8'h00;
		{7'd121, 3'd2}: data = 8'h66; {7'd121, 3'd3}: data = 8'h66;
		{7'd121, 3'd4}: data = 8'h3E; {7'd121, 3'd5}: data = 8'h06;
		{7'd121, 3'd6}: data = 8'h3C; {7'd121, 3'd7}: data = 8'h00;

		// z (122)
		{7'd122, 3'd0}: data = 8'h00; {7'd122, 3'd1}: data = 8'h00;
		{7'd122, 3'd2}: data = 8'h7E; {7'd122, 3'd3}: data = 8'h0C;
		{7'd122, 3'd4}: data = 8'h18; {7'd122, 3'd5}: data = 8'h30;
		{7'd122, 3'd6}: data = 8'h7E; {7'd122, 3'd7}: data = 8'h00;

		// G (71)
		{7'd71, 3'd0}: data = 8'h3C; {7'd71, 3'd1}: data = 8'h66;
		{7'd71, 3'd2}: data = 8'h60; {7'd71, 3'd3}: data = 8'h6E;
		{7'd71, 3'd4}: data = 8'h66; {7'd71, 3'd5}: data = 8'h66;
		{7'd71, 3'd6}: data = 8'h3E; {7'd71, 3'd7}: data = 8'h00;

		// J (74)
		{7'd74, 3'd0}: data = 8'h06; {7'd74, 3'd1}: data = 8'h06;
		{7'd74, 3'd2}: data = 8'h06; {7'd74, 3'd3}: data = 8'h06;
		{7'd74, 3'd4}: data = 8'h66; {7'd74, 3'd5}: data = 8'h66;
		{7'd74, 3'd6}: data = 8'h3C; {7'd74, 3'd7}: data = 8'h00;

		// K (75)
		{7'd75, 3'd0}: data = 8'h66; {7'd75, 3'd1}: data = 8'h6C;
		{7'd75, 3'd2}: data = 8'h78; {7'd75, 3'd3}: data = 8'h70;
		{7'd75, 3'd4}: data = 8'h78; {7'd75, 3'd5}: data = 8'h6C;
		{7'd75, 3'd6}: data = 8'h66; {7'd75, 3'd7}: data = 8'h00;

		// Q (81)
		{7'd81, 3'd0}: data = 8'h3C; {7'd81, 3'd1}: data = 8'h66;
		{7'd81, 3'd2}: data = 8'h66; {7'd81, 3'd3}: data = 8'h66;
		{7'd81, 3'd4}: data = 8'h6A; {7'd81, 3'd5}: data = 8'h6C;
		{7'd81, 3'd6}: data = 8'h36; {7'd81, 3'd7}: data = 8'h00;

		// U (85)
		{7'd85, 3'd0}: data = 8'h66; {7'd85, 3'd1}: data = 8'h66;
		{7'd85, 3'd2}: data = 8'h66; {7'd85, 3'd3}: data = 8'h66;
		{7'd85, 3'd4}: data = 8'h66; {7'd85, 3'd5}: data = 8'h66;
		{7'd85, 3'd6}: data = 8'h3C; {7'd85, 3'd7}: data = 8'h00;

		// X (88)
		{7'd88, 3'd0}: data = 8'h66; {7'd88, 3'd1}: data = 8'h66;
		{7'd88, 3'd2}: data = 8'h3C; {7'd88, 3'd3}: data = 8'h18;
		{7'd88, 3'd4}: data = 8'h3C; {7'd88, 3'd5}: data = 8'h66;
		{7'd88, 3'd6}: data = 8'h66; {7'd88, 3'd7}: data = 8'h00;

		// Z (90)
		{7'd90, 3'd0}: data = 8'h7E; {7'd90, 3'd1}: data = 8'h06;
		{7'd90, 3'd2}: data = 8'h0C; {7'd90, 3'd3}: data = 8'h18;
		{7'd90, 3'd4}: data = 8'h30; {7'd90, 3'd5}: data = 8'h60;
		{7'd90, 3'd6}: data = 8'h7E; {7'd90, 3'd7}: data = 8'h00;

		// b (98)
		{7'd98, 3'd0}: data = 8'h60; {7'd98, 3'd1}: data = 8'h60;
		{7'd98, 3'd2}: data = 8'h7C; {7'd98, 3'd3}: data = 8'h66;
		{7'd98, 3'd4}: data = 8'h66; {7'd98, 3'd5}: data = 8'h66;
		{7'd98, 3'd6}: data = 8'h7C; {7'd98, 3'd7}: data = 8'h00;

		// c (99)
		{7'd99, 3'd0}: data = 8'h00; {7'd99, 3'd1}: data = 8'h00;
		{7'd99, 3'd2}: data = 8'h3C; {7'd99, 3'd3}: data = 8'h60;
		{7'd99, 3'd4}: data = 8'h60; {7'd99, 3'd5}: data = 8'h60;
		{7'd99, 3'd6}: data = 8'h3C; {7'd99, 3'd7}: data = 8'h00;

		// f (102)
		{7'd102, 3'd0}: data = 8'h1C; {7'd102, 3'd1}: data = 8'h30;
		{7'd102, 3'd2}: data = 8'h7C; {7'd102, 3'd3}: data = 8'h30;
		{7'd102, 3'd4}: data = 8'h30; {7'd102, 3'd5}: data = 8'h30;
		{7'd102, 3'd6}: data = 8'h30; {7'd102, 3'd7}: data = 8'h00;

		// g (103)
		{7'd103, 3'd0}: data = 8'h00; {7'd103, 3'd1}: data = 8'h00;
		{7'd103, 3'd2}: data = 8'h3E; {7'd103, 3'd3}: data = 8'h66;
		{7'd103, 3'd4}: data = 8'h66; {7'd103, 3'd5}: data = 8'h3E;
		{7'd103, 3'd6}: data = 8'h06; {7'd103, 3'd7}: data = 8'h3C;

		// k (107)
		{7'd107, 3'd0}: data = 8'h60; {7'd107, 3'd1}: data = 8'h60;
		{7'd107, 3'd2}: data = 8'h66; {7'd107, 3'd3}: data = 8'h6C;
		{7'd107, 3'd4}: data = 8'h78; {7'd107, 3'd5}: data = 8'h6C;
		{7'd107, 3'd6}: data = 8'h66; {7'd107, 3'd7}: data = 8'h00;

		// n (110)
		{7'd110, 3'd0}: data = 8'h00; {7'd110, 3'd1}: data = 8'h00;
		{7'd110, 3'd2}: data = 8'h7C; {7'd110, 3'd3}: data = 8'h66;
		{7'd110, 3'd4}: data = 8'h66; {7'd110, 3'd5}: data = 8'h66;
		{7'd110, 3'd6}: data = 8'h66; {7'd110, 3'd7}: data = 8'h00;

		// v (118)
		{7'd118, 3'd0}: data = 8'h00; {7'd118, 3'd1}: data = 8'h00;
		{7'd118, 3'd2}: data = 8'h66; {7'd118, 3'd3}: data = 8'h66;
		{7'd118, 3'd4}: data = 8'h66; {7'd118, 3'd5}: data = 8'h3C;
		{7'd118, 3'd6}: data = 8'h18; {7'd118, 3'd7}: data = 8'h00;

		// w (119)
		{7'd119, 3'd0}: data = 8'h00; {7'd119, 3'd1}: data = 8'h00;
		{7'd119, 3'd2}: data = 8'h63; {7'd119, 3'd3}: data = 8'h6B;
		{7'd119, 3'd4}: data = 8'h7F; {7'd119, 3'd5}: data = 8'h36;
		{7'd119, 3'd6}: data = 8'h22; {7'd119, 3'd7}: data = 8'h00;

		// x (120)
		{7'd120, 3'd0}: data = 8'h00; {7'd120, 3'd1}: data = 8'h00;
		{7'd120, 3'd2}: data = 8'h66; {7'd120, 3'd3}: data = 8'h3C;
		{7'd120, 3'd4}: data = 8'h18; {7'd120, 3'd5}: data = 8'h3C;
		{7'd120, 3'd6}: data = 8'h66; {7'd120, 3'd7}: data = 8'h00;

		default: data = 8'h00;
	endcase
end

endmodule
