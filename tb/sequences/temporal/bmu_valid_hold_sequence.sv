class bmu_valid_hold_sequence extends bmu_base_sequence;
  `uvm_object_utils(bmu_valid_hold_sequence)

  localparam logic [31:0] KNOWN_RESULT = 32'hA5C3_5A3C;
  localparam int unsigned IDLE_REQUEST_COUNT = 4;

  function new(string name = "bmu_valid_hold_sequence");
    super.new(name);
  endfunction : new

  virtual task body();
    bmu_sequence_item request;

    request = create_request("known_result_request");
    apply_legal_defaults(request);

    request.csr_ren_in    = 1'b1;
    request.csr_rddata_in = KNOWN_RESULT;
    request.a_in          = 32'h0123_4567;
    request.b_in          = 32'h89AB_CDEF;

    `uvm_info("VALID_HOLD_STIMULUS",
              $sformatf("Establishing known registered result with legal CSR read: expected=0x%08h",
                        KNOWN_RESULT), UVM_MEDIUM)

    send_bmu_request(request);

    // TMP-HOLD-01: idle with cleared controls and changed operands.
    request = create_request("idle_cleared_controls_request");
    apply_legal_defaults(request);

    request.valid_in      = 1'b0;
    request.csr_rddata_in = 32'hDEAD_BEEF;
    request.a_in          = 32'h1357_9BDF;
    request.b_in          = 32'h2468_ACE0;

    `uvm_info("VALID_HOLD_STIMULUS",
              "TMP-HOLD-01: valid_in=0 with cleared controls and changed operands", UVM_MEDIUM)

    send_bmu_request(request);

    // TMP-HOLD-01: idle with a legal OR encoding and different operands.
    request = create_request("idle_legal_or_request");
    apply_legal_defaults(request);

    request.valid_in = 1'b0;
    request.ap.lor   = 1'b1;
    request.a_in     = 32'hAAAA_5555;
    request.b_in     = 32'h0F0F_F0F0;

    `uvm_info("VALID_HOLD_STIMULUS", "TMP-HOLD-01: valid_in=0 with a legal OR control encoding",
              UVM_MEDIUM)

    send_bmu_request(request);

    // TMP-IDLE-ERR-01: invalid simultaneous in-scope operation controls.
    request = create_request("idle_invalid_operation_conflict_request");
    apply_legal_defaults(request);

    request.valid_in = 1'b0;
    request.ap.lor   = 1'b1;
    request.ap.lxor  = 1'b1;
    request.a_in     = 32'hCAFE_BABE;
    request.b_in     = 32'h1020_3040;

    `uvm_info("VALID_HOLD_STIMULUS", {"TMP-IDLE-ERR-01: valid_in=0 with conflicting ",
                                      "in-scope OR and XOR controls; error must assert"},
              UVM_MEDIUM)

    send_bmu_request(request);

    // TMP-IDLE-ERR-01: CSR read conflicts with an in-scope OR operation.
    request = create_request("idle_invalid_csr_conflict_request");
    apply_legal_defaults(request);

    request.valid_in      = 1'b0;
    request.ap.lor        = 1'b1;
    request.csr_ren_in    = 1'b1;
    request.csr_rddata_in = 32'h55AA_33CC;
    request.a_in          = 32'hFFFF_0000;
    request.b_in          = 32'h0000_FFFF;

    `uvm_info("VALID_HOLD_STIMULUS", {
              "TMP-IDLE-ERR-01: valid_in=0 with CSR-read/OR conflict; ",
              "error must assert while the registered result remains unchanged"}, UVM_MEDIUM)

    send_bmu_request(request);
  endtask : body

endclass : bmu_valid_hold_sequence
