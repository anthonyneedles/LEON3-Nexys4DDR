# Makefile template for LEON3-Nexys4DDR, using bcc/rcc
# Anthony Needles
#
# User must define the following:
# - BLD_DIR
# - TARGET
# - C_SRC
# - A_SRC

# Compiler Definitions ########################################################

CC = $(PREFIX)-gcc
CCFLAGS  = -std=gnu99 -O2 -Wall -Wextra
CCFLAGS += -MMD -MP -MF $*.d
CCFLAGS += -msoft-float -mcpu=leon3 -qbsp=leon3

CP = $(PREFIX)-objcopy
CPFLAGS  = -O binary

LD = $(PREFIX)-gcc
LDFLAGS = -msoft-float -mcpu=leon3 -qbsp=leon3
#LDFLAGS  = -T $(BLD_DIR)/leon3-nexys4ddr.ld

MP = mkprom2
MPFLAGS  = -leon3 -freq 70 -ddrram 128 -ddrfreq 140 -baud 38377
MPFLAGS += -noinit -msoft-float -nocomp
MPFLAGS += -rstaddr 0x800000  -ccprefix $(PREFIX)

# Build Rules #################################################################

BIN = $(TARGET).bin
ELF = $(TARGET).elf
ROM = $(TARGET).rom

OBJ = $(C_SRC:%.c=%.o) $(A_SRC:%.S=%.o)
DEP = $(C_SRC:%.c=%.d) $(A_SRC:%.S=%.d)

hdr_print = "\n\033[1;38;5;183m$(1)\033[0m"

.PHONY: $(TARGET)
$(TARGET): $(BIN) $(ELF) $(ROM)
		@echo $(call hdr_print,"Make success for target $(TARGET)")

$(ROM): $(ELF)
		@echo $(call hdr_print,"Making bootable ROM image $@ from $^:")
		$(MP) $(MPFLAGS) $(ELF) -o $(ROM)

$(BIN): $(ELF)
		@echo $(call hdr_print,"Creating $@ from $^:")
		$(CP) $(CPFLAGS) $(ELF) $(BIN)

$(ELF): $(OBJ)
		@echo $(call hdr_print,"Linking $@ from $^:")
		$(LD) $(LDFLAGS) $(OBJ) -o $(ELF)

%.o : %.c
		@echo $(call hdr_print,"Compiling $@ from $<:")
		$(CC) $(CCFLAGS) -c $< -o $@

%.o : %.S
		@echo $(call hdr_print,"Compiling $@ from $<:")
		$(CC) $(CCFLAGS) -c -o $@ $<

-include $(DEP)

# Utility Rules ###############################################################

.PHONY: clean
clean:
		@echo $(call hdr_print,"Cleaning: $(ROM) $(BIN) $(ELF) $(OBJ) $(DEP)")
		@rm -f $(ROM) $(BIN) $(ELF) $(OBJ) $(DEP)

.PHONY: help
help:
	  @echo $(call hdr_print,"Make commands:")
		@echo $(call hdr_print,"clean")
		@echo "  Removes all object, dependency, and bin files"
		@echo $(call hdr_print,"$(TARGET)")
		@echo "  Build complete software target"
