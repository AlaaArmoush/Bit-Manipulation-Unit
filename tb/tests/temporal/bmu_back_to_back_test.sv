class bmu_back_to_back_test extends bmu_base_test;
  `uvm_component_utils(bmu_back_to_back_test)

  function new(string name = "bmu_back_to_back_test", uvm_component parent = null);
    super.new(name, parent);

    test_timeout = 2us;
  endfunction : new

  virtual task run_phase(uvm_phase phase);
    bmu_back_to_back_sequence back_to_back_sequence;
    real                      back_to_back_coverage;

    phase.raise_objection(this, "Starting back-to-back test");

    if ((env == null) ||
        (env.agent == null) ||
        (env.agent.sequencer == null) ||
        (env.scoreboard == null) ||
        (env.coverage_subscriber == null)) begin
      `uvm_fatal("BACK_TO_BACK_ENV_INCOMPLETE",
                 "The back-to-back test requires a complete active BMU environment")
    end

    back_to_back_sequence = bmu_back_to_back_sequence::type_id::create("back_to_back_sequence");

    if (back_to_back_sequence == null) begin
      `uvm_fatal("NO_BACK_TO_BACK_SEQUENCE", "Failed to create the back-to-back sequence")
    end

    back_to_back_sequence.start(env.agent.sequencer);

    // Allow the final monitor observation and coverage sample to complete.
    #1step;

    if ((env.scoreboard.match_count !=
         bmu_back_to_back_sequence::TOTAL_REQUEST_COUNT) ||
        (env.scoreboard.mismatch_count != 0)) begin
      `uvm_error("BACK_TO_BACK_COUNT_FAILED",
                 $sformatf("Expected matches=%0d mismatches=0; observed matches=%0d mismatches=%0d",
                           bmu_back_to_back_sequence::TOTAL_REQUEST_COUNT,
                           env.scoreboard.match_count, env.scoreboard.mismatch_count))
    end

    back_to_back_coverage = env.coverage_subscriber.back_to_back_cg.get_inst_coverage();

    if (back_to_back_coverage < 100.0) begin
      `uvm_error("BACK_TO_BACK_COVERAGE_MISS",
                 $sformatf("Ordered cross-family coverage is incomplete: %0.2f%%",
                           back_to_back_coverage))
    end else begin
      `uvm_info("BACK_TO_BACK_COMPLETE", $sformatf(
                "Back-to-back checks completed: matches=%0d mismatches=%0d coverage=%0.2f%%",
                env.scoreboard.match_count,
                env.scoreboard.mismatch_count,
                back_to_back_coverage
                ), UVM_NONE)
    end

    phase.drop_objection(this, "Back-to-back test completed");
  endtask : run_phase

endclass : bmu_back_to_back_test

