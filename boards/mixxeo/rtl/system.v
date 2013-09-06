/*
 * Milkymist VJ SoC fjmem flasher
 * Copyright (C) 2010 Michael Walle
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
 */

module system(
    input clk50,
    
    /* flash */
    output [23:0] flash_adr,
    inout [15:0] flash_d,
    output flash_oe_n,
    output flash_we_n,
    output flash_ce_n,
    output flash_rst_n,
    input flash_sts,

	/* debug */
	output led
);

/* clock and reset */
wire sys_rst;
wire sys_clk;
assign sys_clk = clk50;
assign sys_rst = 1'b0;

/* flash control pins */
assign flash_ce_n = 1'b0;
assign flash_rst_n = 1'b1;

/* debug */
wire fjmem_update;
reg [25:0] counter;
always @(posedge sys_clk)
	counter <= counter + 1'd1;

assign led = counter[25] ^ fjmem_update;

fjmem #(
    .adr_width(24)
) fjmem (
    .sys_clk(sys_clk),
    .sys_rst(sys_rst),

    .flash_adr(flash_adr),
    .flash_d(flash_d),
    .flash_oe_n(flash_oe_n),
    .flash_we_n(flash_we_n),

	.fjmem_update(fjmem_update)
);

endmodule
