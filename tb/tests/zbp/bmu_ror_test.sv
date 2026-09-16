class bmu_ror_test extends bmu_base_test;
  `uvm_component_utils(bmu_ror_test)

  function new(string name = "bmu_ror_test", uvm_component parent = null);
    super.new(name, parent);

    test_timeout = 2us;
  endfunction : new

  virtual task run_phase(uvm_phase phase);
    bmu_ror_sequence ror_sequence;
    real             ror_coverage;

    phase.raise_objection(this, "Starting ROR feature sequence");

    if ((env == null) ||
        (env.agent == null) ||
        (env.agent.sequencer == null) ||
        (env.scoreboard == null) ||
        (env.coverage_subscriber == null)) begin
      `uvm_fatal("ROR_ENV_INCOMPLETE", "The ROR test requires a complete active BMU environment")
    end

    ror_sequence = bmu_ror_sequence::type_id::create("ror_sequence");

    if (ror_sequence == null) begin
      `uvm_fatal("NO_ROR_SEQUENCE", "Failed to create the ROR feature sequence")
    end

    ror_sequence.start(env.agent.sequencer);

    wait (
        (env.scoreboard.match_count >=
         bmu_ror_sequence::TOTAL_REQUEST_COUNT) ||
        (env.scoreboard.mismatch_count != 0)
    );

    ror_coverage = env.coverage_subscriber.ror_cg.get_inst_coverage();

    if (env.scoreboard.mismatch_count != 0) begin
      `uvm_info("ROR_CHECK_FAILURE",
                $sformatf({"ROR checking failed: matches=%0d ", "mismatches=%0d coverage=%0.2f%%"},
                            env.scoreboard.match_count, env.scoreboard.mismatch_count,
                            ror_coverage), UVM_NONE)
    end else if (ror_coverage < 100.0) begin
      `uvm_error("ROR_COVERAGE_MISS", $sformatf("ROR functional coverage is incomplete: %0.2f%%",
                                                ror_coverage))
    end else begin
      `uvm_info("ROR_COMPLETE", $sformatf(
                {
                  "ROR checks completed: matches=%0d ", "mismatches=0 coverage=%0.2f%%"
                },
                env.scoreboard.match_count,
                ror_coverage
                ), UVM_NONE)
    end

    phase.drop_objection(this, "ROR feature sequence completed");
  endtask : run_phase

endclass : bmu_ror_test
