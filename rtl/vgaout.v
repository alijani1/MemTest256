// Text-based VGA display for MemTest256
// 720x480, 8x8 font 2x wide 4x tall = 16x32 char + 8px padding = 40px/row
// 45 chars/line, 12 rows

module vgaout(
	input clk,
	input [3:0] mem_size,
	input [11:0] slot1_freq, slot2_freq,
	input [31:0] slot1_pass, slot2_pass,
	input [5:0] slot1_pos, slot2_pos,
	input [31:0] slot1_total_pass, slot2_total_pass,
	input [31:0] slot1_total_fail, slot2_total_fail,
	input [9:0] slot1_time_d, slot2_time_d,
	input [4:0] slot1_time_h, slot2_time_h,
	input [5:0] slot1_time_m, slot2_time_m,
	input [5:0] slot1_time_s, slot2_time_s,
	input [5:0] bg,
	input [1:0] test_mode,
	input sdram2_detected, active_slot,
	input [1:0] chip,
	input [15:0] watchdog_count1, watchdog_count2,
	input watchdog_type1, watchdog_type2,
	input s1_ever_tested, s2_ever_tested,
	// History: 6 entries per slot
	input [11:0] s1_hfreq0,s1_hfreq1,s1_hfreq2,s1_hfreq3,s1_hfreq4,s1_hfreq5,
	input [11:0] s2_hfreq0,s2_hfreq1,s2_hfreq2,s2_hfreq3,s2_hfreq4,s2_hfreq5,
	input [15:0] s1_hpass0,s1_hpass1,s1_hpass2,s1_hpass3,s1_hpass4,s1_hpass5,
	input [15:0] s2_hpass0,s2_hpass1,s2_hpass2,s2_hpass3,s2_hpass4,s2_hpass5,
	input [2:0] s1_hcount, s2_hcount,
	input probe_phase, txn_testing, auto_mode, search_up,
	input [9:0] total_days, input [4:0] total_hours, input [5:0] total_mins, total_secs,
	output reg hs, vs, de,
	output reg [1:0] b, r, g
);

localparam HSYNC_BEG=12'd0,HSYNC_END=12'd62,HSCRN_BEG=12'd128,HSCRN_END=12'd848,HMAX=12'd858;
localparam VSYNC_BEG=12'd0,VSYNC_END=12'd6,VSCRN_BEG=12'd30,VSCRN_END=12'd510,VMAX=12'd525;
localparam CHAR_W=16, CHAR_H=40, COLS=45, ROWS=12; // 32px char + 8px padding, 12 rows

reg [11:0] hcount,vcount;
reg hscr,vscr;
reg [5:0] char_x,pixel_y,frame_cnt;
reg [3:0] char_y,pixel_x;

wire [2:0] font_col=pixel_x[3:1], font_row=pixel_y[4:2];
wire [6:0] char_code; wire [7:0] font_pixels; wire [5:0] text_color;

font_rom font(.char_code(char_code),.row(font_row),.pixels(font_pixels));
wire font_pixel = font_pixels[7-font_col];

wire [27:0] s1b28, s2b28, s1tp28, s2tp28;
wire [19:0] s1tf,s2tf;
wire [19:0] s1th_bcd,s2th_bcd,s1tm_bcd,s2tm_bcd,s1ts_bcd,s2ts_bcd;
wire [19:0] wdog1_bcd, wdog2_bcd;

