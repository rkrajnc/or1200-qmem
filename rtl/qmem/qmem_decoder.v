/**************************************/
/* qmem_decoder.v                     */
/*                                    */
/* QMEM bus decoder                   */
/* allows a master                    */
/* to access multiple slaves          */
/*                                    */
/* 2010, iztok.jeras@gmail.com        */
/**************************************/


module qmem_decoder #(
  parameter QAW = 32,                 // address width
  parameter QDW = 32,                 // data width
  parameter QSW = QDW/8,              // byte select width
  parameter SN  = 2                   // number of slaves
)(
  // system
  input  wire              clk,       // clock
  input  wire              rst,       // reset
  // slave port for requests from masters
  input  wire              qm_cs,     // chip-select
  input  wire              qm_we,     // write enable
  input  wire    [QSW-1:0] qm_sel,    // byte select
  input  wire    [QAW-1:0] qm_adr,    // address
  input  wire    [QDW-1:0] qm_dat_w,  // write data
  output wire    [QDW-1:0] qm_dat_r,  // read data
  output wire              qm_ack,    // acknowledge
  output wire              qm_err,    // error
  // master port for requests to a slave
  output wire [SN    -1:0] qs_cs,     // chip-select
  output wire [SN    -1:0] qs_we,     // write enable
  output wire [SN*QSW-1:0] qs_sel,    // byte select
  output wire [SN*QAW-1:0] qs_adr,    // address
  output wire [SN*QDW-1:0] qs_dat_w,  // write data
  input  wire [SN*QDW-1:0] qs_dat_r,  // read data
  input  wire [SN    -1:0] qs_ack,    // acknowledge
  input  wire [SN    -1:0] qs_err,    // error
  // one hot slave select signal
  input  wire [SN    -1:0] ss         // selected slave
);


/* local signals */
wire [7:0] ss_a;
reg  [7:0] ss_r;

genvar i;


/* implementation */

generate if (SN == 1) assign ss_a =                                                         0; endgenerate
generate if (SN == 2) assign ss_a =                                                 ss[1]?1:0; endgenerate
generate if (SN == 3) assign ss_a =                                         ss[2]?2:ss[1]?1:0; endgenerate
generate if (SN == 4) assign ss_a =                                 ss[3]?3:ss[2]?2:ss[1]?1:0; endgenerate
generate if (SN == 5) assign ss_a =                         ss[4]?4:ss[3]?3:ss[2]?2:ss[1]?1:0; endgenerate
generate if (SN == 6) assign ss_a =                 ss[5]?5:ss[4]?4:ss[3]?3:ss[2]?2:ss[1]?1:0; endgenerate
generate if (SN == 7) assign ss_a =         ss[6]?6:ss[5]?5:ss[4]?4:ss[3]?3:ss[2]?2:ss[1]?1:0; endgenerate
generate if (SN == 8) assign ss_a = ss[7]?7:ss[6]?6:ss[5]?5:ss[4]?4:ss[3]?3:ss[2]?2:ss[1]?1:0; endgenerate

always @ (posedge clk)
if (qm_cs & (qm_ack | qm_err) & ~qm_we)  ss_r <= #1 ss_a;

// master port for requests to a slave
generate for (i=0; i<SN; i=i+1) begin : loop_select
  assign qs_cs    [     i                   ] = qm_cs & ss [i];
  assign qs_we    [     i                   ] = qm_we;
  assign qs_adr   [QAW*(i+1)-1:QAW*(i+1)-QAW] = qm_adr;
  assign qs_sel   [QSW*(i+1)-1:QSW*(i+1)-QSW] = qm_sel;
  assign qs_dat_w [QDW*(i+1)-1:QDW*(i+1)-QDW] = qm_dat_w;
end endgenerate

// slave port for requests from masters
assign qm_dat_r = qs_dat_r >> (QDW*ss_r);
assign qm_ack   = qs_ack   >>      ss_a ;
assign qm_err   = qs_err   >>      ss_a ;


endmodule

