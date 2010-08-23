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

module fjmem_jtag (
	output jtag_tck,
	output jtag_rst,
	output jtag_update,
	output jtag_shift,
	output jtag_tdi,
	input jtag_tdo
);

BSCAN_SPARTAN6 #(
	.JTAG_CHAIN(1)
) bscan (
	.CAPTURE(),
	.DRCK(jtag_tck),
	.RESET(jtag_rst),
	.RUNTEST(),
	.SEL(),
	.SHIFT(jtag_shift),
	.TCK(),
	.TDI(jtag_tdi),
	.TMS(),
	.UPDATE(jtag_update),
	.TDO(jtag_tdo)
);

endmodule
