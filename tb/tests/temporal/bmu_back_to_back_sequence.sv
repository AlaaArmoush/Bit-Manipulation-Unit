class bmu_back_to_back_sequence extends bmu_base_sequence;
  `uvm_object_utils(bmu_back_to_back_sequence)

  localparam int unsigned TOTAL_REQUEST_COUNT = 5;

  function new(string name = "bmu_back_to_back_sequence");
    super.new(name);
  endfunction : new

  virtual task body();
    bmu_sequence_item request;

    // TMP-B2B-01 / TMP-REC-01:
    // First accepted operation after reset.
    // Expected result: 32'hC001_C0DE.
    request = create_request("recovery_csr_read_request");
    apply_legal_defaults(request);

    request.csr_ren_in    = 1'b1;
    request.csr_rddata_in = 32'hC001_C0DE;

    `uvm_info("BACK_TO_BACK_STIMULUS", "1/5 CSR read: expected result 0xC001C0DE", UVM_MEDIUM)

    send_bmu_request(request);

    // CSR -> Zbb transition.
    // Expected OR result: 32'h1200_0021.
    request = create_request("or_request");
    apply_legal_defaults(request);

    request.ap.lor = 1'b1;
    request.a_in   = 32'h1000_0001;
    request.b_in   = 32'h0200_0020;

    `uvm_info("BACK_TO_BACK_STIMULUS", "2/5 OR: expected result 0x12000021", UVM_MEDIUM)

    send_bmu_request(request);

    // Zbb -> base-integer transition.
    // Expected SRL result: 32'h0200_0001.
    request = create_request("srl_request");
    apply_legal_defaults(request);

    request.ap.srl = 1'b1;
    request.a_in   = 32'h8000_0040;
    request.b_in   = 32'h0000_0006;

    `uvm_info("BACK_TO_BACK_STIMULUS", "3/5 SRL: expected result 0x02000001", UVM_MEDIUM)

    send_bmu_request(request);

    // Base-integer -> Zba transition.
    // Expected SH2ADD result: 32'h0000_4023.
    request = create_request("sh2add_request");
    apply_legal_defaults(request);

    request.ap.sh2add = 1'b1;
    request.ap.zba    = 1'b1;
    request.a_in      = 32'h0000_1000;
    request.b_in      = 32'h0000_0023;

    `uvm_info("BACK_TO_BACK_STIMULUS", "4/5 SH2ADD: expected result 0x00004023", UVM_MEDIUM)

    send_bmu_request(request);

    // Zba -> Zbs transition.
    // Expected BINV result: 32'h55AA_0020.
    request = create_request("binv_request");
    apply_legal_defaults(request);

    request.ap.binv = 1'b1;
    request.a_in    = 32'h55AA_0000;
    request.b_in    = 32'h0000_0005;

    `uvm_info("BACK_TO_BACK_STIMULUS", "5/5 BINV: expected result 0x55AA0020", UVM_MEDIUM)

    send_bmu_request(request);
  endtask : body

endclass : bmu_back_to_back_sequence
