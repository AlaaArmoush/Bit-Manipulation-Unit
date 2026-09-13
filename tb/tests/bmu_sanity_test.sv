class bmu_sanity_test extends bmu_base_test;
  `uvm_component_utils(bmu_sanity_test)

  function new(string name = "bmu_sanity_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual task run_phase(uvm_phase phase);
    bmu_sanity_sequence sanity_seq;

    phase.raise_objection(this, "Starting BMU end-to-end sanity sequence");

    sanity_seq = bmu_sanity_sequence::type_id::create("sanity_seq");

    if (sanity_seq == null) begin
      `uvm_fatal("NO_SEQUENCE", "Failed to create the sanity sequence")
    end

    if ((env == null) || (env.agent == null) || (env.agent.sequencer == null)) begin
      `uvm_fatal("NO_SEQUENCER", "The active BMU agent did not provide a sequencer")
    end

    sanity_seq.start(env.agent.sequencer);

    wait ((env.scoreboard.match_count + env.scoreboard.mismatch_count) > 0);

    `uvm_info("SANITY_COMPLETE", "The scoreboard completed the sanity transaction check", UVM_LOW)

    phase.drop_objection(this, "BMU end-to-end sanity sequence completed");
  endtask : run_phase

endclass : bmu_sanity_test

