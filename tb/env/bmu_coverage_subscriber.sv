class bmu_coverage_subscriber extends uvm_subscriber #(bmu_sequence_item);
  `uvm_component_utils(bmu_coverage_subscriber)

  protected bmu_sequence_item sampled_transaction;
  protected int unsigned sample_count;

  /*
  feature covergroups will be added here
  */

  function new(string name = "bmu_coverage_subscriber", uvm_component parent = null);
    super.new(name, parent);

    sampled_transaction = null;
    sample_count        = 0;
    // covergroups construction will be here
  endfunction : new

  virtual function void write(bmu_sequence_item t);
    if (t == null) begin
      `uvm_fatal("NULL_COVERAGE_TRANSACTION", "The coverage subscriber received a null transaction")
      return;
    end

    sampled_transaction = bmu_sequence_item::type_id::create("coverage_snapshot");
    sampled_transaction.copy(t);

    sample_observation();
  endfunction : write

  protected virtual function void sample_observation();
    sample_count++;
    //sample covergroups here
    `uvm_info("COVERAGE_SAMPLE", $sformatf(
              "Received stable monitor observation %0d: %s",
              sample_count,
              sampled_transaction.convert2string()
              ), UVM_HIGH)
  endfunction

  virtual function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    if (sample_count == 0)
      `uvm_error("NO_COVERAGE_SAMPLES", "The coverage subscriber received no monitor observations")
  endfunction : check_phase

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("COVERAGE_SUMMARY", $sformatf(
              "Coverage subscriber received %0d stable observation(s)", sample_count), UVM_NONE)
  endfunction : report_phase

endclass
