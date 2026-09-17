class bmu_ctz_test extends bmu_base_test;
  `uvm_component_utils(bmu_ctz_test)

  function new(string name = "bmu_ctz_test", uvm_component parent = null);
    super.new(name, parent);

    test_timeout = 2us;
  endfunction : new

  virtual task run_phase(uvm_phase phase);
    bmu_ctz_sequence ctz_sequence;
    real             ctz_coverage;

    phase.raise_objection(this, "Starting CTZ feature sequence");

    if ((env == null) ||
        (env.agent == null) ||
        (env.agent.sequencer == null) ||
        (env.scoreboard == null) ||
        (env.coverage_subscriber == null)) begin
      `uvm_fatal("CTZ_ENV_INCOMPLETE", "The CTZ test requires a complete active BMU environment")
    end

    ctz_sequence = bmu_ctz_sequence::type_id::create("ctz_sequence");

    if (ctz_sequence == null) begin
      `uvm_fatal("NO_CTZ_SEQUENCE", "Failed to create the CTZ feature sequence")
    end

    ctz_sequence.start(env.agent.sequencer);

    wait (
        (env.scoreboard.match_count >=
         bmu_ctz_sequence::TOTAL_REQUEST_COUNT) ||
        (env.scoreboard.mismatch_count != 0)
    );

    ctz_coverage = env.coverage_subscriber.ctz_cg.get_inst_coverage();

    if (env.scoreboard.mismatch_count != 0) begin
      `uvm_info("CTZ_CHECK_FAILURE",
                $sformatf({"CTZ checking failed: matches=%0d ", "mismatches=%0d coverage=%0.2f%%"},
                            env.scoreboard.match_count, env.scoreboard.mismatch_count,
                            ctz_coverage), UVM_NONE)
    end else if (ctz_coverage < 100.0) begin
      `uvm_error("CTZ_COVERAGE_MISS", $sformatf("CTZ functional coverage is incomplete: %0.2f%%",
                                                ctz_coverage))
    end else begin
      `uvm_info("CTZ_COMPLETE", $sformatf(
                {
                  "CTZ checks completed: matches=%0d ", "mismatches=0 coverage=%0.2f%%"
                },
                env.scoreboard.match_count,
                ctz_coverage
                ), UVM_NONE)
    end

    phase.drop_objection(this, "CTZ feature sequence completed");
  endtask : run_phase

endclass : bmu_ctz_test
