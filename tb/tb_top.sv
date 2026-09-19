`timescale 1ns / 1ps

module tb_top;
  import uvm_pkg::*;
  import bmu_pkg::*;

  localparam time CLK_PERIOD = 10ns;

  logic clk;

  bmu_interface bmu_if (.clk(clk));

  Bit_Manipulation_Unit dut (
      .clk          (clk),
      .rst_l        (bmu_if.rst_l),
      .scan_mode    (bmu_if.scan_mode),
      .valid_in     (bmu_if.valid_in),
      .ap           (bmu_if.ap),
      .csr_ren_in   (bmu_if.csr_ren_in),
      .csr_rddata_in(bmu_if.csr_rddata_in),
      .a_in         (bmu_if.a_in),
      .b_in         (bmu_if.b_in),
      .result_ff    (bmu_if.result_ff),
      .error        (bmu_if.error)
  );

  bind bmu_interface bmu_assertions bmu_assertions_i (
      .clk      (clk),
      .rst_l    (rst_l),
      .result_ff(result_ff),
      .error    (error)
  );

  initial begin
    clk = 1'b0;
    forever #(CLK_PERIOD / 2) clk = ~clk;
  end

  initial begin : reset_owner
    //startup reset
    bmu_if.rst_l = 1'b0;
    repeat (2) @(posedge clk);

    @(negedge clk);
    bmu_if.rst_l = 1'b1;

    // reset request from reset test
    forever begin
      @bmu_if.reset_request;

      @(negedge clk);
      bmu_if.rst_l = 1'b0;
      repeat (2) @(posedge clk);

      @(negedge clk);
      bmu_if.rst_l = 1'b1;

      ->bmu_if.reset_complete;
    end
  end

  assign bmu_if.scan_mode = 1'b0;

  initial begin
    uvm_config_db#(virtual bmu_interface)::set(null, "uvm_test_top.env.agent", "vif", bmu_if);

    run_test();
  end

endmodule
