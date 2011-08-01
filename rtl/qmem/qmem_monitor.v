module qmem_monitor #(
  parameter QAW = 32,
  parameter QDW = 32,
  parameter QSW = QDW/8,
  parameter siz = 16,
  parameter ram_off = 'h0000_0000,
  parameter ram_end = 'hffff_ffff,
  parameter name    = "noname",
  parameter logfile = "noname.log",
  parameter debug   = 0
)(
  // system signals
  input  wire           clk,
  input  wire           rst,
  // qmem signals
  input  wire           cs,
  input  wire           we,
  input  wire [QAW-1:0] adr,
  input  wire [QSW-1:0] sel,
  input  wire [QDW-1:0] dat_w,
  input  wire [QDW-1:0] dat_r,
  input  wire           ack,
  input  wire           err,
  // monitor error condition
  output wire           error
);

integer fp;

integer cnt_error;

// data transfer
wire trn, hit, log;

// slave memory
reg  [QDW-1:0] mem [0:2**(siz-2)-1];

wire [QDW-1:0] dat;

// temp signals
reg           tmp_cs;
reg [QAW-1:0] tmp_adr;
reg [QSW-1:0] tmp_sel;
reg           tmp_we;
reg           tmp_trn;
reg           tmp_hit;

reg           tmp_rst;

// data transfer and cycle end
assign trn = cs & (ack | err);
assign hit = (adr >= ram_off) & (adr <= ram_end);
assign log = trn & hit;

// write to memory
always @(posedge clk)
begin
  if (trn & we & hit) begin
    if (sel [0])  mem [adr[QAW-1:2]-ram_off[QAW-1:2]] [ 7: 0] <= #1 dat_w [ 7: 0];
    if (sel [1])  mem [adr[QAW-1:2]-ram_off[QAW-1:2]] [15: 8] <= #1 dat_w [15: 8];
    if (sel [2])  mem [adr[QAW-1:2]-ram_off[QAW-1:2]] [23:16] <= #1 dat_w [23:16];
    if (sel [3])  mem [adr[QAW-1:2]-ram_off[QAW-1:2]] [31:24] <= #1 dat_w [31:24];
    $fwrite (fp, "W @ %08x (%1x) = %08x", adr, sel, dat_w);
  end
end

// read from memory for normal cycles
assign dat [ 7: 0] = (tmp_sel [0]) ? mem [tmp_adr[QAW-1:2]-ram_off[QAW-1:2]] [ 7: 0] : 8'hxx;
assign dat [15: 8] = (tmp_sel [1]) ? mem [tmp_adr[QAW-1:2]-ram_off[QAW-1:2]] [15: 8] : 8'hxx;
assign dat [23:16] = (tmp_sel [2]) ? mem [tmp_adr[QAW-1:2]-ram_off[QAW-1:2]] [23:16] : 8'hxx;
assign dat [31:24] = (tmp_sel [3]) ? mem [tmp_adr[QAW-1:2]-ram_off[QAW-1:2]] [31:24] : 8'hxx;

// checking for corrupted wishbone cycles
always @(posedge clk)
begin
  // storing the current transfer address and byte selects and data
  tmp_cs  <= #1 cs;
  tmp_adr <= #1 adr;
  tmp_sel <= #1 sel;
  tmp_we  <= #1 we;
  tmp_trn <= #1 trn;
  tmp_hit <= #1 hit;
end

assign error = err
             | tmp_trn & ~tmp_we & tmp_hit &
             ( (tmp_sel[3] & (dat_r[31:24] !== dat    [31:24]))
             | (tmp_sel[2] & (dat_r[23:16] !== dat    [23:16]))
             | (tmp_sel[1] & (dat_r[15:08] !== dat    [15:08]))
             | (tmp_sel[0] & (dat_r[07:00] !== dat    [07:00])) );

always @(posedge clk)
begin
  if (tmp_trn & ~tmp_we & tmp_hit)
     $fwrite (fp, "R @ %08x (%1x) = %08x", tmp_adr, tmp_sel, dat_r);
end

initial
begin
  cnt_error = 0;
end

always @(posedge clk)
begin
  if (error) begin
    cnt_error <= #1 cnt_error + 1;
    $display("ERROR: (%0s) n=%2d  @ %08x (%1x) = %08x, at time %t", name, cnt_error,  tmp_adr, tmp_sel, dat_r, $time);
  end
  tmp_rst <= #1 rst;
  if ((tmp_rst == 1'b1) & (rst == 1'b0)) begin
    $display("DEBUG: (%s) Reset at time %t", name, cnt_error, $time);
  end
  // display data transfers
  if (debug &     trn &      we &     hit)
    $display("DEBUG: (%s) Write %h to   bytes %h at address %h. Time is %t", name, dat_w,     sel,     adr, $time);
  if (debug & tmp_trn & ~tmp_we & tmp_hit)
    $display("DEBUG: (%s) Read  %h from bytes %h at address %h. Time is %t", name, dat_r, tmp_sel, tmp_adr, $time);
end

initial begin
  fp = $fopen (logfile, "w");
end

endmodule

