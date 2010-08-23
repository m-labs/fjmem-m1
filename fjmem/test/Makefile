SOURCES=tb_fjmem.v ../rtl/fjmem_core.v

all: isim

isim: tb_fjmem
	./tb_fjmem

cversim: $(SOURCES)
	cver $(SOURCES)

clean:
	rm -f tb_fjmem verilog.log fjmem.vcd

tb_fjmem: $(SOURCES)
	iverilog -o tb_fjmem $(SOURCES)

.PHONY: clean sim cversim

