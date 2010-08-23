/*
 * Milkymist VJ SoC fjmem flasher
 * Copyright (C) 2010 Michael Walle <michael@walle.cc>
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
 */

module fjmem #(
	parameter adr_width = 24
) (
	input sys_clk,
	input sys_rst,

	/* flash */
	output [adr_width-1:0] flash_adr,
	inout [15:0] flash_d,
	output flash_oe_n,
	output flash_we_n,

	/* debug output */
	output fjmem_update
);

wire jtag_tck;
wire jtag_rst;
wire jtag_update;
wire jtag_shift;
wire jtag_tdi;
wire jtag_tdo;

fjmem_core #(
	.adr_width(adr_width)
) core (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	/* jtag */
	.jtag_tck(jtag_tck),
	.jtag_rst(jtag_rst),
	.jtag_update(jtag_update),
	.jtag_shift(jtag_shift),
	.jtag_tdi(jtag_tdi),
	.jtag_tdo(jtag_tdo),

	/* flash */
	.flash_adr(flash_adr),
	.flash_d(flash_d),
	.flash_oe_n(flash_oe_n),
	.flash_we_n(flash_we_n),

	/* debug */
	.fjmem_update(fjmem_update)
);

fjmem_jtag jtag (
	.jtag_tck(jtag_tck),
	.jtag_rst(jtag_rst),
	.jtag_update(jtag_update),
	.jtag_shift(jtag_shift),
	.jtag_tdi(jtag_tdi),
	.jtag_tdo(jtag_tdo)
);

endmodule
