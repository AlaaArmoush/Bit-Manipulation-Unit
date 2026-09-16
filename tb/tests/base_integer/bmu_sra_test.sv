class bmu_sra_test extends bmu_base_test;
  `uvm_component_utils(bmu_sra_test)

  function new(string name = "bmu_sra_test", uvm_component parent = null);
    super.new(name, parent);

    test_timeout = 2us;
  endfunction : new

  virtual task run_phase(uvm_phase phase);
    bmu_sra_sequence sra_sequence;
    real             sra_coverage;

    phase.raise_objection(this, "Starting SRA feature sequence");

    if ((env == null) ||
        (env.agent == null) ||
        (env.agent.sequencer == null) ||
        (env.scoreboard == null) ||
        (env.coverage_subscriber == null)) begin
      `uvm_fatal("SRA_ENV_INCOMPLETE", "The SRA test requires a complete active BMU environment")
    end

    sra_sequence = bmu_sra_sequence::type_id::create("sra_sequence");

    if (sra_sequence == null) begin
      `uvm_fatal("NO_SRA_SEQUENCE", "Failed to create the SRA feature sequence")
    end

    sra_sequence.start(env.agent.sequencer);

    wait (
        (env.scoreboard.match_count >=
         bmu_sra_sequence::TOTAL_REQUEST_COUNT) ||
        (env.scoreboard.mismatch_count != 0)
    );

    sra_coverage = env.coverage_subscriber.sra_cg.get_inst_coverage();

    if (env.scoreboard.mismatch_count != 0) begin
      `uvm_info("SRA_CHECK_FAILURE",
                $sformatf({"SRA checking failed: matches=%0d ", "mismatches=%0d coverage=%0.2f%%"},
                            env.scoreboard.match_count, env.scoreboard.mismatch_count,
                            sra_coverage), UVM_NONE)
    end else if (sra_coverage < 100.0) begin
      `uvm_error("SRA_COVERAGE_MISS", $sformatf("SRA functional coverage is incomplete: %0.2f%%",
                                                sra_coverage))
    end else begin
      `uvm_info("SRA_COMPLETE", $sformatf(
                {
                  "SRA checks completed: matches=%0d ", "mismatches=0 coverage=%0.2f%%"
                },
                env.scoreboard.match_count,
                sra_coverage
                ), UVM_NONE)
    end

    phase.drop_objection(this, "SRA feature sequence completed");
  endtask : run_phase

endclass : bmu_sra_test
