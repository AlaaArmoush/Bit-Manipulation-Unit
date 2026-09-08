`timescale 1ns / 1ps
module tb_top;
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

  initial begin
    clk = 1'b0;
    forever #(CLK_PERIOD / 2) clk = ~clk;
  end

  initial begin
    bmu_if.rst_l = 1'b0;
    repeat (2) @(posedge clk);

    @(negedge clk);
    bmu_if.rst_l = 1'b1;
  end

  assign bmu_if.scan_mode = 1'b0;
endmodule
