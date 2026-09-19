`timescale 1ns / 1ps

module bmu_assertions (
    input logic        clk,
    input logic        rst_l,
    input logic [31:0] result_ff,
    input logic        error
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

endmodule : bmu_assertions
