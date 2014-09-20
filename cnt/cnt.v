`define CNT_UP 1
`define CNT_DOWN 0

module cnt
  #(parameter width=32,
    parameter direction=`CNT_UP)
  (input clk,
   input [width-1:0] top,
   input rstn,
   input clr_it,
   input start,
   input freerun,

   output reg [width-1:0] cnt,
   output reg it);

  wire [width-1:0] one;
  wire [width-1:0] zero;
  wire [width-1:0] load;
  wire [width-1:0] tgt;
  wire [width-1:0] inc;

  assign one = {{width-1{1'b0}}, 1'b1};
  assign zero = {width{1'b0}};
  assign load = (direction == `CNT_UP)?zero:top;
  assign tgt = (direction == `CNT_UP)?top:zero;
  assign inc = (direction == `CNT_UP)?one:-one;

  reg ovf;
  reg run;

  always @(posedge clk) begin
    if (~rstn || ~clr_it)
      it <= 1'b0;
    else if (ovf)
      it <= 1'b1;
  end

  always @(posedge clk) begin
    if (~rstn) begin
      ovf <= 1'b0;
      cnt <= load;
      run <= 1'b0;
    end else if (~run & start) begin
      run <= 1'b1;
    end else begin
      if (run)
        cnt <= cnt + inc;
      if (cnt == tgt) begin
        ovf <= 1'b1;
        cnt <= load;
        if (~freerun)
          run <= 1'b0;
      end else
        ovf <= 1'b0;
    end
  end
endmodule

module clkdiv
  #(parameter div=2)
  (input rstn,
   input iclk,
   output reg oclk);

  wire [31:0] one;
  wire [31:0] top;
  wire [31:0] cnt;

  wire it;
  wire start;

  assign one = {{30{1'b0}}, 1'b1};
  assign top = div-one;

  always @(posedge iclk or negedge rstn) begin
    if (~rstn)
      oclk <= 1'b0;
    else begin
      if (cnt == top)
        oclk <= oclk + 1'b1;
    end
  end

  pulse #(.dly(3), .len(2)) pulseI(.rstn(rstn), .clk(iclk), .pulse(start));
  cnt cntI(.clk(iclk),
           .top(top), .rstn(rstn), .start(start), .freerun(1),
           .cnt(cnt), .it(it));
endmodule

module cnt_sim;
  wire sys_clk;
  sim_clk simClk(sys_clk);

  // ------------

  reg rstn[3:0];
  reg clr_it[3:0];
  reg start[3:0];
  reg [7:0] top[3:0];
  wire it[3:0];
  wire [7:0] cnt[3:0];

  genvar i;
  generate
    for (i=0; i<4; i=i+1) begin :gen0
      initial begin
        top[i] = 4;
        clr_it[i] = 1;
        rstn[i] = 0;
        start[i] = 1'b0;
      end
      initial #4 rstn[i] = 1;
      initial #65 rstn[i] = 0;
      initial begin
        #4 start[i] = 1'b1;
        #2 start[i] = 1'b0;
      end

      always @(posedge it[i]) begin
        #4 clr_it[i] = 1'b0;
        #4 clr_it[i] = 1'b1;
      end
      always @(posedge it[i]) begin
        if (i&1) begin
          #6 start[i] = 1'b1;
          #2 start[i] = 1'b0;
        end
      end
    end
  endgenerate

  initial #15 top[0] = 5;
  initial #50 top[1] = 5;
  initial #50 top[3] = 5;

  cnt #(.width(8),.direction(`CNT_UP)) cntUpFree(.clk(sys_clk),
                                                 .top(top[0]), .rstn(rstn[0]),
                                                 .clr_it(clr_it[0]), .start(start[0]), .freerun(1),
                                                 .cnt(cnt[0]), .it(it[0]));
  cnt #(.width(8),.direction(`CNT_UP)) cntUpLocked(.clk(sys_clk),
                                                 .top(top[1]), .rstn(rstn[1]),
                                                 .clr_it(clr_it[1]), .start(start[1]), .freerun(0),
                                                 .cnt(cnt[1]), .it(it[1]));
  cnt #(.width(8),.direction(`CNT_DOWN)) cntDownFree(.clk(sys_clk),
                                                 .top(top[2]), .rstn(rstn[2]),
                                                 .clr_it(clr_it[2]), .start(start[2]), .freerun(1),
                                                 .cnt(cnt[2]), .it(it[2]));
  cnt #(.width(8),.direction(`CNT_DOWN)) cntDownLocked(.clk(sys_clk),
                                                 .top(top[3]), .rstn(rstn[3]),
                                                 .clr_it(clr_it[3]), .start(start[3]), .freerun(0),
                                                 .cnt(cnt[3]), .it(it[3]));

  // ------------

  wire sys_clk_div_2;
  reg clkdiv_rstn;

  initial begin
    clkdiv_rstn = 0;
    #2 clkdiv_rstn = 1;
  end

  clkdiv clkDiv(.rstn(clkdiv_rstn), .iclk(sys_clk), .oclk(sys_clk_div_2));

  // ------------

  initial begin
    $dumpfile(`VCD_PATH);
    $dumpvars();
    // $monitor("T=%t, clk=%d cnt[0]=%d i[0]=%0d cnt[1]=%d i[1]=%0d cnt[2]=%d i[2]=%0d cnt[3]=%d i[3]=%0d",
    //          $time, sys_clk,
    //          cnt[0], it[0],
    //          cnt[1], it[1],
    //          cnt[2], it[2],
    //          cnt[3], it[3]);
    #70 $finish;
  end
endmodule
