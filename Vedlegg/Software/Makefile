# The Great Heterogenous Bitcoin Miner Project
# Written as part of their master's thesis by:
# 	Kristian Klomsten Skordal <kristian.skordal@wafflemail.net>
#	Torbjørn Langland <torbljan@stud.ntnu.no>
# Read the report on <https://github.com/skordal/tdt4102-master>

.PHONY: all clean remake

TARGET_PREFIX ?= arm-none-eabi

TARGET_CC ?= $(TARGET_PREFIX)-gcc
TARGET_LD ?= $(TARGET_PREFIX)-ld
TARGET_OBJCOPY ?= $(TARGET_PREFIX)-objcopy
TARGET_SIZE ?= $(TARGET_PREFIX)-size

TARGET_CFLAGS += -march=armv4t -std=gnu99 -O3 -fomit-frame-pointer -Wall \
	-Werror=implicit-function-declaration -ffreestanding \
	-mno-unaligned-access -DUSE_IMPROVED_MUTEXES -DSHA256_USE_HARDWARE=1 \
	-DNUM_SCRATCHPADS=2 -DBENCHMARK_PASSES=2 -DENABLE_NUM_CORES=14 -DUSE_CACHES \
	-DUSE_INTERRUPTS  -DUSE_DMA=1
TARGET_LDFLAGS += -nostartfiles -Wl,--fix-v4bx

OBJECTS := \
	bram.o \
	dma.o \
	exceptions.o \
	irq.o \
	main.o \
	mm.o \
	mutex.o \
	sha256.o \
	shmac.o \
	start.o \
	timer.o

LINKER_SCRIPT ?= bitcoin.ld

all: $(OBJECTS)
	$(TARGET_CC) -o bitcoin.elf -Wl,-T$(LINKER_SCRIPT) $(OBJECTS) $(TARGET_LDFLAGS)
	$(TARGET_OBJCOPY) -O binary -j .text -j .data bitcoin.elf bitcoin.bin
	$(TARGET_SIZE) bitcoin.elf

remake:
	@$(MAKE) clean
	@$(MAKE) all

clean:
	-$(RM) $(OBJECTS)
	-$(RM) bitcoin.elf bitcoin.bin

# Manual dependency tracking for now:
start.o: start.S
main.o: main.c shmac.h
shmac.o: shmac.c shmac.h mutex.h
sha256.o: sha256.c sha256.h shmac.h
dma.o: dma.c dma.h shmac.h

# Pattern rules:
%.o: %.S
	$(TARGET_CC) -c $(TARGET_CFLAGS) -o $@ $<

%.o: %.c %.h
	$(TARGET_CC) -c $(TARGET_CFLAGS) -o $@ $<

%.o: %.c
	$(TARGET_CC) -c $(TARGET_CFLAGS) -o $@ $<

