module m1(clk, rstn, leds);
  parameter width=8;

  input clk;
  input rstn;
  output reg [width-1:0] leds;

  always @(posedge clk, negedge rstn) begin
    if (~rstn)
      leds <= {width{1'b0}};
    else
      leds <= leds + {{width-1{1'b0}}, 1'b1};
  end
endmodule

module m1_de0nano(sys_clk, rstn, rstn_it, leds);
  input sys_clk;
  input rstn;
  input rstn_it;
  output [7:0] leds;

  wire clk;
  wire [1:0] top;

  clkdiv #(50000000) clkDiv(.rstn(rstn),
                            .iclk(sys_clk), .oclk(clk));

  m1 #(.width(4)) m1I(.clk(clk),
                      .rstn(rstn), .leds(leds[3:0]));

  cnt #(.width(2)) cntUp(.clk(clk),
                               .top(3), .rstn(rstn), .clr_it(rstn_it), .start(1), .freerun(1),
                               .cnt(leds[6:4]), .it(leds[7]));
endmodule

module m1_sim_clk(clk);
  output reg clk;

  initial begin
    clk = 0;
    forever begin
      clk = #1 !clk;
    end
  end
endmodule

module m1_sim;
  wire sys_clk;
  cnt_sim_clk simClk(sys_clk);

  reg rstn;
  initial begin
    rstn = 0;
    #2 rstn = 1;
  end

  wire clk;
  clkdiv #(50) clkDiv(.rstn(rstn), .iclk(sys_clk), .oclk(clk));

  wire [3:0] leds0;
  wire [2:0] leds1;
  wire led3;

  m1 #(.width(4)) m1I(.clk(clk), .rstn(rstn), .leds(leds0));
  cnt #(.width(3)) cntUp(.clk(clk), .top(3), .rstn(rstn), .start(1), .freerun(1), .cnt(leds1), .it(led3));

  initial begin
    $dumpfile("m1.vcd");
    $dumpvars();
    // $monitor("T=%t, i=%0d", $time, clk);
    #2000 $finish;
  end
endmodule
