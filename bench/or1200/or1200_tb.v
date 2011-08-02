/**************************************/
/* or1200_tb.v                        */
/*                                    */
/* or1200 testbench                   */
/*                                    */
/* 2011, rok.krajnc@gmail.com         */
/**************************************/


`default_nettype none
`timescale 1ns/10ps


module or1200_tb();


////////////////////////////////////////
// parameters                         //
////////////////////////////////////////

parameter QAW = 32;     // qmem adr width
parameter QDW = 32;     // qmem dat width
parameter QSW = QDW/8;  // qmem sel width
parameter AD  = 10;     // allowed delay for qmem slave
parameter MS  = 1<<12-1;// slave memory size
parameter TFD = 0;      // slave fixed delay
parameter TRD = 0;      // slave random delay


////////////////////////////////////////
// internal signals                   //
////////////////////////////////////////

// system signals
reg            clk;
reg            rst;

// slave signals
wire           cs;
wire           we;
wire [QSW-1:0] sel;
wire [QAW-1:0] adr;
wire [QDW-1:0] dat_w;
wire [QDW-1:0] dat_r;
wire           ack;
wire           err;

// cpu instruction bus
wire           icpu_cs;
wire           icpu_we;
wire [QSW-1:0] icpu_sel;
wire [QAW-1:0] icpu_adr;
wire [QDW-1:0] icpu_dat_w;
wire [QDW-1:0] icpu_dat_r;
wire           icpu_ack;
wire           icpu_err;

// cpu data bus
wire           dcpu_cs;
wire           dcpu_we;
wire [QSW-1:0] dcpu_sel;
wire [QAW-1:0] dcpu_adr;
wire [QDW-1:0] dcpu_dat_w;
wire [QDW-1:0] dcpu_dat_r;
wire           dcpu_ack;
wire           dcpu_err;

// arbiter master select
wire [  2-1:0] ms;


////////////////////////////////////////
// bench                              //
////////////////////////////////////////

// clock & reset
initial begin
  clk = 1;
  forever #10 clk = ~clk;
end

initial begin
  rst = 1;
  #101;
  rst = 0;
end

// dump signals
initial begin
  $dumpfile("../out/wav/or1200_tb_waves.fst");
  $dumpvars(0, or1200_tb);
end

