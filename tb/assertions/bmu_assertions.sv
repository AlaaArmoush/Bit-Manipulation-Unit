`timescale 1ns / 1ps

module bmu_assertions (
    input logic        clk,
    input logic        rst_l,
    input logic [31:0] result_ff,
    input logic        error
);

  // Sample outputs after they update on the rising edge.
  clocking reset_cb @(posedge clk);
    default input #0;

    input rst_l;
    input result_ff;
    input error;
  endclocking

  // Active reset must clear the outputs.
  property p_rst_clear;
    @(reset_cb)
      (reset_cb.rst_l === 1'b0)
      |->
      ((reset_cb.result_ff === 32'h0000_0000) &&
       (reset_cb.error     === 1'b0));
  endproperty

  A_RST_CLEAR :
  assert property (p_rst_clear)
  else $error("A_RST_CLEAR: result=0x%08h error=%0b", reset_cb.result_ff, reset_cb.error);

  bit startup_reset_released;

  initial begin
    startup_reset_released = 1'b0;
  end

  // A rising rst_l means active-low reset has been released.
  always @(posedge rst_l) begin
    startup_reset_released = 1'b1;
  end

  // Expected synchronous behavior:
  // reset low -> result unchanged -> rising edge -> result zero
  always @(negedge rst_l) begin : check_synchronous_reset
    if (startup_reset_released) begin
      automatic logic [31:0] result_before_reset;

      result_before_reset = result_ff;

      fork
        begin
          @(posedge clk);

          A_RST_SYNC :
          assert (result_ff === result_before_reset)
          else
            $error(
                {
                  "A_RST_SYNC: result changed before the reset edge: ",
                  "before=0x%08h current=0x%08h"
                },
                result_before_reset,
                result_ff
            );
        end
      join_none
    end
  end

endmodule : bmu_assertions

