
module fifoctrl
  #(parameter size=1)
  (input [$clog2(size):0] w_ptr,
   input [$clog2(size):0] r_ptr,
   output reg full,
   output reg empty,
   output reg [$clog2(size):0] w_ptr_next,
   output reg [$clog2(size):0] r_ptr_next);

  always @* begin
    w_ptr_next = w_ptr + 1;
    if (w_ptr_next == size)
      w_ptr_next = 0;
  end

  always @* begin
    r_ptr_next = r_ptr + 1;
    if (r_ptr_next == size)
      r_ptr_next = 0;
  end

  always @*
    full = (w_ptr_next == r_ptr);
  always @*
    empty = (w_ptr == r_ptr);
endmodule

module fifoctrl_sim_pp(input clk0, input clk1);
  localparam fifosize = 5;
  localparam width = $clog2(fifosize)+1;

  reg [width-1:0] w_ptr;
  wire [width-1:0] w_ptr_next;
  reg [width-1:0] r_ptr;
  wire [width-1:0] r_ptr_next;
  wire full;
  wire empty;

  fifoctrl #(fifosize) f0(w_ptr, r_ptr, full, empty, w_ptr_next, r_ptr_next);

  integer i = 0;

  initial begin
    w_ptr = 0;
    r_ptr = 0;
  end

  always @(posedge clk0) begin
    if (!full && i < 7) begin
      w_ptr = w_ptr_next;
      i = i + 1;
    end
  end

  always @(posedge clk1) begin
    if (!empty)
      r_ptr = r_ptr_next;
  end
endmodule

module fifoctrl_sim;
  wire sys_clk;
  sim_clk sysClk(sys_clk);

  wire slow_clk;
  sim_clk #(.T(8)) slowClk(slow_clk);

  fifoctrl_sim_pp m0(sys_clk, slow_clk);
  fifoctrl_sim_pp m1(slow_clk, sys_clk);

  initial begin
    $dumpfile(`VCD_PATH);
    $dumpvars();

    #100 $finish;
  end
endmodule
