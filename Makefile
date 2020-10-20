#******************************************************************************
# Copyright (C) 2017 by Alex Fosdick - University of Colorado
#
# Redistribution, modification or use of this software in source or binary
# forms is permitted as long as the files maintain this copyright. Users are 
# permitted to modify this and use it to learn about the field of embedded
# software. Alex Fosdick and the University of Colorado are not liable for any
# misuse of this material. 
#
#------------------------------------------------------------------------------
# This makefile is for intended to be used as a Native and CrossCompiler Builder for HOST and the MSP432 platform.
#
# Use: make [TARGET] [PLATFORM-OVERRIDES]
#
# Build Targets:
# <FILE.i>    - Builds <FILE.i> preprocessed output of all c-program implementation files.
# <FILE.asm>  - Builds <FILE.asm> assembly output of c-program implementation files and the final output executable.
# <FILE.o>    - Builds <FILE.o> object file for all c-source files (but do not link).
# compile-all - Compile all object files, but DO NOT link.
# build       - Compile all object files and link into a final executable.
# clean       - Removes all compiled objects, preprocessed outputs, assembly outputs, executable files and build output files.
#    
# 
# Platform Overrides:
#      
# PLATFORM - Developmet platform used (MSP432,HOST)
#------------------------------------------------------------------------------
include sources.mk

# Platform Overrides
	
ifeq ($(PLATFORM),HOST)
		CC = gcc
		# etc
		CPU = 
		ARCH = 
		SPECS = 
	else
		# Architectures Specific Flags		
		CC = arm-none-eabi-gcc
		CPU = -mcpu=cortex-m4
		ARCH = -mthumb -march=armv7e-m -mfloat-abi=hard -mfpu=fpv4-sp-d16
		SPECS = --specs=nosys.specs
		LD = arm-none-eabi-ld
		# Platform Specific Flags
		LNKER_FILE = -T msp432p401r.lds

	endif

# Compiler Flags and Defines
CFLAGS = -Wall -Werror -std=c99 -g
CPPFLAGS = 
BASENAME = c1m2
TARGET = $(BASENAME).out
LDFLAGS = -O0 -map=$(BASENAME).map

OBJECTS  :=$(SOURCES:.c=.o)

%.o : %.c
	$(CC) -c
.PHONY: build
build:all
.PHONY: all
all: $(TARGET)

$(TARGET): $(OBJECTS) $(CFLAGS) $(LDFFLAGS) -o $@

.PHONY: clean
clean:
	rm -f $(OBJECTS) $(TARGET) $(BASENAME)




