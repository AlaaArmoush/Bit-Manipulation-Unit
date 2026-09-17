class bmu_slt_test extends bmu_base_test;
  `uvm_component_utils(bmu_slt_test)

  function new(string name = "bmu_slt_test", uvm_component parent = null);
    super.new(name, parent);

    test_timeout = 2us;
  endfunction : new

  virtual task run_phase(uvm_phase phase);
    bmu_slt_sequence slt_sequence;
    real             slt_coverage;

    phase.raise_objection(this, "Starting SLT/SLTU feature sequence");

    if ((env == null) ||
        (env.agent == null) ||
        (env.agent.sequencer == null) ||
        (env.scoreboard == null) ||
        (env.coverage_subscriber == null)) begin
      `uvm_fatal("SLT_ENV_INCOMPLETE",
                 "The SLT/SLTU test requires a complete active BMU environment")
    end

    slt_sequence = bmu_slt_sequence::type_id::create("slt_sequence");

    if (slt_sequence == null) begin
      `uvm_fatal("NO_SLT_SEQUENCE", "Failed to create the SLT/SLTU feature sequence")
    end

    slt_sequence.start(env.agent.sequencer);

    wait (
        (env.scoreboard.match_count >=
         bmu_slt_sequence::TOTAL_REQUEST_COUNT) ||
        (env.scoreboard.mismatch_count != 0)
    );

    slt_coverage = env.coverage_subscriber.slt_cg.get_inst_coverage();

    if (env.scoreboard.mismatch_count != 0) begin
      `uvm_info("SLT_CHECK_FAILURE",
                $sformatf({"SLT/SLTU checking failed: matches=%0d ",
                           "mismatches=%0d coverage=%0.2f%%"}, env.scoreboard.match_count,
                            env.scoreboard.mismatch_count, slt_coverage), UVM_NONE)
    end else if (slt_coverage < 100.0) begin
      `uvm_error("SLT_COVERAGE_MISS",
                 $sformatf("SLT/SLTU functional coverage is incomplete: %0.2f%%", slt_coverage))
    end else begin
      `uvm_info("SLT_COMPLETE", $sformatf(
                {
                  "SLT/SLTU checks completed: matches=%0d ", "mismatches=0 coverage=%0.2f%%"
                },
                env.scoreboard.match_count,
                slt_coverage
                ), UVM_NONE)
    end

    phase.drop_objection(this, "SLT/SLTU feature sequence completed");
  endtask : run_phase

endclass : bmu_slt_test
