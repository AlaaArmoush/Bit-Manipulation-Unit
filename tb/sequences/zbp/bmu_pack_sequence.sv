class bmu_pack_sequence extends bmu_base_sequence;
  `uvm_object_utils(bmu_pack_sequence)

  localparam int unsigned RANDOM_TRIAL_COUNT = 100;
  localparam int unsigned DIRECTED_REQUEST_COUNT = 7;
  localparam int unsigned INVALID_REQUEST_COUNT = 2;
  localparam int unsigned TOTAL_REQUEST_COUNT =
      DIRECTED_REQUEST_COUNT + RANDOM_TRIAL_COUNT + INVALID_REQUEST_COUNT;

  function new(string name = "bmu_pack_sequence");
    super.new(name);
  endfunction : new

  virtual task body();
    bmu_sequence_item request;

    // PACK-01: different lower halves
    send_legal_pack("different_lower_halves_request", 32'h1234_5678, 32'hABCD_EF12, "PACK-01");

    // PACK-02: change only A[31:16].
    send_legal_pack("a_upper_zero_request", 32'h0000_A55A, 32'h1357_2468, "PACK-02");
    send_legal_pack("a_upper_one_request", 32'hFFFF_A55A, 32'h1357_2468, "PACK-02");

    // PACK-03: change only B[31:16].
    send_legal_pack("b_upper_zero_request", 32'h89AB_1357, 32'h0000_5AA5, "PACK-03");
    send_legal_pack("b_upper_one_request", 32'h89AB_1357, 32'hFFFF_5AA5, "PACK-03");

    // PACK-04: boundary values in both selected lower halves.
    send_legal_pack("selected_halves_zero_request", 32'hCAFE_0000, 32'hBABE_0000, "PACK-04");
    send_legal_pack("selected_halves_one_request", 32'h1234_FFFF, 32'h5678_FFFF, "PACK-04");

    // PACK-05: random legal operands.
    for (int unsigned i = 0; i < RANDOM_TRIAL_COUNT; i++) begin
      request = create_request($sformatf("random_request_%0d", i));
      apply_legal_defaults(request);

      if (!request.randomize(a_in, b_in)) begin
        `uvm_fatal("PACK_RANDOMIZE", $sformatf("Failed to randomize PACK trial %0d", i))
      end

      request.ap.pack = 1'b1;

      `uvm_info("PACK_STIMULUS", $sformatf(
                {
                  "PACK-05 random trial %0d: a_in=0x%08h ",
                  "b_in=0x%08h selected_a=0x%04h selected_b=0x%04h"
                },
                i,
                request.a_in,
                request.b_in,
                request.a_in[15:0],
                request.b_in[15:0]
                ), UVM_MEDIUM)

      send_bmu_request(request);
    end

    // PACK-I-01: combine PACK with the in-scope SRL control.
    request = create_request("invalid_srl_conflict_request");
    apply_legal_defaults(request);

    request.ap.pack = 1'b1;
    request.ap.srl  = 1'b1;
    request.a_in    = 32'h1234_5678;
    request.b_in    = 32'hABCD_EF12;

    `uvm_info("PACK_STIMULUS", "PACK-I-01 invalid control: PACK combined with in-scope SRL",
              UVM_MEDIUM)

    send_bmu_request(request);

    // PACK-I-01: combine PACK with the in-scope CSR-read control.
    request = create_request("invalid_csr_read_conflict_request");
    apply_legal_defaults(request);

    request.ap.pack       = 1'b1;
    request.csr_ren_in    = 1'b1;
    request.csr_rddata_in = 32'hCAFE_BABE;
    request.a_in          = 32'h1234_5678;
    request.b_in          = 32'hABCD_EF12;

    `uvm_info("PACK_STIMULUS", "PACK-I-01 invalid control: PACK combined with in-scope CSR read",
              UVM_MEDIUM)

    send_bmu_request(request);
  endtask : body

  protected task send_legal_pack(string request_name, logic [31:0] a_value, logic [31:0] b_value,
                                 string scenario_id);
    bmu_sequence_item request;

    request = create_request(request_name);
    apply_legal_defaults(request);

    request.ap.pack = 1'b1;
    request.a_in    = a_value;
    request.b_in    = b_value;

    `uvm_info("PACK_STIMULUS", $sformatf({"%s legal PACK '%s': a_in=0x%08h b_in=0x%08h ",
                                          "selected_a=0x%04h selected_b=0x%04h"}, scenario_id,
                                           request_name, a_value, b_value, a_value[15:0],
                                           b_value[15:0]), UVM_MEDIUM)

    send_bmu_request(request);
  endtask : send_legal_pack

endclass : bmu_pack_sequence
