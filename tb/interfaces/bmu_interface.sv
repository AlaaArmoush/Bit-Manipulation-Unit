`timescale 1ns / 1ps

interface bmu_interface (
    input logic clk
);

  logic rst_l;
  logic scan_mode;
  logic valid_in;
  rtl_pkg::rtl_alu_pkt_t ap;
  logic csr_ren_in;
  logic [31:0] csr_rddata_in;
  logic signed [31:0] a_in;
  logic [31:0] b_in;
  logic [31:0] result_ff;
  logic error;

  clocking driver_cb @(posedge clk);
    default input #1step output #0;

    input rst_l;
    input scan_mode;

    output valid_in;
    output ap;
    output csr_ren_in;
    output csr_rddata_in;
    output a_in;
    output b_in;
  endclocking

  clocking monitor_cb @(posedge clk);
    default input #0;

    input rst_l;
    input scan_mode;
    input valid_in;
    input ap;
    input csr_ren_in;
    input csr_rddata_in;
    input a_in;
    input b_in;
    input result_ff;
    input error;
  endclocking

  modport driver_mp(clocking driver_cb);

  modport monitor_mp(clocking monitor_cb);
endinterface
