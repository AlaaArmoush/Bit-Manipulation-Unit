class bmu_reset_test extends bmu_base_test;
  `uvm_component_utils(bmu_reset_test)

  virtual bmu_interface temporal_vif;

  function new(string name = "bmu_reset_test", uvm_component parent = null);
    super.new(name, parent);

    test_timeout = 2us;
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual bmu_interface)::get(this, "", "temporal_vif", temporal_vif)) begin
      `uvm_fatal("NO_TEMPORAL_VIF", "The reset test could not retrieve temporal_vif")
    end
  endfunction : build_phase

  virtual task run_phase(uvm_phase phase);
    bmu_sanity_sequence setup_sequence;
    bmu_sanity_sequence recovery_sequence;

    int unsigned matches_before_reset;
    int unsigned mismatches_before_reset;

    localparam logic [31:0] EXPECTED_RESULT = 32'hA5C3_5A3C;

    phase.raise_objection(this, "Starting synchronous-reset test");

    if ((env == null) ||
        (env.agent == null) ||
        (env.agent.sequencer == null) ||
        (env.scoreboard == null)) begin
      `uvm_fatal("RESET_ENV_INCOMPLETE", "The reset test requires a complete active environment")
    end

    // Create a known nonzero result before reset.
    setup_sequence = bmu_sanity_sequence::type_id::create("setup_sequence");

    if (setup_sequence == null) begin
      `uvm_fatal("NO_SETUP_SEQUENCE", "Failed to create the reset setup sequence")
    end

    setup_sequence.start(env.agent.sequencer);

    wait ((env.scoreboard.match_count >= 1) || (env.scoreboard.mismatch_count != 0));

    if (env.scoreboard.mismatch_count != 0) begin
      `uvm_fatal("RESET_SETUP_FAILED", "Could not establish the pre-reset result")
    end

    if (temporal_vif.monitor_cb.result_ff !== EXPECTED_RESULT) begin
      `uvm_fatal("BAD_PRE_RESET_RESULT", $sformatf("Expected 0x%08h, observed 0x%08h",
                                                   EXPECTED_RESULT,
                                                   temporal_vif.monitor_cb.result_ff))
    end

    matches_before_reset    = env.scoreboard.match_count;
    mismatches_before_reset = env.scoreboard.mismatch_count;

    // Request a reset from the top-level reset owner.
    fork
      begin
        temporal_vif.request_reset();
      end
    join_none

    // The result must not change before the reset clock edge.
    @(negedge temporal_vif.rst_l);
    #1step;

    if (temporal_vif.result_ff !== EXPECTED_RESULT) begin
      `uvm_error("ASYNCHRONOUS_RESET_RESPONSE",
                 $sformatf({"result changed before the reset clock edge: ",
                            "expected=0x%08h actual=0x%08h"}, EXPECTED_RESULT,
                             temporal_vif.result_ff))
    end

    // Check the first active reset edge.
    @(temporal_vif.monitor_cb);

    if ((temporal_vif.monitor_cb.result_ff !== 32'h0000_0000) ||
        (temporal_vif.monitor_cb.error !== 1'b0)) begin
      `uvm_error("RESET_OUTPUT_NOT_CLEAR", $sformatf("result=0x%08h error=%0b",
                                                     temporal_vif.monitor_cb.result_ff,
                                                     temporal_vif.monitor_cb.error))
    end

    wait fork;

    // Reset must not create a scoreboard comparison.
    if ((env.scoreboard.match_count != matches_before_reset) ||
        (env.scoreboard.mismatch_count != mismatches_before_reset)) begin
      `uvm_error("STALE_RESET_COMPARISON", "The scoreboard performed a comparison during reset")
    end

    // Check the first operation after reset release.
    recovery_sequence = bmu_sanity_sequence::type_id::create("recovery_sequence");

    if (recovery_sequence == null) begin
      `uvm_fatal("NO_RECOVERY_SEQUENCE", "Failed to create the recovery sequence")
    end

    recovery_sequence.start(env.agent.sequencer);

    // Allow the recovery observation to reach the scoreboard.
    #1step;

    if ((env.scoreboard.match_count != (matches_before_reset + 1)) ||
        (env.scoreboard.mismatch_count != mismatches_before_reset)) begin
      `uvm_error("RECOVERY_CHECK_COUNT",
                 $sformatf({"The first post-reset operation was not checked exactly once: ",
                            "expected matches/mismatches=%0d/%0d actual=%0d/%0d"},
                             matches_before_reset + 1, mismatches_before_reset,
                             env.scoreboard.match_count, env.scoreboard.mismatch_count))
    end else begin
      `uvm_info("RESET_TEST_COMPLETE",
                "Reset counts remained unchanged and the first recovery operation was checked exactly once",
                UVM_NONE)
    end

    phase.drop_objection(this, "Synchronous-reset test completed");
  endtask : run_phase

endclass : bmu_reset_test
