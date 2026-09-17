class bmu_cpop_sequence extends bmu_base_sequence;
  `uvm_object_utils(bmu_cpop_sequence)

  localparam int unsigned RANDOM_TRIAL_COUNT = 100;
  localparam int unsigned DIRECTED_REQUEST_COUNT = 6;
  localparam int unsigned INVALID_REQUEST_COUNT = 2;
  localparam int unsigned TOTAL_REQUEST_COUNT =
      DIRECTED_REQUEST_COUNT + RANDOM_TRIAL_COUNT + INVALID_REQUEST_COUNT;

  function new(string name = "bmu_cpop_sequence");
    super.new(name);
  endfunction : new

  virtual task body();
    bmu_sequence_item request;

    // CPOP-01: no set bits.
    send_legal_cpop("all_zero_request", 32'h0000_0000, "CPOP-01");

    // CPOP-02: exactly one set bit.
    send_legal_cpop("one_upper_bit_request", 32'h8000_0000, "CPOP-02");

    // CPOP-03: all 32 bits set.
    send_legal_cpop("all_one_request", 32'hFFFF_FFFF, "CPOP-03");

    // CPOP-04: the specified alternating pattern contains 16 set bits.
    send_legal_cpop("alternating_request", 32'hAAAA_AAAA, "CPOP-04");

    // CPOP-06: same number of ones in different positions
    // different halves of the 32-bit operand.
    send_legal_cpop("four_lower_bits_request", 32'h0000_000F, "CPOP-06");

    send_legal_cpop("four_upper_bits_request", 32'hF000_0000, "CPOP-06");

    // CPOP-05: random operands
    for (int unsigned i = 0; i < RANDOM_TRIAL_COUNT; i++) begin
      request = create_request($sformatf("random_request_%0d", i));
      apply_legal_defaults(request);

      if (!request.randomize(
              a_in
          ) with {
            a_in != 32'h0000_0000;
            a_in != 32'h8000_0000;
            a_in != 32'hFFFF_FFFF;
            a_in != 32'hAAAA_AAAA;
            a_in != 32'h0000_000F;
            a_in != 32'hF000_0000;
          }) begin
        `uvm_fatal("CPOP_RANDOMIZE", $sformatf("Failed to randomize CPOP trial %0d", i))
      end

      request.ap.cpop = 1'b1;

      `uvm_info("CPOP_STIMULUS", $sformatf("CPOP-05 random trial %0d: a_in=0x%08h", i, request.a_in
                ), UVM_MEDIUM)

      send_bmu_request(request);
    end

    // CPOP-I-01: combine CPOP with the in-scope CTZ control.
    request = create_request("invalid_ctz_conflict_request");
    apply_legal_defaults(request);

    request.ap.cpop = 1'b1;
    request.ap.ctz  = 1'b1;
    request.a_in    = 32'h0000_00F0;

    `uvm_info("CPOP_STIMULUS", "CPOP-I-01 invalid control: CPOP combined with in-scope CTZ",
              UVM_MEDIUM)

    send_bmu_request(request);

    // CPOP-I-01: combine CPOP with the in-scope CSR-read control.
    request = create_request("invalid_csr_read_conflict_request");
    apply_legal_defaults(request);

    request.ap.cpop       = 1'b1;
    request.csr_ren_in    = 1'b1;
    request.csr_rddata_in = 32'hCAFE_BABE;
    request.a_in          = 32'hF000_0000;

    `uvm_info("CPOP_STIMULUS", "CPOP-I-01 invalid control: CPOP combined with in-scope CSR read",
              UVM_MEDIUM)

    send_bmu_request(request);
  endtask : body

  protected task send_legal_cpop(string request_name, logic [31:0] a_value, string scenario_id);
    bmu_sequence_item request;

    request = create_request(request_name);
    apply_legal_defaults(request);

    request.ap.cpop = 1'b1;
    request.a_in    = a_value;

    `uvm_info("CPOP_STIMULUS", $sformatf("%s legal CPOP '%s': a_in=0x%08h", scenario_id,
                                         request_name, a_value), UVM_MEDIUM)

    send_bmu_request(request);
  endtask : send_legal_cpop

endclass : bmu_cpop_sequence
