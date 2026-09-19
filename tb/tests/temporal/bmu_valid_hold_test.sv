class bmu_valid_hold_test extends bmu_base_test;
  `uvm_component_utils(bmu_valid_hold_test)

  function new(string name = "bmu_valid_hold_test", uvm_component parent = null);
    super.new(name, parent);

    test_timeout = 2us;
  endfunction : new

  virtual task run_phase(uvm_phase phase);
    bmu_valid_hold_sequence valid_hold_sequence;
    real                    valid_hold_coverage;

    phase.raise_objection(this, "Starting valid-in idle-hold test");

    if ((env == null) ||
        (env.agent == null) ||
        (env.agent.sequencer == null) ||
        (env.scoreboard == null) ||
        (env.coverage_subscriber == null)) begin
      `uvm_fatal("VALID_HOLD_ENV_INCOMPLETE",
                 "The valid-hold test requires a complete active BMU environment")
    end

    valid_hold_sequence = bmu_valid_hold_sequence::type_id::create("valid_hold_sequence");

    if (valid_hold_sequence == null) begin
      `uvm_fatal("NO_VALID_HOLD_SEQUENCE", "Failed to create the valid-hold sequence")
    end

    valid_hold_sequence.start(env.agent.sequencer);

    // Allow the last monitor observation to reach all subscribers.
    #1step;

    if ((env.scoreboard.match_count != 1) || (env.scoreboard.mismatch_count != 0)) begin
      `uvm_error("VALID_HOLD_SETUP_FAILED",
                 $sformatf("Expected one passing setup check: matches=%0d mismatches=%0d",
                           env.scoreboard.match_count, env.scoreboard.mismatch_count))
    end

    valid_hold_coverage = env.coverage_subscriber.valid_hold_cg.get_inst_coverage();

    if (valid_hold_coverage < 100.0) begin
      `uvm_error("VALID_HOLD_COVERAGE_MISS",
                 $sformatf("Valid-hold coverage is incomplete: %0.2f%%", valid_hold_coverage))
    end else begin
      `uvm_info("VALID_HOLD_COMPLETE", $sformatf(
                "Valid-hold checks completed with %0.2f%% coverage", valid_hold_coverage), UVM_NONE)
    end

    phase.drop_objection(this, "Valid-in idle-hold test completed");
  endtask : run_phase

endclass : bmu_valid_hold_test
