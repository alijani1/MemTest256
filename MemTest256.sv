//============================================================================
//
//  Memory testes for MiSTer.
//  Copyright (C) 2017-2019 Sorgelig
//
//  Dual SDRAM support added by Ali Jani
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [45:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	output [11:0] VIDEO_ARX,
	output [11:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler

`ifdef USE_FB
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,
`endif

	output        LED_USER,
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,
	output  [1:0] BUTTONS,

	input         CLK_AUDIO,
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,
	output  [1:0] AUDIO_MIX,

	inout   [3:0] ADC_BUS,

	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

`ifdef USE_DDRAM
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,
`endif

`ifdef USE_SDRAM
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,
`endif

`ifdef DUAL_SDRAM
	input         SDRAM2_EN,
	output        SDRAM2_CLK,
	output [12:0] SDRAM2_A,
	output  [1:0] SDRAM2_BA,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_nCS,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nWE,
`endif

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	input   [6:0] USER_IN,
	output  [6:0] USER_OUT,

	input         OSD_STATUS
);

assign ADC_BUS  = 'Z;
assign USER_OUT = '1;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = 0;

assign VGA_SL = 0;
assign VGA_F1 = 0;
assign VGA_SCALER = 0;
assign VIDEO_ARX = 0;
assign VIDEO_ARY = 0;

assign AUDIO_S = 0;
assign AUDIO_L = 0;
assign AUDIO_R = 0;
assign AUDIO_MIX = 0;

assign LED_DISK  = 0;
assign LED_POWER = 0;
assign LED_USER  = 0;
assign BUTTONS   = 0;

wire [31:0] status;
wire  [1:0] buttons;

`include "build_id.v"
localparam CONF_STR =
{
	"MEMTEST256;;",
`ifdef DUAL_SDRAM
	"J1, Reset Freq, Reset Test, Switch IC, Switch Slot, Peek;",
`else
	"J1, Reset Freq, Reset Test, Switch IC;",
`endif
    "jn, A, Start, B;",
    "jp, B, Start, A;",
	"V,v",`BUILD_DATE
};

reg  [10:0] ps2_key;
wire [15:0] joystick_0;
wire  [1:0] sdram_sz;
reg   [1:0] sdram_chip = 2'h0;

`ifdef DUAL_SDRAM
reg         sdram2_detected = 0;
reg         sdram2_probed = 0;

// Mode: 0=auto(alternate both), 1=slot1 only, 2=slot2 only
reg  [1:0]  test_mode = 0;

// Which slot the tester is currently connected to (mux select)
reg         active_slot = 0;     // 0=slot1, 1=slot2

// Per-slot state (fully independent)
reg  [5:0]  slot_pos[2];        // frequency position per slot
reg  [31:0] slot_passcount[2];  // stored passcount per slot
reg  [31:0] slot_failcount[2];  // stored failcount per slot
reg         slot_auto[2];       // auto-stepping enabled per slot
reg         slot_search_up[2]; // per-slot: searching upward for ceiling
reg         slot_coarse[2];   // per-slot: coarse phase (10MHz steps)

// P key: toggle which slot's data is displayed (auto mode only)
reg         view_slot = 0;      // 0=viewing slot1, 1=viewing slot2

// Probe phase
reg         probe_phase = 0;

// Deferred slot switch: S key sets this flag, actual switch happens at clean pass boundary
reg         switch_pending = 0;

// Has each slot ever completed a test? Only reset on S/OSD, not arrows
reg         slot_ever_tested[2];

// History buffer: last 6 frequency steps per slot
// Each entry: {pos[5:0], passcount[15:0]} = 22 bits
reg  [5:0]  hist_pos[2][6];      // frequency position for each history entry
reg  [15:0] hist_pass[2][6];     // pass count at that frequency before it failed
reg  [2:0]  hist_count[2];       // number of valid entries (0-6)

// Total counters (across all frequencies, only reset on OSD reset)
reg  [31:0] slot_total_pass[2];
reg  [31:0] slot_total_fail[2];

// Per-slot timers: days, hours, minutes, seconds (reset when freq changes)
reg  [9:0]  slot_time_d[2];  // days (0-999)
reg  [4:0]  slot_time_h[2];  // hours (0-23)
reg  [5:0]  slot_time_m[2];  // minutes (0-59)
reg  [5:0]  slot_time_s[2];  // seconds (0-59)
reg  [25:0] slot_sec_cnt[2]; // raw 50MHz tick counter for second generation

// Total elapsed time (never resets except OSD/keys)
reg  [9:0]  total_days = 0;
reg  [4:0]  total_hours = 0;
reg  [5:0]  total_mins_cnt = 0;
reg  [5:0]  total_secs_cnt = 0;
reg         timer_reset = 1;
`endif

hps_io #(.STRLEN($size(CONF_STR)>>3)) hps_io
(
	.clk_sys(CLK_50M),
	.HPS_BUS(HPS_BUS),

	.conf_str(CONF_STR),
	.status(status),
	.buttons(buttons),
	.sdram_sz(sdram_sz),

	.joystick_0(joystick_0),
	.ps2_key(ps2_key),
	.ps2_kbd_led_use(0),
	.ps2_kbd_led_status(0)
);


///////////////////////////////////////////////////////////////////
wire clk_ram, locked;

pll pll
(
	.*,
	.refclk(CLK_50M),
	.rst(pll_reset | RESET),
	.outclk_0(clk_ram)
);

wire        mgmt_waitrequest;
reg         mgmt_write;
reg  [5:0]  mgmt_address;
reg  [31:0] mgmt_writedata;
wire [63:0] reconfig_to_pll;
wire [63:0] reconfig_from_pll;

pll_cfg pll_cfg
(
	.*,
	.mgmt_clk(CLK_50M),
	.mgmt_reset(RESET),
	.mgmt_read(0),
	.mgmt_readdata()
);

reg recfg = 0;
reg pll_reset = 0;

wire [31:0] cfg_param[256] =
'{ //      Freq    M         K                C
	// 167-160MHz: M=16 (00808), C=5 (20302), F = 10*(16+K/2^32)
	'h167, 'h00808, 'hB3333333, 'h20302, // pos 0: 167MHz
	'h166, 'h00808, 'h9999999A, 'h20302, // pos 1: 166MHz
	'h165, 'h00808, 'h80000000, 'h20302, // pos 2: 165MHz
	'h164, 'h00808, 'h66666666, 'h20302, // pos 3: 164MHz
	'h163, 'h00808, 'h4CCCCCCD, 'h20302, // pos 4: 163MHz
	'h162, 'h00808, 'h33333333, 'h20302, // pos 5: 162MHz
	'h161, 'h00808, 'h1999999A, 'h20302, // pos 6: 161MHz
	'h160, 'h00808, 'h00000001, 'h20302, // pos 7: 160MHz
	// 159-150MHz: M=15 (20807), C=5 (20302), F = 10*(15+K/2^32)
	'h159, 'h20807, 'hE6666666, 'h20302, // pos 8: 159MHz
	'h158, 'h20807, 'hCCCCCCCD, 'h20302, // pos 9: 158MHz
	'h157, 'h20807, 'hB3333333, 'h20302, // pos 10: 157MHz
	'h156, 'h20807, 'h9999999A, 'h20302, // pos 11: 156MHz
	'h155, 'h20807, 'h80000000, 'h20302, // pos 12: 155MHz
	'h154, 'h20807, 'h66666666, 'h20302, // pos 13: 154MHz
	'h153, 'h20807, 'h4CCCCCCD, 'h20302, // pos 14: 153MHz
	'h152, 'h20807, 'h33333333, 'h20302, // pos 15: 152MHz
	'h151, 'h20807, 'h1999999A, 'h20302, // pos 16: 151MHz
	'h150, 'h20807, 'h00000001, 'h20302, // pos 17: 150MHz
	// 149-140MHz: M=8 (00404), C=3 (20201) — original values
	'h149, 'h00404, 'hF0A3D6B4, 'h20201, // pos 18
	'h148, 'h00404, 'hE147ADBF, 'h20201, // pos 19
	'h147, 'h00404, 'hD1EB851F, 'h20201, // pos 20
	'h146, 'h00404, 'hC28F5C29, 'h20201, // pos 21
	'h145, 'h00404, 'hB33332DD, 'h20201, // pos 22
	'h144, 'h00404, 'hA3D709E8, 'h20201, // pos 23
	'h143, 'h00404, 'h947AE148, 'h20201, // pos 24
	'h142, 'h00404, 'h851EB852, 'h20201, // pos 25
	'h141, 'h00404, 'h75C28F06, 'h20201, // pos 26
	'h140, 'h00707, 'h00000001, 'h20302, // pos 27
	// 139-135MHz: M=8 (00404), C=3 (20201) — original values
	'h139, 'h00404, 'h570A3D71, 'h20201, // pos 28
	'h138, 'h00404, 'h47AE147B, 'h20201, // pos 29
	'h137, 'h00404, 'h3851EA2E, 'h20201, // pos 30
	'h136, 'h00404, 'h28F5C239, 'h20201, // pos 31
	'h135, 'h00404, 'h1999999A, 'h20201, // pos 32
	// 134-125MHz: M=10 (00505), C=4 (00202) — original values
	'h134, 'h00505, 'hB851EB2F, 'h00202, // pos 33
	'h133, 'h00505, 'hA3D709E8, 'h00202, // pos 34
	'h132, 'h00505, 'h8F5C28F6, 'h00202, // pos 35
	'h131, 'h00505, 'h7AE14758, 'h00202, // pos 36
	'h130, 'h00505, 'h66666611, 'h00202, // pos 37
	'h129, 'h00505, 'h51EB851F, 'h00202, // pos 38
	'h128, 'h00505, 'h3D70A381, 'h00202, // pos 39
	'h127, 'h00505, 'h28F5C239, 'h00202, // pos 40
	'h126, 'h00505, 'h147AE148, 'h00202, // pos 41
	'h125, 'h00505, 'h00000001, 'h00202, // pos 42
	// 124-121MHz: M=9 (20504), C=4 (00202) — original values
	'h124, 'h20504, 'hEB851E62, 'h00202, // pos 43
	'h123, 'h20504, 'hD70A3D71, 'h00202, // pos 44
	'h122, 'h20504, 'hC28F5C29, 'h00202, // pos 45
	'h121, 'h20504, 'hAE147A8B, 'h00202, // pos 46
	// 120MHz and below — original values
	'h120, 'h00707, 'h66666611, 'h00303, // pos 47
	'h110, 'h20706, 'h333332DD, 'h00303, // pos 48
	'h100, 'h00404, 'h00000001, 'h00202, // pos 49
	 'h90, 'h00707, 'h66666666, 'h00404, // pos 50
	 'h80, 'h00707, 'h66666666, 'h20504, // pos 51
	 'h70, 'h00707, 'h00000001, 'h00505, // pos 52
	 'h69, 'h00404, 'h47AE147B, 'h00303, // pos 53
	 'h68, 'h00404, 'h28F5C28F, 'h00303, // pos 54
	 'h67, 'h00505, 'hB851EB85, 'h00404, // pos 55
	 'h66, 'h00505, 'h8F5C28F6, 'h00404, // pos 56
	 'h65, 'h20706, 'h00000001, 'h00505, // pos 57
	 'h64, 'h00606, 'hCCCCCCCD, 'h00505, // pos 58
	 'h63, 'h00606, 'h9999999A, 'h00505, // pos 59
	'h625, 'h00404, 'hC0000000, 'h20403, // pos 60: 62.5MHz
	 'h62, 'h00606, 'h66666666, 'h00505, // pos 61
	 'h61, 'h00606, 'h33333333, 'h00505, // pos 62
	 'h60, 'h00404, 'h66666611, 'h20403  // pos 63: 60MHz
};

// pos is the ACTIVE frequency position — drives the PLL
localparam [5:0] START_POS = 6'd47; // 120MHz — start low and step up
reg   [5:0] pos  = START_POS;
reg  [15:0] mins = 0;
reg  [15:0] secs = 0;
reg         auto = 0;
reg         search_up = 1;          // searching upward for ceiling
reg         coarse = 1;             // coarse phase: 10MHz steps up

// Next coarse step: jump to next 10MHz boundary (higher freq = lower pos)
// Decade positions: 49=100, 48=110, 47=120, 37=130, 27=140, 17=150, 7=160, 0=167
function [5:0] next_coarse;
	input [5:0] p;
	begin
		if(p >= 38) next_coarse = 37; // 120+→130
		else if(p >= 28) next_coarse = 27; // 130+→140
		else if(p >= 18) next_coarse = 17; // 140+→150
		else if(p >= 8)  next_coarse = 7;  // 150+→160
		else             next_coarse = 0;  // 160+→167
	end
endfunction
// timer_reset deferred — timer still resets on recfg for now

// Cross-clock synchronizer: reset (clk_ram) -> CLK_50M
reg reset_sync1 = 1, reset_sync2 = 1;

`ifdef DUAL_SDRAM
// Test Transaction State Machine
localparam TXN_START         = 4'd0;
localparam TXN_WAIT_RECFG   = 4'd1;
localparam TXN_WAIT_RESET_HI= 4'd2;
localparam TXN_WAIT_RESET_LO= 4'd3;
localparam TXN_SETTLE        = 4'd4;
localparam TXN_WAIT_TEST    = 4'd5;
localparam TXN_LATCH        = 4'd6;
localparam TXN_FAIL_DELAY   = 4'd7;
localparam TXN_DECIDE       = 4'd8;
localparam TXN_CONTINUE     = 4'd9;  // continuous run: skip recfg, wait for next pass

reg  [3:0]  txn_state = TXN_START;
reg  [24:0] fail_delay_cnt = 0;
reg  [24:0] settle_cnt = 0;
reg  [5:0]  txn_tested_pos = 0; // frequency position that was actually tested
reg  [31:0] txn_last_passcount = 0; // for continuous mode: detect next pass completion
reg  [5:0]  slot_display_pos[2]; // last tested pos per slot for display
reg  [31:0] txn_passcount = 0;
reg  [31:0] txn_failcount = 0;
reg  [29:0] txn_watchdog = 0;  // ~10.7 sec at 50MHz (2^29 = 536M cycles)
reg  [15:0] watchdog_count[2]; // per-slot watchdog triggers
reg         watchdog_type[2];  // 0=state machine timeout, 1=progress timeout
// Progress watchdog: tracks if any passcount changed in last ~10 seconds
reg  [31:0] last_total_pass = 0; // snapshot of total passes
reg  [29:0] progress_timer = 0;  // ~10.7 sec at 50MHz (2^29 = 537M cycles)
`endif

always @(posedge CLK_50M) begin
	reg  [7:0] state = 0;
	reg [31:0] min = 0;
	integer    sec = 0, real_sec = 0;
	reg        old_stb = 0;
	reg [15:0] old_joy = 0;

	mgmt_write <= 0;

	if(((locked && !mgmt_waitrequest) || pll_reset) && recfg) begin
		state <= state + 1'd1;
		if(!state[2:0]) begin
			case(state[7:3])
				0: begin mgmt_address <= 0; mgmt_writedata <= 0;                          mgmt_write <= 1; end
				1: begin mgmt_address <= 4; mgmt_writedata <= cfg_param[{pos, 2'd1}];     mgmt_write <= 1; end
				2: begin mgmt_address <= 7; mgmt_writedata <= cfg_param[{pos, 2'd2}];     mgmt_write <= 1; end
				3: begin mgmt_address <= 3; mgmt_writedata <= 'h10000;                    mgmt_write <= 1; end
				4: begin mgmt_address <= 5; mgmt_writedata <= cfg_param[{pos, 2'd3}];     mgmt_write <= 1; end
				5: begin mgmt_address <= 9; mgmt_writedata <= 1;                          mgmt_write <= 1; end
				6: begin mgmt_address <= 8; mgmt_writedata <= 7;                          mgmt_write <= 1; end
				7: begin mgmt_address <= 2; mgmt_writedata <= 0;                          mgmt_write <= 1; end
				8: pll_reset <= 1;
				9: pll_reset <= 0;
				10: recfg <= 0;
			endcase
		end
	end

`ifdef DUAL_SDRAM
	// Total elapsed timer (only resets on OSD/boot/keys)
	if(timer_reset) begin
		{sec, secs} <= 0;
		real_sec <= 0;
		total_days <= 0; total_hours <= 0; total_mins_cnt <= 0; total_secs_cnt <= 0;
		timer_reset <= 0;
	end else begin
		sec <= sec + 1;
		if(sec == 4999999) begin
			sec <= 0;
			secs <= secs + 1'd1; // 10Hz tick for spinner animation
		end
		// Real 1-second tick for per-slot timer (50M cycles = 1 second)
		real_sec <= real_sec + 1;
		if(real_sec == 49999999) begin
			real_sec <= 0;
			// Total elapsed time
			if(total_secs_cnt == 59) begin
				total_secs_cnt <= 0;
				if(total_mins_cnt == 59) begin
					total_mins_cnt <= 0;
					if(total_hours == 23) begin
						total_hours <= 0;
						total_days <= total_days + 1'd1;
					end else total_hours <= total_hours + 1'd1;
				end else total_mins_cnt <= total_mins_cnt + 1'd1;
			end else total_secs_cnt <= total_secs_cnt + 1'd1;
			// Per-slot time
			if(slot_time_s[active_slot] == 59) begin
				slot_time_s[active_slot] <= 0;
				if(slot_time_m[active_slot] == 59) begin
					slot_time_m[active_slot] <= 0;
					if(slot_time_h[active_slot] == 23) begin
						slot_time_h[active_slot] <= 0;
						slot_time_d[active_slot] <= slot_time_d[active_slot] + 1'd1;
					end else begin
						slot_time_h[active_slot] <= slot_time_h[active_slot] + 1'd1;
					end
				end else begin
					slot_time_m[active_slot] <= slot_time_m[active_slot] + 1'd1;
				end
			end else begin
				slot_time_s[active_slot] <= slot_time_s[active_slot] + 1'd1;
			end
		end
	end
`else
	if(recfg) begin
		{min, mins} <= 0;
		{sec, secs} <= 0;
	end else begin
		min <= min + 1;
		if(min == 2999999999) begin
			min <= 0;
			if(mins[3:0]<9) mins[3:0] <= mins[3:0] + 1'd1;
			else begin
				mins[3:0] <= 0;
				if(mins[7:4]<9) mins[7:4] <= mins[7:4] + 1'd1;
				else begin
					mins[7:4] <= 0;
					if(mins[11:8]<9) mins[11:8] <= mins[11:8] + 1'd1;
					else begin
						mins[11:8] <= 0;
						if(mins[15:12]<9) mins[15:12] <= mins[15:12] + 1'd1;
						else mins[15:12] <= 0;
					end
				end
			end
		end
		sec <= sec + 1;
		if(sec == 4999999) begin
			sec <= 0;
			secs <= secs + 1'd1;
		end
	end
`endif

	old_stb <= ps2_key[10];
	old_joy <= joystick_0;
	if(old_stb != ps2_key[10] || old_joy != joystick_0) begin
		state <= 0;
		if(ps2_key[9] || joystick_0) begin

			// Up/Down: manual frequency control
`ifdef DUAL_SDRAM
			if((ps2_key[7:0] == 'h75 || (~old_joy[3] && joystick_0[3])) && pos > 0) begin
				recfg <= 1;
				txn_state <= TXN_WAIT_RECFG;
				watchdog_count[0] <= 0; watchdog_count[1] <= 0; txn_watchdog <= 0; progress_timer <= 0; timer_reset <= 1;
				pos <= pos - 1'd1;
				auto <= 0; search_up <= 0; coarse <= 0;
				slot_passcount[active_slot] <= 0;
				slot_failcount[active_slot] <= 0;
				slot_total_pass[active_slot] <= 0; slot_total_fail[active_slot] <= 0;
				slot_time_d[active_slot] <= 0; slot_time_h[active_slot] <= 0; slot_time_m[active_slot] <= 0; slot_time_s[active_slot] <= 0;
				if(test_mode == 0) begin
					slot_pos[0] <= pos - 1'd1;
					slot_pos[1] <= pos - 1'd1;
					slot_auto[0] <= 0;
					slot_auto[1] <= 0;
					slot_passcount[0] <= 0; slot_passcount[1] <= 0;
					slot_failcount[0] <= 0; slot_failcount[1] <= 0;
					slot_total_pass[0] <= 0; slot_total_pass[1] <= 0;
					slot_total_fail[0] <= 0; slot_total_fail[1] <= 0;
					slot_time_d[0]<=0; slot_time_h[0]<=0; slot_time_m[0]<=0; slot_time_s[0]<=0; slot_time_d[1]<=0; slot_time_h[1]<=0; slot_time_m[1]<=0; slot_time_s[1]<=0;
				end
			end
			if((ps2_key[7:0] == 'h72 || (~old_joy[2] && joystick_0[2])) && pos < 63) begin
				recfg <= 1;
				txn_state <= TXN_WAIT_RECFG;
				watchdog_count[0] <= 0; watchdog_count[1] <= 0; txn_watchdog <= 0; progress_timer <= 0; timer_reset <= 1;
				pos <= pos + 1'd1;
				auto <= 0; search_up <= 0; coarse <= 0;
				slot_passcount[active_slot] <= 0;
				slot_failcount[active_slot] <= 0;
				slot_total_pass[active_slot] <= 0; slot_total_fail[active_slot] <= 0;
				slot_time_d[active_slot] <= 0; slot_time_h[active_slot] <= 0; slot_time_m[active_slot] <= 0; slot_time_s[active_slot] <= 0;
				if(test_mode == 0) begin
					slot_pos[0] <= pos + 1'd1;
					slot_pos[1] <= pos + 1'd1;
					slot_auto[0] <= 0;
					slot_auto[1] <= 0;
					slot_passcount[0] <= 0; slot_passcount[1] <= 0;
					slot_failcount[0] <= 0; slot_failcount[1] <= 0;
					slot_total_pass[0] <= 0; slot_total_pass[1] <= 0;
					slot_total_fail[0] <= 0; slot_total_fail[1] <= 0;
					slot_time_d[0]<=0; slot_time_h[0]<=0; slot_time_m[0]<=0; slot_time_s[0]<=0; slot_time_d[1]<=0; slot_time_h[1]<=0; slot_time_m[1]<=0; slot_time_s[1]<=0;
				end
			end
`else
			if((ps2_key[7:0] == 'h75 || (~old_joy[3] && joystick_0[3])) && pos > 0) begin
				recfg <= 1;
				pos <= pos - 1'd1;
				auto <= 0;
			end
			if((ps2_key[7:0] == 'h72 || (~old_joy[2] && joystick_0[2]))  && pos < 63) begin
				recfg <= 1;
				pos <= pos + 1'd1;
				auto <= 0;
			end
`endif

			// Enter: reset test
			if(ps2_key[7:0] == 'h5a || (~old_joy[4] && joystick_0[4])) begin
				recfg <= 1;
`ifdef DUAL_SDRAM
				txn_state <= TXN_WAIT_RECFG;
				watchdog_count[0] <= 0; watchdog_count[1] <= 0; txn_watchdog <= 0; progress_timer <= 0; timer_reset <= 1;
`endif
				auto <= 0;
			end

			// A: re-enable auto at current frequency, clear all counts
			if(ps2_key[7:0] == 'h1c || (~old_joy[5] && joystick_0[5])) begin
				recfg <= 1;
				auto <= 1;
				search_up <= 0; coarse <= 0; // A resumes auto from current freq, no longer searching up
`ifdef DUAL_SDRAM
				txn_state <= TXN_WAIT_RECFG;
				watchdog_count[0] <= 0; watchdog_count[1] <= 0; txn_watchdog <= 0; progress_timer <= 0; timer_reset <= 1;
				// Keep pos unchanged (resume auto from current freq)
				slot_passcount[active_slot] <= 0;
				slot_failcount[active_slot] <= 0;
				slot_total_pass[0] <= 0; slot_total_pass[1] <= 0;
				slot_total_fail[0] <= 0; slot_total_fail[1] <= 0;
				slot_time_d[active_slot] <= 0; slot_time_h[active_slot] <= 0; slot_time_m[active_slot] <= 0; slot_time_s[active_slot] <= 0;
				if(test_mode == 0) begin
					slot_pos[0] <= pos; // keep current freq for both
					slot_pos[1] <= pos;
					slot_auto[0] <= 1;
					slot_auto[1] <= 1;
					slot_passcount[0] <= 0; slot_passcount[1] <= 0;
					slot_failcount[0] <= 0; slot_failcount[1] <= 0;
					slot_time_h[0]<=0; slot_time_m[0]<=0; slot_time_s[0]<=0;
					slot_time_h[1]<=0; slot_time_m[1]<=0; slot_time_s[1]<=0;
					active_slot <= 0;
				end
`endif
			end

			// C: switch chip
			if(ps2_key[7:0] == 'h21 || (~old_joy[6] && joystick_0[6])) begin
				recfg <= 1;
`ifdef DUAL_SDRAM
				txn_state <= TXN_WAIT_RECFG;
				watchdog_count[0] <= 0; watchdog_count[1] <= 0; txn_watchdog <= 0; progress_timer <= 0; timer_reset <= 1;
				slot_passcount[active_slot] <= 0;
				slot_failcount[active_slot] <= 0;
				slot_total_pass[active_slot] <= 0; slot_total_fail[active_slot] <= 0;
				slot_time_d[active_slot] <= 0; slot_time_h[active_slot] <= 0; slot_time_m[active_slot] <= 0; slot_time_s[active_slot] <= 0;
`endif
				if (sdram_chip == 2) sdram_chip <= 0; else sdram_chip <= sdram_chip + 1'd1;
			end

`ifdef DUAL_SDRAM
			// S key (0x1B) or joy[7]: request mode switch (deferred to clean pass boundary)
			if(ps2_key[7:0] == 'h1b || (~old_joy[7] && joystick_0[7])) begin
				if(sdram2_detected && !probe_phase) begin
					switch_pending <= 1;
				end
			end

			// P key (0x4D) or joy[8]: toggle view slot (auto mode only)
			if(old_stb != ps2_key[10]) begin
				if(ps2_key[9] && ps2_key[7:0] == 'h4d && test_mode == 0)
					view_slot <= ~view_slot;
			end
			if(~old_joy[8] && joystick_0[8] && test_mode == 0)
				view_slot <= ~view_slot;
`endif
		end
	end

	// Synchronize reset from clk_ram into CLK_50M domain (2-stage FF)
	reset_sync1 <= reset;
	reset_sync2 <= reset_sync1;

	// =========================================================
	// Test Transaction State Machine
	// Serialized: START -> WAIT_RECFG -> WAIT_RESET -> WAIT_TEST -> LATCH -> DECIDE -> START
	// No passcount/failcount sampling except in WAIT_TEST state
	// No active_slot changes except in DECIDE state
	// =========================================================
`ifdef DUAL_SDRAM
	// S key override: if switch_pending, force reset of state machine
	// Watchdog: if stuck in any wait state for ~10.7 seconds, force restart
	if(txn_state == TXN_START || txn_state == TXN_LATCH || txn_state == TXN_DECIDE || txn_state == TXN_SETTLE || txn_state == TXN_FAIL_DELAY || txn_state == TXN_CONTINUE || txn_state == TXN_WAIT_TEST || probe_phase)
		txn_watchdog <= 0;
	else
		txn_watchdog <= txn_watchdog + 1'd1;

	if(txn_watchdog[29]) begin
		// Watchdog fired
		txn_watchdog <= 0;
		watchdog_count[active_slot] <= watchdog_count[active_slot] + 1'd1;
		watchdog_type[active_slot] <= 0; // S = state machine timeout
		if(watchdog_count[active_slot] >= 4) begin
			// 5+ consecutive timeouts: treat as fail, drop frequency
			watchdog_count[active_slot] <= 0;
			if(test_mode == 0) begin
				slot_search_up[active_slot] <= 0; slot_coarse[active_slot] <= 0;
				if(slot_auto[active_slot] && slot_pos[active_slot] < 63) begin
					slot_pos[active_slot] <= slot_pos[active_slot] + 1'd1;
					slot_time_d[active_slot] <= 0; slot_time_h[active_slot] <= 0; slot_time_m[active_slot] <= 0; slot_time_s[active_slot] <= 0;
				end
				slot_total_fail[active_slot] <= slot_total_fail[active_slot] + 1'd1;
				slot_passcount[active_slot] <= 0;
				// Switch to other slot
				active_slot <= ~active_slot;
				pos <= slot_pos[~active_slot];
				auto <= slot_auto[~active_slot];
			end else begin
				search_up <= 0; coarse <= 0;
				if(auto && pos < 63) begin
					pos <= pos + 1'd1;
					slot_time_d[active_slot] <= 0; slot_time_h[active_slot] <= 0; slot_time_m[active_slot] <= 0; slot_time_s[active_slot] <= 0;
				end
				slot_total_fail[active_slot] <= slot_total_fail[active_slot] + 1'd1;
				slot_passcount[active_slot] <= 0;
			end
		end
		recfg <= 1;
		txn_state <= TXN_WAIT_RECFG;
	end else

	// Progress watchdog: if no passcount change for ~10 seconds, force recovery
	begin
		if((slot_total_pass[0] + slot_passcount[0] + slot_total_pass[1] + slot_passcount[1] +
		    slot_total_fail[0] + slot_total_fail[1]) != last_total_pass) begin
			// Any test completed (pass or fail) = progress, reset timer
			last_total_pass <= slot_total_pass[0] + slot_passcount[0] + slot_total_pass[1] + slot_passcount[1] +
			                   slot_total_fail[0] + slot_total_fail[1];
			progress_timer <= 0;
		end else if(!probe_phase) begin
			progress_timer <= progress_timer + 1'd1;
		end

		if(progress_timer[29]) begin // ~10.7 seconds no progress
			progress_timer <= 0;
			watchdog_count[active_slot] <= watchdog_count[active_slot] + 1'd1;
			watchdog_type[active_slot] <= 1; // P = progress timeout
			if(watchdog_count[active_slot] >= 4) begin
				// 5+ no-progress timeouts: treat as fail, drop frequency
				watchdog_count[active_slot] <= 0;
				if(test_mode == 0) begin
					slot_search_up[active_slot] <= 0; slot_coarse[active_slot] <= 0;
					if(slot_auto[active_slot] && slot_pos[active_slot] < 63) begin
						slot_pos[active_slot] <= slot_pos[active_slot] + 1'd1;
						slot_time_d[active_slot] <= 0; slot_time_h[active_slot] <= 0; slot_time_m[active_slot] <= 0; slot_time_s[active_slot] <= 0;
					end
					slot_total_fail[active_slot] <= slot_total_fail[active_slot] + 1'd1;
					slot_passcount[active_slot] <= 0;
					active_slot <= ~active_slot;
					pos <= slot_pos[~active_slot];
					auto <= slot_auto[~active_slot];
				end else begin
					search_up <= 0; coarse <= 0;
					if(auto && pos < 63) begin
						pos <= pos + 1'd1;
						slot_time_d[active_slot] <= 0; slot_time_h[active_slot] <= 0; slot_time_m[active_slot] <= 0; slot_time_s[active_slot] <= 0;
					end
					slot_total_fail[active_slot] <= slot_total_fail[active_slot] + 1'd1;
					slot_passcount[active_slot] <= 0;
				end
			end
			recfg <= 1;
			txn_state <= TXN_WAIT_RECFG;
		end
	end

	// switch_pending is handled only in TXN_DECIDE (deferred to clean pass boundary) else
	case(txn_state)

	TXN_START: begin
		// Begin a test transaction: configure PLL and start recfg
		recfg <= 1;
		txn_state <= TXN_WAIT_RECFG;
	end

	TXN_WAIT_RECFG: begin
		// Wait for PLL reconfiguration to complete (recfg goes back to 0)
		if(!recfg)
			txn_state <= TXN_WAIT_RESET_HI;
	end

	TXN_WAIT_RESET_HI: begin
		// Wait for reset to go HIGH (confirms tester is being reset)
		if(reset_sync2)
			txn_state <= TXN_WAIT_RESET_LO;
	end

	TXN_WAIT_RESET_LO: begin
		// Wait for reset to go LOW AND passcount == 0
		if(!reset_sync2 && passcount == 0) begin
			txn_state <= TXN_SETTLE;
			txn_tested_pos <= pos;
			slot_display_pos[active_slot] <= pos;
			slot_ever_tested[active_slot] <= 1;
			settle_cnt <= 25'd2500000; // 50ms settle after PLL reconfig
		end
	end

	TXN_SETTLE: begin
		// Post-reset settling delay for SDRAM/PLL stability
		if(settle_cnt > 0)
			settle_cnt <= settle_cnt - 1'd1;
		else
			txn_state <= TXN_WAIT_TEST;
	end

	TXN_WAIT_TEST: begin
		// Wait for test to complete (passcount becomes > 0)
		// passcount was confirmed 0 in WAIT_RESET, so this is a real new result
		if(passcount > 0) begin
			txn_passcount <= passcount;
			txn_failcount <= failcount;
			txn_state <= TXN_LATCH;
		end
	end

	TXN_LATCH: begin
		// Save results to the correct slot's registers
		if(txn_failcount > 0) begin
			// Failed — record history (skip during search_up, those are discovery not real fails)
			if(!((test_mode == 0) ? slot_search_up[active_slot] : search_up) && hist_count[active_slot] < 6) begin
				hist_pos[active_slot][hist_count[active_slot]] <= txn_tested_pos;
				hist_pass[active_slot][hist_count[active_slot]] <= slot_passcount[active_slot];
				hist_count[active_slot] <= hist_count[active_slot] + 1'd1;
			end else if(!((test_mode == 0) ? slot_search_up[active_slot] : search_up)) begin
				// Shift history left, drop oldest
				hist_pos[active_slot][0] <= hist_pos[active_slot][1];
				hist_pos[active_slot][1] <= hist_pos[active_slot][2];
				hist_pos[active_slot][2] <= hist_pos[active_slot][3];
				hist_pos[active_slot][3] <= hist_pos[active_slot][4];
				hist_pos[active_slot][4] <= hist_pos[active_slot][5];
				hist_pos[active_slot][5] <= txn_tested_pos;
				hist_pass[active_slot][0] <= hist_pass[active_slot][1];
				hist_pass[active_slot][1] <= hist_pass[active_slot][2];
				hist_pass[active_slot][2] <= hist_pass[active_slot][3];
				hist_pass[active_slot][3] <= hist_pass[active_slot][4];
				hist_pass[active_slot][4] <= hist_pass[active_slot][5];
				hist_pass[active_slot][5] <= slot_passcount[active_slot];
			end
			slot_passcount[active_slot] <= 0;
			slot_failcount[active_slot] <= slot_failcount[active_slot] + txn_failcount;
			slot_total_fail[active_slot] <= slot_total_fail[active_slot] + 1'd1;
			if(test_mode == 0) begin
				// Auto mode: any fail during search ends search, switch to downward stepping
				slot_search_up[active_slot] <= 0; slot_coarse[active_slot] <= 0;
				if(slot_auto[active_slot] && slot_pos[active_slot] < 63) begin
					slot_pos[active_slot] <= slot_pos[active_slot] + 1'd1;
					slot_time_d[active_slot] <= 0; slot_time_h[active_slot] <= 0; slot_time_m[active_slot] <= 0; slot_time_s[active_slot] <= 0;
				end
			end else begin
				// Single slot mode: any fail during search ends search, switch to downward stepping
				search_up <= 0; coarse <= 0;
				if(auto && pos < 63) begin
					pos <= pos + 1'd1;
					slot_time_d[active_slot] <= 0; slot_time_h[active_slot] <= 0; slot_time_m[active_slot] <= 0; slot_time_s[active_slot] <= 0;
				end
			end
		end else begin
			// Passed — decrement watchdog_count on success (self-heal)
			slot_passcount[active_slot] <= slot_passcount[active_slot] + txn_passcount;
			slot_failcount[active_slot] <= 0;
			slot_total_pass[active_slot] <= slot_total_pass[active_slot] + txn_passcount;
			if(watchdog_count[active_slot] > 0) watchdog_count[active_slot] <= watchdog_count[active_slot] - 1'd1;
			// Search up: step to higher frequency on pass
			if(test_mode == 0) begin
				if(slot_search_up[active_slot] && slot_auto[active_slot] && slot_pos[active_slot] > 0) begin
					slot_pos[active_slot] <= slot_coarse[active_slot] ? next_coarse(slot_pos[active_slot]) : (slot_pos[active_slot] - 1'd1);
					slot_time_d[active_slot] <= 0; slot_time_h[active_slot] <= 0; slot_time_m[active_slot] <= 0; slot_time_s[active_slot] <= 0;
				end
			end else begin
				if(search_up && auto && pos > 0) begin
					pos <= coarse ? next_coarse(pos) : (pos - 1'd1);
					slot_time_d[active_slot] <= 0; slot_time_h[active_slot] <= 0; slot_time_m[active_slot] <= 0; slot_time_s[active_slot] <= 0;
				end
			end
		end
		// Single-slot fail: show red result briefly before moving on
		if(txn_failcount > 0 && test_mode != 0) begin
			fail_delay_cnt <= 25000000; // 500ms at 50MHz
			txn_state <= TXN_FAIL_DELAY;
		end else
			txn_state <= TXN_DECIDE;
	end

	TXN_FAIL_DELAY: begin
		if(fail_delay_cnt > 0)
			fail_delay_cnt <= fail_delay_cnt - 1'd1;
		else
			txn_state <= TXN_DECIDE;
	end

	TXN_DECIDE: begin
		// Decide what to do next
		if(switch_pending) begin
			// S key was pressed: switch mode — reset ALL state
			switch_pending <= 0;
			pos <= START_POS;
			auto <= 1;
			search_up <= 1; coarse <= 1;
			view_slot <= 0;
			watchdog_count[0] <= 0; watchdog_count[1] <= 0;
			txn_watchdog <= 0; progress_timer <= 0; timer_reset <= 1;
			slot_total_pass[0] <= 0; slot_total_pass[1] <= 0;
			slot_total_fail[0] <= 0; slot_total_fail[1] <= 0;
			slot_passcount[0] <= 0; slot_passcount[1] <= 0;
			slot_failcount[0] <= 0; slot_failcount[1] <= 0;
			slot_pos[0] <= START_POS; slot_pos[1] <= START_POS; slot_display_pos[0] <= 0; slot_display_pos[1] <= 0;
			slot_auto[0] <= 1; slot_auto[1] <= 1; slot_search_up[0] <= 1; slot_search_up[1] <= 1; slot_coarse[0] <= 1; slot_coarse[1] <= 1; slot_ever_tested[0] <= 0; slot_ever_tested[1] <= 0; hist_count[0] <= 0; hist_count[1] <= 0;
			slot_time_d[0]<=0; slot_time_h[0]<=0; slot_time_m[0]<=0; slot_time_s[0]<=0; slot_time_d[1]<=0; slot_time_h[1]<=0; slot_time_m[1]<=0; slot_time_s[1]<=0;
			if(test_mode == 2'd2) begin
				test_mode <= 2'd0;
				active_slot <= 0;
			end else begin
				test_mode <= test_mode + 1'd1;
				active_slot <= test_mode;
			end
		end else if(test_mode == 0) begin
			// Auto mode: switch to other slot — always needs recfg
			active_slot <= ~active_slot;
			pos <= slot_pos[~active_slot];
			auto <= slot_auto[~active_slot];
			search_up <= slot_search_up[~active_slot];
			coarse <= slot_coarse[~active_slot];
			txn_state <= TXN_START;
		end else begin
			// Single slot mode
			if(txn_failcount == 0) begin
				if(pos != txn_tested_pos) begin
					// Freq changed (search_up stepped it), need recfg
					txn_state <= TXN_START;
				end else begin
					// Passed at same freq — keep running continuously, no recfg
					txn_last_passcount <= passcount;
					txn_state <= TXN_CONTINUE;
				end
			end else begin
				// Failed — freq changed in LATCH, need full recfg
				txn_state <= TXN_START;
			end
		end
	end

	TXN_CONTINUE: begin
		// Continuous run: tester keeps running, no recfg
		// Wait for passcount to change (next pass completed)
		if(passcount != txn_last_passcount) begin
			txn_passcount <= passcount - txn_last_passcount;
			txn_failcount <= failcount;
			txn_state <= TXN_LATCH;
		end
	end

	default: txn_state <= TXN_START;
	endcase

	// Probe overrides the state machine
	if(probe_phase) begin
		if(sdram2_probed) begin
			probe_phase <= 0;
			recfg <= 1;
			pos <= START_POS;
			auto <= 1;
			search_up <= 1; coarse <= 1;
			slot_search_up[0] <= 1; slot_search_up[1] <= 1; slot_coarse[0] <= 1; slot_coarse[1] <= 1;
			test_mode <= sdram2_detected ? 2'd0 : 2'd1; // Both Slots if 256MB, else Slot 1
			active_slot <= 0;
			txn_state <= TXN_WAIT_RECFG;
			// Clear probe residue from both slots
			slot_passcount[0] <= 0; slot_passcount[1] <= 0;
			slot_failcount[0] <= 0; slot_failcount[1] <= 0;
			slot_total_pass[0] <= 0; slot_total_pass[1] <= 0;
			slot_total_fail[0] <= 0; slot_total_fail[1] <= 0;
			slot_display_pos[0] <= START_POS; slot_display_pos[1] <= 0;
			slot_pos[0] <= START_POS; slot_pos[1] <= START_POS;
			slot_ever_tested[0] <= 0; slot_ever_tested[1] <= 0;
			watchdog_count[0] <= 0; watchdog_count[1] <= 0;
			txn_watchdog <= 0; progress_timer <= 0; last_total_pass <= 0;
		end
	end

`else
	// Non-dual SDRAM: simple auto stepping (no slot switching)
	if(auto && !recfg && !reset_sync2 && pos < 63 && (failcount && passcount)) begin
		recfg <= 1;
		pos <= pos + 1'd1;
	end
`endif

	// Probe handling moved inside TXN state machine for DUAL_SDRAM

	if(status[0] | buttons[1]) begin
		recfg <= 1;
		sdram_chip <= 0;
`ifdef DUAL_SDRAM
		if(SDRAM2_EN) begin
			pos <= 49;       // probe at 100MHz (pos 49 in table)
			auto <= 0;
			probe_phase <= 1;
			active_slot <= 1; // probe uses slot 2
		end else begin
			pos <= START_POS;
			auto <= 1;
			search_up <= 1; coarse <= 1;
			test_mode <= 2'd1;
		end
		view_slot <= 0;
		switch_pending <= 0;
		timer_reset <= 1;
		slot_pos[0] <= START_POS; slot_pos[1] <= START_POS; slot_display_pos[0] <= 0; slot_display_pos[1] <= 0;
		slot_passcount[0] <= 0; slot_passcount[1] <= 0;
		slot_failcount[0] <= 0; slot_failcount[1] <= 0;
		slot_total_pass[0] <= 0; slot_total_pass[1] <= 0;
		slot_total_fail[0] <= 0; slot_total_fail[1] <= 0;
		slot_time_d[0]<=0; slot_time_h[0]<=0; slot_time_m[0]<=0; slot_time_s[0]<=0; slot_time_d[1]<=0; slot_time_h[1]<=0; slot_time_m[1]<=0; slot_time_s[1]<=0;
		slot_auto[0] <= 1; slot_auto[1] <= 1; slot_search_up[0] <= 1; slot_search_up[1] <= 1; slot_coarse[0] <= 1; slot_coarse[1] <= 1; slot_ever_tested[0] <= 0; slot_ever_tested[1] <= 0; hist_count[0] <= 0; hist_count[1] <= 0;
		txn_state <= TXN_WAIT_RECFG; // OSD reset triggers recfg, go straight to wait
		watchdog_count[0] <= 0; watchdog_count[1] <= 0; progress_timer <= 0; last_total_pass <= 0;
`else
		pos <= START_POS;
		auto <= 1;
		search_up <= 1; coarse <= 1;
`endif
	end
end


///////////////////////////////////////////////////////////////////
// Single tester with mux to SDRAM controllers
///////////////////////////////////////////////////////////////////

assign SDRAM_CKE = 1;

reg reset = 0;
always @(posedge clk_ram) begin
	integer timeout;

	if(timeout) timeout <= timeout - 1;
	reset <= |timeout;

	if((recfg || ~locked) && (timeout < 1000000)) timeout <= 1000000;

	if(RESET) timeout <= 100000000;
end

// Single tester instance
wire        tst_sdram_start, tst_sdram_rnw, tst_sdram_rst_n;
wire [15:0] tst_sdram_wdat;
wire        tst_sdram_done, tst_sdram_ready;
wire [15:0] tst_sdram_rdat;

wire [31:0] passcount, failcount;

tester my_memtst
(
	.clk(clk_ram),
	.rst_n(~reset),
	.sz(sdram_sz),
	.chip(sdram_chip),
	.passcount(passcount),
	.failcount(failcount),
	.sdram_start(tst_sdram_start),
	.sdram_rnw(tst_sdram_rnw),
	.sdram_rst_n(tst_sdram_rst_n),
	.sdram_wdat(tst_sdram_wdat),
	.sdram_done(tst_sdram_done),
	.sdram_ready(tst_sdram_ready),
	.sdram_rdat(tst_sdram_rdat)
);

// SDRAM1 controller (GPIO 0)
wire        sdram1_done, sdram1_ready;
wire [15:0] sdram1_rdat;

sdram sdram1
(
	.clk(clk_ram),
`ifdef DUAL_SDRAM
	.rst_n(active_slot == 0 ? tst_sdram_rst_n : 1'b0),
	.start(active_slot == 0 ? tst_sdram_start : 1'b0),
`else
	.rst_n(tst_sdram_rst_n),
	.start(tst_sdram_start),
`endif
	.rnw(tst_sdram_rnw),
	.done(sdram1_done),
	.ready(sdram1_ready),
	.wdat(tst_sdram_wdat),
	.rdat(sdram1_rdat),
	.sz(sdram_sz),
	.chip(sdram_chip),
	.DRAM_CLK(SDRAM_CLK),
	.DRAM_DQ(SDRAM_DQ),
	.DRAM_ADDR(SDRAM_A),
	.DRAM_LDQM(SDRAM_DQML),
	.DRAM_UDQM(SDRAM_DQMH),
	.DRAM_WE_N(SDRAM_nWE),
	.DRAM_CS_N(SDRAM_nCS),
	.DRAM_RAS_N(SDRAM_nRAS),
	.DRAM_CAS_N(SDRAM_nCAS),
	.DRAM_BA_0(SDRAM_BA[0]),
	.DRAM_BA_1(SDRAM_BA[1])
);

`ifdef DUAL_SDRAM
// SDRAM2 controller (GPIO 1)
wire        sdram2_done, sdram2_ready;
wire [15:0] sdram2_rdat;
wire        sdram2_dqml, sdram2_dqmh;

sdram sdram2
(
	.clk(clk_ram),
	.rst_n(active_slot == 1 ? tst_sdram_rst_n : 1'b0),
	.start(active_slot == 1 ? tst_sdram_start : 1'b0),
	.rnw(tst_sdram_rnw),
	.done(sdram2_done),
	.ready(sdram2_ready),
	.wdat(tst_sdram_wdat),
	.rdat(sdram2_rdat),
	.sz(sdram_sz),
	.chip(sdram_chip),
	.DRAM_CLK(SDRAM2_CLK),
	.DRAM_DQ(SDRAM2_DQ),
	.DRAM_ADDR(SDRAM2_A),
	.DRAM_LDQM(sdram2_dqml),
	.DRAM_UDQM(sdram2_dqmh),
	.DRAM_WE_N(SDRAM2_nWE),
	.DRAM_CS_N(SDRAM2_nCS),
	.DRAM_RAS_N(SDRAM2_nRAS),
	.DRAM_CAS_N(SDRAM2_nCAS),
	.DRAM_BA_0(SDRAM2_BA[0]),
	.DRAM_BA_1(SDRAM2_BA[1])
);

// Mux: route tester to active SDRAM controller
assign tst_sdram_done  = active_slot ? sdram2_done  : sdram1_done;
assign tst_sdram_ready = active_slot ? sdram2_ready : sdram1_ready;
assign tst_sdram_rdat  = active_slot ? sdram2_rdat  : sdram1_rdat;

// SDRAM2 probe at 100MHz
reg saw_read_phase = 0;

always @(posedge clk_ram) begin
	if(RESET) begin
		sdram2_probed <= 0;
		sdram2_detected <= SDRAM2_EN;
		saw_read_phase <= 0;
	end else if(SDRAM2_EN && !sdram2_probed && !reset && active_slot == 1) begin
		if(tst_sdram_rnw) saw_read_phase <= 1;
		if(saw_read_phase) begin
			if(failcount > 100) begin
				sdram2_detected <= 0;
				sdram2_probed <= 1;
			end else if(passcount > 0) begin
				sdram2_detected <= 1;
				sdram2_probed <= 1;
			end
		end
	end
end

// Display: which slot's data to show
// Auto mode: always show stored values (avoids flicker between live/stored on slot switches)
// Single mode: show live tester output
wire        display_slot = (test_mode == 0) ? view_slot : active_slot;
wire [5:0]  display_pos  = (test_mode == 0) ? slot_pos[display_slot] : pos;
wire [31:0] display_pass = (test_mode == 0) ? slot_passcount[display_slot] : passcount;
wire [31:0] display_fail = (test_mode == 0) ? slot_failcount[display_slot] : failcount;

// Per-slot status: 0=yellow, 1=green(passing), add blink flag for <130MHz
// Always use stored passcount for display (live passcount resets on every recfg)
wire [31:0] s1_pass = slot_passcount[0];
wire [31:0] s2_pass = slot_passcount[1];
// Display pos: use slot_display_pos (saved at end of each test in LATCH)
// Active slot shows txn_tested_pos (live), inactive shows saved
wire [5:0]  s1_pos  = (active_slot == 0) ? txn_tested_pos : slot_display_pos[0];
wire [5:0]  s2_pos  = (active_slot == 1) ? txn_tested_pos : slot_display_pos[1];

wire [1:0] slot1_status = (s1_pass > 0) ? 2'd1 : 2'd0;
wire [1:0] slot2_status = (s2_pass > 0) ? 2'd1 : 2'd0;
wire       slot1_blink  = (s1_pos > 27); // below 125MHz
wire       slot2_blink  = (s2_pos > 27);

`else
// Single SDRAM mode
assign tst_sdram_done  = sdram1_done;
assign tst_sdram_ready = sdram1_ready;
assign tst_sdram_rdat  = sdram1_rdat;
`endif


///////////////////////////////////////////////////////////////////
wire videoclk;

vpll vpll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(videoclk)
);

assign CLK_VIDEO = videoclk;
assign CE_PIXEL  = 1;

wire hs, vs;
wire [1:0] b, r, g;

// rez3: [1:0]=chip, [2]=sdram2_detected, [3]=display_slot
wire [3:0] rez3_val;
`ifdef DUAL_SDRAM
assign rez3_val = {display_slot, sdram2_detected, (sdram_sz == 3) ? ~sdram_chip : 2'b00};
`else
assign rez3_val = {2'b00, (sdram_sz == 3) ? ~sdram_chip : 2'b00};
`endif

// Per-slot frequency values for display
`ifdef DUAL_SDRAM
wire [11:0] s1_freq = cfg_param[{s1_pos, 2'd0}][11:0];
wire [11:0] s2_freq = cfg_param[{s2_pos, 2'd0}][11:0];

// History frequency lookups
wire [11:0] s1_hfreq[6], s2_hfreq[6];
genvar gi;
generate
	for(gi=0; gi<6; gi=gi+1) begin : hist_freq_gen
		assign s1_hfreq[gi] = cfg_param[{hist_pos[0][gi], 2'd0}][11:0];
		assign s2_hfreq[gi] = cfg_param[{hist_pos[1][gi], 2'd0}][11:0];
	end
endgenerate
`endif

vgaout showrez
(
	.clk(videoclk),
`ifdef DUAL_SDRAM
	.mem_size(sdram2_detected ? 4'd4 : {2'b00, sdram_sz}),
	.slot1_freq(s1_freq),
	.slot2_freq(s2_freq),
	.slot1_pass(s1_pass),
	.slot2_pass(s2_pass),
	.slot1_pos(s1_pos),
	.slot2_pos(s2_pos),
	.slot1_total_pass((slot_total_pass[0] >= s1_pass) ? slot_total_pass[0] - s1_pass : 32'd0),
	.slot2_total_pass((slot_total_pass[1] >= s2_pass) ? slot_total_pass[1] - s2_pass : 32'd0),
	.slot1_total_fail(slot_total_fail[0]),
	.slot2_total_fail(slot_total_fail[1]),
	.slot1_time_d(slot_time_d[0]), .slot1_time_h(slot_time_h[0]), .slot1_time_m(slot_time_m[0]), .slot1_time_s(slot_time_s[0]),
	.slot2_time_d(slot_time_d[1]), .slot2_time_h(slot_time_h[1]), .slot2_time_m(slot_time_m[1]), .slot2_time_s(slot_time_s[1]),
	.bg(6'b000001),
	.test_mode(test_mode),
	.sdram2_detected(sdram2_detected),
	.active_slot(active_slot),
	.chip(sdram_chip),
	.watchdog_count1(watchdog_count[0]), .watchdog_type1(watchdog_type[0]),
	.watchdog_count2(watchdog_count[1]), .watchdog_type2(watchdog_type[1]),
	.s1_ever_tested(slot_ever_tested[0]),
	.s2_ever_tested(slot_ever_tested[1]),
	// History data
	.s1_hfreq0(s1_hfreq[0]),.s1_hfreq1(s1_hfreq[1]),.s1_hfreq2(s1_hfreq[2]),
	.s1_hfreq3(s1_hfreq[3]),.s1_hfreq4(s1_hfreq[4]),.s1_hfreq5(s1_hfreq[5]),
	.s2_hfreq0(s2_hfreq[0]),.s2_hfreq1(s2_hfreq[1]),.s2_hfreq2(s2_hfreq[2]),
	.s2_hfreq3(s2_hfreq[3]),.s2_hfreq4(s2_hfreq[4]),.s2_hfreq5(s2_hfreq[5]),
	.s1_hpass0(hist_pass[0][0]),.s1_hpass1(hist_pass[0][1]),.s1_hpass2(hist_pass[0][2]),
	.s1_hpass3(hist_pass[0][3]),.s1_hpass4(hist_pass[0][4]),.s1_hpass5(hist_pass[0][5]),
	.s2_hpass0(hist_pass[1][0]),.s2_hpass1(hist_pass[1][1]),.s2_hpass2(hist_pass[1][2]),
	.s2_hpass3(hist_pass[1][3]),.s2_hpass4(hist_pass[1][4]),.s2_hpass5(hist_pass[1][5]),
	.s1_hcount(hist_count[0]),.s2_hcount(hist_count[1]),
	.probe_phase(probe_phase),
	.txn_testing(txn_state == TXN_WAIT_TEST || txn_state == TXN_SETTLE || txn_state == TXN_CONTINUE),
	.auto_mode(auto),
	.search_up(search_up),
`else
	.mem_size({2'b00, sdram_sz}),
	.slot1_freq(cfg_param[{pos, 2'd0}][11:0]),
	.slot2_freq(12'd0),
	.slot1_pass(passcount),
	.slot2_pass(32'd0),
	.slot1_pos(pos),
	.slot2_pos(6'd0),
	.slot1_total_pass(32'd0),
	.slot2_total_pass(32'd0),
	.slot1_total_fail(32'd0),
	.slot2_total_fail(32'd0),
	.slot1_time_d(10'd0), .slot1_time_h(5'd0), .slot1_time_m(6'd0), .slot1_time_s(6'd0),
	.slot2_time_d(10'd0), .slot2_time_h(5'd0), .slot2_time_m(6'd0), .slot2_time_s(6'd0),
	.bg(6'b000001),
	.test_mode(2'd1),
	.sdram2_detected(1'b0),
	.active_slot(1'b0),
	.chip(sdram_chip),
	.watchdog_count1(16'd0), .watchdog_type1(1'b0),
	.watchdog_count2(16'd0), .watchdog_type2(1'b0),
	.s1_ever_tested(1'b1),
	.s2_ever_tested(1'b0),
	.s1_hfreq0(12'd0),.s1_hfreq1(12'd0),.s1_hfreq2(12'd0),
	.s1_hfreq3(12'd0),.s1_hfreq4(12'd0),.s1_hfreq5(12'd0),
	.s2_hfreq0(12'd0),.s2_hfreq1(12'd0),.s2_hfreq2(12'd0),
	.s2_hfreq3(12'd0),.s2_hfreq4(12'd0),.s2_hfreq5(12'd0),
	.s1_hpass0(16'd0),.s1_hpass1(16'd0),.s1_hpass2(16'd0),
	.s1_hpass3(16'd0),.s1_hpass4(16'd0),.s1_hpass5(16'd0),
	.s2_hpass0(16'd0),.s2_hpass1(16'd0),.s2_hpass2(16'd0),
	.s2_hpass3(16'd0),.s2_hpass4(16'd0),.s2_hpass5(16'd0),
	.s1_hcount(3'd0),.s2_hcount(3'd0),
	.probe_phase(1'b0),
	.txn_testing(1'b0),
	.auto_mode(auto),
	.search_up(search_up),
`endif
`ifdef DUAL_SDRAM
	.total_days(total_days), .total_hours(total_hours), .total_mins(total_mins_cnt), .total_secs(total_secs_cnt),
`else
	.total_days(10'd0), .total_hours(5'd0), .total_mins(mins[5:0]), .total_secs(6'd0),
`endif
	.hs(hs),
	.vs(vs),
	.de(VGA_DE),
	.b(b),
	.r(r),
	.g(g)
);

assign VGA_HS = ~hs;
assign VGA_VS = ~vs;

assign VGA_B  = {4{b}};
assign VGA_R  = {4{r}};
assign VGA_G  = {4{g}};

endmodule
