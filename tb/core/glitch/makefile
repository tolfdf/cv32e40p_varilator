SRCS:=$(wildcard *.c)
ELFS:=$(SRCS:.c=.elf)
HEXS:=$(SRCS:.c=.hex)
DUMPS:=$(SRCS:.c=.dump)

all: $(HEXS) $(DUMPS) 

.PRECIOUS: %.elf
%.elf: %.c
	riscv32-unknown-elf-gcc -march=rv32imc_zicsr -o $@ -w -Os -g -nostdlib \
        -T ../custom/link.ld \
        -static \
        ../custom/crt0.S \
        $^ ../custom/syscalls.c ../custom/vectors.S \
        -lc -lm -lgcc

%.dump: %.elf
	riscv32-unknown-elf-objdump -DS $^ > $@ 

%.hex: %.elf
	riscv32-unknown-elf-objcopy -O verilog $^ $@ 

clean:
	-rm *.hex *.elf *.dump
