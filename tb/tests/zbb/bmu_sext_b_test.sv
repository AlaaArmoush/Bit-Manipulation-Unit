class bmu_sext_b_test extends bmu_base_test;
  `uvm_component_utils(bmu_sext_b_test)

  function new(string name = "bmu_sext_b_test", uvm_component parent = null);
    super.new(name, parent);

    test_timeout = 2us;
  endfunction : new

  virtual task run_phase(uvm_phase phase);
    bmu_sext_b_sequence sext_b_sequence;
    real                sext_b_coverage;

    phase.raise_objection(this, "Starting SEXT.B feature sequence");

    if ((env == null) ||
        (env.agent == null) ||
        (env.agent.sequencer == null) ||
        (env.scoreboard == null) ||
        (env.coverage_subscriber == null)) begin
      `uvm_fatal("SEXT_B_ENV_INCOMPLETE",
                 "The SEXT.B test requires a complete active BMU environment")
    end

    sext_b_sequence = bmu_sext_b_sequence::type_id::create("sext_b_sequence");

    if (sext_b_sequence == null) begin
      `uvm_fatal("NO_SEXT_B_SEQUENCE", "Failed to create the SEXT.B feature sequence")
    end

    sext_b_sequence.start(env.agent.sequencer);

    wait (
        (env.scoreboard.match_count >=
         bmu_sext_b_sequence::TOTAL_REQUEST_COUNT) ||
        (env.scoreboard.mismatch_count != 0)
    );

    sext_b_coverage = env.coverage_subscriber.sext_b_cg.get_inst_coverage();

    if (env.scoreboard.mismatch_count != 0) begin
      `uvm_info("SEXT_B_CHECK_FAILURE",
                $sformatf(
                    {"SEXT.B checking failed: matches=%0d ", "mismatches=%0d coverage=%0.2f%%"},
                      env.scoreboard.match_count, env.scoreboard.mismatch_count, sext_b_coverage),
                UVM_NONE)
    end else if (sext_b_coverage < 100.0) begin
      `uvm_error("SEXT_B_COVERAGE_MISS",
                 $sformatf("SEXT.B functional coverage is incomplete: %0.2f%%", sext_b_coverage))
    end else begin
      `uvm_info("SEXT_B_COMPLETE", $sformatf(
                {
                  "SEXT.B checks completed: matches=%0d ", "mismatches=0 coverage=%0.2f%%"
                },
                env.scoreboard.match_count,
                sext_b_coverage
                ), UVM_NONE)
    end

    phase.drop_objection(this, "SEXT.B feature sequence completed");
  endtask : run_phase

endclass : bmu_sext_b_test
