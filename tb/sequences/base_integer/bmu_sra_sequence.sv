class bmu_sra_sequence extends bmu_base_sequence;
  `uvm_object_utils(bmu_sra_sequence)

  localparam int unsigned RANDOM_TRIAL_COUNT = 100;
  localparam int unsigned TOTAL_REQUEST_COUNT = RANDOM_TRIAL_COUNT + 10;

  function new(string name = "bmu_sra_sequence");
    super.new(name);
  endfunction : new

  virtual task body();
    bmu_sequence_item request;

    // SRA-02: directed interior shifts demonstrate sign-bit replication.
    send_legal_sra("positive_sign_fill_request", 32'h7000_0000, 32'h0000_0004, "SRA-02");
    send_legal_sra("negative_sign_fill_request", 32'hF000_0000, 32'h0000_0004, "SRA-02");

    // SRA-04: shifting by zero leaves either sign class unchanged.
    send_legal_sra("shift_zero_positive_request", 32'h1234_5678, 32'h0000_0000, "SRA-04");
    send_legal_sra("shift_zero_negative_request", 32'h8765_4321, 32'h0000_0000, "SRA-04");

    // SRA-05: shifting by 31 produces all zeros or all ones according
    // to the original sign bit.
    send_legal_sra("shift_31_positive_request", 32'h7FFF_FFFF, 32'h0000_001F, "SRA-05");
    send_legal_sra("shift_31_negative_request", 32'h8000_0000, 32'h0000_001F, "SRA-05");

    // SRA-06: these B values have the same b_in[4:0] value, 5'd13.
    // Changing only b_in[31:5] must not change the result.
    send_legal_sra("upper_b_zero_request", 32'hC3A5_5A3C, 32'h0000_000D, "SRA-06");
    send_legal_sra("upper_b_one_request", 32'hC3A5_5A3C, 32'hFFFF_FFED, "SRA-06");

    // SRA-01 and SRA-02: randomized interior shifts. Alternating the
    // operand sign guarantees both positive and negative sign classes.
    for (int unsigned i = 0; i < RANDOM_TRIAL_COUNT; i++) begin
      request = create_request($sformatf("random_request_%0d", i));
      apply_legal_defaults(request);

      if (!request.randomize() with {
            csr_rddata_in == 32'h0000_0000;
            b_in[4:0] inside {[5'd1 : 5'd30]};
            a_in[31] == i[0];
          }) begin
        `uvm_fatal("SRA_RANDOMIZE", $sformatf("Failed to randomize SRA trial %0d", i))
      end

      request.ap.sra = 1'b1;

      `uvm_info("SRA_STIMULUS", $sformatf(
                {
                  "SRA-01/SRA-02 random trial %0d: ",
                  "a_in=0x%08h b_in=0x%08h shift_amount=%0d sign=%0b"
                },
                i,
                request.a_in,
                request.b_in,
                request.b_in[4:0],
                request.a_in[31]
                ), UVM_MEDIUM)

      send_bmu_request(request);
    end

    // SRA-03: combine SRA with the in-scope ROR control. ROR is used
    // only as a conflicting control; its standalone result is not tested.
    request = create_request("invalid_ror_conflict_request");
    apply_legal_defaults(request);

    request.ap.sra = 1'b1;
    request.ap.ror = 1'b1;
    request.a_in   = 32'hF000_0000;
    request.b_in   = 32'h0000_0004;

    `uvm_info("SRA_STIMULUS", "SRA-03 invalid conflict: sra combined with in-scope ror", UVM_MEDIUM)

    send_bmu_request(request);

    // SRA-03: combine SRA with the in-scope CSR-read control.
    request = create_request("invalid_csr_read_conflict_request");
    apply_legal_defaults(request);

    request.ap.sra        = 1'b1;
    request.csr_ren_in    = 1'b1;
    request.csr_rddata_in = 32'hCAFE_BABE;
    request.a_in          = 32'hF000_0000;
    request.b_in          = 32'h0000_0004;

    `uvm_info("SRA_STIMULUS", "SRA-03 invalid conflict: sra combined with in-scope CSR read",
              UVM_MEDIUM)

    send_bmu_request(request);
  endtask : body

  protected task send_legal_sra(string request_name, logic [31:0] a_value, logic [31:0] b_value,
                                string scenario_id);
    bmu_sequence_item request;

    request = create_request(request_name);
    apply_legal_defaults(request);

    request.ap.sra = 1'b1;
    request.a_in   = a_value;
    request.b_in   = b_value;

    `uvm_info("SRA_STIMULUS", $sformatf({"%s legal SRA '%s': a_in=0x%08h ",
                                         "b_in=0x%08h shift_amount=%0d sign=%0b"}, scenario_id,
                                          request_name, a_value, b_value, b_value[4:0],
                                          a_value[31]), UVM_MEDIUM)

    send_bmu_request(request);
  endtask : send_legal_sra

endclass : bmu_sra_sequence
