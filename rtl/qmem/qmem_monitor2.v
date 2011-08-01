/* qmem_monitor.v */

module qmem_monitor #(
  parameter QAW = 32,
  parameter QDW = 32,
  parameter QSW = QDW/8,
  parameter name    = "qmem monitor",
  parameter logfile = "qmem_monitor.log",
  parameter debug   = 0
)(
  // system signals
  input  wire           clk,
  input  wire           rst,
  // qmem signals
  input  wire           cs,
  input  wire           we,
  input  wire [QSW-1:0] sel,
  input  wire [QAW-1:0] adr,
  input  wire [QDW-1:0] dat_w,
  input  wire [QDW-1:0] dat_r,
  input  wire           ack,
  input  wire           err,
  // monitor error condition
  output wire           error
);


// log file pointer
integer           fp;

// write / read counters
integer           r_cnt, w_cnt;

// signals registers
reg           cs_r;
reg           we_r;
reg [QSW-1:0] sel_r;
reg [QAW-1:0] adr_r;
reg [QDW-1:0] dat_w_r;
reg [QDW-1:0] dat_r_r;
reg           err_r;
reg           trn_r;

// transfer
wire              trn;

// log start / stop
reg               log = 0;


// register all signals
always @ (posedge clk or posedge rst)
begin
  if (rst) begin
    cs_r    <= #1 1'b0;
    we_r    <= #1 1'b0;
    sel_r   <= #1 {QSW{1'b0}};
    adr_r   <= #1 {QAW{1'b0}};
    dat_w_r <= #1 {QDW{1'b0}};
    dat_r_r <= #1 {QDW{1'b0}};
    err_r   <= #1 1'b0;
    trn_r  <=  #1 1'b0;
  end
  else begin
    cs_r    <= #1 cs;
    we_r    <= #1 we;
    sel_r   <= #1 sel;
    adr_r   <= #1 adr;
    dat_w_r <= #1 dat_w;
    dat_r_r <= #1 dat_r;
    err_r   <= #1 err;
    trn_r   <= #1 trn;
  end
end

// transfer
assign trn = cs && (ack || err);

// log master write access at ack
always @ (posedge clk)
begin
  if (!rst && trn && we && (log == 1)) begin
    if (debug == 1) $display("QMEM MONITOR (%s) : write :\taddress: 0x%08x\tdata: 0x%08x\tsel: %01x\ttime: %t", name, adr, dat_w, sel, $time);
    $fwrite (fp, "WRITE:\t0x%08x\t%01x\t0x%08x\n", adr, sel, dat_w);
    w_cnt = w_cnt + 1;
  end
end

// log master read access at ack+1
always @ (posedge clk)
begin
  if (!rst && trn_r && !we_r && (log==1)) begin
    if (debug == 1) $display("QMEM MONITOR (%s) : read :\taddress: 0x%08x\tdata: 0x%08x\tsel: %01x\ttime: %t", name, adr_r, dat_r, sel_r, $time);
    $fwrite (fp, "READ: \t0x%08x\t%01x\t0x%08x\n", adr_r, sel_r, dat_r);
    r_cnt = r_cnt + 1;
  end
end



// tasks

// start log
task start;
begin
  r_cnt = 0;
  w_cnt = 0;
  fp = $fopen (logfile, "w");
  $fwrite (fp, "QMEM MONITOR %s\nLog started @ %t\n\n", name, $time);
  $fwrite (fp, "R/W\tADDRESS\t\tSEL\tDATA\n");
  log = 1;
end
endtask

// stop log
task stop;
begin
  //@(posedge clk);
  log = 0;
  $fwrite(fp, "QMEM MONITOR\nLog stopped @ %t\n", $time);
  $fwrite(fp, "Write cycles: %d\n", w_cnt);
  $fwrite(fp, "Read  cycles: %d\n", r_cnt);
  $fwrite(fp, "All   cycles: %d\n", w_cnt + r_cnt);
  $fclose(fp);
end
endtask



endmodule

