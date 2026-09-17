`timescale 1ns / 1ps

package bmu_pkg;

  // UVM dependencies
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  typedef enum {
    BMU_OP_UNKNOWN,
    BMU_OP_INVALID_CONTROL,
    BMU_OP_CSR_READ,
    BMU_OP_CSR_WRITE_REGISTER,
    BMU_OP_CSR_WRITE_IMMEDIATE,
    BMU_OP_OR,
    BMU_OP_ORN,
    BMU_OP_XOR,
    BMU_OP_XNOR,
    BMU_OP_SRL,
    BMU_OP_SRA,
    BMU_OP_ROR,
    BMU_OP_BINV,
    BMU_OP_SH2ADD,
    BMU_OP_SUB,
    BMU_OP_SLT,
    BMU_OP_SLTU
  } bmu_operation_e;

  // Transaction and sequencer
  `include "agent/bmu_sequence_item.sv"
  `include "agent/bmu_sequencer.sv"

  // Base and sanity sequences
  `include "sequences/bmu_base_sequence.sv"
  `include "sequences/bmu_sanity_sequence.sv"

  // CSR sequences
  `include "sequences/csr/bmu_csr_read_sequence.sv"
  `include "sequences/csr/bmu_csr_write_sequence.sv"

  // Base-integer sequences
  `include "sequences/base_integer/bmu_srl_sequence.sv"
  `include "sequences/base_integer/bmu_sra_sequence.sv"
  `include "sequences/base_integer/bmu_sub_sequence.sv"
  `include "sequences/base_integer/bmu_slt_sequence.sv"

  // Zba sequences
  `include "sequences/zba/bmu_sh2add_sequence.sv"

  // Zbp sequences
  `include "sequences/zbp/bmu_ror_sequence.sv"

  // Zbs sequences
  `include "sequences/zbs/bmu_binv_sequence.sv"

  // Zbb sequences
  `include "sequences/zbb/bmu_or_orn_sequence.sv"
  `include "sequences/zbb/bmu_xor_xnor_sequence.sv"

  // Agent components
  `include "agent/bmu_driver.sv"
  `include "agent/bmu_monitor.sv"
  `include "agent/bmu_agent.sv"

  // Environment components
  `include "env/bmu_reference_model.sv"
  `include "env/bmu_scoreboard.sv"
  `include "env/bmu_coverage_subscriber.sv"
  `include "env/bmu_environment.sv"

  // Base and sanity tests
  `include "tests/bmu_base_test.sv"
  `include "tests/bmu_sanity_test.sv"

  // CSR tests
  `include "tests/csr/bmu_csr_read_test.sv"
  `include "tests/csr/bmu_csr_write_test.sv"

  // Base-integer tests
  `include "tests/base_integer/bmu_srl_test.sv"
  `include "tests/base_integer/bmu_sra_test.sv"
  `include "tests/base_integer/bmu_sub_test.sv"
  `include "tests/base_integer/bmu_slt_test.sv"

  // Zba tests
  `include "tests/zba/bmu_sh2add_test.sv"

  // Zbp tests
  `include "tests/zbp/bmu_ror_test.sv"

  // Zbs tests
  `include "tests/zbs/bmu_binv_test.sv"

  // Zbb tests
  `include "tests/zbb/bmu_or_orn_test.sv"
  `include "tests/zbb/bmu_xor_xnor_test.sv"

endpackage : bmu_pkg
