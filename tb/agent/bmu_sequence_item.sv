class bmu_sequence_item extends uvm_sequence_item;
  // Driver-owned request controls
  logic                         valid_in;
  rtl_pkg::rtl_alu_pkt_t        ap;
  logic                         csr_ren_in;

  // Randomizable request data
  rand logic             [31:0] csr_rddata_in;
  rand logic signed      [31:0] a_in;
  rand logic             [31:0] b_in;

  // Top-level and DUT observations
  logic                         rst_l;
  logic                         scan_mode;
  logic                  [31:0] result_ff;
  logic                         error;

  `uvm_object_utils_begin(bmu_sequence_item)
    `uvm_field_int(valid_in, UVM_DEFAULT)
    `uvm_field_int(ap, UVM_DEFAULT)
    `uvm_field_int(csr_ren_in, UVM_DEFAULT)
    `uvm_field_int(csr_rddata_in, UVM_DEFAULT)
    `uvm_field_int(a_in, UVM_DEFAULT)
    `uvm_field_int(b_in, UVM_DEFAULT)
    `uvm_field_int(rst_l, UVM_DEFAULT)
    `uvm_field_int(scan_mode, UVM_DEFAULT)
    `uvm_field_int(result_ff, UVM_DEFAULT)
    `uvm_field_int(error, UVM_DEFAULT)
  `uvm_object_utils_end

  function new(string name = "bmu_sequence_item");
    super.new(name);

    valid_in      = 1'b0;
    ap            = '0;
    csr_ren_in    = 1'b0;
    csr_rddata_in = '0;
    a_in          = '0;
    b_in          = '0;
    rst_l         = 1'b0;
    scan_mode     = 1'b0;
    result_ff     = '0;
    error         = 1'b0;
  endfunction

  function string convert2string();
    return $sformatf(
        {
          "valid=%0b ap=0x%0h csr_ren=%0b csr_rddata=0x%08h ",
          "a=0x%08h b=0x%08h rst_l=%0b scan_mode=%0b ",
          "result=0x%08h error=%0b"
        },
        valid_in,
        ap,
        csr_ren_in,
        csr_rddata_in,
        a_in,
        b_in,
        rst_l,
        scan_mode,
        result_ff,
        error
    );
  endfunction
endclass


