# The Great Heterogenous Bitcoin Miner Project
# Written as part of their master's thesis by:
# 	Kristian Klomsten Skordal <kristian.skordal@wafflemail.net>
#	Torbjørn Langland <torbljan@stud.ntnu.no>
# Read the report on <https://github.com/skordal/tdt4102-master>

.PHONY: all clean

TARGET_PREFIX ?= arm-cortex_a15-linux-gnueabihf

TARGET_CC ?= $(TARGET_PREFIX)-gcc
TARGET_LD ?= $(TARGET_PREFIX)-ld
TARGET_OBJCOPY ?= $(TARGET_PREFIX)-objcopy
TARGET_SIZE ?= $(TARGET_PREFIX)-size

TARGET_CFLAGS += -mcpu=cortex-a15 -std=gnu99 -O2 -g -Wall \
	-Werror=implicit-function-declaration -Wno-unused-result -mfpu=neon-vfpv4 \
	-mfloat-abi=hard -pthread -I.. -I/home/kskordal/arm-libraries/include
TARGET_LDFLAGS +=  -L/home/kskordal/arm-libraries/lib  -ljansson

OBJECTS := \
	line_buffer.o \
	main.o \
	mining_job.o \
	sha256.o \
	stratum.o

all: $(OBJECTS)
	$(TARGET_CC) $(TARGET_CFLAGS) -o bitcoin-host $(TARGET_LDFLAGS) $(OBJECTS)

clean:
	-$(RM) $(OBJECTS)
	-$(RM) bitcoin-host

# Manual dependency tracking for now:
main.o: main.c

# Pattern rules:
%.o: %.S
	$(TARGET_CC) -c $(TARGET_CFLAGS) -o $@ $<

%.o: %.c %.h
	$(TARGET_CC) -c $(TARGET_CFLAGS) -o $@ $<

%.o: %.c
	$(TARGET_CC) -c $(TARGET_CFLAGS) -o $@ $<

