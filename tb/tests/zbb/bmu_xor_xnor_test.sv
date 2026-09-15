class bmu_xor_xnor_test extends bmu_base_test;
  `uvm_component_utils(bmu_xor_xnor_test)

  function new(string name = "bmu_xor_xnor_test", uvm_component parent = null);
    super.new(name, parent);

    test_timeout = 2us;
  endfunction : new

  virtual task run_phase(uvm_phase phase);
    bmu_xor_xnor_sequence xor_xnor_sequence;
    real                  xor_xnor_coverage;

    phase.raise_objection(this, "Starting XOR/XNOR feature sequence");

    xor_xnor_sequence = bmu_xor_xnor_sequence::type_id::create("xor_xnor_sequence");

    if (xor_xnor_sequence == null) begin
      `uvm_fatal("NO_XOR_XNOR_SEQUENCE", "Failed to create the XOR/XNOR feature sequence")
    end

    if ((env == null) ||
        (env.agent == null) ||
        (env.agent.sequencer == null) ||
        (env.scoreboard == null) ||
        (env.coverage_subscriber == null)) begin
      `uvm_fatal("XOR_XNOR_ENV_INCOMPLETE",
                 "The XOR/XNOR test requires a complete active BMU environment")
    end

    xor_xnor_sequence.start(env.agent.sequencer);

    wait (
        (env.scoreboard.match_count >=
         bmu_xor_xnor_sequence::TOTAL_REQUEST_COUNT) ||
        (env.scoreboard.mismatch_count != 0)
    );

    xor_xnor_coverage = env.coverage_subscriber.xor_xnor_cg.get_inst_coverage();

    if (env.scoreboard.mismatch_count != 0) begin
      `uvm_info("XOR_XNOR_CHECK_FAILURE",
                $sformatf({"XOR/XNOR checking failed: matches=%0d ",
                           "mismatches=%0d coverage=%0.2f%%"}, env.scoreboard.match_count,
                            env.scoreboard.mismatch_count, xor_xnor_coverage), UVM_NONE)
    end else if (xor_xnor_coverage < 100.0) begin
      `uvm_error("XOR_XNOR_COVERAGE_MISS",
                 $sformatf("XOR/XNOR functional coverage is incomplete: %0.2f%%",
                           xor_xnor_coverage))
    end else begin
      `uvm_info("XOR_XNOR_COMPLETE", $sformatf(
                {
                  "XOR/XNOR checks completed: matches=%0d ", "mismatches=0 coverage=%0.2f%%"
                },
                env.scoreboard.match_count,
                xor_xnor_coverage
                ), UVM_NONE)
    end

    phase.drop_objection(this, "XOR/XNOR feature sequence completed");
  endtask : run_phase

endclass : bmu_xor_xnor_test
