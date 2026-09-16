class bmu_sh2add_test extends bmu_base_test;
  `uvm_component_utils(bmu_sh2add_test)

  function new(string name = "bmu_sh2add_test", uvm_component parent = null);
    super.new(name, parent);

    test_timeout = 2us;
  endfunction : new

  virtual task run_phase(uvm_phase phase);
    bmu_sh2add_sequence sh2add_sequence;
    real                sh2add_coverage;

    phase.raise_objection(this, "Starting SH2ADD feature sequence");

    if ((env == null) ||
        (env.agent == null) ||
        (env.agent.sequencer == null) ||
        (env.scoreboard == null) ||
        (env.coverage_subscriber == null)) begin
      `uvm_fatal("SH2ADD_ENV_INCOMPLETE",
                 "The SH2ADD test requires a complete active BMU environment")
    end

    sh2add_sequence = bmu_sh2add_sequence::type_id::create("sh2add_sequence");

    if (sh2add_sequence == null) begin
      `uvm_fatal("NO_SH2ADD_SEQUENCE", "Failed to create the SH2ADD feature sequence")
    end

    sh2add_sequence.start(env.agent.sequencer);

    wait (
        (env.scoreboard.match_count >=
         bmu_sh2add_sequence::TOTAL_REQUEST_COUNT) ||
        (env.scoreboard.mismatch_count != 0)
    );

    sh2add_coverage = env.coverage_subscriber.sh2add_cg.get_inst_coverage();

    if (env.scoreboard.mismatch_count != 0) begin
      `uvm_info("SH2ADD_CHECK_FAILURE",
                $sformatf(
                    {"SH2ADD checking failed: matches=%0d ", "mismatches=%0d coverage=%0.2f%%"},
                      env.scoreboard.match_count, env.scoreboard.mismatch_count, sh2add_coverage),
                UVM_NONE)
    end else if (sh2add_coverage < 100.0) begin
      `uvm_error("SH2ADD_COVERAGE_MISS",
                 $sformatf("SH2ADD functional coverage is incomplete: %0.2f%%", sh2add_coverage))
    end else begin
      `uvm_info("SH2ADD_COMPLETE", $sformatf(
                {
                  "SH2ADD checks completed: matches=%0d ", "mismatches=0 coverage=%0.2f%%"
                },
                env.scoreboard.match_count,
                sh2add_coverage
                ), UVM_NONE)
    end

    phase.drop_objection(this, "SH2ADD feature sequence completed");
  endtask : run_phase

endclass : bmu_sh2add_test
