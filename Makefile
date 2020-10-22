#**********************************************************************************************************************************
# 2020 by Braulio Peraza - Embbeded software student from Coursera
#
# Redistribution, modification or use of this software in source or binary is allowed, feel free to use it and send feedback to:
# brawkio@gmail.com
#
#------------------------------------------------------------------------------------------------------------------------------------
# This makefile is for intended to be used as a Native and CrossCompiler Builder for HOST and the MSP432 platform.
# 
#
# Use: make [TARGET] [PLATFORM-OVERRIDES]
#
# Build Targets:
# <FILE.i>    - Builds <FILE.i> preprocessed output of all c-program implementation files.
# <FILE.asm>  - Builds <FILE.asm> assembly output of c-program implementation files and the final output executable named
# (c1m2_assembly),also throwing an assembly report using the objdump utility.
# <FILE.o>    - Builds <FILE.o> object file for all c-source files (but do not link).
# compile-all - Compile all object files, but DO NOT link.
# build       - Compile all object files and link into a final executable (c1m2.out), also creating a report of the size of 
# the program using the size utility.
# clean       - Removes all compiled objects, preprocessed outputs, assembly outputs, executable files and build output files.
#    
# 
# Platform Overrides:
#      
# PLATFORM - Developmet platform used (MSP432,HOST)
#------------------------------------------------------------------------------------------------------------------------------------
include sources.mk

LINKER_FILE = msp432p401r.lds 
CPU = cortex-m4
ARCH = armv7e-m
SPECS = nosys.specs
TARGET = c1m2
TARGET_ASSEMBLY = c1m2_assembly#this target is created with the solely purpose of avoiding the override in the recipe between the
#targets build and %.asm:%.c thus allowing to generate two different targets with the same recipe.

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
	LDFLAGS_ASSEMBLY = -Wl,-Map=$(TARGET_ASSEMBLY).map #Linker flags for the assembly build
	CPPFLAGS = -g -O0 -std=c99 -Wall -Werror $(INCLUDES) #C Preprocessor flags
	OBJ = objdump -d#Utility for throwing assembly code from the output file
	SZ = size#Utility for throwing the data size from the output file
else
	CC = arm-none-eabi-gcc
	CFLAGS = -DMSP432 -mcpu=$(CPU) -march=$(ARCH) -mthumb -mfloat-abi=hard -mfpu=fpv4-sp-d16 --specs=$(SPECS) 
	LD = arm-none-eabi-ld
	OBJECTS = $(SOURCES_MSP432:.c=.o)
	DEPENDENCIES = $(SOURCES_MSP432:.c=.d)
	ASSEMBLY = $(SOURCES_MSP432:.c=.asm)	
	PREPROCESSOR = $(SOURCES_MSP432:.c=.i)
	LDFLAGS = -Wl,-Map=$(TARGET).map -Wl,-T../$(LINKER_FILE)
	LDFLAGS_ASSEMBLY = -Wl,-Map=$(TARGET_ASSEMBLY).map -Wl,-T../$(LINKER_FILE)#Linker flags for assembly build
	CPPFLAGS = -g -O0 -std=c99 -Wall -Werror $(INCLUDES_MSP432)
	OBJ = arm-none-eabi-objdump -d
	SZ = arm-none-eabi-size
endif

-include $(DEPENDENCIES) #include the generated dependencies in the makefile, prefix -silences errors if the .d files don't yet exist
#**********************************************************Targets*******************************************************************
#The format %.*:%.c makes sure that any .o, .i or .asm file to be created will have a .c file associated with the same name
# $@ is the name of the target being generated
# $< is the first prerequisite (usually a source file)

# FILE.i target binary
%.i: %.c
	$(CC) -E $< $(CFLAGS) $(CPPFLAGS) -o $@

# FILE.asm target binary
%.asm: %.c $(TARGET_ASSEMBLY).out
	$(CC) -S $< $(CFLAGS) $(CPPFLAGS) -o $@
$(TARGET_ASSEMBLY).out:$(OBJECTS) 
	$(CC) $(OBJECTS) $(CFLAGS) $(CPPFLAGS) $(LDFLAGS_ASSEMBLY) -o $@
	$(OBJ) $(TARGET_ASSEMBLY).out
	
# FILE.o target binary stop after the stage of compilation proper; do not assemble. The output is in the form of an assembler
# code file for each non-assembler input file specified
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
# Info taken from a forum discussion in:
# https://stackoverflow.com/questions/97338/gcc-dependency-generation-for-a-different-output-directory

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
	$(SZ) -Atd $@ # All memory sections compiled
	$(SZ) -Bx $@ # Section size in binary
	$(SZ) -Bd $@ # Section size i decimal

# Cleans all generated files from the build
.PHONY: clean
clean:
	rm -f $(OBJECTS) $(TARGET).out $(TARGET).map $(TARGET_ASSEMBLY).out $(TARGET_ASSEMBLY).map $(DEPENDENCIES) $(ASSEMBLY) $(PREPROCESSOR)
