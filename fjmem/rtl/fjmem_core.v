/*
 * Milkymist VJ SoC fjmem flasher
 * Copyright (C) 2010 Michael Walle <michael@walle.cc>
 * Copyright (C) 2008 Arnim Laeuger <arniml@users.sourceforge.net>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3 of the License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 *
 * This core is derived from the VHDL version supplied with UrJTAG, written
 * by Arnim Laeuger.
 *
 */

module fjmem_core #(
	parameter adr_width = 24,
	parameter timing = 4'd6
) (
	input sys_clk,
	input sys_rst,

	/* jtag */
	input jtag_tck,
	input jtag_rst,
	input jtag_update,
	input jtag_shift,
	input jtag_tdi,
	output jtag_tdo,

	/* flash */
	output [adr_width-1:0] flash_adr,
	inout [15:0] flash_d,
	output reg flash_oe_n,
	output reg flash_we_n,

	/* debug */
	output fjmem_update
);

parameter INSTR_IDLE   = 3'b000;
parameter INSTR_DETECT = 3'b111;
parameter INSTR_QUERY  = 3'b110;
parameter INSTR_READ   = 3'b001;
parameter INSTR_WRITE  = 3'b010;


parameter aw = adr_width;
parameter sw = aw+21;

reg [sw-1:0] shift_r;

assign jtag_tdo = shift_r[0];
assign read = (instr == INSTR_READ);
assign write = (instr == INSTR_WRITE);

always @(posedge jtag_tck or posedge jtag_rst)
begin
	if (jtag_rst) begin
		shift_r <= {(sw){1'b0}};
	end
	else if (jtag_shift) begin
		/* shift mode */
		shift_r[sw-1:0] <= { jtag_tdi, shift_r[sw-1:1] };
	end
	else begin
		/* capture mode */
		shift_r[2:0] <= instr;
		case (instr)
			INSTR_READ:
			begin
				shift_r[3] <= ack_q;
				shift_r[aw+20:aw+5] <= din;
			end
			INSTR_WRITE:
			begin
			end
			INSTR_IDLE:
			begin
				shift_r <= {(sw){1'b0}};
			end
			INSTR_DETECT:
			begin
				shift_r[4]           <= 1'b1;
				shift_r[aw+4:5]      <= {(aw){1'b0}};
				shift_r[aw+20:aw+5]  <= 16'b1111111111111111;
			end
			INSTR_QUERY:
			begin
				if (~block) begin
					shift_r[aw+4:5]      <= {(aw){1'b1}};
					shift_r[aw+20:aw+5]  <= 16'b1111111111111111;
				end
				else begin
					shift_r[sw-1:3] <= {(sw-3){1'b0}};
				end
			end
			default:
				shift_r[sw-1:3] <= {(sw-3){1'bx}};
		endcase
	end
end

reg [2:0] instr;
reg block;
reg [aw-1:0] addr;
reg [15:0] dout;
reg strobe_toggle;

assign flash_d = (flash_oe_n) ? dout : 16'bz;
assign flash_adr = addr;

/*
 * 2:0            : instr
 * 3              : ack
 * 4              : block
 * (aw+4):5       : addr
 * (aw+20):(aw+5) : data
 */

always @(posedge jtag_update or posedge jtag_rst)
begin
	if (jtag_rst) begin
		instr <= INSTR_IDLE;
		block <= 1'b0;
		addr <= {(aw){1'b0}};
		dout <= 16'h0000;
		strobe_toggle <= 1'b0;
	end
	else begin
		instr <= shift_r[2:0];
		block <= shift_r[4];
		addr <= shift_r[aw+4:5];
		dout <= shift_r[aw+20:aw+5];

		strobe_toggle <= ~strobe_toggle;
	end
end

wire strobe;
reg strobe_q;
reg strobe_qq;
reg strobe_qqq;

assign strobe = strobe_qq ^ strobe_qqq;

always @(posedge sys_clk)
begin
	if (sys_rst) begin
		strobe_q   <= 1'b0;
		strobe_qq  <= 1'b0;
		strobe_qqq <= 1'b0;
	end
	else begin
		strobe_q   <= strobe_toggle;
		strobe_qq  <= strobe_q;
		strobe_qqq <= strobe_qq;
	end
end

reg [3:0] counter;
reg counter_en;
wire counter_done = (counter == timing);

always @(posedge sys_clk)
begin
	if (sys_rst)
		counter <= 4'd0;
	else begin
		if (counter_en & ~counter_done)
			counter <= counter + 4'd1;
		else
			counter <= 4'd0;
	end
end

reg ack_q;
always @(posedge sys_clk)
begin
	if (sys_rst)
		ack_q <= 1'b0;
	else
		ack_q <= ack;
end

parameter IDLE    = 2'd0;
parameter DELAYRD = 2'd1;
parameter DELAYWR = 2'd2;
parameter RD      = 2'd3;

reg [15:0] din;
reg [1:0] state;
reg ack;

always @(posedge sys_clk)
begin
	if (sys_rst) begin
		flash_oe_n <= 1'b1;
		flash_we_n <= 1'b1;
		ack <= 1'b0;
		din <= 16'h0000;
		state <= IDLE;
	end
	else begin
		flash_oe_n <= 1'b1;
		flash_we_n <= 1'b1;
		counter_en <= 1'b0;
		case (state)
			IDLE: begin
				ack <= 1;
				if (strobe)
					if (read)
						state <= DELAYRD;
					else if (write)
						state <= DELAYWR;
			end
			DELAYRD: begin
				ack <= 0;
				flash_oe_n <= 1'b0;
				counter_en <= 1'b1;
				if (counter_done)
					state <= RD;
			end
			DELAYWR: begin
				flash_we_n <= 1'b0;
				counter_en <= 1'b1;
				if (counter_done)
					state <= IDLE;
			end
			RD: begin
				counter_en <= 1'b0;
				din <= flash_d;
				state <= IDLE;
			end
		endcase
	end
end

assign fjmem_update = strobe_toggle;

endmodule
