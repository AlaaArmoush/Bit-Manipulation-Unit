SHELL := /bin/bash

.DELETE_ON_ERROR:
.PHONY: help check test clean

XRUN           ?= xrun
XRUN_FLAGS     ?= -64bit -sv -uvm -coverage functional -timescale 1ns/1ps
XRUN_RUN_FLAGS ?= -64bit -R -coverage functional -covoverwrite

TOP          ?= tb_top
SNAPSHOT     ?= bmu_tb_snapshot
TEST         ?= bmu_sanity_test
SEED         ?= 1
UVM_VERBOSITY ?= UVM_LOW

RTL_FILELIST ?= rtl/files_rtl.f
TB_FILELIST  ?= filelist.f

BUILD_DIR     := build
COMPILE_DIR   := $(BUILD_DIR)/compile
COMPILE_STAMP := $(COMPILE_DIR)/.check_passed
RUN_DIR        = $(BUILD_DIR)/runs/$(TEST)_seed_$(SEED)

help:
	@echo "make check"
	@echo "  Compile and elaborate the reusable BMU snapshot."
	@echo
	@echo "make test TEST=<uvm_test_name> SEED=<seed> [UVM_VERBOSITY=<level>]"
	@echo "  Run a test from the reusable snapshot."
	@echo
	@echo "make clean"
	@echo "  Remove only generated output beneath build/."

check:
	@test -f "$(RTL_FILELIST)" || { echo "ERROR: missing $(RTL_FILELIST)"; exit 2; }
	@test -f "$(TB_FILELIST)"  || { echo "ERROR: missing $(TB_FILELIST)"; exit 2; }
	@mkdir -p "$(COMPILE_DIR)"
	@rm -f -- "$(COMPILE_STAMP)"
	$(XRUN) $(XRUN_FLAGS) \
		-f "$(RTL_FILELIST)" \
		-f "$(TB_FILELIST)" \
		-top "$(TOP)" \
		-elaborate \
		-snapshot "$(SNAPSHOT)" \
		-xmlibdirname "$(COMPILE_DIR)/xcelium.d" \
		-logfile "$(COMPILE_DIR)/xrun.log" \
		-history_file "$(COMPILE_DIR)/xrun.history" \
		-keyfile "$(COMPILE_DIR)/xrun.key"
	@touch "$(COMPILE_STAMP)"

test:
	@test -n "$(TEST)" || { echo "ERROR: TEST must not be empty"; exit 2; }
	@test -n "$(SEED)" || { echo "ERROR: SEED must not be empty"; exit 2; }
	@test -f "$(COMPILE_STAMP)" || { \
		echo "ERROR: no successful reusable snapshot; run 'make check' first"; \
		exit 2; \
	}
	@mkdir -p "$(RUN_DIR)"
	cd "$(RUN_DIR)" && \
		$(XRUN) $(XRUN_RUN_FLAGS) \
		-snapshot "$(SNAPSHOT)" \
		-xmlibdirname "../../compile/xcelium.d" \
		+UVM_TESTNAME="$(TEST)" \
		+UVM_VERBOSITY="$(UVM_VERBOSITY)" \
		+BMU_SEED="$(SEED)" \
		-svseed "$(SEED)" \
		-logfile xrun.log \
		-history_file xrun.history \
		-keyfile xrun.key

clean:
	@test "$(BUILD_DIR)" = "build"
	rm -rf -- "$(BUILD_DIR)"
