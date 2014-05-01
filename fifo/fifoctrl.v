module fifoctrl_dualclk
  #(parameter width=1)
  (input [width:0] size_i,
   input [width:0] w_ptr_i,
   input [width:0] r_ptr_i,
   input w_clk_i,
   input r_clk_i,
   output full_o,
   output empty_o,
   output [width:0] w_ptr_next_o,
   output [width:0] r_ptr_next_o,
   output w_busy_o,
   output r_busy_o);

  wire [width:0] zero;
  wire [width:0] one;

  assign zero = {width+1{1'b0}};
  assign one = {{width{1'b0}}, 1'b1};

  reg  [width:0] w_ptr;
  wire [width:0] w_ptr_next;
  reg  [width:0] w_ptr_meta;

  reg  [width:0] r_ptr;
  wire [width:0] r_ptr_next;
  reg  [width:0] r_ptr_meta;

  assign full_o = (w_ptr_next_o == r_ptr);
  assign empty_o = (w_ptr == r_ptr);

  assign w_ptr_next = w_ptr + one;
  assign r_ptr_next = r_ptr + one;

  assign w_busy_o = (w_ptr != w_ptr_i);
  assign r_busy_o = (r_ptr != r_ptr_i);

  assign w_ptr_next_o = (w_ptr_next == size_i) ? zero : w_ptr_next;
  assign r_ptr_next_o = (r_ptr_next == size_i) ? zero : r_ptr_next;

  always @(posedge w_clk_i) begin
    w_ptr_meta <= w_ptr_i;
    w_ptr <= w_ptr_meta;
  end

  always @(posedge r_clk_i) begin
    r_ptr_meta <= r_ptr_i;
    r_ptr <= r_ptr_meta;
  end
endmodule

module fifoctrl
  #(parameter width=1)
  (input [width:0] size_i,
   input [width:0] w_ptr_i,
   input [width:0] r_ptr_i,
   input clk_i,
   output full_o,
   output empty_o,
   output [width:0] w_ptr_next_o,
   output [width:0] r_ptr_next_o,
   output w_busy_o,
   output r_busy_o);

  fifoctrl_dualclk #(.width(width)) f(.size_i(size_i),
                                      .w_ptr_i(w_ptr_i),
                                      .r_ptr_i(r_ptr_i),
                                      .w_clk_i(clk_i),
                                      .r_clk_i(clk_i),
                                      .full_o(full_o),
                                      .empty_o(empty_o),
                                      .w_ptr_next_o(w_ptr_next_o),
                                      .r_ptr_next_o(r_ptr_next_o),
                                      .w_busy_o(w_busy_o),
                                      .r_busy_o(r_busy_o));
endmodule

module fifoctrl_sim_pp(input wclk, input rclk);
  localparam fifosize = 5;
  localparam width = 10;

  reg [width:0] w_ptr;
  wire [width:0] w_ptr_next;
  wire r_busy;
  reg [width:0] r_ptr;
  wire [width:0] r_ptr_next;
  wire w_busy;
  wire full;
  wire empty;

  fifoctrl_dualclk #(.width(width)) f0(.size_i(fifosize),
                                       .w_ptr_i(w_ptr), .r_ptr_i(r_ptr),
                                       .w_clk_i(wclk), .r_clk_i(rclk),
                                       .full_o(full), .empty_o(empty),
                                       .w_ptr_next_o(w_ptr_next), .r_ptr_next_o(r_ptr_next),
                                       .w_busy_o(w_busy), .r_busy_o(r_busy));

  integer i = 0;
  integer we = 0;
  integer re = 0;

  initial begin
    w_ptr = 0;
    r_ptr = 0;
  end

  always @(posedge wclk)
    i <= i + 1;

  always @(posedge wclk)
    if (!full && !w_busy && i < 18) begin
      w_ptr <= w_ptr + 1;
      we <= we + 1;
    end

  always @(posedge rclk)
    if (!empty && !r_busy) begin
      r_ptr <= r_ptr + 1;
      re <= re + 1;
    end
endmodule

module fifoctrl_sim;
  wire sys_clk;
  sim_clk sysClk(sys_clk);

  wire slow_clk;
  sim_clk #(.T(8)) slowClk(slow_clk);

  fifoctrl_sim_pp m0(slow_clk, slow_clk);
  fifoctrl_sim_pp m1(sys_clk, slow_clk);
  fifoctrl_sim_pp m2(slow_clk, sys_clk);
  fifoctrl_sim_pp m3(sys_clk, sys_clk);

  initial begin
    $dumpfile(`VCD_PATH);
    $dumpvars();

    #100 $finish;
  end
endmodule
