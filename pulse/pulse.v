module pulse
  #(parameter dly=3,
    parameter len=2,
    parameter width=8)
  (input rstn,
   input clk,
   output reg pulse);

  reg [width-1:0] cnt;

  always @(posedge clk or negedge rstn) begin
    if (~rstn)
      cnt <= 1'b0;
    else if (cnt != dly+len)
      cnt <= cnt + 1'b1;
  end

  always @(posedge clk or negedge rstn) begin
    if (~rstn)
      pulse <= 1'b0;
    else if (cnt == dly)
      pulse <= 1'b1;
    else if (cnt == dly+len)
      pulse <= 1'b0;
  end
endmodule

module pulse_sim_clk(clk);
  output reg clk;

  initial begin
    clk = 0;
    forever begin
      clk = #1 !clk;
    end
  end
endmodule

module pulse_sim;
  wire sys_clk;
  pulse_sim_clk simClk(sys_clk);

  // ------------

  reg rstn;
  wire p[6:0];

  initial rstn = 0;
  initial #2 rstn = 1;
  initial #65 rstn = 0;

  pulse #(.dly(8), .len(0))      pulseI0(.rstn(rstn), .clk(sys_clk), .pulse(p[0]));
  pulse #(.dly(8), .len(1))      pulseI1(.rstn(rstn), .clk(sys_clk), .pulse(p[1]));
  pulse #(.dly(8), .len(1024))   pulseI2(.rstn(rstn), .clk(sys_clk), .pulse(p[2]));
  pulse #(.dly(0), .len(1))      pulseI3(.rstn(rstn), .clk(sys_clk), .pulse(p[3]));
  pulse #(.dly(1), .len(0))      pulseI4(.rstn(rstn), .clk(sys_clk), .pulse(p[4]));
  pulse #(.dly(0), .len(0))      pulseI5(.rstn(rstn), .clk(sys_clk), .pulse(p[5]));

  // ------------

  initial begin
    $dumpfile("pulse.vcd");
    $dumpvars();
    // $monitor("T=%t, clk=%d p[0]=%d p[1]=%d p[2]=%d p[3]=%d",
    //          $time, sys_clk,
    //          p[0],
    //          p[1],
    //          p[2],
    //          p[3])
    #70 $finish;
  end
endmodule
