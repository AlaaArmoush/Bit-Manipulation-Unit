class bmu_base_sequence extends uvm_sequence #(bmu_sequence_item);
  `uvm_object_utils(bmu_base_sequence)

  function new(string name = "bmu_base_sequence");
    super.new(name);
  endfunction : new

  protected function void apply_legal_defaults(bmu_sequence_item request);
    if (request == null) begin
      `uvm_fatal("NULL_REQUEST", "Cannot initialize a null sequence item")
      return;
    end

    request.valid_in      = 1'b1;
    request.ap            = '0;
    request.csr_ren_in    = 1'b0;
    request.csr_rddata_in = '0;
    request.a_in          = '0;
    request.b_in          = '0;
  endfunction : apply_legal_defaults

  protected task send_request(bmu_sequence_item request);
    if (request == null) begin
      `uvm_fatal("NULL_REQUEST", "Cannot send a null sequence item")
      return;
    end

    start_item(request);
    finish_item(request);
  endtask : send_request
endclass
