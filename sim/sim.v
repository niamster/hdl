`ifndef SIM_HEPLERS
`define SIM_HEPLERS

module sim_clk
  #(parameter T=2)
  (output reg clk);

  initial begin
    clk = 0;
    forever begin
      clk = #(T/2) !clk;
    end
  end
endmodule

`endif
