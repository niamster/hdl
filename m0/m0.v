module m0(clk, key, rstn, leds);
  parameter width=8;

  input clk;
  input key;
  input rstn;
  output reg [width-1:0] leds;

  reg [width-1:0] r0;

  initial begin
    leds = 0;
    r0 = 0;
  end

  always @(negedge key, negedge rstn) begin
    if (rstn == 0)
      r0 = {width{1'b0}};
    else
      r0 = r0 + {{width-1{1'b0}}, 1'b1};
  end

  always @(posedge clk) begin
    if (rstn == 0)
      leds <= {width{1'b0}};
    else
      leds <= r0;
  end
endmodule

module m0_de0nano(sys_clk, key, rstn, leds);
  input sys_clk;
  input key;
  input rstn;
  output [7:0] leds;

  m0 #(.width(8)) m0I(sys_clk, key, rstn, leds);
endmodule

module m0_mock(leds, key, rstn);
  parameter width = 8;

  input [width-1:0] leds;
  output reg key;
  output reg rstn;

  initial begin
    key = 1;
    rstn = 1;
    forever begin
      key = #5 !key;
    end
  end
  initial #30 rstn = 0;
  initial #50 rstn = 1;
endmodule

module m0_sim;
  wire [7:0] leds;
  wire key;
  wire clk;
  wire rstn;

  sim_clk m0IClk(clk);
  m0 #(.width(8)) m0I(clk, key, rstn, leds);
  m0_mock #(.width(8)) m0_mockI(leds, key, rstn);

  initial begin
    $dumpfile("m0.vcd");
    $dumpvars();
    $monitor("T=%t, clk=%d key=%d rstn=%0d leds=%0d", $time, clk, key, rstn, leds);
    #70 $finish;
  end
endmodule
