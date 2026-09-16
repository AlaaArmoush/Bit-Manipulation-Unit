class bmu_binv_sequence extends bmu_base_sequence;
  `uvm_object_utils(bmu_binv_sequence)

  localparam int unsigned RANDOM_TRIAL_COUNT = 100;
  localparam int unsigned TOTAL_REQUEST_COUNT = RANDOM_TRIAL_COUNT + 10;

  function new(string name = "bmu_binv_sequence");
    super.new(name);
  endfunction : new

  virtual task body();
    bmu_sequence_item request;

    // BINV-01: selected bit equals 0
    send_legal_binv("selected_bit_clear_request", 32'h0000_0000, 32'h0000_000D, "BINV-01");

    // BINV-02: selected bit equals 1
    send_legal_binv("selected_bit_set_request", 32'hFFFF_FFFF, 32'h0000_000D, "BINV-02");

    // BINV-03: LSB toggle
    send_legal_binv("index_zero_bit_clear_request", 32'hA5A5_A5A4, 32'h0000_0000, "BINV-03");
    send_legal_binv("index_zero_bit_set_request", 32'hA5A5_A5A5, 32'h0000_0000, "BINV-03");

    // BINV-04: MSB toggle
    send_legal_binv("index_31_bit_clear_request", 32'h7FFF_FFFF, 32'h0000_001F, "BINV-04");
    send_legal_binv("index_31_bit_set_request", 32'h8000_0000, 32'h0000_001F, "BINV-04");

    // BINV-05: both B values select bit 13. Only b_in[31:5] changes.
    send_legal_binv("upper_b_zero_request", 32'hC3A5_5A3C, 32'h0000_000D, "BINV-05");
    send_legal_binv("upper_b_one_request", 32'hC3A5_5A3C, 32'hFFFF_FFED, "BINV-05");

    // BINV-06: representative randomized operands and interior indices.
    for (int unsigned i = 0; i < RANDOM_TRIAL_COUNT; i++) begin
      request = create_request($sformatf("random_request_%0d", i));
      apply_legal_defaults(request);

      if (!request.randomize() with {
            csr_rddata_in == 32'h0000_0000;
            b_in[4:0] inside {[5'd1 : 5'd30]};
          }) begin
        `uvm_fatal("BINV_RANDOMIZE", $sformatf("Failed to randomize BINV trial %0d", i))
      end

      request.ap.binv = 1'b1;
      request.a_in[request.b_in[4:0]] = i[0];

      `uvm_info("BINV_STIMULUS", $sformatf(
                {
                  "BINV-06 random trial %0d: a_in=0x%08h b_in=0x%08h ",
                  "bit_index=%0d selected_bit=%0b"
                },
                i,
                request.a_in,
                request.b_in,
                request.b_in[4:0],
                request.a_in[request.b_in[4:0]]
                ), UVM_MEDIUM)

      send_bmu_request(request);
    end

    // BINV-I-01: conflict with the in-scope SRL control.
    request = create_request("invalid_srl_conflict_request");
    apply_legal_defaults(request);

    request.ap.binv = 1'b1;
    request.ap.srl  = 1'b1;
    request.a_in    = 32'hA5A5_5A5A;
    request.b_in    = 32'h0000_000D;

    `uvm_info("BINV_STIMULUS", "BINV-I-01 invalid conflict: binv combined with in-scope srl",
              UVM_MEDIUM)

    send_bmu_request(request);

    // BINV-I-01: conflict with the in-scope CSR-read control.
    request = create_request("invalid_csr_read_conflict_request");
    apply_legal_defaults(request);

    request.ap.binv       = 1'b1;
    request.csr_ren_in    = 1'b1;
    request.csr_rddata_in = 32'hCAFE_BABE;
    request.a_in          = 32'hA5A5_5A5A;
    request.b_in          = 32'h0000_000D;

    `uvm_info("BINV_STIMULUS", "BINV-I-01 invalid conflict: binv combined with in-scope CSR read",
              UVM_MEDIUM)

    send_bmu_request(request);
  endtask : body

  protected task send_legal_binv(string request_name, logic [31:0] a_value, logic [31:0] b_value,
                                 string scenario_id);
    bmu_sequence_item request;

    request = create_request(request_name);
    apply_legal_defaults(request);

    request.ap.binv = 1'b1;
    request.a_in    = a_value;
    request.b_in    = b_value;

    `uvm_info("BINV_STIMULUS", $sformatf({"%s legal BINV '%s': a_in=0x%08h b_in=0x%08h ",
                                          "bit_index=%0d selected_bit=%0b"}, scenario_id,
                                           request_name, a_value, b_value, b_value[4:0],
                                           a_value[b_value[4:0]]), UVM_MEDIUM)

    send_bmu_request(request);
  endtask : send_legal_binv

endclass : bmu_binv_sequence
