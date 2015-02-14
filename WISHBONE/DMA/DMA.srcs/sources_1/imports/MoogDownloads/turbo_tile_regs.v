`include "common_defs.v"

module turbo_tile_regs
  #(
    parameter WB_DWIDTH  = 32,
    parameter WB_SWIDTH  = 4,
    parameter tile_x = 4'b0,
    parameter tile_y = 4'b0,
    parameter cpu_id = 8'hff
    )
   (
    input                  i_clk,
    input                  i_rst,

    input [31:0]           i_wb_adr,
    input [WB_SWIDTH-1:0]  i_wb_sel,
    input                  i_wb_we,
    output [WB_DWIDTH-1:0] o_wb_dat,
    input [WB_DWIDTH-1:0]  i_wb_dat,
    input                  i_wb_cyc,
    input                  i_wb_stb,
    output                 o_wb_ack,
    output                 o_wb_err
    );


   // Wishbone registers
   reg [31:0]              tile_coord  = {tile_y[3:0], tile_x[3:0]};
   reg [31:0]              dummy;

   // Wishbone interface
   reg [31:0]              wb_rdata32 = 'd0;
   wire                    wb_start_write;
   wire                    wb_start_read;
   reg                     wb_start_read_d1 = 'd0;
   wire [31:0]             wb_wdata32;

   // ======================================================
   // Wishbone Interface
   // ======================================================

   // Can't start a write while a read is completing. The ack for the read cycle
   // needs to be sent first
   assign wb_start_write = i_wb_stb && i_wb_we && !wb_start_read_d1;
   assign wb_start_read  = i_wb_stb && !i_wb_we && !o_wb_ack;

   always @( posedge i_clk or posedge i_rst) begin
      if(i_rst)
        wb_start_read_d1 <= 'd0;
      else
        wb_start_read_d1 <= wb_start_read;
   end


   assign o_wb_err = 1'd0;
   assign o_wb_ack = i_wb_stb && ( wb_start_write || wb_start_read_d1 );

   generate
      if (WB_DWIDTH == 128) 
        begin : wb128
           assign wb_wdata32   = i_wb_adr[3:2] == 2'd3 ? i_wb_dat[127:96] :
                                 i_wb_adr[3:2] == 2'd2 ? i_wb_dat[ 95:64] :
                                 i_wb_adr[3:2] == 2'd1 ? i_wb_dat[ 63:32] :
                                 i_wb_dat[ 31: 0] ;
           
           assign o_wb_dat    = {4{wb_rdata32}};
        end
      else
        begin : wb32
           assign wb_wdata32  = i_wb_dat;
           assign o_wb_dat    = wb_rdata32;
        end
   endgenerate


   // ========================================================
   // Register Writes
   // ========================================================
   always @( posedge i_clk or posedge i_rst ) begin
      if(i_rst) begin
         dummy <= 0;
      end
      else begin
         if ( wb_start_write )
           case ( i_wb_adr[11:0] )
             `TILEREG_DUMMY: dummy <= i_wb_dat;
           endcase
      end
   end

   // ========================================================
   // Register Reads
   // ========================================================
   always @( posedge i_clk or posedge i_rst ) begin
      if(i_rst) begin
         wb_rdata32 <= 'd0;
      end
      else begin
         if ( wb_start_read )
           case ( i_wb_adr[11:0] )
             
             `TILEREG_CPUID:  wb_rdata32 <= cpu_id;
             `TILEREG_TILE_X: wb_rdata32 <= tile_x;
             `TILEREG_TILE_Y: wb_rdata32 <= tile_y;
             `TILEREG_DUMMY:  wb_rdata32 <= dummy;
             
             default:         wb_rdata32 <= 32'h22334455;
             
           endcase
      end
   end

endmodule
