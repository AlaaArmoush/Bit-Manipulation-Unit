class bmu_cpop_test extends bmu_base_test;
  `uvm_component_utils(bmu_cpop_test)

  function new(string name = "bmu_cpop_test", uvm_component parent = null);
    super.new(name, parent);

    test_timeout = 2us;
  endfunction : new

  virtual task run_phase(uvm_phase phase);
    bmu_cpop_sequence cpop_sequence;
    real              cpop_coverage;

    phase.raise_objection(this, "Starting CPOP feature sequence");

    if ((env == null) ||
        (env.agent == null) ||
        (env.agent.sequencer == null) ||
        (env.scoreboard == null) ||
        (env.coverage_subscriber == null)) begin
      `uvm_fatal("CPOP_ENV_INCOMPLETE", "The CPOP test requires a complete active BMU environment")
    end

    cpop_sequence = bmu_cpop_sequence::type_id::create("cpop_sequence");

    if (cpop_sequence == null) begin
      `uvm_fatal("NO_CPOP_SEQUENCE", "Failed to create the CPOP feature sequence")
    end

    cpop_sequence.start(env.agent.sequencer);

    wait (
        (env.scoreboard.match_count >=
         bmu_cpop_sequence::TOTAL_REQUEST_COUNT) ||
        (env.scoreboard.mismatch_count != 0)
    );

    cpop_coverage = env.coverage_subscriber.cpop_cg.get_inst_coverage();

    if (env.scoreboard.mismatch_count != 0) begin
      `uvm_info("CPOP_CHECK_FAILURE",
                $sformatf({"CPOP checking failed: matches=%0d ", "mismatches=%0d coverage=%0.2f%%"
                            }, env.scoreboard.match_count, env.scoreboard.mismatch_count,
                            cpop_coverage), UVM_NONE)
    end else if (cpop_coverage < 100.0) begin
      `uvm_error("CPOP_COVERAGE_MISS", $sformatf("CPOP functional coverage is incomplete: %0.2f%%",
                                                 cpop_coverage))
    end else begin
      `uvm_info("CPOP_COMPLETE", $sformatf(
                {
                  "CPOP checks completed: matches=%0d ", "mismatches=0 coverage=%0.2f%%"
                },
                env.scoreboard.match_count,
                cpop_coverage
                ), UVM_NONE)
    end

    phase.drop_objection(this, "CPOP feature sequence completed");
  endtask : run_phase

endclass : bmu_cpop_test
