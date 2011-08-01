/**************************************/
/* qmem_freq_down.v                   */
/*                                    */
/* QMEM frequency change              */
/* allows master to run at faster     */
/* (or equal) synchronous clock       */
/*                                    */
/* 2010, rok.krajnc@gmail.com         */
/**************************************/


module qmem_freq_down #(
  parameter QAW = 32,               // address width
  parameter QDW = 32,               // data width
  parameter QSW = QDW/8,            // select width
  parameter RW = 3                  // ratio width
)(
  // system
  input  wire           qm_clk,     // 1x or nx clock
  input  wire           qs_clk,     // 1x clock
  input  wire           rst,        // reset
  // clock configuration
  input  wire  [RW-1:0] ratio,      // qm_clk / qs_clk ratio (1:1 = 0)
  input  wire           ratio_req,  // ratio change request
  output wire           ratio_grt,  // ratio change grant
  // input qmem port
  input  wire           qm_cs,      // chip-select
  input  wire           qm_we,      // write enable
  input  wire [QSW-1:0] qm_sel,     // byte select
  input  wire [QAW-1:0] qm_adr,     // address
  input  wire [QDW-1:0] qm_dat_w,   // write data
  output wire [QDW-1:0] qm_dat_r,   // read data
  output wire           qm_ack,     // acknowledge
  output wire           qm_err,     // error
  // output qmem port
  output wire           qs_cs,      // chip-select
  output wire           qs_we,      // write enable
  output wire [QSW-1:0] qs_sel,     // byte select
  output wire [QAW-1:0] qs_adr,     // address
  output wire [QDW-1:0] qs_dat_w,   // write data
  input  wire [QDW-1:0] qs_dat_r,   // read data
  input  wire           qs_ack,     // acknowledge
  input  wire           qs_err      // error
);


/* local signals */

reg            qm_toggle;
reg            qs_toggle;
reg  [RW-1:0]  toggle_cnt;
wire           clk_posedge;
reg            clk_posedge_d;

reg  [RW-1:0]  ratio_d;
wire           ratio_changed;
reg            ratio_changed_d;

reg  [RW-1:0]  ack_delay;


/* implementation */

// TODO
assign qm_err = qs_err;
assign ratio_grt = ratio_req;

// qs_clk toggle
always @ (posedge qs_clk or posedge rst)
if (rst)  qs_toggle <= #1 1'b0;
else      qs_toggle <= #1 !qs_toggle;

// qm_clk toggle
always @ (posedge qm_clk or posedge rst)
if (rst)  qm_toggle <= #1 1'b0;
else      qm_toggle <= #1 qs_toggle;

// toggle_cnt
always @ (posedge qm_clk or posedge rst)
if (rst)                      toggle_cnt <= #1 {RW{1'b0}};
else begin
  if (qs_toggle ^ qm_toggle)  toggle_cnt <= #1 ratio;
  else                        toggle_cnt <= #1 toggle_cnt - |toggle_cnt;
end

// clk_posedge
assign clk_posedge = (toggle_cnt == 3'b001) | (ratio == 'd0);

always @ (posedge qm_clk)
clk_posedge_d <= #1 clk_posedge;

// delayed inputs
always @ (posedge qs_clk)
ratio_d <= #1 ratio;

// ratio changed
always @ (posedge qm_clk or posedge rst)
if (rst)                 ratio_changed_d <= #1 1'b0;
else begin
if (clk_posedge)         ratio_changed_d <= #1 1'b0;
else if (ratio_changed)  ratio_changed_d <= #1 1'b1;
end

assign ratio_changed = ratio_changed_d | (ratio != ratio_d);

// ack delay
always @ (posedge qm_clk or posedge rst)
if (rst)                                     ack_delay <= #1 'd0;
else begin
  if (|ack_delay)                            ack_delay <= #1 ack_delay - |ack_delay;
  else if (qm_cs & qs_ack &  clk_posedge_d)  ack_delay <= #1 ratio - 'd0;
  else if (qm_cs & qs_ack & ~clk_posedge_d)  ack_delay <= #1 toggle_cnt - 'd1;
  else                                       ack_delay <= #1 ack_delay - |ack_delay;
end


// outputs - input side
assign qm_dat_r = qs_dat_r;
assign qm_ack   = qs_ack & ((ratio == 'd0) | (ack_delay == 'd1));

// outputs - output side
assign qs_we    = qm_we;
assign qs_cs    = qm_cs;
assign qs_sel   = qm_sel;
assign qs_adr   = qm_adr;
assign qs_dat_w = qm_dat_w;


endmodule

