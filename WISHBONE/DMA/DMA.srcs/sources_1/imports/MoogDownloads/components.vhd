library IEEE;
use IEEE.STD_LOGIC_1164.all;

use work.types.all;

package Components is

  -----------------------------------------------------------------------------
  -- Tiles
  -----------------------------------------------------------------------------

  component zbtram_tile
    generic (
      coord : tile_coord;
      apb_i : integer;
      apb_j : integer;
      zbt_i : integer;
      zbt_j : integer;
      bram0_i : integer;
      bram0_j : integer;
      bram1_i : integer;
      bram1_j : integer;
      bram2_i : integer;
      bram2_j : integer;
      bram3_i : integer;
      bram3_j : integer;
      bram4_i : integer;
      bram4_j : integer;
      bram5_i : integer;
      bram5_j : integer;
      bram6_i : integer;
      bram6_j : integer;
      bram7_i : integer;
      bram7_j : integer
      );
    port (
      clk              : in    std_logic;
      reset_ic         : in    std_logic;
      rx_req_vector    : in    direction_boolean_vector;
      rx_packet_vector : in    packet_vector;
      rx_ack_vector    : out   direction_boolean_vector;
      tx_req_vector    : out   direction_boolean_vector;
      tx_packet_vector : out   packet_vector;
      tx_ack_vector    : in    direction_boolean_vector;
      RAM_A_SnWBYTE    : out   std_logic_vector(7 downto 0);
      RAM_A_SnOE       : out   std_logic;
      RAM_A_SnCE       : out   std_logic;
      RAM_A_SADVnLD    : out   std_logic;
      RAM_A_SnWR       : out   std_logic;
      RAM_A_SnCKE      : out   std_logic;
      RAM_A_SMODE      : out   std_logic;
      RAM_A_SA         : out   std_logic_vector(23 downto 3);
      RAM_A_SD         : inout std_logic_vector(63 downto 0);
      RAM_B_SnWBYTE    : out   std_logic_vector(7 downto 0);
      RAM_B_SnOE       : out   std_logic;
      RAM_B_SnCE       : out   std_logic;
      RAM_B_SADVnLD    : out   std_logic;
      RAM_B_SnWR       : out   std_logic;
      RAM_B_SnCKE      : out   std_logic;
      RAM_B_SMODE      : out   std_logic;
      RAM_B_SA         : out   std_logic_vector(23 downto 3);
      RAM_B_SD         : inout std_logic_vector(63 downto 0));
  end component;

  component ddr_tile
    generic (
      coord : tile_coord;
      apb_i : integer;
      apb_j : integer;
      zbt_i : integer;
      zbt_j : integer;
      bram0_i : integer;
      bram0_j : integer;
      bram1_i : integer;
      bram1_j : integer;
      bram2_i : integer;
      bram2_j : integer;
      bram3_i : integer;
      bram3_j : integer;
      bram4_i : integer;
      bram4_j : integer;
      bram5_i : integer;
      bram5_j : integer;
      bram6_i : integer;
      bram6_j : integer;
      bram7_i : integer;
      bram7_j : integer
      );
    port (
      clk              : in    std_logic;
      reset_ic         : in    std_logic;
      rx_req_vector    : in    direction_boolean_vector;
      rx_packet_vector : in    packet_vector;
      rx_ack_vector    : out   direction_boolean_vector;
      tx_req_vector    : out   direction_boolean_vector;
      tx_packet_vector : out   packet_vector;
      tx_ack_vector    : in    direction_boolean_vector;
      DDR3_A              : out   std_logic_vector(15 downto 0);
      DDR3_BA             : out   std_logic_vector(2 downto 0);
      DDR3_CK_P           : out   std_logic;
      DDR3_CK_N           : out   std_logic;
      DDR3_CKE            : out   std_logic;
      DDR3_DM             : out   std_logic_vector(7 downto 0);
      DDR3_DQ             : inout std_logic_vector(63 downto 0);
      DDR3_DQS_P          : inout std_logic_vector(7 downto 0);
      DDR3_DQS_N          : inout std_logic_vector(7 downto 0);
      DDR3_nCAS           : out   std_logic;
      DDR3_nEVENT         : in    std_logic;
      DDR3_nRAS           : out   std_logic;
      DDR3_nRESET         : out   std_logic;
      DDR3_nS             : inout std_logic_vector(1 downto 0);
      DDR3_nWE            : out   std_logic;
      DDR3_ODT            : out   std_logic;
      DDR3_SDA            : inout std_logic;
      DDR3_REFCLK_P       : in    std_logic;
      DDR3_REFCLK_N       : in    std_logic;
      init_calib_complete : out   std_logic;
      MEM_CLK             : in    std_logic;
      ddr3_clk            : out   std_logic;
      ddr3_clk_sync_rst   : out   std_logic;
      ddr3_aresetn        : in    std_logic
      );
  end component;

  component amber_tile
    generic (
      coord : tile_coord;
      apb_i : integer;
      apb_j : integer;
      zbt_i : integer;
      zbt_j : integer;
      bram0_i : integer;
      bram0_j : integer;
      bram1_i : integer;
      bram1_j : integer;
      bram2_i : integer;
      bram2_j : integer;
      bram3_i : integer;
      bram3_j : integer;
      bram4_i : integer;
      bram4_j : integer;
      bram5_i : integer;
      bram5_j : integer;
      bram6_i : integer;
      bram6_j : integer;
      bram7_i : integer;
      bram7_j : integer;
      cpu_id : integer
      );
    port (
      clk              : in  std_logic;
      reset_cpu        : in  std_logic;
      reset_ic         : in  std_logic;
      irq              : in  std_logic;
      system_rdy       : in std_logic;
      rx_req_vector    : in  direction_boolean_vector;
      rx_packet_vector : in  packet_vector;
      rx_ack_vector    : out direction_boolean_vector;
      tx_req_vector    : out direction_boolean_vector;
      tx_packet_vector : out packet_vector;
      tx_ack_vector    : in  direction_boolean_vector);
  end component;

  component turbo_amber
    generic (
      coord : tile_coord;
      apb_i : integer;
      apb_j : integer;
      zbt_i : integer;
      zbt_j : integer;
      bram0_i : integer;
      bram0_j : integer;
      bram1_i : integer;
      bram1_j : integer;
      bram2_i : integer;
      bram2_j : integer;
      bram3_i : integer;
      bram3_j : integer;
      bram4_i : integer;
      bram4_j : integer;
      bram5_i : integer;
      bram5_j : integer;
      bram6_i : integer;
      bram6_j : integer;
      bram7_i : integer;
      bram7_j : integer;
      cpu_id : integer
      );
    port (
      clk              : in  std_logic;
      reset_cpu        : in  std_logic;
      reset_ic         : in  std_logic;
      irq              : in  std_logic;
      system_rdy       : in std_logic;
      rx_req_vector    : in  direction_boolean_vector;
      rx_packet_vector : in  packet_vector;
      rx_ack_vector    : out direction_boolean_vector;
      tx_req_vector    : out direction_boolean_vector;
      tx_packet_vector : out packet_vector;
      tx_ack_vector    : in  direction_boolean_vector);
  end component;


  component apb_tile
    generic (
      coord : tile_coord;
      apb_i : integer;
      apb_j : integer;
      zbt_i : integer;
      zbt_j : integer;
      bram0_i : integer;
      bram0_j : integer;
      bram1_i : integer;
      bram1_j : integer;
      bram2_i : integer;
      bram2_j : integer;
      bram3_i : integer;
      bram3_j : integer;
      bram4_i : integer;
      bram4_j : integer;
      bram5_i : integer;
      bram5_j : integer;
      bram6_i : integer;
      bram6_j : integer;
      bram7_i : integer;
      bram7_j : integer;
      cpu_count : integer := 0
      );
    port (
      clk              : in  std_logic;
      reset_cpu        : out std_logic;
      reset_ic         : out std_logic;
      shmac_irq        : out std_logic;
      host_irq         : out std_logic;
      system_rdy : out std_logic;
      rx_req_vector    : in  direction_boolean_vector;
      rx_packet_vector : in  packet_vector;
      rx_ack_vector    : out direction_boolean_vector;
      tx_req_vector    : out direction_boolean_vector;
      tx_packet_vector : out packet_vector;
      tx_ack_vector    : in  direction_boolean_vector;
      nRESET           : in  std_logic;
      PCLK             : in  std_logic;
      PADDR            : in  std_logic_vector(7 downto 0);
      PWRITE           : in  std_logic;
      PSEL             : in  std_logic;
      PENABLE          : in  std_logic;
      PWDATA           : in  std_logic_vector(31 downto 0);
      PRDATA           : out std_logic_vector(31 downto 0);
      PREADY           : out std_logic;
      PSLVERR          : out std_logic);
  end component;

  component ram_tile is
    generic (
      coord : tile_coord := (i => 0, j => 0);
      apb_i : integer;
      apb_j : integer;
      zbt_i : integer;
      zbt_j : integer;
      bram0_i : integer;
      bram0_j : integer;
      bram1_i : integer;
      bram1_j : integer;
      bram2_i : integer;
      bram2_j : integer;
      bram3_i : integer;
      bram3_j : integer;
      bram4_i : integer;
      bram4_j : integer;
      bram5_i : integer;
      bram5_j : integer;
      bram6_i : integer;
      bram6_j : integer;
      bram7_i : integer;
      bram7_j : integer
      );
    port (
      clk   : in  std_logic;

      reset_ic : in  std_logic;
      
      rx_req_vector    : in  direction_boolean_vector;
      rx_packet_vector : in  packet_vector;
      rx_ack_vector    : out direction_boolean_vector;
      
      tx_req_vector    : out direction_boolean_vector;
      tx_packet_vector : out packet_vector;
      tx_ack_vector    : in  direction_boolean_vector
      );
  end component;

  component dummy_tile
    generic (
      coord   : tile_coord;
      apb_i   : integer;
      apb_j   : integer;
      zbt_i   : integer;
      zbt_j   : integer;
      bram0_i : integer;
      bram0_j : integer;
      bram1_i : integer;
      bram1_j : integer;
      bram2_i : integer;
      bram2_j : integer;
      bram3_i : integer;
      bram3_j : integer;
      bram4_i : integer;
      bram4_j : integer;
      bram5_i : integer;
      bram5_j : integer;
      bram6_i : integer;
      bram6_j : integer;
      bram7_i : integer;
      bram7_j : integer);
    port (
      clk              : in  std_logic;
      reset_ic         : in  std_logic;
      rx_req_vector    : in  direction_boolean_vector;
      rx_packet_vector : in  packet_vector;
      rx_ack_vector    : out direction_boolean_vector;
      tx_req_vector    : out direction_boolean_vector;
      tx_packet_vector : out packet_vector;
      tx_ack_vector    : in  direction_boolean_vector);
  end component;

  -----------------------------------------------------------------------------
  -- Wrappers
  -----------------------------------------------------------------------------
  
  component apb_wrapper
    generic (
      cpu_count : integer := 0
      );
    port (
      clk       : in  std_logic;
      reset_cpu : out std_logic;
      reset_ic  : out std_logic;

      shmac_irqs : out std_logic_vector(0 downto 0);
      host_irq  : out std_logic;

      system_rdy : out std_logic;

      req_in   : in  std_logic;
      rdy_in   : out std_logic;
      data_in  : in  std_logic_vector;
      req_out  : out std_logic;
      rdy_out  : in  std_logic;
      data_out : out std_logic_vector;

      nRESET  : in  std_logic;
      PCLK    : in  std_logic;
      PADDR   : in  std_logic_vector(7 downto 0);
      PWRITE  : in  std_logic;
      PSEL    : in  std_logic;
      PENABLE : in  std_logic;
      PWDATA  : in  std_logic_vector(31 downto 0);
      PRDATA  : out std_logic_vector(31 downto 0);
      PREADY  : out std_logic;
      PSLVERR : out std_logic);
  end component;

  component zbtram_wrapper 
     generic(
         link_width      : integer := 188
     );
     port(
         clk             : in    std_logic;
         rst             : in    std_logic;
         req_in          : in    std_logic;
         rdy_in          : out   std_logic;
         data_in         : in    std_logic_vector;
         req_out         : out   std_logic;
         rdy_out         : in    std_logic;
         data_out        : out   std_logic_vector;
         RAM_A_SnWBYTE : out   std_logic_vector(7 downto 0);
         RAM_A_SnOE    : out   std_logic;
         RAM_A_SnCE    : out   std_logic;
         RAM_A_SADVnLD : out   std_logic;
         RAM_A_SnWR    : out   std_logic;
         RAM_A_SnCKE   : out   std_logic;
         RAM_A_SMODE   : out   std_logic;
         RAM_A_SA      : out   std_logic_vector(23 downto 3);
         RAM_A_SD      : inout std_logic_vector(63 downto 0);
         RAM_B_SnWBYTE : out   std_logic_vector(7 downto 0);
         RAM_B_SnOE    : out   std_logic;
         RAM_B_SnCE    : out   std_logic;
         RAM_B_SADVnLD : out   std_logic;
         RAM_B_SnWR    : out   std_logic;
         RAM_B_SnCKE   : out   std_logic;
         RAM_B_SMODE   : out   std_logic;
         RAM_B_SA      : out   std_logic_vector(23 downto 3);
         RAM_B_SD      : inout std_logic_vector(63 downto 0)
       );
  end component;

  component ddr_wrapper 
     port(
         clk             : in    std_logic;
         rst             : in    std_logic;
         req_in          : in    std_logic;
         rdy_in          : out   std_logic;
         data_in         : in    std_logic_vector;
         req_out         : out   std_logic;
         rdy_out         : in    std_logic;
         data_out        : out   std_logic_vector;

         DDR3_A              : out   std_logic_vector(15 downto 0);
         DDR3_BA             : out   std_logic_vector(2 downto 0);
         DDR3_CK_P           : out   std_logic;
         DDR3_CK_N           : out   std_logic;
         DDR3_CKE            : out   std_logic;
         DDR3_DM             : out   std_logic_vector(7 downto 0);
         DDR3_DQ             : inout std_logic_vector(63 downto 0);
         DDR3_DQS_P          : inout std_logic_vector(7 downto 0);
         DDR3_DQS_N          : inout std_logic_vector(7 downto 0);
         DDR3_nCAS           : out   std_logic;
         DDR3_nEVENT         : in    std_logic;
         DDR3_nRAS           : out   std_logic;
         DDR3_nRESET         : out   std_logic;
         DDR3_nS             : inout std_logic_vector(1 downto 0);
         DDR3_nWE            : out   std_logic;
         DDR3_ODT            : out   std_logic;
         DDR3_SDA            : inout std_logic;
         DDR3_REFCLK_P       : in    std_logic;
         DDR3_REFCLK_N       : in    std_logic;
         init_calib_complete : out   std_logic;
         MEM_CLK             : in    std_logic;
         ddr3_clk            : out   std_logic;
         ddr3_clk_sync_rst   : out   std_logic;
         ddr3_aresetn        : in    std_logic
       );
  end component;

  -- WARNING: If you change amber_wrapper, you might also have to change turbo_amber_wrapper.
  component amber_wrapper
    generic(
      tile_x          : integer := 0;
      tile_y          : integer := 0;
      cpu_id          : integer := 255
      );
    port (
      clk             : in    std_logic;
      rst             : in    std_logic;
      irq             : in    std_logic;
      system_rdy      : in std_logic;
      req_in          : in    std_logic;
      rdy_in          : out   std_logic;
      data_in         : in    std_logic_vector;
      req_out         : out   std_logic;
      rdy_out         : in    std_logic;
      data_out        : out   std_logic_vector
      );
  end component;

  -- WARNING: If you change turbo_amber_wrapper, you might also have to change amber_wrapper.
  component turbo_amber_wrapper
    generic(
      tile_x          : integer := 0;
      tile_y          : integer := 0;
      cpu_id          : integer := 255
      );
    port (
      clk             : in    std_logic;
      rst             : in    std_logic;
      irq             : in    std_logic;
      system_rdy      : in std_logic;
      req_in          : in    std_logic;
      rdy_in          : out   std_logic;
      data_in         : in    std_logic_vector;
      req_out         : out   std_logic;
      rdy_out         : in    std_logic;
      data_out        : out   std_logic_vector
      );
  end component;

  component ram_wrapper 
     port(
         clk             : in    std_logic;
         rst             : in    std_logic;
         req_in          : in    std_logic;
         rdy_in          : out   std_logic;
         data_in         : in    std_logic_vector;
         req_out         : out   std_logic;
         rdy_out         : in    std_logic;
         data_out        : out   std_logic_vector
     );
  end component;

  -----------------------------------------------------------------------------
  -- Core components
  -----------------------------------------------------------------------------

  component ram
    generic (
      WORDS : integer;
      DI_WIDTH : integer); 
    port (
      clk     : in  std_logic;
      we      : in  std_logic;
      wmask   : in  std_logic_vector(15 downto 0);
      addr    : in  std_logic_vector(27 downto 0);
      di      : in  std_logic_vector(127 downto 0);
      do      : out std_logic_vector(127 downto 0)); 
  end component;

  -- Misc
  component router 
     generic(
         LINKWIDTH       : integer := 196;
         IN_PORT_CNT     : integer := 5;
         OUT_PORT_CNT    : integer := 5;
         TILE_X          : integer := 0;
         TILE_Y          : integer := 0
     );
     port(
         clk             : in    std_logic;
         rst             : in    std_logic;
         req_in          : in    std_logic_vector;
         rdy_in          : out   std_logic_vector;
         data_in         : in    std_logic_vector;
         req_out         : out   std_logic_vector;
         rdy_out         : in    std_logic_vector;
         data_out        : out   std_logic_vector
     );
  end component;

  component netiface 
     generic(
         link_width_loc  : integer := 188;
         tile_x          : integer := 0;
         tile_y          : integer := 0;
         apb_i : integer;
         apb_j : integer;
         zbt_i : integer;
         zbt_j : integer;
         bram0_i : integer;
         bram0_j : integer;
         bram1_i : integer;
         bram1_j : integer;
         bram2_i : integer;
         bram2_j : integer;
         bram3_i : integer;
         bram3_j : integer;
         bram4_i : integer;
         bram4_j : integer;
         bram5_i : integer;
         bram5_j : integer;
         bram6_i : integer;
         bram6_j : integer;
         bram7_i : integer;
         bram7_j : integer
     );
     port(
         clk             : in    std_logic;
         rst             : in    std_logic;
         req_in          : in    std_logic;
         rdy_in          : out   std_logic;
         data_in         : in    std_logic_vector;
         req_out         : out   std_logic;
         rdy_out         : in    std_logic;
         data_out        : out   std_logic_vector;
         req_in_r        : out   std_logic;
         rdy_in_r        : in    std_logic;
         data_in_r       : out   std_logic_vector;
         req_out_r       : in    std_logic;
         rdy_out_r       : out   std_logic;
         data_out_r      : in    std_logic_vector
     );
  end component;

end package;
