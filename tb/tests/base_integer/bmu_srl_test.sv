class bmu_srl_test extends bmu_base_test;
  `uvm_component_utils(bmu_srl_test)

  function new(string name = "bmu_srl_test", uvm_component parent = null);
    super.new(name, parent);

    test_timeout = 2us;
  endfunction : new

  virtual task run_phase(uvm_phase phase);
    bmu_srl_sequence srl_sequence;
    real             srl_coverage;

    phase.raise_objection(this, "Starting SRL feature sequence");

    if ((env == null) ||
        (env.agent == null) ||
        (env.agent.sequencer == null) ||
        (env.scoreboard == null) ||
        (env.coverage_subscriber == null)) begin
      `uvm_fatal("SRL_ENV_INCOMPLETE", "The SRL test requires a complete active BMU environment")
    end

    srl_sequence = bmu_srl_sequence::type_id::create("srl_sequence");

    if (srl_sequence == null) begin
      `uvm_fatal("NO_SRL_SEQUENCE", "Failed to create the SRL feature sequence")
    end

    srl_sequence.start(env.agent.sequencer);

    wait (
        (env.scoreboard.match_count >=
         bmu_srl_sequence::TOTAL_REQUEST_COUNT) ||
        (env.scoreboard.mismatch_count != 0)
    );

    srl_coverage = env.coverage_subscriber.srl_cg.get_inst_coverage();

    if (env.scoreboard.mismatch_count != 0) begin
      `uvm_info("SRL_CHECK_FAILURE",
                $sformatf({"SRL checking failed: matches=%0d ", "mismatches=%0d coverage=%0.2f%%"},
                            env.scoreboard.match_count, env.scoreboard.mismatch_count,
                            srl_coverage), UVM_NONE)
    end else if (srl_coverage < 100.0) begin
      `uvm_error("SRL_COVERAGE_MISS", $sformatf("SRL functional coverage is incomplete: %0.2f%%",
                                                srl_coverage))
    end else begin
      `uvm_info("SRL_COMPLETE", $sformatf(
                {
                  "SRL checks completed: matches=%0d ", "mismatches=0 coverage=%0.2f%%"
                },
                env.scoreboard.match_count,
                srl_coverage
                ), UVM_NONE)
    end

    phase.drop_objection(this, "SRL feature sequence completed");
  endtask : run_phase

endclass : bmu_srl_test
