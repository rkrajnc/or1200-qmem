/**************************************/
/* qmem_slave.v                       */
/*                                    */
/* QMEM slave (memory)                */
/* simulates a slave on a QMEM bus    */
/*                                    */
/* 2010, rok.krajnc@gmail.com         */
/**************************************/


module qmem_slave #(
  parameter QAW = 32,           // address width
  parameter QDW = 32,           // data width
  parameter QSW = QDW/8,        // byte select width
  parameter MS = 0,             // address space size
  parameter T_FIX_DELAY = 0,    // slave fixed delay
  parameter T_RND_DELAY = 0     // slave random delay
)(
  // system signals
  input  wire           clk,    // clock
  input  wire           rst,    // reset
  // memory interface
  input  wire           cs,     // chip-select
  input  wire           we,     // write enable
  input  wire [QSW-1:0] sel,    // byte select
  input  wire [QAW-1:0] adr,    // address
  input  wire [QDW-1:0] dat_w,  // write data
  output reg  [QDW-1:0] dat_r,  // read data
  output wire           ack,    // acknowledge
  output wire           err     // error
);


/* local signals */

// delay registers
integer seed = 0;
integer cnt;

// timing parameters registers
integer R_FIX_DELAY = T_FIX_DELAY;
integer R_RND_DELAY = T_RND_DELAY;

// generate variables
genvar i;

// bus transfer
wire           trn;

// memory
reg  [QDW-1:0] mem [0:MS-1];


/* implementation */

// transfer
assign trn = cs & (ack | err);

// memory write
generate for (i=0; i<QSW; i=i+1) begin : LOOP_SW
always @(posedge clk)
if (trn &  we & sel[i])  mem[adr[QAW-1:2]] [i*8+:8] <= dat_w [i*8+:8];
end endgenerate

// memory read
always @ (posedge clk)
dat_r <= #1 (trn & ~we) ? mem[adr[QAW-1:2]] : {QDW{1'bx}};

// acknowledge counter
always @ (posedge clk)
if (~cs | trn)  cnt <= #1 $dist_uniform(seed, R_FIX_DELAY, R_FIX_DELAY + R_RND_DELAY);
else            cnt <= #1 cnt - 1;

// success and error acknowledge
assign ack = ~|cnt;
assign err = rst;


/* tasks */

// set timing
task set_timing;
  input integer fix_delay;
  input integer rnd_delay;
begin
  R_FIX_DELAY = fix_delay;
  R_RND_DELAY = rnd_delay;
end
endtask

// initialize to zero task
task fill_zeros;
  integer i;
  for (i=0; i<MS; i=i+1)  mem[i] = {QDW{1'b0}};
endtask

// initialize to ones task
task fill_ones;
  integer i;
  for (i=0; i<MS; i=i+1)  mem[i] = {QDW{1'b1}};
endtask

// initialize to random values
task fill_rand (input [31:0] seed);
  integer i;
  for (i=0; i<MS; i=i+1)  mem[i] = {$random(seed)};
endtask

// initialize to address val
task fill_adr;
  integer        i;
  for (i=0; i<MS; i=i+1)  mem[i] = 4*i;
endtask

// load from file
task load_hex (input [(8*256-1):0] file);
  integer fp;
begin
  fp = $fopen(file, "r");
  if (fp == 0) begin
    $display("QMEM_SLAVE: load_hex error (file doesn't exist or isn't readable)!");
    $finish(1);
  end
  $fclose(fp);
  $readmemh(file, mem);
end
endtask

// save memory content to file
task dump_hex (input [(8*256-1):0] file);
  $writememh(file, mem);
endtask


endmodule

