class bmu_coverage_subscriber extends uvm_subscriber #(bmu_sequence_item);

  `uvm_component_utils(bmu_coverage_subscriber)

  protected bmu_sequence_item sampled_transaction;
  protected int unsigned      sample_count;

  protected function bit is_legal_csr_write_sample();
    rtl_pkg::rtl_alu_pkt_t legal_ap;

    if (sampled_transaction == null) begin
      return 1'b0;
    end

    legal_ap           = '0;
    legal_ap.csr_write = 1'b1;
    legal_ap.csr_imm   = sampled_transaction.ap.csr_imm;

    return (
        (sampled_transaction.rst_l        === 1'b1) &&
        (sampled_transaction.valid_in     === 1'b1) &&
        (sampled_transaction.csr_ren_in   === 1'b0) &&
        (sampled_transaction.ap.csr_write === 1'b1) &&
        ((sampled_transaction.ap.csr_imm  === 1'b0) ||
         (sampled_transaction.ap.csr_imm  === 1'b1)) &&
        (sampled_transaction.ap           === legal_ap)
    );
  endfunction : is_legal_csr_write_sample

  covergroup sanity_flow_cg;
    //track each individual instance instead of global pooling
    option.per_instance = 1;

    accept_cp: coverpoint sampled_transaction.valid_in iff (sampled_transaction.rst_l === 1'b1) {
      bins accepted = {1'b1};
    }
  endgroup : sanity_flow_cg

  covergroup csr_read_cg;
    option.per_instance = 1;

    csr_data_class_cp: coverpoint sampled_transaction.csr_rddata_in
        iff ((sampled_transaction.rst_l       === 1'b1) &&
             (sampled_transaction.valid_in   === 1'b1) &&
             (sampled_transaction.csr_ren_in === 1'b1) &&
             (sampled_transaction.ap         === '0)) {
      bins all_zero = {32'h0000_0000};
      bins all_one = {32'hFFFF_FFFF};
      bins random_non_boundary = {[32'h0000_0001 : 32'hFFFF_FFFE]};
    }

    csr_read_legality_cp: coverpoint
        (sampled_transaction.ap === '0)
        iff ((sampled_transaction.rst_l       === 1'b1) &&
             (sampled_transaction.valid_in   === 1'b1) &&
             (sampled_transaction.csr_ren_in === 1'b1)) {
      bins legal = {1'b1}; bins invalid = {1'b0};
    }
  endgroup

  covergroup csr_write_cg;
    option.per_instance = 1;

    csr_write_mode_cp: coverpoint sampled_transaction.ap.csr_imm iff (is_legal_csr_write_sample()) {
      bins register_source = {1'b0}; bins immediate_source = {1'b1};
    }

    csr_write_selected_data_cp: coverpoint
        ((sampled_transaction.ap.csr_imm === 1'b1)
             ? sampled_transaction.b_in
             : sampled_transaction.a_in)
        iff (is_legal_csr_write_sample()) {
      bins all_zero = {32'h0000_0000};
      bins all_one = {32'hFFFF_FFFF};
      bins random_non_boundary = {[32'h0000_0001 : 32'hFFFF_FFFE]};
    }

    csr_write_mode_source_cross: cross csr_write_mode_cp, csr_write_selected_data_cp;

    csr_write_invalid_control_cp:
        coverpoint sampled_transaction.csr_ren_in
        iff ((sampled_transaction.rst_l        === 1'b1) &&
             (sampled_transaction.valid_in     === 1'b1) &&
             (sampled_transaction.ap.csr_write === 1'b1)) {
      bins csr_read_conflict = {1'b1}; ignore_bins no_csr_read_conflict = {1'b0};
    }
  endgroup : csr_write_cg

  function new(string name = "bmu_coverage_subscriber", uvm_component parent = null);
    super.new(name, parent);

    sampled_transaction = null;
    sample_count        = 0;
    sanity_flow_cg      = new();
    csr_read_cg         = new();
    csr_write_cg        = new();
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
    csr_read_cg.sample();
    csr_write_cg.sample();

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
                "observations=%0d sanity_accept_coverage=%0.2f%% ",
                "csr_read_coverage=%0.2f%% csr_write_coverage=%0.2f%%"
              },
              sample_count,
              sanity_flow_cg.get_inst_coverage(),
              csr_read_cg.get_inst_coverage(),
              csr_write_cg.get_inst_coverage()
              ), UVM_NONE)
  endfunction : report_phase

endclass
