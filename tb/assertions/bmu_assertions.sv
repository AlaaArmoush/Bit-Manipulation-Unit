`timescale 1ns / 1ps

module bmu_assertions (
    input logic                         clk,
    input logic                         rst_l,
    input logic                         valid_in,
    input rtl_pkg::rtl_alu_pkt_t        ap,
    input logic                         csr_ren_in,
    input logic                  [31:0] result_ff,
    input logic                         error
);
  // Active reset must clear the outputs.
  always @(posedge clk) begin : check_reset_clear
    #1ps;

    if (rst_l === 1'b0) begin
      A_RST_CLEAR :
      assert ((result_ff === 32'h0000_0000) && (error === 1'b0))
      else $error("A_RST_CLEAR: result=0x%08h error=%0b", result_ff, error);
    end
  end

  bit runtime_reset_armed;

  initial begin
    runtime_reset_armed = 1'b0;
  end

  // Ignore the initial startup reset.
  always @(posedge rst_l) begin
    runtime_reset_armed = 1'b1;
  end

  // Expected synchronous behavior:
  // reset low -> result unchanged -> rising edge -> result zero
  always @(negedge rst_l) begin : check_synchronous_reset
    if (runtime_reset_armed) begin
      automatic logic [31:0] result_before_reset;

      result_before_reset = result_ff;

      fork
        begin
          @(posedge clk);
          A_RST_SYNC :
          assert (result_ff === result_before_reset)
          else
            $error(
                "A_RST_SYNC: result changed before the reset edge: before=0x%08h current=0x%08h",
                result_before_reset,
                result_ff
            );
        end
      join_none
    end
  end

  // The registered result must hold while valid_in is low.
  always @(posedge clk) begin : check_result_hold
    logic [31:0] result_before_edge;
    logic        reset_at_edge;
    logic        valid_at_edge;

    result_before_edge = result_ff;
    reset_at_edge      = rst_l;
    valid_at_edge      = valid_in;

    #1ps;

    if ((reset_at_edge === 1'b1) && (valid_at_edge === 1'b0)) begin
      A_RESULT_HOLD :
      assert (result_ff === result_before_edge)
      else $error("A_RESULT_HOLD: before=0x%08h after=0x%08h", result_before_edge, result_ff);
    end
  end

  // Invalid controls can assert error while valid_in is low.
  always @(rst_l or valid_in or ap or csr_ren_in) begin : check_idle_error
    #1ps;

    if ((rst_l    === 1'b1) &&
        (valid_in === 1'b0) &&
        (((ap.lor     === 1'b1) &&
          (ap.lxor    === 1'b1)) ||
         ((csr_ren_in === 1'b1) &&
          (ap.lor     === 1'b1)))) begin
      A_IDLE_ERROR :
      assert (error === 1'b1)
      else
        $error(
            {
              "A_IDLE_ERROR: csr_ren_in=%0b lor=%0b ", "lxor=%0b error=%0b"
            },
            csr_ren_in,
            ap.lor,
            ap.lxor,
            error
        );
    end
  end

endmodule : bmu_assertions