// bench
initial begin
  $display("* BENCH : Starting ...");

  $display("* BENCH : Initializing memory ...");
  ram.fill_adr;

  $display("* BENCH : Loading firmware ...");
  ram.load_hex("../out/hex/fw.hex");

  #1;
  wait(rst);
  #1;

  fork

  begin : watchdog_block
    repeat (5000) @ (posedge clk);
    $display("* BENCH : ERROR : timeout reached!");
    disable run_block;
    $finish(1);
  end

  begin : run_block
    wait ( (dcpu_adr == 32'h0) && (dcpu_we == 1'b1) && (dcpu_dat_w == 32'hdeadbeef) ); // wait for cpu to signal end
    disable watchdog_block;
    repeat (20) @ (posedge clk);
    $display("* BENCH : SUCCESS : finished!");
  end

  join

  $display("* BENCH : Dumping memory contents ...");
  ram.dump_hex("../out/hex/ram.hex");

  $display("* BENCH : Done.");
  $finish;

end


////////////////////////////////////////
// module instantiations              //
////////////////////////////////////////

// or1200 cpu
or1200_top or1200 (
  // system
  .clk_i                  (clk),
  .rst_i                  (rst),
  .clmode_i               (2'b00),
  .pic_ints_i             (4'b0),
  // Instruction wishbone
  .iwb_clk_i              (1'b0),
  .iwb_rst_i              (1'b1),
  .iwb_ack_i              (1'b0),
  .iwb_err_i              (1'b0),
  .iwb_rty_i              (1'b0),
  .iwb_dat_i              (32'h0),
  .iwb_cyc_o              (),
  .iwb_adr_o              (),
  .iwb_stb_o              (),
  .iwb_we_o               (),
  .iwb_sel_o              (),
  .iwb_dat_o              (),
//  .iwb_cab_o              (),
  .iwb_cti_o              (),
  .iwb_bte_o              (),
  // Data wishbone
  .dwb_clk_i              (1'b0),
  .dwb_rst_i              (1'b1),
  .dwb_ack_i              (1'b0),
  .dwb_err_i              (1'b0),
  .dwb_rty_i              (1'b0),
  .dwb_dat_i              (32'h0),
  .dwb_cyc_o              (),
  .dwb_adr_o              (),
  .dwb_stb_o              (),
  .dwb_we_o               (),
  .dwb_sel_o              (),
  .dwb_dat_o              (),
//  .dwb_cab_o              (),
  .dwb_cti_o              (),
  .dwb_bte_o              (),
  // Debug interface
  .dbg_stall_i            (1'b0),
  .dbg_ewt_i              (1'b0),
  .dbg_lss_o              (),
  .dbg_is_o               (),
  .dbg_wp_o               (),
  .dbg_bp_o               (),
  .dbg_stb_i              (1'b0),
  .dbg_we_i               (1'b0),
  .dbg_adr_i              (32'h0),
  .dbg_dat_i              (32'h0),
  .dbg_dat_o              (),
  .dbg_ack_o              (),
  // QMEM interface
  .dqmem_cs_o             (dcpu_cs),
  .dqmem_we_o             (dcpu_we),
  .dqmem_sel_o            (dcpu_sel),
  .dqmem_adr_o            (dcpu_adr),
  .dqmem_dat_o            (dcpu_dat_w),
  .dqmem_dat_i            (dcpu_dat_r),
  .dqmem_ack_i            (dcpu_ack),
  .dqmem_err_i            (dcpu_err),
  .iqmem_cs_o             (icpu_cs),
  .iqmem_we_o             (icpu_we),
  .iqmem_sel_o            (icpu_sel),
  .iqmem_adr_o            (icpu_adr),
  .iqmem_dat_o            (icpu_dat_w),
  .iqmem_dat_i            (icpu_dat_r),
  .iqmem_ack_i            (icpu_ack),
  .iqmem_err_i            (icpu_err),
  // Power management
  .pm_cpustall_i          (1'b0),
  .pm_clksd_o             (),
  .pm_dc_gate_o           (),
  .pm_ic_gate_o           (),
  .pm_dmmu_gate_o         (),
  .pm_immu_gate_o         (),
  .pm_tt_gate_o           (),
  .pm_cpu_gate_o          (),
  .pm_wakeup_o            (),
  .pm_lvolt_o             ()
);


// arbiter
qmem_arbiter #(
  .QAW    (QAW),
  .QDW    (QDW),
  .QSW    (QSW),
  .MN     (2)
) ram_arbiter (
  // system
  .clk      (clk),
  .rst      (rst),
  // slave port for requests from masters
  .qm_cs    ({icpu_cs   , dcpu_cs   }),
  .qm_we    ({icpu_we   , dcpu_we   }),
  .qm_sel   ({icpu_sel  , dcpu_sel  }),
  .qm_adr   ({icpu_adr  , dcpu_adr  }),
  .qm_dat_w ({icpu_dat_w, dcpu_dat_w}),
  .qm_dat_r ({icpu_dat_r, dcpu_dat_r}),
  .qm_ack   ({icpu_ack  , dcpu_ack  }),
  .qm_err   ({icpu_err  , dcpu_err  }),
  // master port for requests to a slave
  .qs_cs    (cs),
  .qs_we    (we),
  .qs_sel   (sel),
  .qs_adr   (adr),
  .qs_dat_w (dat_w),
  .qs_dat_r (dat_r),
  .qs_ack   (ack),
  .qs_err   (err),
  // one hot master (bit MN is always 1'b0)
  .ms       (ms)
);

// qmem slave
qmem_slave #(
  .QAW         (QAW),
  .QDW         (QDW),
  .QSW         (QSW),
  .MS          (MS),
  .T_FIX_DELAY (TFD),
  .T_RND_DELAY (TRD)
) ram (
  .clk        (clk),
  .rst        (rst),
  .cs         (cs),
  .we         (we),
  .sel        (sel),
  .adr        (adr),
  .dat_w      (dat_w),
  .dat_r      (dat_r),
  .ack        (ack),
  .err        (err)
);


endmodule

