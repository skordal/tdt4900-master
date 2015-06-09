// For this Master Thesis: New signals are annotated with the comment //MASTER THESIS, and new code regions begin and end with similar annotations



`include "common_defs.v"

module turbo_amber_system
  #(
    parameter tile_x = 4'b0,
    parameter tile_y = 4'b0,
    parameter cpu_id = 8'hff
    )
   (
    input wire          i_clk,
    input wire          i_rst,

    input wire          i_irq,

    input wire          i_system_rdy,

    output reg [31:0]  o_wb_adr,
    output reg [15:0]  o_wb_sel,
    output reg         o_wb_we,
	
	input wire [127:0]  i_wb_dat,
    output wire         o_wb_cyc,
    output reg [127:0] o_wb_dat,
    
	
	output reg          o_wb_stb,
    input wire          i_wb_ack,
    input wire          i_wb_err,
    output wire         o_ld_excl

    );

   ////////////////////////////////////////////////////////////////////////////

   wire                 irq;
   wire                 firq;

   //MASTER THESIS: Every new signal has //MASTER THESIS as comment, to distinguish them from original signals 
   wire 	irq_regular;
   wire		irq_dma;

   reg [127:0]			wb_dat_r_MASTER_MODULE; //MASTER THESIS // Covers both DMA Master and CPU
   wire [127:0]         wb_dat_r_tileregs;
   wire [127:0]         wb_dat_r_timer;
   wire [127:0]         wb_dat_r_irq;
   wire [127:0]			wb_dat_r_sha256;	//MASTER THESIS
   wire [127:0]			wb_dat_r_dma_slave; //MASTER THESIS

   reg                  wb_ack_cpu;
   wire                 wb_ack_tileregs;
   wire                 wb_ack_timer;
   wire                 wb_ack_irq;
   wire					wb_ack_sha256;		//MASTER THESIS
   wire 				wb_ack_dma_slave;	//MASTER THESIS
   reg 					wb_ack_dma_master;	//MASTER THESIS
   
   

   reg                  wb_err_cpu;
   wire                 wb_err_tileregs;
   wire                 wb_err_timer;
   wire                 wb_err_irq;
   wire					wb_err_sha256;		//MASTER THESIS
   wire 				wb_err_dma_slave;	//MASTER THESIS
   reg 					wb_err_dma_master;	//MASTER THESIS

   wire                 wb_stb_cpu;
   reg                  wb_stb_tileregs;
   reg                  wb_stb_timer;
   reg                  wb_stb_irq;
   reg					wb_stb_sha256;		//MASTER THESIS
   reg					wb_stb_dma_slave;	//MASTER THESIS
   wire 				wb_stb_dma_master;	//MASTER THESIS

   wire [2:0]           irq_timers;
   wire [31:1]          int_sources;

   wire [31:0]          tile_base = `TILE_BASE;
   wire [15:0]          tilereg = `TILE_REGS;
   wire [15:0]          timer_mod = `TIMER;
   wire [15:0]          int_ctrl = `INT_CTRL;
   wire [15:0]          sha256_mod = `ACC;		//MASTER THESIS
   wire [15:0]			dma_slave = `DMA_SLAVE; //MASTER THESIS

    //MASTER THESIS
    // New MASTER SIGNALS, set for CPU and set for DMA MASTER. 
    // linked to original master signals previously used by CPU only, but chosen by arbiter
   
    // Input to arbiter from CPU
   
    wire [31:0] 	cpu_o_wb_adr;
    wire [15:0]		cpu_o_wb_sel;
    wire 			cpu_o_wb_we;
    wire [127:0]	cpu_o_wb_dat;
    wire 			cpu_o_wb_cyc;
   
   
    // Input to arbiter from DMA Master
   
    wire [31:0] 	dma_master_o_wb_adr;
    wire [15:0]		dma_master_o_wb_sel;
    wire 			dma_master_o_wb_we;
    wire [127:0]	dma_master_o_wb_dat;
    wire 			dma_master_o_wb_cyc;


    // NOTE: MASTER_MODULE is used as common signal for both CPU and DMA MASTER, for ack, err and stb.
    // cpu-signals are previously used throughout the process code at the end of this file
    // Now that both cpu and DMA Master compete for input signals, a common signal with MASTER_MODULE in title 
    // is set first based on which input is selected, then input is passed on to EITHER cpu OR dma_master afterwards
    reg 	wb_ack_MASTER_MODULE; 
    reg 	wb_err_MASTER_MODULE;
    reg 	wb_stb_MASTER_MODULE;
	
	//Wires from current arbiter
	
	wire [1:0] 	grant;
	wire		grant0;
	wire		grant1;

	//Empty signals for two unused input ports for Wishbone Arbiter, to ensure correct behaviour
	wire empty;
	

   ////////////////////////////////////////////////////////////////////////////

    ta_core u_amber
	  (
       .i_clk          (i_clk),
       .i_rst          (i_rst),
      
       .i_irq          (irq),
       .i_firq         (firq),

       .i_system_rdy   (i_system_rdy),
      
       .i_wb_dat 		(wb_dat_r_MASTER_MODULE),
       .o_wb_stb       (wb_stb_cpu),
       .i_wb_ack       (wb_ack_cpu),
       .i_wb_err       (wb_err_cpu),
      
 	  //MASTER THESIS: CPU signals into arbiter
       .o_wb_adr       (cpu_o_wb_adr),
       .o_wb_sel       (cpu_o_wb_sel),
       .o_wb_we        (cpu_o_wb_we),
       .o_wb_dat       (cpu_o_wb_dat),
       .o_wb_cyc       (cpu_o_wb_cyc),
	  
 	  .o_ld_excl      (o_ld_excl)
	  
       );
	
	DMA_WISHBONE_Toplevel //
	 #()
	u_dma_module
	  (
		  //Common inputs/outputs
		  .clk_i (i_clk),
		  .rst_i (i_rst),
		  
		  //DMA MASTER Inputs
		  .ack_i (wb_ack_dma_master),
		  .err_i (wb_err_dma_master),
		  //.rty_i (),
		  //.stall_i (),
		  .M_dat_i(wb_dat_r_MASTER_MODULE),
		  
		  //DMA MASTER Outputs
		  .M_dat_o (dma_master_o_wb_dat),
		  //.M_tgd_o (),
		  .adr_o (dma_master_o_wb_adr),
		  .cyc_o (dma_master_o_wb_cyc),
		  //.lock_o (),
		  .sel_o (dma_master_o_wb_sel),
		  .stb_o(wb_stb_dma_master),
		  //.tga_o (),
		  //.tgc_o (),
		  .we_o (dma_master_o_wb_we),
		  
		  //DMA SLAVE Inputs
		  .adr_i (o_wb_adr),
		  .cyc_i (o_wb_cyc),
		  //.lock_i (),
		  .sel_i (o_wb_sel),
		  .stb_i (wb_stb_dma_slave),
		  //.tga_i (),
		  //.tgc_i (),
		  .we_i (o_wb_we),
		  .S_dat_i(o_wb_dat),
		  
		  //DMA SLAVE Outputs
		  .S_dat_o (wb_dat_r_dma_slave),
		  //.S_tgd_o (),
		  .ack_o (wb_ack_dma_slave),
		  .err_o (wb_err_dma_slave),
		  //.rty_o (),
		  //.stall_o (),
		  
		  .interrupt (irq_dma)
		  
		  );


	wb_public_arbiter 
		#()
	u_arbiter 
	    (
	            .CLK(i_clk),
	            .RST(i_rst),
				
				.COMCYC(o_wb_cyc),     //out std_logic;
	            .CYC3(empty),       //in  std_logic;
	            .CYC2(empty),       //in  std_logic;
	            .CYC1(dma_master_o_wb_cyc),       //in  std_logic;
	            .CYC0(cpu_o_wb_cyc),       //in  std_logic;
	            .GNT(grant),        //out std_logic_vector( 1 downto 0 );
	            //.GNT3(),       //out std_logic;
	            //.GNT2(),       //out std_logic;
	            .GNT1(grant1),       //out std_logic;
	            .GNT0(grant0)       //out std_logic;
		);

    turbo_amber_sha256_accelerator u_sha256_accelerator
      (
       .i_clk (i_clk),
       .i_rst (i_rst),

       .i_wb_addr (o_wb_adr),
       .i_wb_sel (o_wb_sel),
       .i_wb_we (o_wb_we),
       .o_wb_dat (wb_dat_r_sha256),
       .i_wb_dat (o_wb_dat),
       .i_wb_cyc (o_wb_cyc),
       .i_wb_stb (wb_stb_sha256),
       .o_wb_ack (wb_ack_sha256),
       .o_wb_err (wb_err_sha256),

       .o_irq (irq_sha256)
      );


// END MASTER THESIS
 
 
   turbo_tile_regs
     #(
       .WB_DWIDTH (128),
       .WB_SWIDTH (16),
       .tile_x (tile_x),
       .tile_y (tile_y),
       .cpu_id (cpu_id)
       )
   u_turbo_tile_regs
     (
      .i_clk (i_clk),
      .i_rst (i_rst),

      .i_wb_adr (o_wb_adr),
      .i_wb_sel (o_wb_sel),
      .i_wb_we (o_wb_we),
      .o_wb_dat (wb_dat_r_tileregs),
      .i_wb_dat (o_wb_dat),
      .i_wb_cyc (o_wb_cyc),
      .i_wb_stb (wb_stb_tileregs),
      .o_wb_ack (wb_ack_tileregs),
      .o_wb_err (wb_err_tileregs)
      );

   timer_module 
     #(
       .WB_DWIDTH (128),
       .WB_SWIDTH (16)
       )
   u_timer
     (
      .i_clk (i_clk),
      .i_rst (i_rst),

      .i_wb_adr (o_wb_adr),
      .i_wb_sel (o_wb_sel),
      .i_wb_we (o_wb_we),
      .o_wb_dat (wb_dat_r_timer),
      .i_wb_dat (o_wb_dat),
      .i_wb_cyc (o_wb_cyc),
      .i_wb_stb (wb_stb_timer),
      .o_wb_ack (wb_ack_timer),
      .o_wb_err (wb_err_timer),
      .o_timer_int (irq_timers)
      );

   interrupt_controller  
     #(
       .WB_DWIDTH (128),
       .WB_SWIDTH (16)
       )
   u_irq_ctrl
     (
      .i_clk (i_clk),
      .i_rst (i_rst),

      .i_wb_adr (o_wb_adr),
      .i_wb_sel (o_wb_sel),
      .i_wb_we (o_wb_we),
      .o_wb_dat (wb_dat_r_irq),
      .i_wb_dat (o_wb_dat),
      .i_wb_cyc (o_wb_cyc),
      .i_wb_stb (wb_stb_irq),
      .o_wb_ack (wb_ack_irq),
      .o_wb_err (wb_err_irq),
      
      .o_irq (irq),
      .o_firq (firq),
      
      .i_int_sources (int_sources)
      );

   ////////////////////////////////////////////////////////////////////////////
	
	assign empty = 0;
	assign int_sources = {25'b0, irq_dma, irq_sha256, irq_timers, i_irq};

   always @* begin
   
	  // default is router
      wb_dat_r_MASTER_MODULE = i_wb_dat;
      wb_ack_MASTER_MODULE = i_wb_ack;
      wb_err_MASTER_MODULE = i_wb_err;
      wb_stb_tileregs = 0;
      wb_stb_timer = 0;
      wb_stb_irq = 0;
	  wb_stb_sha256 = 0;	//MASTER THESIS
	  wb_stb_dma_slave = 0; //MASTER THESIS

	  //MASTER THESIS: Select Output from correct Master Module
	  
	  if (o_wb_cyc == 1) begin
	  
	  		if(grant == 01) begin //DMA Master buss request acknowledged by arbiter
	  			// Select outputs:
			
				o_wb_adr = dma_master_o_wb_adr;
				o_wb_sel = dma_master_o_wb_sel;
				o_wb_we = dma_master_o_wb_we;
				o_wb_dat = dma_master_o_wb_dat;
				
				o_wb_stb = wb_stb_dma_master;
				wb_stb_MASTER_MODULE = wb_stb_dma_master;
			end
			else // CPU as default
	  		begin
				o_wb_adr = cpu_o_wb_adr;
				o_wb_sel = cpu_o_wb_sel;
				o_wb_we = cpu_o_wb_we;
				o_wb_dat = cpu_o_wb_dat;
				
				o_wb_stb = wb_stb_cpu;
				wb_stb_MASTER_MODULE = wb_stb_cpu;
			end
			end
		else 
		begin //stb signals are not allowed, according to Wishbone manual, to be set high before cyc is high. If cyc is low, stb must be low.
			o_wb_stb = 0;
			wb_stb_MASTER_MODULE = 0;
		end
		

      // override default for local wishbone addresses
      if(o_wb_adr[31:16] == tile_base[31:16]) begin
         case(o_wb_adr[15:12])
           tilereg[15:12]: begin
              wb_dat_r_MASTER_MODULE = wb_dat_r_tileregs;
			  wb_ack_MASTER_MODULE = wb_ack_tileregs;
			  wb_err_MASTER_MODULE = wb_err_tileregs;
              o_wb_stb = 0;
			  wb_stb_tileregs = wb_stb_MASTER_MODULE; 
           end

           timer_mod[15:12]: begin
			  wb_dat_r_MASTER_MODULE = wb_dat_r_timer;
              wb_ack_MASTER_MODULE = wb_ack_timer;
			  wb_err_MASTER_MODULE = wb_err_timer;
              o_wb_stb = 0;
			  wb_stb_timer = wb_stb_MASTER_MODULE; 
           end

           int_ctrl[15:12]: begin
			  wb_dat_r_MASTER_MODULE = wb_dat_r_irq;
			  wb_ack_MASTER_MODULE = wb_ack_irq;
              wb_err_MASTER_MODULE = wb_err_irq;
			  o_wb_stb = 0;
			  wb_stb_irq = wb_stb_MASTER_MODULE;
           end
		   
		   // MASTER THESIS block:
		   
		   //SHA256-module
		   sha256_mod[15:12]: begin
		      wb_dat_r_MASTER_MODULE = wb_dat_r_sha256;
		      wb_ack_MASTER_MODULE = wb_ack_sha256;
		      wb_err_MASTER_MODULE = wb_err_sha256;
		      o_wb_stb = 0;
		      wb_stb_sha256 = wb_stb_MASTER_MODULE;
		   end
		   
		   //DMA Slave
		   dma_slave[15:12]: begin
				wb_dat_r_MASTER_MODULE = wb_dat_r_dma_slave;
				wb_ack_MASTER_MODULE = wb_ack_dma_slave;
				wb_err_MASTER_MODULE = wb_err_dma_slave;
            	o_wb_stb = 0;
				wb_stb_dma_slave = wb_stb_MASTER_MODULE;
		   end
         endcase
      end
	  
	  //  MASTER THESIS: Select correct Master Module to pass input from MASTER_MODULE-signals
	  //  Needed to pass ack- and err-signals to correct module (Input Data is passed to both, but ack/err should control that correct module is used)
  	  if (grant0 == 0 && grant1 == 1) begin //DMA Master requests buss, while CPU don't (CPU has first priority)
  	  		//Select inputs
  			wb_ack_dma_master = wb_ack_MASTER_MODULE;
  			wb_err_dma_master = wb_err_MASTER_MODULE;
		end
  		else // No DMA Master request, OR CPU wants priority (or not) 
		begin
		
  	  		// Select inputs
  			wb_ack_dma_master = 0;
  			wb_err_dma_master = 0;
  	  end
	  
	  //  MASTER THESIS: Select correct Master Module to pass input from MASTER_MODULE-signals
	  //  Needed to pass ack- and err-signals to correct module (Input Data is passed to both, but ack/err should control that correct module is used)
  	  if (grant0 == 1 && grant1 == 0) begin //DMA Master requests buss, while CPU don't (CPU has first priority)
  	  		//Select inputs
  			wb_ack_cpu = wb_ack_MASTER_MODULE;
  			wb_err_cpu = wb_err_MASTER_MODULE;
		end
  		else // No DMA Master request, OR CPU wants priority (or not) 
		begin
  	  		// Select inputs
  			wb_ack_cpu = 0;
  			wb_err_cpu = 0;
  	  end
	  
	  
        
   end

endmodule
