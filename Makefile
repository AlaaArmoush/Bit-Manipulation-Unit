SHELL := /bin/bash

.DELETE_ON_ERROR:
.PHONY: help check clean

XRUN       ?= xrun
XRUN_FLAGS ?= -64bit -sv -uvm
TOP        ?= tb_top
SNAPSHOT   ?= bmu_tb_snapshot

RTL_FILELIST ?= rtl/files_rtl.f
TB_FILELIST  ?= filelist.f

BUILD_DIR   := build
COMPILE_DIR := $(BUILD_DIR)/compile

help:
	@echo "make check  - compile and elaborate the testbench"
	@echo "make clean  - remove generated build output"

check:
	@test -f "$(RTL_FILELIST)" || { echo "ERROR: missing $(RTL_FILELIST)"; exit 2; }
	@test -f "$(TB_FILELIST)"  || { echo "ERROR: missing $(TB_FILELIST)"; exit 2; }
	@mkdir -p "$(COMPILE_DIR)"
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

clean:
	@test "$(BUILD_DIR)" = "build"
	rm -rf -- "$(BUILD_DIR)"