bin2bcd24 bp1(.bin(slot1_pass[23:0]),.bcd(s1b28));
bin2bcd24 bp2(.bin(slot2_pass[23:0]),.bcd(s2b28));
bin2bcd24 bp3(.bin(slot1_total_pass[23:0]),.bcd(s1tp28));
bin2bcd24 bp4(.bin(slot2_total_pass[23:0]),.bcd(s2tp28));
bin2bcd b5(.bin(slot1_total_fail[15:0]),.bcd(s1tf));
bin2bcd b6(.bin(slot2_total_fail[15:0]),.bcd(s2tf));
wire [19:0] s1td_bcd,s2td_bcd;
bin2bcd b6d(.bin({6'd0,slot1_time_d}),.bcd(s1td_bcd));
bin2bcd b6e(.bin({6'd0,slot2_time_d}),.bcd(s2td_bcd));
bin2bcd b7(.bin({11'd0,slot1_time_h}),.bcd(s1th_bcd));
bin2bcd b8(.bin({10'd0,slot1_time_m}),.bcd(s1tm_bcd));
bin2bcd b9(.bin({10'd0,slot1_time_s}),.bcd(s1ts_bcd));
bin2bcd b10(.bin({11'd0,slot2_time_h}),.bcd(s2th_bcd));
bin2bcd b11x(.bin({10'd0,slot2_time_m}),.bcd(s2tm_bcd));
bin2bcd b12(.bin({10'd0,slot2_time_s}),.bcd(s2ts_bcd));
// Total time BCD
wire [19:0] tt_d_bcd, tt_h_bcd, tt_m_bcd, tt_s_bcd;
bin2bcd btd(.bin({6'd0,total_days}),.bcd(tt_d_bcd));
bin2bcd bth(.bin({11'd0,total_hours}),.bcd(tt_h_bcd));
bin2bcd btm(.bin({10'd0,total_mins}),.bcd(tt_m_bcd));
bin2bcd bts(.bin({10'd0,total_secs}),.bcd(tt_s_bcd));
bin2bcd b13(.bin(watchdog_count1),.bcd(wdog1_bcd));
bin2bcd b14(.bin(watchdog_count2),.bcd(wdog2_bcd));

// History pass BCD converters (use 16-bit, 4 digit display)
wire [19:0] s1_hp_bcd[6], s2_hp_bcd[6];
bin2bcd bh0(.bin(s1_hpass0),.bcd(s1_hp_bcd[0])); bin2bcd bh1(.bin(s1_hpass1),.bcd(s1_hp_bcd[1]));
bin2bcd bh2(.bin(s1_hpass2),.bcd(s1_hp_bcd[2])); bin2bcd bh3(.bin(s1_hpass3),.bcd(s1_hp_bcd[3]));
bin2bcd bh4(.bin(s1_hpass4),.bcd(s1_hp_bcd[4])); bin2bcd bh5(.bin(s1_hpass5),.bcd(s1_hp_bcd[5]));
bin2bcd bh6(.bin(s2_hpass0),.bcd(s2_hp_bcd[0])); bin2bcd bh7(.bin(s2_hpass1),.bcd(s2_hp_bcd[1]));
bin2bcd bh8(.bin(s2_hpass2),.bcd(s2_hp_bcd[2])); bin2bcd bh9(.bin(s2_hpass3),.bcd(s2_hp_bcd[3]));
bin2bcd bh10(.bin(s2_hpass4),.bcd(s2_hp_bcd[4])); bin2bcd bh11(.bin(s2_hpass5),.bcd(s2_hp_bcd[5]));

// Pack history freq arrays for layout module
wire [11:0] s1_hf[6]; wire [11:0] s2_hf[6];
assign s1_hf[0]=s1_hfreq0; assign s1_hf[1]=s1_hfreq1; assign s1_hf[2]=s1_hfreq2;
assign s1_hf[3]=s1_hfreq3; assign s1_hf[4]=s1_hfreq4; assign s1_hf[5]=s1_hfreq5;
assign s2_hf[0]=s2_hfreq0; assign s2_hf[1]=s2_hfreq1; assign s2_hf[2]=s2_hfreq2;
assign s2_hf[3]=s2_hfreq3; assign s2_hf[4]=s2_hfreq4; assign s2_hf[5]=s2_hfreq5;

text_layout layout(
	.cx(char_x),.cy(char_y),.mem_size(mem_size),
	.s1f(slot1_freq),.s2f(slot2_freq),
	.s1b(s1b28),.s2b(s2b28),.s1pnz(slot1_pass!=0),.s2pnz(slot2_pass!=0),
	.s1low(slot1_pos>42 && !search_up),.s2low(slot2_pos>42 && !search_up),
	.s1tp(s1tp28),.s2tp(s2tp28),.s1tf(s1tf),.s2tf(s2tf),
	.s1_tested(s1_ever_tested),.s2_tested(s2_ever_tested),
	.s1th(s1th_bcd[7:0]),.s1tm(s1tm_bcd[7:0]),.s1ts(s1ts_bcd[7:0]),
	.s2th(s2th_bcd[7:0]),.s2tm(s2tm_bcd[7:0]),.s2ts(s2ts_bcd[7:0]),
	.tm(test_mode),.det(sdram2_detected),.act(active_slot),.chip(chip),
	.wdog1_bcd(wdog1_bcd),.wdog2_bcd(wdog2_bcd),.wt1(watchdog_type1),.wt2(watchdog_type2),
	.probe(probe_phase),.testing(txn_testing),.amode(auto_mode),
	.s1td(s1td_bcd[7:0]),.s2td(s2td_bcd[7:0]),
	.tt_d(tt_d_bcd[7:0]),.tt_h(tt_h_bcd[7:0]),.tt_m(tt_m_bcd[7:0]),.tt_s(tt_s_bcd[7:0]),
	.spin(frame_cnt[4:3]),.blink(frame_cnt[3]),
	// History
	.s1_hf0(s1_hf[0]),.s1_hf1(s1_hf[1]),.s1_hf2(s1_hf[2]),
	.s1_hf3(s1_hf[3]),.s1_hf4(s1_hf[4]),.s1_hf5(s1_hf[5]),
	.s2_hf0(s2_hf[0]),.s2_hf1(s2_hf[1]),.s2_hf2(s2_hf[2]),
	.s2_hf3(s2_hf[3]),.s2_hf4(s2_hf[4]),.s2_hf5(s2_hf[5]),
	.s1_hp0(s1_hp_bcd[0]),.s1_hp1(s1_hp_bcd[1]),.s1_hp2(s1_hp_bcd[2]),
	.s1_hp3(s1_hp_bcd[3]),.s1_hp4(s1_hp_bcd[4]),.s1_hp5(s1_hp_bcd[5]),
	.s2_hp0(s2_hp_bcd[0]),.s2_hp1(s2_hp_bcd[1]),.s2_hp2(s2_hp_bcd[2]),
	.s2_hp3(s2_hp_bcd[3]),.s2_hp4(s2_hp_bcd[4]),.s2_hp5(s2_hp_bcd[5]),
	.s1_hcnt(s1_hcount),.s2_hcnt(s2_hcount),
	.ch(char_code),.co(text_color)
);

wire pix = font_pixel && (char_x<COLS) && (char_y<ROWS) && (pixel_y<32);

always @(posedge clk) begin
	if(hcount==HMAX) hcount<=0; else hcount<=hcount+1'd1;
	if(hcount==HSCRN_END) begin hscr<=0; de<=0; end
	else if(hcount==HSCRN_BEG) begin hscr<=1; de<=vscr; end
	if(hcount==HSYNC_BEG) hs<=0; else if(hcount==HSYNC_END) hs<=1;
	if(hcount==HSCRN_BEG) begin char_x<=0; pixel_x<=0; end
	else if(hscr) begin
		if(pixel_x==CHAR_W-1) begin pixel_x<=0; char_x<=char_x+1'd1; end
		else pixel_x<=pixel_x+1'd1;
	end
	if(hcount==HSYNC_BEG) begin
		if(vcount==VMAX) begin vcount<=0; frame_cnt<=frame_cnt+1'd1; end
		else vcount<=vcount+1'd1;
		if(vcount==VSCRN_END) vscr<=0; else if(vcount==VSCRN_BEG) vscr<=1;
		if(vcount==VSYNC_BEG) vs<=1; else if(vcount==VSYNC_END) vs<=0;
		if(vcount==VSCRN_BEG) begin char_y<=0; pixel_y<=0; end
		else begin
			if(pixel_y==CHAR_H-1) begin pixel_y<=0; char_y<=char_y+1'd1; end
			else pixel_y<=pixel_y+1'd1;
		end
	end
	{g,r,b} <= pix ? text_color : (hscr&vscr) ? bg : 6'b000000;
end
endmodule

//=============================================================================
module text_layout(
	input [5:0] cx, input [3:0] cy,
	input [3:0] mem_size,
	input [11:0] s1f,s2f,
	input [27:0] s1b,s2b, input s1pnz,s2pnz, s1low,s2low,
	input [27:0] s1tp,s2tp, input [19:0] s1tf,s2tf,
	input s1_tested, s2_tested,
	input [7:0] s1th,s1tm,s1ts, s2th,s2tm,s2ts,
	input [1:0] tm, input det,act, input [1:0] chip,
	input [19:0] wdog1_bcd, wdog2_bcd, input wt1, wt2,
	input probe, testing, amode,
	input [7:0] s1td, s2td, // per-slot days BCD
	input [7:0] tt_d, tt_h, tt_m, tt_s, // total time D:H:M:S BCD
	input [1:0] spin, input blink,
	// History per slot: 6 entries
	input [11:0] s1_hf0,s1_hf1,s1_hf2,s1_hf3,s1_hf4,s1_hf5,
	input [11:0] s2_hf0,s2_hf1,s2_hf2,s2_hf3,s2_hf4,s2_hf5,
	input [19:0] s1_hp0,s1_hp1,s1_hp2,s1_hp3,s1_hp4,s1_hp5,
	input [19:0] s2_hp0,s2_hp1,s2_hp2,s2_hp3,s2_hp4,s2_hp5,
	input [2:0] s1_hcnt, s2_hcnt,
	output reg [6:0] ch, output reg [5:0] co
);

function [6:0] dc; input [3:0] v; dc=7'd48+{3'd0,v}; endfunction
function [6:0] fd; input [11:0] f; input [1:0] p;
	case(p) 0:fd=(f[11:8]!=0)?dc(f[11:8]):7'd32; 1:fd=(f[11:4]!=0)?dc(f[7:4]):7'd32; 2:fd=dc(f[3:0]); default:fd=7'd32; endcase
endfunction
function [6:0] bd7; input [27:0] b; input [2:0] p;
	reg [2:0] s; begin
		if(b[27:24]!=0) s=0; else if(b[23:20]!=0) s=1; else if(b[19:16]!=0) s=2;
		else if(b[15:12]!=0) s=3; else if(b[11:8]!=0) s=4; else if(b[7:4]!=0) s=5; else s=6;
		case(p+s) 0:bd7=dc(b[27:24]);1:bd7=dc(b[23:20]);2:bd7=dc(b[19:16]);
		3:bd7=dc(b[15:12]);4:bd7=dc(b[11:8]);5:bd7=dc(b[7:4]);6:bd7=dc(b[3:0]); default:bd7=7'd32; endcase
	end
endfunction
function [6:0] bd; input [19:0] b; input [2:0] p;
	reg [2:0] s; begin
		if(b[19:16]!=0) s=0; else if(b[15:12]!=0) s=1;
		else if(b[11:8]!=0) s=2; else if(b[7:4]!=0) s=3; else s=4;
		case(p+s) 0:bd=dc(b[19:16]);1:bd=dc(b[15:12]);2:bd=dc(b[11:8]);3:bd=dc(b[7:4]);4:bd=dc(b[3:0]); default:bd=7'd32; endcase
	end
endfunction

function [6:0] sp; input [1:0] p;
	case(p) 0:sp="-";1:sp=7'd92;2:sp="|";3:sp="/"; endcase
endfunction

// History column: get freq digit for column n (0-5) at digit position p (0-2)
// Columns start at cx=13, each 4 chars wide
function [11:0] get_hfreq;
	input [2:0] col; input is_slot2;
	begin
		if(!is_slot2) case(col)
			0:get_hfreq=s1_hf0;1:get_hfreq=s1_hf1;2:get_hfreq=s1_hf2;
			3:get_hfreq=s1_hf3;4:get_hfreq=s1_hf4;5:get_hfreq=s1_hf5;
			default:get_hfreq=12'd0;
		endcase
		else case(col)
			0:get_hfreq=s2_hf0;1:get_hfreq=s2_hf1;2:get_hfreq=s2_hf2;
			3:get_hfreq=s2_hf3;4:get_hfreq=s2_hf4;5:get_hfreq=s2_hf5;
			default:get_hfreq=12'd0;
		endcase
	end
endfunction

function [19:0] get_hpass;
	input [2:0] col; input is_slot2;
	begin
		if(!is_slot2) case(col)
			0:get_hpass=s1_hp0;1:get_hpass=s1_hp1;2:get_hpass=s1_hp2;
			3:get_hpass=s1_hp3;4:get_hpass=s1_hp4;5:get_hpass=s1_hp5;
			default:get_hpass=20'd0;
		endcase
		else case(col)
			0:get_hpass=s2_hp0;1:get_hpass=s2_hp1;2:get_hpass=s2_hp2;
			3:get_hpass=s2_hp3;4:get_hpass=s2_hp4;5:get_hpass=s2_hp5;
			default:get_hpass=20'd0;
		endcase
	end
endfunction

localparam W=6'b111111, C=6'b110011, Y=6'b111100, G=6'b110000, R=6'b001100, M=6'b001111, O=6'b011100;

// History layout: "Slot N: Mhz NNN NNN NNN NNN NNN NNN|Fail"
// Positions:       0-12    13-15 17-19 21-23 25-27 29-31 33-35 36(|) 37-40(Fail)
// "Passed:     NNNN NNNN NNNN NNNN NNNN NNNN|NNNN"
// Positions:   0-7      13-16 17-20 21-24 25-28 29-32 33-36 37(|) 38-41

// Compute which history column cx falls in (for freq row)
// Freq columns: col0=13-15, col1=17-19, col2=21-23, col3=25-27, col4=29-31, col5=33-35
// Each column: start = 13 + col*4, width = 3 digits

always @(*) begin
	ch=7'd32; co=W;

	if(probe) begin
		case(cy)
		0: begin co=C; case(cx)
			0:ch="M";1:ch="E";2:ch="M";3:ch="T";4:ch="E";5:ch="S";6:ch="T";7:ch="2";8:ch="5";9:ch="6";
			default:ch=7'd32; endcase end
		2: begin co=Y; case(cx)
			0:ch="D";1:ch="e";2:ch="t";3:ch="e";4:ch="c";5:ch="t";6:ch="i";7:ch="n";8:ch="g";
			10:ch="M";11:ch="e";12:ch="m";13:ch="o";14:ch="r";15:ch="y";16:ch=".";17:ch=".";18:ch=".";
			default:ch=7'd32; endcase end
		default: begin ch=7'd32; co=W; end
		endcase
	end else begin
		case(cy)

		// Row 0: Memory cyan, Time right-justified
		0: begin
			co = (cx <= 12) ? C : W;
			case(cx)
			0:ch="M";1:ch="e";2:ch="m";3:ch="o";4:ch="r";5:ch="y";6:ch=":";
			8:case(mem_size) 4'd3:ch="1";4'd4:ch="2";default:ch=7'd32; endcase
			9:case(mem_size) 4'd1:ch="3";4'd2:ch="6";4'd3:ch="2";4'd4:ch="5";default:ch=7'd32; endcase
			10:case(mem_size) 4'd1:ch="2";4'd2:ch="4";4'd3:ch="8";4'd4:ch="6";default:ch="0"; endcase
			11:ch="M";12:ch="B";
			// Total time right-justified ending at 44
			// No hours: "Time:MM:SS" (10 chars, pos 35-44)
			// Hours:    "Time:H:MM:SS" (12 chars, pos 33-44)
			// Days:     "D:HH:MM:SS" (10+ chars)
			32:ch=(tt_h!=0||tt_d!=0)?"T":7'd32;
			33:ch=(tt_h!=0||tt_d!=0)?"i":7'd32;
			34:ch=(tt_h!=0||tt_d!=0)?"m":"T";
			35:ch=(tt_h!=0||tt_d!=0)?"e":"i";
			36:ch=(tt_h!=0||tt_d!=0)?":":"m";
			37:ch=(tt_h!=0||tt_d!=0)?7'd32:"e";
			38:ch=(tt_h!=0||tt_d!=0)?dc(tt_h[3:0]):":";
			39:ch=(tt_h!=0||tt_d!=0)?":":7'd32;
			40:ch=dc(tt_m[7:4]);
			41:ch=dc(tt_m[3:0]);
			42:ch=":";
			43:ch=dc(tt_s[7:4]);
			44:ch=dc(tt_s[3:0]);
			default:ch=7'd32; endcase end

		// Row 1: Test Mode magenta, Chip yellow
		1: begin
			co = (cx <= 20) ? M : Y;
			case(cx)
			0:ch="T";1:ch="e";2:ch="s";3:ch="t";5:ch="M";6:ch="o";7:ch="d";8:ch="e";9:ch=":";
			11:case(tm) 2'd0:ch="B";default:ch="S"; endcase
			12:case(tm) 2'd0:ch="o";default:ch="l"; endcase
			13:case(tm) 2'd0:ch="t";default:ch="o"; endcase
			14:case(tm) 2'd0:ch="h";default:ch="t"; endcase
			16:case(tm) 2'd0:ch="S";2'd1:ch="1";2'd2:ch="2";default:ch=7'd32; endcase
			17:case(tm) 2'd0:ch="l";default:ch=7'd32; endcase
			18:case(tm) 2'd0:ch="o";default:ch=7'd32; endcase
			19:case(tm) 2'd0:ch="t";default:ch=7'd32; endcase
			20:case(tm) 2'd0:ch="s";default:ch=7'd32; endcase
			23:ch="C";24:ch="h";25:ch="i";26:ch="p";27:ch=":";
			29:case(chip) 2'd0:ch="B";default:ch=7'd32; endcase
			30:case(chip) 2'd0:ch="o";2'd1:ch="1";2'd2:ch="2";default:ch=7'd32; endcase
			31:case(chip) 2'd0:ch="t";default:ch=7'd32; endcase
			32:case(chip) 2'd0:ch="h";default:ch=7'd32; endcase
			default:ch=7'd32; endcase end

		// Row 2: separator with "Current Test" label starting at pos 4
		2: begin co=Y;
			if(cx<4) ch="-";
			else case(cx)
				5:ch="C";6:ch="u";7:ch="r";8:ch="r";9:ch="e";10:ch="n";11:ch="t";
				13:ch="T";14:ch="e";15:ch="s";16:ch="t";
				default:ch=(cx>=18&&cx<45)?"-":7'd32;
			endcase
		end

		// Row 3: Slot 1
		3: begin
			if(tm==2'd2) begin co=W; case(cx)
				0:ch="S";1:ch="l";2:ch="o";3:ch="t";5:ch="1";6:ch=":";
				8:ch="S";9:ch="k";10:ch="i";11:ch="p";12:ch="p";13:ch="e";14:ch="d";15:ch=".";
				17:ch="P";18:ch="r";19:ch="e";20:ch="s";21:ch="s";
				23:ch="S";
				25:ch="t";26:ch="o";
				28:ch="c";29:ch="h";30:ch="a";31:ch="n";32:ch="g";33:ch="e";
				35:ch="T";36:ch="e";37:ch="s";38:ch="t";
				40:ch="M";41:ch="o";42:ch="d";43:ch="e";
				default:ch=7'd32; endcase end
			else if(!s1_tested) begin co=C; case(cx)
				0:ch="S";1:ch="l";2:ch="o";3:ch="t";5:ch="1";6:ch=":";
				default:ch=7'd32; endcase end
			else begin
				if(s1low) co=s1pnz?O:R;
				else if(cx>=8&&cx<=13) begin
					if(testing && act==0 && !s1pnz) co=blink?Y:6'b000000;
					else if(testing && act==0 && s1pnz) co=blink?G:6'b000000;
					else co=s1pnz?G:R;
				end else if(cx>=15&&cx<=26) co=s1pnz?G:R;
				else co=s1pnz?G:C;
				case(cx)
				0:ch="S";1:ch="l";2:ch="o";3:ch="t";5:ch="1";6:ch=":";
				8:ch=fd(s1f,0);9:ch=fd(s1f,1);10:ch=fd(s1f,2);11:ch="M";12:ch="h";13:ch="z";
				15:ch=(testing&&act==0&&!s1pnz)?7'd32:(s1pnz?"P":"F");
				16:ch=(testing&&act==0&&!s1pnz)?7'd32:(s1pnz?"a":"a");
				17:ch=(testing&&act==0&&!s1pnz)?7'd32:(s1pnz?"s":"i");
				18:ch=(testing&&act==0&&!s1pnz)?7'd32:(s1pnz?"s":"l");
				19:ch=(testing&&act==0&&!s1pnz)?7'd32:(s1pnz?":":"e");
				20:ch=(testing&&act==0&&!s1pnz)?7'd32:(s1pnz?bd7(s1b,0):"d");
				21:ch=s1pnz?bd7(s1b,1):7'd32;22:ch=s1pnz?bd7(s1b,2):7'd32;
				23:ch=s1pnz?bd7(s1b,3):7'd32;24:ch=s1pnz?bd7(s1b,4):7'd32;
				25:ch=s1pnz?bd7(s1b,5):7'd32;26:ch=s1pnz?bd7(s1b,6):7'd32;
				// Time: "Time:Dd H:MM" when days>0, "Time:H:MM:SS" when hours>0, "Time:M:SS" otherwise
				28:ch="T";29:ch="i";30:ch="m";31:ch="e";32:ch=":";
				33:ch=(s1td!=0)?dc(s1td[3:0]):(s1th!=0)?dc(s1th[3:0]):(s1tm[7:4]!=0)?dc(s1tm[7:4]):7'd32;
				34:ch=(s1td!=0)?"d":(s1th!=0)?":":dc(s1tm[3:0]);
				35:ch=(s1td!=0)?dc(s1th[3:0]):(s1th!=0)?dc(s1tm[7:4]):":";
				36:ch=(s1td!=0)?":":(s1th!=0)?dc(s1tm[3:0]):dc(s1ts[7:4]);
				37:ch=(s1td!=0)?dc(s1tm[7:4]):(s1th!=0)?":":dc(s1ts[3:0]);
				38:ch=(s1td!=0)?dc(s1tm[3:0]):(s1th!=0)?dc(s1ts[7:4]):7'd32;
				39:ch=(s1td!=0)?7'd32:(s1th!=0)?dc(s1ts[3:0]):7'd32;
				44:ch=(act==0)?sp(spin):7'd32;
				default:ch=7'd32; endcase
			end end

		// Row 4: Slot 2
		4: begin
			if(tm==2'd1 && !det) begin ch=7'd32; co=W; end
			else if(tm==2'd1) begin co=W; case(cx)
				0:ch="S";1:ch="l";2:ch="o";3:ch="t";5:ch="2";6:ch=":";
				8:ch="S";9:ch="k";10:ch="i";11:ch="p";12:ch="p";13:ch="e";14:ch="d";15:ch=".";
				17:ch="P";18:ch="r";19:ch="e";20:ch="s";21:ch="s";
				23:ch="S";
				25:ch="t";26:ch="o";
				28:ch="c";29:ch="h";30:ch="a";31:ch="n";32:ch="g";33:ch="e";
				35:ch="T";36:ch="e";37:ch="s";38:ch="t";
				40:ch="M";41:ch="o";42:ch="d";43:ch="e";
				default:ch=7'd32; endcase end
			else if(!s2_tested) begin co=C; case(cx)
				0:ch="S";1:ch="l";2:ch="o";3:ch="t";5:ch="2";6:ch=":";
				default:ch=7'd32; endcase end
			else begin
				if(s2low) co=s2pnz?O:R;
				else if(cx>=8&&cx<=13) begin
					if(testing && act==1 && !s2pnz) co=blink?Y:6'b000000;
					else if(testing && act==1 && s2pnz) co=blink?G:6'b000000;
					else co=s2pnz?G:R;
				end else if(cx>=15&&cx<=26) co=s2pnz?G:R;
				else co=s2pnz?G:C;
				case(cx)
				0:ch="S";1:ch="l";2:ch="o";3:ch="t";5:ch="2";6:ch=":";
				8:ch=det?fd(s2f,0):"-";9:ch=det?fd(s2f,1):"-";10:ch=det?fd(s2f,2):"-";
				11:ch="M";12:ch="h";13:ch="z";
				15:ch=(testing&&act==1&&!s2pnz)?7'd32:(s2pnz?"P":"F");
				16:ch=(testing&&act==1&&!s2pnz)?7'd32:(s2pnz?"a":"a");
				17:ch=(testing&&act==1&&!s2pnz)?7'd32:(s2pnz?"s":"i");
				18:ch=(testing&&act==1&&!s2pnz)?7'd32:(s2pnz?"s":"l");
				19:ch=(testing&&act==1&&!s2pnz)?7'd32:(s2pnz?":":"e");
				20:ch=(testing&&act==1&&!s2pnz)?7'd32:(s2pnz?(det?bd7(s2b,0):"-"):"d");
				21:ch=s2pnz?(det?bd7(s2b,1):"-"):7'd32;22:ch=s2pnz?(det?bd7(s2b,2):"-"):7'd32;
				23:ch=s2pnz?(det?bd7(s2b,3):"-"):7'd32;24:ch=s2pnz?(det?bd7(s2b,4):"-"):7'd32;
				25:ch=s2pnz?(det?bd7(s2b,5):"-"):7'd32;26:ch=s2pnz?(det?bd7(s2b,6):"-"):7'd32;
				28:ch="T";29:ch="i";30:ch="m";31:ch="e";32:ch=":";
				33:ch=(s2td!=0)?dc(s2td[3:0]):(s2th!=0)?dc(s2th[3:0]):(s2tm[7:4]!=0)?dc(s2tm[7:4]):7'd32;
				34:ch=(s2td!=0)?"d":(s2th!=0)?":":dc(s2tm[3:0]);
				35:ch=(s2td!=0)?dc(s2th[3:0]):(s2th!=0)?dc(s2tm[7:4]):":";
				36:ch=(s2td!=0)?":":(s2th!=0)?dc(s2tm[3:0]):dc(s2ts[7:4]);
				37:ch=(s2td!=0)?dc(s2tm[7:4]):(s2th!=0)?":":dc(s2ts[3:0]);
				38:ch=(s2td!=0)?dc(s2tm[3:0]):(s2th!=0)?dc(s2ts[7:4]):7'd32;
				39:ch=(s2td!=0)?7'd32:(s2th!=0)?dc(s2ts[3:0]):7'd32;
				44:ch=(act==1)?sp(spin):7'd32;
				default:ch=7'd32; endcase
			end end

		// Row 5: separator with "History" label
		5: begin co=Y;
			if(cx<4) ch="-";
			else case(cx)
				5:ch="H";6:ch="i";7:ch="s";8:ch="t";9:ch="o";10:ch="r";11:ch="y";
				default:ch=(cx>=13&&cx<45)?"-":7'd32;
			endcase
		end

		// Row 6: Slot 1 history freq row
		// "Slot 1: Mhz NNN NNN NNN NNN NNN NNN|Fail"
		6: begin
			if(tm==2'd2 || s1_hcnt==0) begin ch=7'd32; co=W; end
			else begin co=W;
				case(cx)
				0:ch="S";1:ch="l";2:ch="o";3:ch="t";5:ch="1";6:ch=":";
				8:ch="M";9:ch="h";10:ch="z";
				// 6 freq columns: positions 12,16,20,24,28,32 (4 chars each: space+3 digits)
				12:ch=(s1_hcnt>0)?fd(get_hfreq(0,0),0):7'd32;
				13:ch=(s1_hcnt>0)?fd(get_hfreq(0,0),1):7'd32;
				14:ch=(s1_hcnt>0)?fd(get_hfreq(0,0),2):7'd32;
				16:ch=(s1_hcnt>1)?fd(get_hfreq(1,0),0):7'd32;
				17:ch=(s1_hcnt>1)?fd(get_hfreq(1,0),1):7'd32;
				18:ch=(s1_hcnt>1)?fd(get_hfreq(1,0),2):7'd32;
				20:ch=(s1_hcnt>2)?fd(get_hfreq(2,0),0):7'd32;
				21:ch=(s1_hcnt>2)?fd(get_hfreq(2,0),1):7'd32;
				22:ch=(s1_hcnt>2)?fd(get_hfreq(2,0),2):7'd32;
				24:ch=(s1_hcnt>3)?fd(get_hfreq(3,0),0):7'd32;
				25:ch=(s1_hcnt>3)?fd(get_hfreq(3,0),1):7'd32;
				26:ch=(s1_hcnt>3)?fd(get_hfreq(3,0),2):7'd32;
				28:ch=(s1_hcnt>4)?fd(get_hfreq(4,0),0):7'd32;
				29:ch=(s1_hcnt>4)?fd(get_hfreq(4,0),1):7'd32;
				30:ch=(s1_hcnt>4)?fd(get_hfreq(4,0),2):7'd32;
				32:ch=(s1_hcnt>5)?fd(get_hfreq(5,0),0):7'd32;
				33:ch=(s1_hcnt>5)?fd(get_hfreq(5,0),1):7'd32;
				34:ch=(s1_hcnt>5)?fd(get_hfreq(5,0),2):7'd32;
				36:ch=7'd32;
				41:ch="F";42:ch="a";43:ch="i";44:ch="l";
				default:ch=7'd32;
				endcase
			end end

		// Row 7: Slot 1 history pass row
		7: begin
			if(tm==2'd2 || s1_hcnt==0) begin ch=7'd32; co=W; end
			else begin
				co=(cx<36)?G:R; // pass numbers green, fail red
				case(cx)
				0:ch="P";1:ch="a";2:ch="s";3:ch="s";4:ch="e";5:ch="d";6:ch=":";
				12:ch=(s1_hcnt>0)?bd(get_hpass(0,0),0):7'd32;
				13:ch=(s1_hcnt>0)?bd(get_hpass(0,0),1):7'd32;
				14:ch=(s1_hcnt>0)?bd(get_hpass(0,0),2):7'd32;
				16:ch=(s1_hcnt>1)?bd(get_hpass(1,0),0):7'd32;
				17:ch=(s1_hcnt>1)?bd(get_hpass(1,0),1):7'd32;
				18:ch=(s1_hcnt>1)?bd(get_hpass(1,0),2):7'd32;
				20:ch=(s1_hcnt>2)?bd(get_hpass(2,0),0):7'd32;
				21:ch=(s1_hcnt>2)?bd(get_hpass(2,0),1):7'd32;
				22:ch=(s1_hcnt>2)?bd(get_hpass(2,0),2):7'd32;
				24:ch=(s1_hcnt>3)?bd(get_hpass(3,0),0):7'd32;
				25:ch=(s1_hcnt>3)?bd(get_hpass(3,0),1):7'd32;
				26:ch=(s1_hcnt>3)?bd(get_hpass(3,0),2):7'd32;
				28:ch=(s1_hcnt>4)?bd(get_hpass(4,0),0):7'd32;
				29:ch=(s1_hcnt>4)?bd(get_hpass(4,0),1):7'd32;
				30:ch=(s1_hcnt>4)?bd(get_hpass(4,0),2):7'd32;
				32:ch=(s1_hcnt>5)?bd(get_hpass(5,0),0):7'd32;
				33:ch=(s1_hcnt>5)?bd(get_hpass(5,0),1):7'd32;
				34:ch=(s1_hcnt>5)?bd(get_hpass(5,0),2):7'd32;
				36:ch=7'd32;
				42:ch=bd(s1tf,0);43:ch=bd(s1tf,1);44:ch=bd(s1tf,2);
				default:ch=7'd32;
				endcase
			end end

		// Row 8: Slot 2 history freq row
		8: begin
			if(tm==2'd1 || s2_hcnt==0) begin ch=7'd32; co=W; end
			else begin co=W;
				case(cx)
				0:ch="S";1:ch="l";2:ch="o";3:ch="t";5:ch="2";6:ch=":";
				8:ch="M";9:ch="h";10:ch="z";
				12:ch=(s2_hcnt>0)?fd(get_hfreq(0,1),0):7'd32;
				13:ch=(s2_hcnt>0)?fd(get_hfreq(0,1),1):7'd32;
				14:ch=(s2_hcnt>0)?fd(get_hfreq(0,1),2):7'd32;
				16:ch=(s2_hcnt>1)?fd(get_hfreq(1,1),0):7'd32;
				17:ch=(s2_hcnt>1)?fd(get_hfreq(1,1),1):7'd32;
				18:ch=(s2_hcnt>1)?fd(get_hfreq(1,1),2):7'd32;
				20:ch=(s2_hcnt>2)?fd(get_hfreq(2,1),0):7'd32;
				21:ch=(s2_hcnt>2)?fd(get_hfreq(2,1),1):7'd32;
				22:ch=(s2_hcnt>2)?fd(get_hfreq(2,1),2):7'd32;
				24:ch=(s2_hcnt>3)?fd(get_hfreq(3,1),0):7'd32;
				25:ch=(s2_hcnt>3)?fd(get_hfreq(3,1),1):7'd32;
				26:ch=(s2_hcnt>3)?fd(get_hfreq(3,1),2):7'd32;
				28:ch=(s2_hcnt>4)?fd(get_hfreq(4,1),0):7'd32;
				29:ch=(s2_hcnt>4)?fd(get_hfreq(4,1),1):7'd32;
				30:ch=(s2_hcnt>4)?fd(get_hfreq(4,1),2):7'd32;
				32:ch=(s2_hcnt>5)?fd(get_hfreq(5,1),0):7'd32;
				33:ch=(s2_hcnt>5)?fd(get_hfreq(5,1),1):7'd32;
				34:ch=(s2_hcnt>5)?fd(get_hfreq(5,1),2):7'd32;
				36:ch=7'd32;
				41:ch="F";42:ch="a";43:ch="i";44:ch="l";
				default:ch=7'd32;
				endcase
			end end

		// Row 9: Slot 2 history pass row
		9: begin
			if(tm==2'd1 || s2_hcnt==0) begin ch=7'd32; co=W; end
			else begin
				co=(cx<36)?G:R;
				case(cx)
				0:ch="P";1:ch="a";2:ch="s";3:ch="s";4:ch="e";5:ch="d";6:ch=":";
				12:ch=(s2_hcnt>0)?bd(get_hpass(0,1),0):7'd32;
				13:ch=(s2_hcnt>0)?bd(get_hpass(0,1),1):7'd32;
				14:ch=(s2_hcnt>0)?bd(get_hpass(0,1),2):7'd32;
				16:ch=(s2_hcnt>1)?bd(get_hpass(1,1),0):7'd32;
				17:ch=(s2_hcnt>1)?bd(get_hpass(1,1),1):7'd32;
				18:ch=(s2_hcnt>1)?bd(get_hpass(1,1),2):7'd32;
				20:ch=(s2_hcnt>2)?bd(get_hpass(2,1),0):7'd32;
				21:ch=(s2_hcnt>2)?bd(get_hpass(2,1),1):7'd32;
				22:ch=(s2_hcnt>2)?bd(get_hpass(2,1),2):7'd32;
				24:ch=(s2_hcnt>3)?bd(get_hpass(3,1),0):7'd32;
				25:ch=(s2_hcnt>3)?bd(get_hpass(3,1),1):7'd32;
				26:ch=(s2_hcnt>3)?bd(get_hpass(3,1),2):7'd32;
				28:ch=(s2_hcnt>4)?bd(get_hpass(4,1),0):7'd32;
				29:ch=(s2_hcnt>4)?bd(get_hpass(4,1),1):7'd32;
				30:ch=(s2_hcnt>4)?bd(get_hpass(4,1),2):7'd32;
				32:ch=(s2_hcnt>5)?bd(get_hpass(5,1),0):7'd32;
				33:ch=(s2_hcnt>5)?bd(get_hpass(5,1),1):7'd32;
				34:ch=(s2_hcnt>5)?bd(get_hpass(5,1),2):7'd32;
				36:ch=7'd32;
				42:ch=bd(s2tf,0);43:ch=bd(s2tf,1);44:ch=bd(s2tf,2);
				default:ch=7'd32;
				endcase
			end end

		// Row 10: Watchdog errors
		10: begin
			if(wdog1_bcd != 0 || wdog2_bcd != 0) begin
				co=R; case(cx)
				0:ch="E";1:ch="r";2:ch="r";3:ch="1";4:ch=":";
				5:ch=bd(wdog1_bcd,0);6:ch=bd(wdog1_bcd,1);7:ch=bd(wdog1_bcd,2);
				8:ch=(wdog1_bcd!=0)?(wt1?"P":"S"):7'd32;
				11:ch="E";12:ch="r";13:ch="r";14:ch="2";15:ch=":";
				16:ch=bd(wdog2_bcd,0);17:ch=bd(wdog2_bcd,1);18:ch=bd(wdog2_bcd,2);
				19:ch=(wdog2_bcd!=0)?(wt2?"P":"S"):7'd32;
				default:ch=7'd32; endcase
			end else begin ch=7'd32; co=W; end
		end

		default: begin ch=7'd32; co=W; end
		endcase
	end
end
endmodule
