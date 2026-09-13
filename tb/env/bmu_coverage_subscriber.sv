class bmu_coverage_subscriber extends uvm_subscriber #(bmu_sequence_item);

  `uvm_component_utils(bmu_coverage_subscriber)

  protected bmu_sequence_item sampled_transaction;
  protected int unsigned      sample_count;

  covergroup sanity_flow_cg;
    //track each individual instance instead of global pooling
    option.per_instance = 1;

    accept_cp: coverpoint sampled_transaction.valid_in iff (sampled_transaction.rst_l === 1'b1) {
      bins accepted = {1'b1};
    }
  endgroup : sanity_flow_cg

  function new(string name = "bmu_coverage_subscriber", uvm_component parent = null);
    super.new(name, parent);

    sampled_transaction = null;
    sample_count        = 0;
    sanity_flow_cg      = new();
  endfunction : new

  virtual function void write(bmu_sequence_item t);
    if (t == null) begin
      `uvm_fatal("NULL_COVERAGE_TRANSACTION", "The coverage subscriber received a null transaction")
      return;
    end

    sampled_transaction = bmu_sequence_item::type_id::create("coverage_snapshot");

    if (sampled_transaction == null) begin
      `uvm_fatal("NO_COVERAGE_SNAPSHOT", "Failed to create a stable coverage snapshot")
      return;
    end

    sampled_transaction.copy(t);
    sample_observation();
  endfunction : write

  protected virtual function void sample_observation();
    sample_count++;
    sanity_flow_cg.sample();

    `uvm_info(
        "COVERAGE_SAMPLE", $sformatf(
        "Received stable observation %0d: %s", sample_count, sampled_transaction.convert2string()),
        UVM_HIGH)
  endfunction : sample_observation

  virtual function void check_phase(uvm_phase phase);
    super.check_phase(phase);

    if (sanity_flow_cg.get_inst_coverage() < 100.0) begin
      `uvm_error("SANITY_COVERAGE_MISS",
                 "No accepted post-reset request reached the coverage subscriber")
    end
  endfunction : check_phase

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);

    `uvm_info("COVERAGE_SUMMARY", $sformatf(
              {
                "observations=%0d ", "sanity_accept_coverage=%0.2f%%"
              },
              sample_count,
              sanity_flow_cg.get_inst_coverage()
              ), UVM_NONE)
  endfunction : report_phase

endclass
