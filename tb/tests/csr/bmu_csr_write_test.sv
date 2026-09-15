class bmu_csr_write_test extends bmu_base_test;
  `uvm_component_utils(bmu_csr_write_test)

  function new(string name = "bmu_csr_write_test", uvm_component parent = null);
    super.new(name, parent);

    test_timeout = 2us;
  endfunction : new

  virtual task run_phase(uvm_phase phase);
    bmu_csr_write_sequence csr_write_sequence;
    real                   csr_write_coverage;

    phase.raise_objection(this, "Starting CSR-write feature sequence");

    csr_write_sequence = bmu_csr_write_sequence::type_id::create("csr_write_sequence");

    if (csr_write_sequence == null) begin
      `uvm_fatal("NO_CSR_WRITE_SEQUENCE", "Failed to create the CSR-write feature sequence")
    end

    if ((env == null) ||
        (env.agent == null) ||
        (env.agent.sequencer == null) ||
        (env.scoreboard == null) ||
        (env.coverage_subscriber == null)) begin
      `uvm_fatal("CSR_WRITE_ENV_INCOMPLETE",
                 "The CSR-write test requires a complete active BMU environment")
    end

    csr_write_sequence.start(env.agent.sequencer);

    wait (
        (env.scoreboard.match_count ==
         bmu_csr_write_sequence::TOTAL_REQUEST_COUNT) ||
        (env.scoreboard.mismatch_count != 0)
    );

    csr_write_coverage = env.coverage_subscriber.csr_write_cg.get_inst_coverage();

    if (csr_write_coverage < 100.0) begin
      `uvm_error("CSR_WRITE_COVERAGE_MISS",
                 $sformatf("CSR-write functional coverage is incomplete: %0.2f%%",
                           csr_write_coverage))
    end else begin
      `uvm_info("CSR_WRITE_COMPLETE", $sformatf(
                {
                  "CSR-write checks completed: matches=%0d ", "mismatches=%0d coverage=%0.2f%%"
                },
                env.scoreboard.match_count,
                env.scoreboard.mismatch_count,
                csr_write_coverage
                ), UVM_NONE)
    end

    phase.drop_objection(this, "CSR-write feature sequence completed");
  endtask : run_phase

endclass : bmu_csr_write_test
