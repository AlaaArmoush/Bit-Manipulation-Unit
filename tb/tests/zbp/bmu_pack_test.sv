class bmu_pack_test extends bmu_base_test;
  `uvm_component_utils(bmu_pack_test)

  function new(string name = "bmu_pack_test", uvm_component parent = null);
    super.new(name, parent);

    test_timeout = 2us;
  endfunction : new

  virtual task run_phase(uvm_phase phase);
    bmu_pack_sequence pack_sequence;
    real              pack_coverage;

    phase.raise_objection(this, "Starting PACK feature sequence");

    if ((env == null) ||
        (env.agent == null) ||
        (env.agent.sequencer == null) ||
        (env.scoreboard == null) ||
        (env.coverage_subscriber == null)) begin
      `uvm_fatal("PACK_ENV_INCOMPLETE", "The PACK test requires a complete active BMU environment")
    end

    pack_sequence = bmu_pack_sequence::type_id::create("pack_sequence");

    if (pack_sequence == null) begin
      `uvm_fatal("NO_PACK_SEQUENCE", "Failed to create the PACK feature sequence")
    end

    pack_sequence.start(env.agent.sequencer);

    wait (
        (env.scoreboard.match_count >=
         bmu_pack_sequence::TOTAL_REQUEST_COUNT) ||
        (env.scoreboard.mismatch_count != 0)
    );

    pack_coverage = env.coverage_subscriber.pack_cg.get_inst_coverage();

    if (env.scoreboard.mismatch_count != 0) begin
      `uvm_info("PACK_CHECK_FAILURE",
                $sformatf({"PACK checking failed: matches=%0d ", "mismatches=%0d coverage=%0.2f%%"
                            }, env.scoreboard.match_count, env.scoreboard.mismatch_count,
                            pack_coverage), UVM_NONE)
    end else if (pack_coverage < 100.0) begin
      `uvm_error("PACK_COVERAGE_MISS", $sformatf("PACK functional coverage is incomplete: %0.2f%%",
                                                 pack_coverage))
    end else begin
      `uvm_info("PACK_COMPLETE", $sformatf(
                {
                  "PACK checks completed: matches=%0d ", "mismatches=0 coverage=%0.2f%%"
                },
                env.scoreboard.match_count,
                pack_coverage
                ), UVM_NONE)
    end

    phase.drop_objection(this, "PACK feature sequence completed");
  endtask : run_phase

endclass : bmu_pack_test
