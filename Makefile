# Fortran compiler.
FC = gfortran

# Directories for build and source code
BUILD_DIR = build-cmake
SRC_DIR = src

# Path to the main executable
MAIN_EXE = $(BUILD_DIR)/bin/seird_main

# ANSI color codes for formatted terminal output
GREEN  := \033[0;32m
YELLOW := \033[0;33m
RED    := \033[0;31m
NC     := \033[0m  # No color

# Declare phony targets (not associated with actual files)
.PHONY: all clean run test cmake-build

# Default target: build everything using CMake
all: cmake-build

# Create the build directory if it doesn't exist
$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)
	@printf "$(GREEN)==> Build folder created: $(BUILD_DIR)$(NC)\n"

# Configure and compile the project with CMake
cmake-build: $(BUILD_DIR)
	@printf "$(GREEN)==> Configuring project with CMake...$(NC)\n"
	cd $(BUILD_DIR) && cmake .. > /dev/null
	@printf "$(GREEN)==> Building project...$(NC)\n"
	cd $(BUILD_DIR) && $(MAKE) --no-print-directory
	@printf "$(GREEN)==> Build completed ✅$(NC)\n"

# Run the main executable with optional arguments
run: cmake-build
	@printf "$(YELLOW)==> Running binary: $(MAIN_EXE)$(NC)\n"
	./$(MAIN_EXE) $(ARGS)

# Run tests defined in CTest after building
test: cmake-build
	@printf "$(YELLOW)==> Running tests...$(NC)\n"
	cd $(BUILD_DIR) && ctest --verbose

# Remove the build directory and all compiled files
clean:
	@printf "$(RED)==> Cleaning build...$(NC)\n"
	@rm -rf $(BUILD_DIR)
	@printf "$(RED)==> Build folder removed ✅$(NC)\n"
