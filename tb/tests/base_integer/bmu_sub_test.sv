class bmu_sub_test extends bmu_base_test;
  `uvm_component_utils(bmu_sub_test)

  function new(string name = "bmu_sub_test", uvm_component parent = null);
    super.new(name, parent);

    test_timeout = 2us;
  endfunction : new

  virtual task run_phase(uvm_phase phase);
    bmu_sub_sequence sub_sequence;
    real             sub_coverage;

    phase.raise_objection(this, "Starting SUB feature sequence");

    if ((env == null) ||
        (env.agent == null) ||
        (env.agent.sequencer == null) ||
        (env.scoreboard == null) ||
        (env.coverage_subscriber == null)) begin
      `uvm_fatal("SUB_ENV_INCOMPLETE", "The SUB test requires a complete active BMU environment")
    end

    sub_sequence = bmu_sub_sequence::type_id::create("sub_sequence");

    if (sub_sequence == null) begin
      `uvm_fatal("NO_SUB_SEQUENCE", "Failed to create the SUB feature sequence")
    end

    sub_sequence.start(env.agent.sequencer);

    wait (
        (env.scoreboard.match_count >=
         bmu_sub_sequence::TOTAL_REQUEST_COUNT) ||
        (env.scoreboard.mismatch_count != 0)
    );

    sub_coverage = env.coverage_subscriber.sub_cg.get_inst_coverage();

    if (env.scoreboard.mismatch_count != 0) begin
      `uvm_info("SUB_CHECK_FAILURE",
                $sformatf("SUB checking failed: matches=%0d mismatches=%0d coverage=%0.2f%%",
                          env.scoreboard.match_count, env.scoreboard.mismatch_count, sub_coverage),
                UVM_NONE)
    end else if (sub_coverage < 100.0) begin
      `uvm_error("SUB_COVERAGE_MISS", $sformatf("SUB functional coverage is incomplete: %0.2f%%",
                                                sub_coverage))
    end else begin
      `uvm_info("SUB_COMPLETE", $sformatf(
                "SUB checks completed: matches=%0d mismatches=0 coverage=%0.2f%%",
                env.scoreboard.match_count,
                sub_coverage
                ), UVM_NONE)
    end

    phase.drop_objection(this, "SUB feature sequence completed");
  endtask : run_phase

endclass : bmu_sub_test
