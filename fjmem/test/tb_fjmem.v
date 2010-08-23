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

`timescale 1ns / 1ps

module tb_fjmem();

parameter adr_width = 24;

/* 100MHz system clock */
reg clk;
initial clk = 1'b0;
always #5 clk = ~clk;

reg rst;

wire [adr_width-1:0] flash_adr;
wire [15:0] flash_d;
wire flash_oe_n;
wire flash_we_n;

reg [15:0] flash_do;
assign flash_d = (flash_oe_n) ? 16'bz : flash_do;

reg jtag_tck;
reg jtag_rst;
reg jtag_update;
reg jtag_shift;
reg jtag_tdi;
wire jtag_tdo;

fjmem_core #(
	.adr_width(adr_width)
) core (
	.sys_clk(clk),
	.sys_rst(rst),

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
	.flash_we_n(flash_we_n)
);

task jtagclock;
	input integer n;
begin
	repeat(n)
	begin
		jtag_tck = 1'b0;
		#50;
		jtag_tck = 1'b1;
		#50;
		jtag_tck = 1'b0;
	end
end
endtask

task jtagshift;
	input integer sw;
	input [63:0] din;
	output [63:0] dout;
begin
	repeat(sw)
	begin 
		jtag_shift = 1'b1;
		jtag_tck = 1'b0;
		{din[62:0], jtag_tdi} = din;

		#50;
		jtag_tck = 1'b1;
		dout = {dout[61:0], jtag_tdo};

		#50;
		jtag_tck = 1'b0;
		jtag_shift = 1'b0;
	end
end
endtask

task jtagupdate;
begin
	jtag_update = 1'b0;
	jtag_tck = 1'b0;
	#50;
	jtag_update = 1'b1;
	jtag_tck = 1'b1;
	#50;
	jtag_update = 1'b0;
	jtag_tck = 1'b0;
end
endtask

task jtagreset;
begin
	jtag_rst = 1'b0;
	jtag_tck = 1'b0;
	#50;
	jtag_rst = 1'b1;
	jtag_tck = 1'b1;
	#50;
	jtag_rst = 1'b0;
	jtag_tck = 1'b0;
end
endtask

parameter IDLE   = 3'b000;
parameter DETECT = 3'b111;
parameter QUERY  = 3'b110;
parameter READ   = 3'b001;
parameter WRITE  = 3'b010;

task fjmemcommand;
input [2:0] cmd;
input block;
input [23:0] adr;
input data;
reg [44:0] din;
reg [44:0] dout;
begin
	din = { data, adr, block, 1'b0, cmd};
	$display("din=%x", din);
	jtagshift(45, din, dout);
	jtagupdate();
	$display("dout=%x", dout);
	$display("data=%x adr=%x block=%x ack=%x cmd=%x",
		dout[44:29], dout[28:5], dout[4], dout[3], dout[2:0]);
end
endtask

always @(negedge flash_oe_n)
begin
	$display("Flash read access @%x: %x", flash_adr, flash_adr[15:0]);
	#110 flash_do = flash_adr[15:0];
end

always @(negedge flash_we_n)
begin
	$display("Flash write access @%x: %x", flash_adr, flash_d[15:0]);
end

reg [44:0] data_r;
always begin
	$dumpfile("fjmem.vcd");
	$dumpvars();

	/* Reset / Initialize our logic */
	rst = 1'b1;
	
	jtag_tck = 1'b0;
	jtag_rst = 1'b0;
	jtag_update = 1'b0;
	jtag_shift = 1'b0;
	jtag_tdi = 1'b0;
	
	#10;
	rst = 1'b0;

	jtagreset();

	fjmemcommand(DETECT, 0, 0, 0);
	fjmemcommand(IDLE, 0, 0, 0);

	$finish;
end

endmodule

