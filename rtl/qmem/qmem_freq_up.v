/**************************************/
/* qmem_freq_up.v                     */
/*                                    */
/* QMEM frequency change              */
/* allows master to run at slower     */
/* (or equal) synchronous clock       */
/*                                    */
/* 2010, rok.krajnc@gmail.com         */
/**************************************/


module qmem_freq_up #(
  parameter QAW = 32,               // address width
  parameter QDW = 32,               // data width
  parameter QSW = QDW/8,            // select width
  parameter RW = 3                  // ratio width
)(
  // system
  input  wire           qm_clk,     // 1x clock
  input  wire           qs_clk,     // 1x or nx clock
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
reg   [RW-1:0] qs_toggle_cnt;
wire           clk_posedge;

reg            ack_d;
reg            cs_d;
reg  [QDW-1:0] dat_d;

reg   [RW-1:0] ratio_d;
wire           ratio_changed;
reg            ratio_changed_d;

reg            cycle_delay;
reg            ack_delay;

reg            dat_loc;


/* implementation */

// TODO
assign qm_err = qs_err;
assign ratio_grt = ratio_req;

// qm_clk toggle
always @ (posedge qm_clk, posedge rst)
if (rst)  qm_toggle <= #1 1'b0;
else      qm_toggle <= #1 !qm_toggle;

// qs_clk toggle
always @ (posedge qs_clk, posedge rst)
if (rst)  qs_toggle <= #1 1'b0;
else      qs_toggle <= #1 qm_toggle;

// qs_toggle_cnt
always @ (posedge qs_clk, posedge rst)
if (rst)                      qs_toggle_cnt <= #1 {RW{1'b0}};
else begin
  if (qm_toggle ^ qs_toggle)  qs_toggle_cnt <= #1 ratio;
  else                        qs_toggle_cnt <= #1 qs_toggle_cnt - |qs_toggle_cnt;
end

// clk_posedge
assign clk_posedge = (qs_toggle_cnt == 3'b001) | (ratio == 'd0);

// delayed signals
always @ (posedge qs_clk)
begin
  ack_d   <= #1 qs_ack;
  cs_d    <= #1 qs_cs;
  ratio_d <= #1 ratio;
end

// ratio changed
always @ (posedge qs_clk, posedge rst)
if (rst)    ratio_changed_d <= #1 1'b0;
else begin
  if (clk_posedge)         ratio_changed_d <= #1 1'b0;
  else if (ratio_changed)  ratio_changed_d <= #1 1'b1;
end

assign ratio_changed = ratio_changed_d || (ratio != ratio_d);

// data register
always @ (posedge qs_clk)
if (cs_d & ack_d)  dat_d <= #1 qs_dat_r;

always @ (posedge qs_clk, posedge rst)
if (rst)           dat_loc <= #1 1'b1;
else begin
  if (qs_ack)      dat_loc <= #1 1'b1;
  else if (ack_d)  dat_loc <= #1 1'b0;
end

// delay signals
always @ (posedge qs_clk, posedge rst)
if (rst)            ack_delay <= #1 1'b0;
else begin
  if (clk_posedge)  ack_delay <= #1 1'b0;
  else if (qs_ack)  ack_delay <= #1 1'b1;
end

always @ (posedge qm_clk, posedge rst)
if (rst)                             cycle_delay <= #1 1'b0;
else begin
  if (cycle_delay)                   cycle_delay <= #1 1'b0;
  else if (qm_cs & qm_ack & ~qm_we)  cycle_delay <= #1 1'b1;
  else                               cycle_delay <= #1 1'b0;
end


// outputs - input side
assign qm_dat_r = (dat_loc) ? qs_dat_r : dat_d; // !
assign qm_ack   = (qs_ack | ack_delay);

// outputs - output side
assign qs_we    = qm_we & ~(ack_delay);
assign qs_cs    = qm_cs & ~(ack_delay);
assign qs_sel   = qm_sel;
assign qs_adr   = qm_adr;
assign qs_dat_w = qm_dat_w;


endmodule

