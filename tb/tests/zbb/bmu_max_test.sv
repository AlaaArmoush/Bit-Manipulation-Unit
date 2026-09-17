class bmu_max_test extends bmu_base_test;
  `uvm_component_utils(bmu_max_test)

  function new(string name = "bmu_max_test", uvm_component parent = null);
    super.new(name, parent);

    test_timeout = 2us;
  endfunction : new

  virtual task run_phase(uvm_phase phase);
    bmu_max_sequence max_sequence;
    real             max_coverage;

    phase.raise_objection(this, "Starting signed MAX feature sequence");

    if ((env == null) ||
        (env.agent == null) ||
        (env.agent.sequencer == null) ||
        (env.scoreboard == null) ||
        (env.coverage_subscriber == null)) begin
      `uvm_fatal("MAX_ENV_INCOMPLETE",
                 "The signed MAX test requires a complete active BMU environment")
    end

    max_sequence = bmu_max_sequence::type_id::create("max_sequence");

    if (max_sequence == null) begin
      `uvm_fatal("NO_MAX_SEQUENCE", "Failed to create the signed MAX feature sequence")
    end

    max_sequence.start(env.agent.sequencer);

    wait (
        (env.scoreboard.match_count >=
         bmu_max_sequence::TOTAL_REQUEST_COUNT) ||
        (env.scoreboard.mismatch_count != 0)
    );

    max_coverage = env.coverage_subscriber.max_cg.get_inst_coverage();

    if (env.scoreboard.mismatch_count != 0) begin
      `uvm_info("MAX_CHECK_FAILURE",
                $sformatf({"Signed MAX checking failed: matches=%0d ",
                           "mismatches=%0d coverage=%0.2f%%"}, env.scoreboard.match_count,
                            env.scoreboard.mismatch_count, max_coverage), UVM_NONE)
    end else if (max_coverage < 100.0) begin
      `uvm_error("MAX_COVERAGE_MISS",
                 $sformatf("Signed MAX functional coverage is incomplete: %0.2f%%", max_coverage))
    end else begin
      `uvm_info("MAX_COMPLETE", $sformatf(
                {
                  "Signed MAX checks completed: matches=%0d ", "mismatches=0 coverage=%0.2f%%"
                },
                env.scoreboard.match_count,
                max_coverage
                ), UVM_NONE)
    end

    phase.drop_objection(this, "Signed MAX feature sequence completed");
  endtask : run_phase

endclass : bmu_max_test
