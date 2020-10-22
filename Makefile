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
	
ifeq ($(PLATFORM),HOST)#if HOST is selected
	CC = gcc #Compiler is gcc (native)
	CFLAGS = -DHOST  # C Programming Flags Defines macro
	LD = ld #linker to be used
	OBJECTS = $(SOURCES:.c=.o)#OBJECTS is a vector which contains all the .o generated files from the source files
	DEPENDENCIES = $(SOURCES:.c=.d)#DEPENDENCIES is a vector which contains all the .d generated files from the source files
	ASSEMBLY = $(SOURCES:.c=.asm)#ASSEMBLY is a vector which contains all the .d generated files from the source files
	PREPROCESSOR = $(SOURCES:.c=.i)#PREPROCESSOR is a vector which contains all the .d generated files from the source files
	LDFLAGS = -Wl,-Map=$(TARGET).map #Linker flags
	CPPFLAGS = -g -O0 -std=c99 -Wall -Werror $(INCLUDES) #C Preprocessor flags
else
	CC = arm-none-eabi-gcc
	CFLAGS = -DMSP432 -mcpu=$(CPU) -march=$(ARCH) -mthumb -mfloat-abi=hard -mfpu=fpv4-sp-d16 --specs=$(SPECS) 
	LD = arm-none-eabi-ld
	OBJECTS = $(SOURCES_MSP432:.c=.o)
	DEPENDENCIES = $(SOURCES_MSP432:.c=.d)
	ASSEMBLY = $(SOURCES_MSP432:.c=.asm)	
	PREPROCESSOR = $(SOURCES_MSP432:.c=.i)
	LDFLAGS = -Wl,-Map=$(TARGET).map -Wl,-T../$(LINKER_FILE)
	CPPFLAGS = -g -O0 -std=c99 -Wall -Werror $(INCLUDES_MSP432)
endif

-include $(DEPENDENCIES) #include the generated dependencies in the makefile, prefix -silences errors if the .d files don't yet exist
#********************************************Targets*****************************************************
#The format %.*:%.c makes sure that any .o, .i or .asm file to be created will have a .c file associated with the same name
# $@ is the name of the target being generated
# $< is the first prerequisite (usually a source file)

# FILE.i target binary
%.i: %.c
	$(CC) -E $< $(CFLAGS) $(CPPFLAGS) -o $@

# FILE.asm target binary
%.asm: %.c
	$(CC) -S $< $(CFLAGS) $(CPPFLAGS) -o $@ #arm-none-eabi-objdump utilize -objdump utility, this may be used in the build target

# FILE.o target binary stop after the stage of compilation proper; do not assemble. The output is in the form of an assembler code file for
#each non-assembler input file specified
$%.o: %.c
	$(CC) -c $< $(CFLAGS) $(CPPFLAGS) -o $@

# Dependencies
%.d: %.c
	$(CC) $(CFLAGS) $(CPPFLAGS) -MF $@ -MG -MM -MP -MT $(<:.c=.o) $<
# -MD  generates a dependency output file as a side-effect of the compilation process
# -MF  write the generated dependency rule to a file
# -MG  assume missing headers will be generated and don't stop with an error
# -MM  generate dependency rule for prerequisite, skipping system headers
# -MP  add phony target for each header to prevent errors when header is missing
# -MT  add a target to the generated dependency
# Taken from a forum discussion in https://stackoverflow.com/questions/97338/gcc-dependency-generation-for-a-different-output-directory

# Compilation of all source files without linking them
.PHONY: compile_all
compile_all: $(TARGET)	
$(TARGET): $(OBJECTS)
	$(CC) -MMD -c $< $(OBJECTS) $(CFLAGS) $(CPPFLAGS) $(LDFLAGS) -o $@

# Build of all source files
.PHONY: build
build: $(TARGET).out	
$(TARGET).out: $(OBJECTS) 
	$(CC) -MMD $(OBJECTS) $(CFLAGS) $(CPPFLAGS) $(LDFLAGS) -o $@


# Cleans all generated files from the build
.PHONY: clean
clean:
	rm -f $(OBJECTS) $(TARGET).out $(TARGET).map $(DEPENDENCIES) $(ASSEMBLY) $(PREPROCESSOR)
# Cleans all generated files from the build
.PHONY: clean
clean:
	rm -f $(OBJECTS) $(TARGET).out $(TARGET).map $(DEPENDENCIES).d #$(OBJECTS).asm $(OBJECTS).i


