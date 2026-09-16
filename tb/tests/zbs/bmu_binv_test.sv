class bmu_binv_test extends bmu_base_test;
  `uvm_component_utils(bmu_binv_test)

  function new(string name = "bmu_binv_test", uvm_component parent = null);
    super.new(name, parent);

    test_timeout = 2us;
  endfunction : new

  virtual task run_phase(uvm_phase phase);
    bmu_binv_sequence binv_sequence;
    real              binv_coverage;

    phase.raise_objection(this, "Starting BINV feature sequence");

    if ((env == null) ||
        (env.agent == null) ||
        (env.agent.sequencer == null) ||
        (env.scoreboard == null) ||
        (env.coverage_subscriber == null)) begin
      `uvm_fatal("BINV_ENV_INCOMPLETE", "The BINV test requires a complete active BMU environment")
    end

    binv_sequence = bmu_binv_sequence::type_id::create("binv_sequence");

    if (binv_sequence == null) begin
      `uvm_fatal("NO_BINV_SEQUENCE", "Failed to create the BINV feature sequence")
    end

    binv_sequence.start(env.agent.sequencer);

    wait (
        (env.scoreboard.match_count >=
         bmu_binv_sequence::TOTAL_REQUEST_COUNT) ||
        (env.scoreboard.mismatch_count != 0)
    );

    binv_coverage = env.coverage_subscriber.binv_cg.get_inst_coverage();

    if (env.scoreboard.mismatch_count != 0) begin
      `uvm_info("BINV_CHECK_FAILURE",
                $sformatf({"BINV checking failed: matches=%0d ", "mismatches=%0d coverage=%0.2f%%"
                            }, env.scoreboard.match_count, env.scoreboard.mismatch_count,
                            binv_coverage), UVM_NONE)
    end else if (binv_coverage < 100.0) begin
      `uvm_error("BINV_COVERAGE_MISS", $sformatf("BINV functional coverage is incomplete: %0.2f%%",
                                                 binv_coverage))
    end else begin
      `uvm_info("BINV_COMPLETE", $sformatf(
                {
                  "BINV checks completed: matches=%0d ", "mismatches=0 coverage=%0.2f%%"
                },
                env.scoreboard.match_count,
                binv_coverage
                ), UVM_NONE)
    end

    phase.drop_objection(this, "BINV feature sequence completed");
  endtask : run_phase

endclass : bmu_binv_test
