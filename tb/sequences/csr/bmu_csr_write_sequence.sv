class bmu_csr_write_sequence extends bmu_base_sequence;
  `uvm_object_utils(bmu_csr_write_sequence)

  localparam int unsigned RANDOM_TRIAL_COUNT = 100;
  localparam int unsigned TOTAL_REQUEST_COUNT = RANDOM_TRIAL_COUNT + 7;

  function new(string name = "bmu_csr_write_sequence");
    super.new(name);
  endfunction : new

  virtual task body();
    bmu_sequence_item request;

    // CSR-W-01, CSR-W-02, and CSR-W-03:
    // Toggle csr_imm while keeping distinct A and B values unchanged.
    send_legal_csr_write("directed_immediate_request", 1'b1, 32'h1357_9BDF, 32'h2468_ACE0,
                         "CSR-W-01/CSR-W-03");

    send_legal_csr_write("directed_register_request", 1'b0, 32'h1357_9BDF, 32'h2468_ACE0,
                         "CSR-W-02/CSR-W-03");

    // CSR-W-04: all-zero selected source in both modes.
    send_legal_csr_write("immediate_all_zero_request", 1'b1, 32'hFFFF_FFFF, 32'h0000_0000,
                         "CSR-W-04");

    send_legal_csr_write("register_all_zero_request", 1'b0, 32'h0000_0000, 32'hFFFF_FFFF,
                         "CSR-W-04");

    // CSR-W-05: all-one selected source in both modes.
    send_legal_csr_write("immediate_all_one_request", 1'b1, 32'h0000_0000, 32'hFFFF_FFFF,
                         "CSR-W-05");

    send_legal_csr_write("register_all_one_request", 1'b0, 32'hFFFF_FFFF, 32'h0000_0000,
                         "CSR-W-05");

    // CSR-W-06: randomized, distinct, non-boundary operands.
    // Alternating csr_imm guarantees random coverage in both modes.
    for (int unsigned i = 0; i < RANDOM_TRIAL_COUNT; i++) begin
      request = create_request($sformatf("random_request_%0d", i));
      apply_legal_defaults(request);

      if (!request.randomize() with {
            csr_rddata_in == 32'h0000_0000;
            a_in != 32'h0000_0000;
            a_in != 32'hFFFF_FFFF;
            b_in != 32'h0000_0000;
            b_in != 32'hFFFF_FFFF;
            a_in != b_in;
          }) begin
        `uvm_fatal("CSR_WRITE_RANDOMIZE", $sformatf("Failed to randomize CSR-write trial %0d", i))
      end

      request.ap.csr_write = 1'b1;
      request.ap.csr_imm   = i[0];

      `uvm_info("CSR_WRITE_STIMULUS", $sformatf(
                {
                  "CSR-W-06 random trial %0d: csr_imm=%0b ", "a_in=0x%08h b_in=0x%08h"
                },
                i,
                request.ap.csr_imm,
                request.a_in,
                request.b_in
                ), UVM_MEDIUM)

      send_bmu_request(request);
    end

    // CSR-W-07: CSR write conflicts with the in-scope CSR-read control.
    request = create_request("invalid_csr_read_conflict_request");
    apply_legal_defaults(request);

    request.ap.csr_write  = 1'b1;
    request.ap.csr_imm    = 1'b1;
    request.csr_ren_in    = 1'b1;
    request.csr_rddata_in = 32'hCAFE_BABE;
    request.a_in          = 32'h1357_9BDF;
    request.b_in          = 32'h2468_ACE0;

    `uvm_info("CSR_WRITE_STIMULUS", {"CSR-W-07 invalid conflict: CSR write combined with ",
                                     "in-scope CSR read"}, UVM_MEDIUM)

    send_bmu_request(request);
  endtask : body

  protected task send_legal_csr_write(string request_name, logic immediate_mode,
                                      logic [31:0] a_value, logic [31:0] b_value,
                                      string scenario_id);
    bmu_sequence_item request;

    request = create_request(request_name);
    apply_legal_defaults(request);

    request.ap.csr_write = 1'b1;
    request.ap.csr_imm   = immediate_mode;
    request.a_in         = a_value;
    request.b_in         = b_value;

    `uvm_info("CSR_WRITE_STIMULUS",
              $sformatf({"%s legal CSR write '%s': csr_imm=%0b ", "a_in=0x%08h b_in=0x%08h"},
                          scenario_id, request_name, immediate_mode, a_value, b_value), UVM_MEDIUM)

    send_bmu_request(request);
  endtask : send_legal_csr_write

endclass : bmu_csr_write_sequence
