# Project Paths ###############################################################

BLD_DIR := ../build

# Compiler Definitions ########################################################

CC = sparc-gaisler-elf-gcc
CCFLAGS  = -std=gnu99 -g -O2 -Wall -Wextra
CCFLAGS += -MMD -MP -MF $*.d
CCFLAGS += -msoft-float -mcpu=leon3

LD = sparc-gaisler-elf-gcc
LDFLAGS  = -T $(BLD_DIR)/leon3-nexys4ddr.ld

# Build Rules #################################################################

BIN = $(TARGET).bin
ELF = $(TARGET).elf

OBJ = $(C_SRC:%.c=%.o) $(A_SRC:%.S=%.o)
DEP = $(C_SRC:%.c=%.d) $(A_SRC:%.S=%.d)

.PHONY: $(TARGET)
$(TARGET): $(BIN)
		@echo "Make success for target '$(TARGET)'"

$(BIN): $(ELF) | $(BIN_DIR)
		@echo "Copying:     $^"
		@$(CP) $(CPFLAGS) $(ELF) $(BIN)
		@echo "Copied:      $@\n"

$(ELF): $(OBJ) | $(BIN_DIR)
		@echo "Linking:     $^"
		@$(LD) $(LDFLAGS) $(OBJ) -o $(ELF)
		@echo "Linked:      $@\n"

$(OBJ_DIR)/%.o : %.c | $(OBJ_DIR) $(DEP_DIR)
		@echo "Compiling:   $<"
		@$(CC) $(CCFLAGS) -c -o $@ $<
		@echo "Compiled:    $@\n"

$(OBJ_DIR)/%.o : %.S | $(OBJ_DIR) $(DEP_DIR)
		@echo "Compiling:   $<"
		@$(CC) $(CCFLAGS) -c -o $@ $<
		@echo "Compiled:    $@\n"

$(BIN_DIR) $(OBJ_DIR) $(DEP_DIR):
		@echo "Making dir:  $@"
		@mkdir $@

-include $(DEP)

# Utility Rules ###############################################################

.PHONY: clean
clean:
		@echo "Cleaning:    $(BIN) $(ELF) $(OBJ) $(DEP)"
		@rm -f $(BIN) $(ELF) $(OBJ) $(DEP)
		@echo "Cleaned"

.PHONY: help
help:
		@echo ""
		@echo "clean"
		@echo "  Removes all object, dependency, and bin files"
		@echo ""
		@echo "$(TARGET)"
		@echo "  Build complete software target"
		@echo ""



