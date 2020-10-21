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
# PLATFORM - Developmet platform used (-DMSP432,-DHOST)
#------------------------------------------------------------------------------
include sources.mk

LINKER_FILE = msp432p401r.lds 
CPU = cortex-m4
ARCH = armv7e-m
SPECS = nosys.specs
TARGET = c1m2

# Platform Overrides
	
ifeq ($(PLATFORM),HOST)
	CC = gcc 
	CFLAGS = -DHOST  
	LD = ld
	OBJECTS = $(SOURCES:.c=.o)#OBJECTS is a vector which contains all the .o associated/created files of the source files
	LDFLAGS = -Wl,-Map=$(TARGET).map
	CPPFLAGS = -g -O0 -std=c99 -Wall -Werror  $(INCLUDES)
else
	CC = arm-none-eabi-gcc
	CFLAGS = -DMSP432 -mcpu=$(CPU) -march=$(ARCH) -mthumb -mfloat-abi=hard -mfpu=fpv4-sp-d16 --specs=$(SPECS) 
	LD = arm-none-eabi-ld
	OBJECTS = $(SOURCES_MSP432:.c=.o)
	LDFLAGS = -Wl,-Map=$(TARGET).map -T../$(LINKER_FILE)
	CPPFLAGS = -g -O0 -std=c99 -Wall -Werror  $(INCLUDES_MSP432)
endif

#********************************************Targets*****************************************************
#Any .o, .i and .asm file to be created will have a .c file associated with the same name

# FILE.i target binary
%.i: %.c
	$(CC) $(CFLAGS) $(CPPFLAGS) -E $@


# FILE.asm target binary
%.asm: %.c
	$(CC) $(CFLAGS) $(CPPFLAGS) -S $@ #utilize -objump utility

# FILE.o target binary
$%.o: %.c
	$(CC) -c $< $(CFLAGS) $(CPPFLAGS) -o $@

# Compilation of all source files without linking them
.PHONY: compile_all
compile_all: $(TARGET)	
$(TARGET): $(OBJECTS)
	$(CC) -c $< $(OBJECTS) $(CFLAGS) $(CPPFLAGS) $(LDFLAGS)


# Build of all source files
.PHONY: build
build:all


# Cleans all generated files from the build
.PHONY: clean
clean:
	rm -f $(OBJECTS) $(TARGET).out $(TARGET).map


