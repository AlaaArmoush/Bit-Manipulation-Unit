class bmu_or_orn_sequence extends bmu_base_sequence;
  `uvm_object_utils(bmu_or_orn_sequence)

  localparam int unsigned RANDOM_TRIAL_COUNT = 100;
  localparam int unsigned TOTAL_REQUEST_COUNT = RANDOM_TRIAL_COUNT + 8;

  function new(string name = "bmu_or_orn_sequence");
    super.new(name);
  endfunction : new

  virtual task body();
    bmu_sequence_item request;

    // OR-01: all-zero operands in both modes.
    send_legal_or_orn("or_all_zero_request", 1'b0, 32'h0000_0000, 32'h0000_0000, "OR-01");
    send_legal_or_orn("orn_all_zero_request", 1'b1, 32'h0000_0000, 32'h0000_0000, "OR-01");

    // OR-02: all-one operands in both modes.
    send_legal_or_orn("or_all_one_request", 1'b0, 32'hFFFF_FFFF, 32'hFFFF_FFFF, "OR-02");
    send_legal_or_orn("orn_all_one_request", 1'b1, 32'hFFFF_FFFF, 32'hFFFF_FFFF, "OR-02");

    // OR-03: complementary alternating operands in both modes.
    send_legal_or_orn("or_alternating_request", 1'b0, 32'hAAAA_AAAA, 32'h5555_5555, "OR-03");
    send_legal_or_orn("orn_alternating_request", 1'b1, 32'hAAAA_AAAA, 32'h5555_5555, "OR-03");

    // OR-04: random, non-directed operands.
    // Alternating zbb guarantees random stimulus in both OR and ORN modes.
    for (int unsigned i = 0; i < RANDOM_TRIAL_COUNT; i++) begin
      request = create_request($sformatf("random_request_%0d", i));
      apply_legal_defaults(request);

      if (!request.randomize() with {
            csr_rddata_in == 32'h0000_0000;

            a_in != 32'h0000_0000;
            a_in != 32'hFFFF_FFFF;
            a_in != 32'hAAAA_AAAA;
            a_in != 32'h5555_5555;

            b_in != 32'h0000_0000;
            b_in != 32'hFFFF_FFFF;
            b_in != 32'hAAAA_AAAA;
            b_in != 32'h5555_5555;
          }) begin
        `uvm_fatal("OR_ORN_RANDOMIZE", $sformatf("Failed to randomize OR/ORN trial %0d", i))
      end

      request.ap.lor = 1'b1;
      request.ap.zbb = i[0];

      `uvm_info("OR_ORN_STIMULUS", $sformatf(
                "OR-04 random trial %0d: mode=%s a_in=0x%08h b_in=0x%08h",
                i,
                request.ap.zbb ? "ORN" : "OR",
                request.a_in,
                request.b_in
                ), UVM_MEDIUM)

      send_bmu_request(request);
    end

    // OR-I-01: lor combined with the in-scope XOR control.
    request = create_request("invalid_xor_conflict_request");
    apply_legal_defaults(request);

    request.ap.lor  = 1'b1;
    request.ap.lxor = 1'b1;
    request.a_in    = 32'h1357_9BDF;
    request.b_in    = 32'h2468_ACE0;

    `uvm_info("OR_ORN_STIMULUS", "OR-I-01 invalid conflict: lor combined with in-scope lxor",
              UVM_MEDIUM)

    send_bmu_request(request);

    // OR-I-01: lor combined with the in-scope CSR-read control.
    request = create_request("invalid_csr_read_conflict_request");
    apply_legal_defaults(request);

    request.ap.lor        = 1'b1;
    request.ap.zbb        = 1'b1;
    request.csr_ren_in    = 1'b1;
    request.csr_rddata_in = 32'hCAFE_BABE;
    request.a_in          = 32'h1357_9BDF;
    request.b_in          = 32'h2468_ACE0;

    `uvm_info("OR_ORN_STIMULUS", "OR-I-01 invalid conflict: lor combined with in-scope CSR read",
              UVM_MEDIUM)

    send_bmu_request(request);
  endtask : body

  protected task send_legal_or_orn(string request_name, logic zbb_mode, logic [31:0] a_value,
                                   logic [31:0] b_value, string scenario_id);
    bmu_sequence_item request;

    request = create_request(request_name);
    apply_legal_defaults(request);

    request.ap.lor = 1'b1;
    request.ap.zbb = zbb_mode;
    request.a_in   = a_value;
    request.b_in   = b_value;

    `uvm_info("OR_ORN_STIMULUS",
              $sformatf("%s legal %s '%s': a_in=0x%08h b_in=0x%08h", scenario_id,
                        zbb_mode ? "ORN" : "OR", request_name, a_value, b_value), UVM_MEDIUM)

    send_bmu_request(request);
  endtask : send_legal_or_orn

endclass : bmu_or_orn_sequence
