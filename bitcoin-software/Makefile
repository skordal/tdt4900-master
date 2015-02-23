# The Great Heterogenous Bitcoin Miner Project
# Written as part of their master's thesis by:
# 	Kristian Klomsten Skordal <kristian.skordal@wafflemail.net>
#	Torbjørn Langland <torbljan@stud.ntnu.no>
# Read the report on <https://github.com/skordal/tdt4102-master>

.PHONY: all clean

TARGET_PREFIX ?= arm-none-eabi

TARGET_CC ?= $(TARGET_PREFIX)-gcc
TARGET_LD ?= $(TARGET_PREFIX)-ld
TARGET_OBJCOPY ?= $(TARGET_PREFIX)-objcopy
TARGET_SIZE ?= $(TARGET_PREFIX)-size

TARGET_CFLAGS += -march=armv2a -std=gnu99 -O2 -Wall -ffreestanding -mno-unaligned-access -mno-thumb-interwork
TARGET_LDFLAGS +=  -Wl,--fix-v4bx -nostartfiles

OBJECTS := \
	exceptions.o \
	main.o \
	sha256.o \
	shmac.o \
	start.o

LINKER_SCRIPT ?= bitcoin.ld

all: $(OBJECTS)
	$(TARGET_CC) -o bitcoin.elf -Wl,-T$(LINKER_SCRIPT) $(OBJECTS) $(TARGET_LDFLAGS)
	$(TARGET_OBJCOPY) -O binary -j .text -j .data bitcoin.elf bitcoin.bin
	$(TARGET_SIZE) bitcoin.elf

clean:
	-$(RM) $(OBJECTS)
	-$(RM) bitcoin.elf bitcoin.bin

# Manual dependency tracking for now:
start.o: start.S
main.o: main.c shmac.h
sha256.o: sha256.c sha256.h shmac.h

# Pattern rules:
%.o: %.S
	$(TARGET_CC) -c $(TARGET_CFLAGS) -o $@ $<

%.o: %.c %.h
	$(TARGET_CC) -c $(TARGET_CFLAGS) -o $@ $<

%.o: %.c
	$(TARGET_CC) -c $(TARGET_CFLAGS) -o $@ $<

