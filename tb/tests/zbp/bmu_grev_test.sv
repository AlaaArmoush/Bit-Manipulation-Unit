class bmu_grev_test extends bmu_base_test;
  `uvm_component_utils(bmu_grev_test)

  function new(string name = "bmu_grev_test", uvm_component parent = null);
    super.new(name, parent);

    test_timeout = 2us;
  endfunction : new

  virtual task run_phase(uvm_phase phase);
    bmu_grev_sequence grev_sequence;
    real              grev_coverage;

    phase.raise_objection(this, "Starting GREV byte-reverse feature sequence");

    if ((env == null) ||
        (env.agent == null) ||
        (env.agent.sequencer == null) ||
        (env.scoreboard == null) ||
        (env.coverage_subscriber == null)) begin
      `uvm_fatal("GREV_ENV_INCOMPLETE", "The GREV test requires a complete active BMU environment")
    end

    grev_sequence = bmu_grev_sequence::type_id::create("grev_sequence");

    if (grev_sequence == null) begin
      `uvm_fatal("NO_GREV_SEQUENCE", "Failed to create the GREV byte-reverse feature sequence")
    end

    grev_sequence.start(env.agent.sequencer);

    wait (
        (env.scoreboard.match_count >=
         bmu_grev_sequence::TOTAL_REQUEST_COUNT) ||
        (env.scoreboard.mismatch_count != 0)
    );

    grev_coverage = env.coverage_subscriber.grev_cg.get_inst_coverage();

    if (env.scoreboard.mismatch_count != 0) begin
      `uvm_info("GREV_CHECK_FAILURE",
                $sformatf({"GREV checking failed: matches=%0d ", "mismatches=%0d coverage=%0.2f%%"
                            }, env.scoreboard.match_count, env.scoreboard.mismatch_count,
                            grev_coverage), UVM_NONE)
    end else if (grev_coverage < 100.0) begin
      `uvm_error("GREV_COVERAGE_MISS", $sformatf("GREV functional coverage is incomplete: %0.2f%%",
                                                 grev_coverage))
    end else begin
      `uvm_info("GREV_COMPLETE", $sformatf(
                {
                  "GREV checks completed: matches=%0d ", "mismatches=0 coverage=%0.2f%%"
                },
                env.scoreboard.match_count,
                grev_coverage
                ), UVM_NONE)
    end

    phase.drop_objection(this, "GREV byte-reverse feature sequence completed");
  endtask : run_phase

endclass : bmu_grev_test
