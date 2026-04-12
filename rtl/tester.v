/*

reset...init...save.start_write.stop_write.restore.start_read(compare).stop_read.loop

error...

*/

module tester
(
	input         clk,
	input         rst_n,

	input  [1:0]  sz,
	input  [1:0]  chip,

	output reg [31:0] passcount,
	output reg [31:0] failcount,

	// Abstract SDRAM interface (directly drives external sdram controller)
	output reg    sdram_start,
	output reg    sdram_rnw,
	output reg    sdram_rst_n,
	output [15:0] sdram_wdat,
	input         sdram_done,
	input         sdram_ready,
	input  [15:0] sdram_rdat
);


reg rnd_save,rnd_restore; // rnd_vec_gen control
wire [15:0] rnd_out; // rnd_vec_gen output

rnd_vec_gen my_rnd
(
	.clk(clk),
	.next(sdram_ready),
	.save(rnd_save),
	.restore(rnd_restore),
	.out(rnd_out)
);

assign sdram_wdat = rnd_out;


// FSM states and registers
reg [3:0] curr_state,next_state;

localparam RESET        = 4'h0;
localparam INIT1        = 4'h1;
localparam INIT2        = 4'h2;
localparam BEGIN_WRITE1 = 4'h3;
localparam BEGIN_WRITE2 = 4'h4;
localparam BEGIN_WRITE3 = 4'h5;
localparam BEGIN_WRITE4 = 4'h6;
localparam WRITE        = 4'h7;
localparam BEGIN_READ1  = 4'h8;
localparam BEGIN_READ2  = 4'h9;
localparam BEGIN_READ3  = 4'hA;
localparam BEGIN_READ4  = 4'hB;
localparam READ         = 4'hC;
localparam END_READ     = 4'hD;
localparam INC_PASSES   = 4'hE;


// FSM dispatcher

always @* begin
	case( curr_state )

		RESET:   next_state <= INIT1;
		INIT1:
				if( sdram_done )
					next_state <= INIT2;
				else
					next_state <= INIT1;

		INIT2:        next_state <= BEGIN_WRITE1;
		BEGIN_WRITE1: next_state <= BEGIN_WRITE2;
		BEGIN_WRITE2: next_state <= BEGIN_WRITE3;
		BEGIN_WRITE3: next_state <= BEGIN_WRITE4;
		BEGIN_WRITE4: next_state <= WRITE;
		WRITE:
				if( sdram_done )
					next_state <= BEGIN_READ1;
				else
					next_state <= WRITE;

		BEGIN_READ1: next_state <= BEGIN_READ2;
		BEGIN_READ2: next_state <= BEGIN_READ3;
		BEGIN_READ3: next_state <= BEGIN_READ4;
		BEGIN_READ4: next_state <= READ;
		READ:
				if( sdram_done )
				  next_state <= END_READ;
				else
				  next_state <= READ;

		END_READ:    next_state <= INC_PASSES;
		INC_PASSES:  next_state <= BEGIN_WRITE1;

		default: next_state <= RESET;
	endcase
end


// FSM controller
always @(posedge clk) begin
	reg        check_in_progress; // when 1 - enables errors checking
	reg        reset_req = 1;
	reg [31:0] rst_cnt;

	if (check_in_progress & sdram_ready & (sdram_rdat!=rnd_out)) failcount <= failcount + 1;

	curr_state <= ( reset_req & sdram_done ) ? RESET : next_state;
	if(~rst_n) begin
		reset_req <= 1;
		rst_cnt <= 0;
	end

	if(~rst_n || reset_req) begin
		check_in_progress <= 0;
		passcount <= 0;
		failcount <= 0;
	end

	case( curr_state )

	//////////////////////////////////////////////////
	RESET: begin
		// various initializings begin

		check_in_progress <= 0;

		rnd_save <= 0;
		rnd_restore <= 0;

		sdram_start <= 0;
		reset_req <= 0;
		sdram_rst_n <= 0;
		rst_cnt <= 0;
		if(rst_cnt < 5000000) begin
			rst_cnt <= rst_cnt + 1;
			curr_state <= RESET;
		end
	end

	INIT1: begin
		sdram_start  <= 0; // end dram start
		sdram_rst_n <= 1;
	end

	//////////////////////////////////////////////////
	BEGIN_WRITE1: begin
		rnd_save <= 1;
		sdram_rnw <= 0;
	end

	BEGIN_WRITE2: begin
		rnd_save   <= 0;
		sdram_start <= 1;
	end

	BEGIN_WRITE3: begin
		sdram_start <= 0;
	end

	//////////////////////////////////////////////////
	BEGIN_READ1: begin
		rnd_restore <= 1;
		sdram_rnw <= 1;
	end

	BEGIN_READ2: begin
		rnd_restore <= 0;
		sdram_start <= 1;
	end

	BEGIN_READ3: begin
		sdram_start <= 0;
		check_in_progress <= 1;
	end

	END_READ: begin
		check_in_progress <= 0;
	end

	INC_PASSES: begin
		passcount <= passcount + 1;
	end

	endcase
end

endmodule
