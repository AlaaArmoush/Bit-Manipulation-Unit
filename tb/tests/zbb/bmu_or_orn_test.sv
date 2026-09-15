class bmu_or_orn_test extends bmu_base_test;
  `uvm_component_utils(bmu_or_orn_test)

  function new(string name = "bmu_or_orn_test", uvm_component parent = null);
    super.new(name, parent);

    test_timeout = 2us;
  endfunction : new

  virtual task run_phase(uvm_phase phase);
    bmu_or_orn_sequence or_orn_sequence;
    real                or_orn_coverage;

    phase.raise_objection(this, "Starting OR/ORN feature sequence");

    or_orn_sequence = bmu_or_orn_sequence::type_id::create("or_orn_sequence");

    if (or_orn_sequence == null) begin
      `uvm_fatal("NO_OR_ORN_SEQUENCE", "Failed to create the OR/ORN feature sequence")
    end

    if ((env == null) ||
        (env.agent == null) ||
        (env.agent.sequencer == null) ||
        (env.scoreboard == null) ||
        (env.coverage_subscriber == null)) begin
      `uvm_fatal("OR_ORN_ENV_INCOMPLETE",
                 "The OR/ORN test requires a complete active BMU environment")
    end

    or_orn_sequence.start(env.agent.sequencer);

    wait (
        (env.scoreboard.match_count >=
         bmu_or_orn_sequence::TOTAL_REQUEST_COUNT) ||
        (env.scoreboard.mismatch_count != 0)
    );

    or_orn_coverage = env.coverage_subscriber.or_orn_cg.get_inst_coverage();

    if (or_orn_coverage < 100.0) begin
      `uvm_error("OR_ORN_COVERAGE_MISS",
                 $sformatf("OR/ORN functional coverage is incomplete: %0.2f%%", or_orn_coverage))
    end else begin
      `uvm_info("OR_ORN_COMPLETE", $sformatf(
                {
                  "OR/ORN checks completed: matches=%0d ", "mismatches=%0d coverage=%0.2f%%"
                },
                env.scoreboard.match_count,
                env.scoreboard.mismatch_count,
                or_orn_coverage
                ), UVM_NONE)
    end

    phase.drop_objection(this, "OR/ORN feature sequence completed");
  endtask : run_phase

endclass : bmu_or_orn_test
