class bmu_srl_sequence extends bmu_base_sequence;
  `uvm_object_utils(bmu_srl_sequence)

  localparam int unsigned RANDOM_TRIAL_COUNT = 100;
  localparam int unsigned TOTAL_REQUEST_COUNT = RANDOM_TRIAL_COUNT + 8;

  function new(string name = "bmu_srl_sequence");
    super.new(name);
  endfunction : new

  virtual task body();
    bmu_sequence_item request;

    // SRL-04: shift by zero leaves the operand unchanged.
    send_legal_srl("shift_zero_msb_clear_request", 32'h1234_5678, 32'h0000_0000,
                   "SRL-04");  // MSB 0
    send_legal_srl("shift_zero_msb_set_request", 32'h8765_4321, 32'h0000_0000, "SRL-04");  //MSB 1

    // SRL-05: at shift amount 31, original bit 31 becomes result bit 0.
    send_legal_srl("shift_31_msb_clear_request", 32'h7FFF_FFFF, 32'h0000_001F, "SRL-05");
    send_legal_srl("shift_31_msb_set_request", 32'h8000_0000, 32'h0000_001F, "SRL-05");

    // SRL-06: changing only b_in[31:5] must not change the shift amount
    // or result. These values both have b_in[4:0] == 5'd13.
    send_legal_srl("upper_b_zero_request", 32'hC3A5_5A3C, 32'h0000_000D, "SRL-06");

    send_legal_srl("upper_b_one_request", 32'hC3A5_5A3C, 32'hFFFF_FFED, "SRL-06");

    // SRL-01 and SRL-02: legal randomized interior shifts.
    // Alternating the operand MSB guarantees both operand classes and
    // repeatedly checks that an MSB of one is shifted in with zeros.
    for (int unsigned i = 0; i < RANDOM_TRIAL_COUNT; i++) begin
      request = create_request($sformatf("random_request_%0d", i));
      apply_legal_defaults(request);

      if (!request.randomize() with {
            csr_rddata_in == 32'h0000_0000;
            b_in[4:0] inside {[5'd1 : 5'd30]};
            a_in[31] == i[0];
          }) begin
        `uvm_fatal("SRL_RANDOMIZE", $sformatf("Failed to randomize SRL trial %0d", i))
      end

      request.ap.srl = 1'b1;

      `uvm_info("SRL_STIMULUS", $sformatf(
                {
                  "SRL-01/SRL-02 random trial %0d: ", "a_in=0x%08h b_in=0x%08h shift_amount=%0d"
                },
                i,
                request.a_in,
                request.b_in,
                request.b_in[4:0]
                ), UVM_MEDIUM)

      send_bmu_request(request);
    end

    // SRL-03: SRL combined with the in-scope SRA control.
    request = create_request("invalid_sra_conflict_request");
    apply_legal_defaults(request);

    request.ap.srl = 1'b1;
    request.ap.sra = 1'b1;
    request.a_in   = 32'hF000_0000;
    request.b_in   = 32'h0000_0004;

    `uvm_info("SRL_STIMULUS", "SRL-03 invalid conflict: srl combined with in-scope sra", UVM_MEDIUM)

    send_bmu_request(request);

    // SRL-03: SRL combined with the in-scope CSR-read control.
    request = create_request("invalid_csr_read_conflict_request");
    apply_legal_defaults(request);

    request.ap.srl        = 1'b1;
    request.csr_ren_in    = 1'b1;
    request.csr_rddata_in = 32'hCAFE_BABE;
    request.a_in          = 32'hF000_0000;
    request.b_in          = 32'h0000_0004;

    `uvm_info("SRL_STIMULUS", "SRL-03 invalid conflict: srl combined with in-scope CSR read",
              UVM_MEDIUM)

    send_bmu_request(request);
  endtask : body

  protected task send_legal_srl(string request_name, logic [31:0] a_value, logic [31:0] b_value,
                                string scenario_id);
    bmu_sequence_item request;

    request = create_request(request_name);
    apply_legal_defaults(request);

    request.ap.srl = 1'b1;
    request.a_in   = a_value;
    request.b_in   = b_value;

    `uvm_info("SRL_STIMULUS",
              $sformatf({"%s legal SRL '%s': a_in=0x%08h ", "b_in=0x%08h shift_amount=%0d"},
                          scenario_id, request_name, a_value, b_value, b_value[4:0]), UVM_MEDIUM)

    send_bmu_request(request);
  endtask : send_legal_srl

endclass : bmu_srl_sequence
