class bmu_csr_read_test extends bmu_base_test;
  `uvm_component_utils(bmu_csr_read_test)

  function new(string name = "bmu_csr_read_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual task run_phase(uvm_phase phase);
    bmu_csr_read_sequence csr_read_sequence;
    real csr_read_coverage;

    phase.raise_objection(this, "Starting CSR-read feature sequence");

    csr_read_sequence = bmu_csr_read_sequence::type_id::create("csr_read_sequence");

    if (csr_read_sequence == null) begin
      `uvm_fatal("NO_CSR_READ_SEQUENCE", "Failed to create the CSR-read feature sequence")
    end

    if ((env == null) ||
        (env.agent == null) ||
        (env.agent.sequencer == null) ||
        (env.scoreboard == null) ||
        (env.coverage_subscriber == null)) begin
      `uvm_fatal("CSR_READ_ENV_INCOMPLETE",
                 "The CSR-read test requires a complete active BMU environment")
    end

    csr_read_sequence.start(env.agent.sequencer);

    wait (
        (env.scoreboard.match_count ==
         bmu_csr_read_sequence::TOTAL_REQUEST_COUNT) ||
        (env.scoreboard.mismatch_count != 0)
    );

    csr_read_coverage = env.coverage_subscriber.csr_read_cg.get_inst_coverage();

    if (csr_read_coverage < 100.0) begin
      `uvm_error("CSR_READ_COVERAGE_MISS",
                 $sformatf("CSR-read functional coverage is incomplete: %0.2f%%",
                           csr_read_coverage))
    end else begin
      `uvm_info("CSR_READ_COMPLETE", $sformatf(
                {
                  "CSR-read checks completed: matches=%0d mismatches=%0d ", "coverage=%0.2f%%"
                },
                env.scoreboard.match_count,
                env.scoreboard.mismatch_count,
                csr_read_coverage
                ), UVM_NONE)
    end

    phase.drop_objection(this, "CSR-read feature sequence completed");
  endtask : run_phase

endclass : bmu_csr_read_test
