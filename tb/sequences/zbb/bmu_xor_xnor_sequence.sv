class bmu_xor_xnor_sequence extends bmu_base_sequence;
  `uvm_object_utils(bmu_xor_xnor_sequence)

  localparam int unsigned RANDOM_TRIAL_COUNT = 100;
  localparam int unsigned TOTAL_REQUEST_COUNT = RANDOM_TRIAL_COUNT + 10;

  function new(string name = "bmu_xor_xnor_sequence");
    super.new(name);
  endfunction : new

  virtual task body();
    bmu_sequence_item request;

    // XOR-01: equal, non-boundary operands in both modes.
    send_legal_xor_xnor("xor_equal_request", 1'b0, 32'h3C3C_C3C3, 32'h3C3C_C3C3, "XOR-01");
    send_legal_xor_xnor("xnor_equal_request", 1'b1, 32'h3C3C_C3C3, 32'h3C3C_C3C3, "XOR-01");

    // XOR-02: complementary operands in both modes.
    send_legal_xor_xnor("xor_complementary_request", 1'b0, 32'hF0F0_F0F0, 32'h0F0F_0F0F, "XOR-02");
    send_legal_xor_xnor("xnor_complementary_request", 1'b1, 32'hF0F0_F0F0, 32'h0F0F_0F0F, "XOR-02");

    // XOR-03: all-zero operands in both modes.
    send_legal_xor_xnor("xor_all_zero_request", 1'b0, 32'h0000_0000, 32'h0000_0000, "XOR-03");
    send_legal_xor_xnor("xnor_all_zero_request", 1'b1, 32'h0000_0000, 32'h0000_0000, "XOR-03");

    // XOR-04: all-one operands in both modes.
    send_legal_xor_xnor("xor_all_one_request", 1'b0, 32'hFFFF_FFFF, 32'hFFFF_FFFF, "XOR-04");
    send_legal_xor_xnor("xnor_all_one_request", 1'b1, 32'hFFFF_FFFF, 32'hFFFF_FFFF, "XOR-04");

    // XOR-05: random non-directed operands.
    // Alternating zbb guarantees random stimulus in both modes.
    for (int unsigned i = 0; i < RANDOM_TRIAL_COUNT; i++) begin
      request = create_request($sformatf("random_request_%0d", i));
      apply_legal_defaults(request);

      if (!request.randomize() with {
            csr_rddata_in == 32'h0000_0000;

            a_in != b_in;
            a_in != ~b_in;

            {a_in, b_in} != 64'h0000_0000_0000_0000;
            {a_in, b_in} != 64'hFFFF_FFFF_FFFF_FFFF;
          }) begin
        `uvm_fatal("XOR_XNOR_RANDOMIZE", $sformatf("Failed to randomize XOR/XNOR trial %0d", i))
      end

      request.ap.lxor = 1'b1;
      request.ap.zbb  = i[0];

      `uvm_info("XOR_XNOR_STIMULUS", $sformatf(
                "XOR-05 random trial %0d: mode=%s a_in=0x%08h b_in=0x%08h",
                i,
                request.ap.zbb ? "XNOR" : "XOR",
                request.a_in,
                request.b_in
                ), UVM_MEDIUM)

      send_bmu_request(request);
    end

    // XOR-I-01: lxor combined with the in-scope SRL control.
    request = create_request("invalid_srl_conflict_request");
    apply_legal_defaults(request);

    request.ap.lxor = 1'b1;
    request.ap.srl  = 1'b1;
    request.a_in    = 32'h1357_9BDF;
    request.b_in    = 32'h2468_ACE0;

    `uvm_info("XOR_XNOR_STIMULUS", "XOR-I-01 invalid conflict: lxor combined with in-scope srl",
              UVM_MEDIUM)

    send_bmu_request(request);

    // XOR-I-01: lxor combined with the in-scope CSR-read control.
    request = create_request("invalid_csr_read_conflict_request");
    apply_legal_defaults(request);

    request.ap.lxor       = 1'b1;
    request.ap.zbb        = 1'b1;
    request.csr_ren_in    = 1'b1;
    request.csr_rddata_in = 32'hCAFE_BABE;
    request.a_in          = 32'h1357_9BDF;
    request.b_in          = 32'h2468_ACE0;

    `uvm_info("XOR_XNOR_STIMULUS",
              "XOR-I-01 invalid conflict: lxor combined with in-scope CSR read", UVM_MEDIUM)

    send_bmu_request(request);
  endtask : body

  protected task send_legal_xor_xnor(string request_name, logic zbb_mode, logic [31:0] a_value,
                                     logic [31:0] b_value, string scenario_id);
    bmu_sequence_item request;

    request = create_request(request_name);
    apply_legal_defaults(request);

    request.ap.lxor = 1'b1;
    request.ap.zbb  = zbb_mode;
    request.a_in    = a_value;
    request.b_in    = b_value;

    `uvm_info("XOR_XNOR_STIMULUS", $sformatf("%s legal %s '%s': a_in=0x%08h b_in=0x%08h",
                                             scenario_id, zbb_mode ? "XNOR" : "XOR", request_name,
                                             a_value, b_value), UVM_MEDIUM)

    send_bmu_request(request);
  endtask : send_legal_xor_xnor

endclass : bmu_xor_xnor_sequence
