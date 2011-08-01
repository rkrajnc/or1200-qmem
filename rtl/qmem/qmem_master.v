/**************************************/
/* qmem_master.v                      */
/*                                    */
/* QMEM master                        */
/* simulates a master on a QMEM bus   */
/*                                    */
/* 2010, rok.krajnc@gmail.com         */
/**************************************/


module qmem_master #(
  parameter QAW = 32,           // address width
  parameter QDW = 32,           // data width
  parameter QSW = QDW/8,        // byte select width
  parameter AD = 10             // allowed delay for ack
)(
  // system signals
  input wire            clk,    // clock
  input wire            rst,    // reset
  // qmem interface
  output reg            cs,     // chip-select
  output reg            we,     // write enable
  output reg  [QSW-1:0] sel,    // byte select
  output reg  [QAW-1:0] adr,    // address
  output reg  [QDW-1:0] dat_w,  // write data
  input  wire [QDW-1:0] dat_r,  // read data
  input  wire           ack,    // acknowledge
  input  wire           err,    // error
  // error
  output reg            error   // error on bus detected
);


/* initial settings */
initial begin
  cs    = 1'b0;
  we    = 1'bx;
  sel   = {QSW{1'bx}};
  adr   = {QAW{1'bx}};
  dat_w = {QDW{1'bx}};
  error = 1'b0;
end


/* tasks */

//wait ack task
task wait_ack;
  integer cnt;
begin
  cnt = 0;
  while (!(ack | err)) begin
    if (cnt == AD) begin
      $display("ERROR : QMEM_MASTER (%m) : acknowledge delay longer than %01d (time : %t) !!!", AD, $time);
      error = 1;
      $finish(1);
    end
    cnt = cnt + 1;
    @(posedge clk);
  end
end
endtask

// init
// sets initial - default bus state
task init;
begin
  @(posedge clk);
  #1;
  cs    = 1'b0;
  we    = 1'bx;
  sel   = {QSW{1'bx}};
  adr   = {QAW{1'bx}};
  dat_w = {QDW{1'bx}};
  @(posedge clk);
end
endtask

// single write task
// normal cycle termination
task write;
  input  [QAW-1:0] madr,  // address
  input  [QSW-1:0] msel,  // byte select
  input  [QDW-1:0] mdat   // write data
begin
  @(posedge clk);
  #1;
  cs    = 1'b1;
  we    = 1'b1;
  adr   = madr;
  sel   = msel;
  dat_w = mdat;
  @(posedge clk);
  // wait for answer
  wait_ack;
  #1;
  cs    = 1'b0;
  we    = 1'bx;
  sel   = {QSW{1'bx}};
  adr   = {QAW{1'bx}};
  dat_w = {QDW{1'bx}};
end
endtask

// read task
// normal cycle termination
task read;
  input  [QAW-1:0] madr;  // address
  input  [QSW-1:0] msel;  // byte select
  output [QDW-1:0] mdat;  // read data
begin
  @(posedge clk);
  #1;
  cs    = 1'b1;
  we    = 1'b0;
  adr   = madr;
  sel   = msel;
  @(posedge clk);
  // wait for answer
  wait_ack;
  #1;
  cs    = 1'b0;
  we    = 1'bx;
  sel   = {QSW{1'bx}};
  adr   = {QAW{1'bx}};
  @(posedge clk);
  mdat  = dat_i;
  #1;
end
endtask

// cycle task
// raw bus cycles, no cycle termination
task cycle;
  input            mcs;   // chip-select
  input            mwe;   // write enable
  input  [QSW-1:0] msel;  // byte select
  input  [QAW-1:0] madr;  // address
  output [QDW-1:0] mdat;  // write data
  input            last_cycle;
begin
  //@(posedge clk); // bus should be ready here!
  #1;
  cs    = mcs;
  we    = mwe;
  adr   = madr;
  sel   = msel;
  dat_w = mdat;
  @(posedge clk);
  if (mcs) begin // only wait for ack if cs is HIGH
    wait_ack;
  end
  // leave bus in x state if last cycle
  if (last_cycle == 1) begin
    #1;
    cs    = 1'b0;
    we    = 1'bx;
    adr   = {QAW{1'bx}};
    sel   = {QSW{1'bx}};
    dat_w = {QDW{1'bx}};
  end
end
endtask

// load
// read cycles from specified file
task load;
  input filename;
begin
  // TODO
end
endtask

// write mulitple task
// TODO: this should be fixed!
task write_multiple;
  parameter IW = 2;
  input  [IW*QAW-1:0] madr;
  input  [IW*QSW-1:0] msel;
  input  [IW*QDW-1:0] mdat;
  integer            i;
begin
  @(posedge clk);
  #1;
  for(i = 0; i < IW; i = i + 1) begin
    cs    = 1'b1;
    we    = 1'b1;
    sel   = msel[QSW*i +:QSW];
    adr   = madr[QAW*i +:QAW];
    dat_w = mdat[QDW*i +:QDW];
    @(posedge clk);
    // wait for answer
    wait_ack;
    #1;
  end
  cs    = 1'b0;
  we    = 1'b0;
  sel   = {QSW{1'bx}};
  adr   = {QAW{1'bx}};
  dat_w = {QDW{1'bx}};
end
endtask     

// read multiple task
// TODO: this should be fixed!
task read_multiple;
  parameter IW = 2;
  input  [IW*QAW-1:0] madr;
  input  [IW*QSW-1:0] msel;
  output [IW*QDW-1:0] mdat;
  integer            i;
begin
  @(posedge clk);
  #1;
  for (i = 0; i < IW; i = i + 1) begin
    cs    = 1'b1;
    we    = 1'b0;
    adr   = madr[QAW*i +:QAW];
    sel   = msel[QSW*i +:QSW];
    @(posedge clk);
    // wait for answer
    wait_ack;
    #1;
    cs    = 1'b0;  // TODO : this should be fixed for real concurrent read accesses, next address should be appplied immediately after ack, in the read cycle!
    we    = 1'b0;
    @(posedge clk);
    #1;
    mdat[QDW*i +:QDW] = dat_i;
  end
  cs    = 1'b0;
  we    = 1'b0;
  sel   = {QSW{1'bx}};
  adr   = {QAW{1'bx}};
end
endtask


endmodule

