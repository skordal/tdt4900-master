library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.conv_integer;

package Types is

  subtype bus32 is std_logic_vector(31 downto 0);
  type bus32_vector is array (natural range <>) of bus32;

  subtype leds_t is std_logic_vector(7 downto 0);
  
  constant sizeof_coord : integer := 4;
  subtype coord_int is natural range 0 to 15;
  
  type tile_coord is
  record
    i  : coord_int;
    j  : coord_int;
  end record;
  
  -- Direction enums
  --constant dir_cnt : integer := 6;
  --type direction_enum is (east, north, west, south, intern_proc, intern_mem);
  constant dir_cnt : integer := 5;
  type direction_enum is (east, north, west, south);
  type direction_enum_vector is array (direction_enum) of direction_enum;
  type direction_boolean_vector is array (direction_enum) of boolean;  -- Boolean vector with direction as index
  type doubledirection_boolean_vector is array (direction_enum) of direction_boolean_vector;  -- Direction_boolean_vector with direction as index
  type direction_stdlogic_vector is array (direction_enum) of std_logic;
  
  -- Type for router packages
  constant mem_read : std_logic_vector(3 downto 0) := "0000";

  type packet_flag is (none, interrupt, synco);
  constant sizeof_flag : integer := 2;
  subtype flag_bitsign is std_logic_vector(sizeof_flag-1 downto 0);
  --constant sizeof_pkt : integer := 87;
  --type packet is record
  --  req          : boolean;   -- Request(1) or response(0)
  --  write_enable : std_logic_vector(3 downto 0); -- Read: "0000", Write32: "1111"
  --  flag         : packet_flag; -- Flag: none, synco, interrupt
  --  sender       : tile_coord;  -- Coordinate for sender
  --  address      : bus32;       -- Address
  --  data         : bus32;       -- Data
  --  dest         : tile_coord;  -- Destination coordinate (temporarily introduced for IC)
  --end record;
  constant sizeof_pkt : integer := 196;
  subtype packet is std_logic_vector(sizeof_pkt-1 downto 0);
  constant sizeof_pkt_vec : integer := 196*dir_cnt;
  

  constant sizeof_local_pkt : integer := 188;
  
  constant EAST_DIR : integer := 0;
  constant NORTH_DIR : integer := 1;
  constant WEST_DIR : integer := 2;
  constant SOUTH_DIR : integer := 3;
  constant LOCAL_DIR : integer := 4;

  constant EAST_PACKET_BEGIN : integer := sizeof_pkt*0;
  constant EAST_PACKET_END : integer := sizeof_pkt*1-1;
  constant NORTH_PACKET_BEGIN : integer := sizeof_pkt*1;
  constant NORTH_PACKET_END : integer := sizeof_pkt*2-1;
  constant WEST_PACKET_BEGIN : integer := sizeof_pkt*2;
  constant WEST_PACKET_END : integer := sizeof_pkt*3-1;
  constant SOUTH_PACKET_BEGIN : integer := sizeof_pkt*3;
  constant SOUTH_PACKET_END : integer := sizeof_pkt*4-1;
  constant LOCAL_PACKET_BEGIN : integer := sizeof_pkt*4;
  constant LOCAL_PACKET_END : integer := sizeof_pkt*5-1;
  
  

  subtype packet_bitsign is std_logic_vector(sizeof_pkt-1 downto 0);
  type packet_vector is array (direction_enum) of packet;
   
  type boolean_vector is array (natural range <>) of boolean;

  --constant dummy_packet : packet := (req => false, write_enable => (others => 'X'), flag => none, 
  --                                   sender => (i => 0, j => 0), address => (others => 'X'),
  --                                   data => (others => 'X'), dest => (i => 0, j => 0));
  
  -- Declare functions and procedure

  function get_i (signal address : bus32) return coord_int;
  function get_j (signal address : bus32) return coord_int;

  -- Conversion functions
  function boolean_to_std_logic (signal a : boolean) return std_logic;
--  function direction_boolean_vector_to_std_logic_vector (signal dbv : direction_boolean_vector)
--    return std_logic_vector;
--  function to_std_logic_vector (signal f : packet_flag) return std_logic_vector;
--  function packet_to_std_logic_vector (signal p : packet)
--    return std_logic_vector;
--  function packet_vector_to_std_logic_vector (signal pv : packet_vector)
--    return std_logic_vector;
--  
  function std_logic_to_boolean (signal a : std_logic) return boolean;
--  function std_logic_vector_to_direction_boolean_vector (signal v : std_logic_vector)
--    return direction_boolean_vector;
--  function std_logic_vector_to_flag (signal v : flag_bitsign)
--    return packet_flag;
--  function std_logic_vector_to_packet (signal v : packet_bitsign)
--    return packet;
--  function std_logic_vector_to_packet_vector (signal v : std_logic_vector)
--    return packet_vector;
--
--  procedure WriteData ( signal clk : in std_logic;
--                        signal req : inout boolean;
--                        signal ack : in boolean;
--                        constant wr_addr : in bus32;
--                        constant wr_data : in bus32;
--                        signal data : out packet );

end Types;


package body Types is

--  procedure WriteData ( signal clk : in std_logic;
--                        signal req : inout boolean;
--                        signal ack : in boolean;
--                        constant wr_addr : in bus32;
--                        constant wr_data : in bus32;
--                        signal data : out packet ) is
--  begin
--    req  <= true;
--    data <= ( 
--      req => true,
--      write_enable => "1111",
--      flag => none,
--      sender => (i => 0, j => 0),   -- Don't care, this is write...
--      address => wr_addr,
--      data => wr_data,
--      dest => (i => 0, j => 0)
--    );
--    wait until ack;
--    wait until rising_edge(clk);
--    req <= false;
--    wait until rising_edge(clk);
--    wait until not ack;
--    wait until rising_edge(clk);
--  end WriteData;

  function get_j (
    signal address : bus32)
    return coord_int is
  begin
    if address(31 downto 8) = X"FFFFFF" then
      return 0;
    elsif address(31 downto 27) = B"11111" then
      return 1;
    else
      return 2;
    end if;
  end get_j;

  function get_i (
    signal address : bus32)
    return coord_int is
  begin
    return 0;
  end get_i;

  function boolean_to_std_logic (
    signal a : boolean)
    return std_logic is
  begin  -- to_std_logic
    if a then
      return '1';
    else
      return '0';
    end if;
  end boolean_to_std_logic;

--  function direction_boolean_vector_to_std_logic_vector (
--    signal dbv : direction_boolean_vector)
--    return std_logic_vector is
--  begin
--    return to_std_logic(dbv(intern_mem)) &
--           to_std_logic(dbv(intern_proc)) &
--           to_std_logic(dbv(south)) &
--           to_std_logic(dbv(west)) &
--           to_std_logic(dbv(north)) &
--           to_std_logic(dbv(east));
--  end direction_boolean_vector_to_std_logic_vector;
--
--  function to_std_logic_vector (
--    signal f : packet_flag)
--    return std_logic_vector is
--  begin
--    if f = none then
--      return STD_LOGIC_VECTOR(TO_UNSIGNED(0,2));
--    elsif f = interrupt then
--      return STD_LOGIC_VECTOR(TO_UNSIGNED(1,2));
--    elsif f = synco then
--      return STD_LOGIC_VECTOR(TO_UNSIGNED(2,2));
--    else
--      return STD_LOGIC_VECTOR(TO_UNSIGNED(0,2));
--    end if;
--  end to_std_logic_vector;
--
--  function packet_to_std_logic_vector (
--    signal p : packet)
--    return std_logic_vector is
--  begin
--    return STD_LOGIC_VECTOR(TO_UNSIGNED(p.dest.j,4)) &
--           STD_LOGIC_VECTOR(TO_UNSIGNED(p.dest.i,4)) &
--           p.data & p.address &
--           STD_LOGIC_VECTOR(TO_UNSIGNED(p.sender.j,4)) &
--           STD_LOGIC_VECTOR(TO_UNSIGNED(p.sender.i,4)) &
--           to_std_logic_vector(p.flag) & p.write_enable &
--           to_std_logic(p.req);
--  end packet_to_std_logic_vector;
--
--  function packet_vector_to_std_logic_vector (
--    signal pv : packet_vector)
--    return std_logic_vector is
--  begin
--    return packet_to_std_logic_vector(pv(intern_mem)) &
--           packet_to_std_logic_vector(pv(intern_proc)) &
--           packet_to_std_logic_vector(pv(south)) &
--           packet_to_std_logic_vector(pv(west)) &
--           packet_to_std_logic_vector(pv(north)) &
--           packet_to_std_logic_vector(pv(east));
--  end packet_vector_to_std_logic_vector;

  function std_logic_to_boolean (
    signal a : std_logic)
    return boolean is
  begin
    if a = '1' then
      return true;
    else
      return false;
    end if;
  end std_logic_to_boolean;

--  function std_logic_vector_to_direction_boolean_vector (
--    signal v : std_logic_vector)
--    return direction_boolean_vector is
--    variable dbv : direction_boolean_vector;
--  begin
--    -- TODO: replace hardcoded packet width
--    dbv(east) := std_logic_to_boolean(v(0));
--    dbv(north) := std_logic_to_boolean(v(1));
--    dbv(west) := std_logic_to_boolean(v(2));
--    dbv(south) := std_logic_to_boolean(v(3));
--    dbv(intern_proc) := std_logic_to_boolean(v(4));
--    dbv(intern_mem) := std_logic_to_boolean(v(5));
--    return dbv;
--  end std_logic_vector_to_direction_boolean_vector;
--
--  function std_logic_vector_to_flag (
--    signal v : flag_bitsign)
--    return packet_flag is
--  begin
--    if conv_integer(v) = 0 then
--      return none;
--    elsif conv_integer(v) = 1 then
--      return interrupt;
--    elsif conv_integer(v) = 2 then
--      return synco;
--    else
--      return none;
--    end if;
--  end std_logic_vector_to_flag;
--
--  function std_logic_vector_to_packet (
--    signal v : packet_bitsign)
--    return packet is
--    variable pkt : packet;
--  begin
--    -- TODO: replace hardcoded field indices
--    pkt.req := std_logic_to_boolean(v(0));
--    pkt.write_enable := v(4 downto 1);
--    pkt.flag := std_logic_vector_to_flag(v(6 downto 5));
--    pkt.sender.i := TO_INTEGER(UNSIGNED(v(10 downto 7)));
--    pkt.sender.j := TO_INTEGER(UNSIGNED(v(14 downto 11)));
--    pkt.address := v(46 downto 15);
--    pkt.data := v(78 downto 47);
--    pkt.dest.i := TO_INTEGER(UNSIGNED(v(82 downto 79)));
--    pkt.dest.j := TO_INTEGER(UNSIGNED(v(86 downto 83)));
--    return pkt;
--  end std_logic_vector_to_packet;
--
--  function std_logic_vector_to_packet_vector (
--    signal v : std_logic_vector)
--    return packet_vector is
--    variable pv : packet_vector;
--  begin
--    -- TODO: replace hardcoded packet width and start indices
--    pv(east) := std_logic_vector_to_packet(v(sizeof_pkt*1-1 downto 0));
--    pv(north) := std_logic_vector_to_packet(v(sizeof_pkt*2-1 downto sizeof_pkt*1));
--    pv(west) := std_logic_vector_to_packet(v(sizeof_pkt*3-1 downto sizeof_pkt*2));
--    pv(south) := std_logic_vector_to_packet(v(sizeof_pkt*4-1 downto sizeof_pkt*3));
--    pv(intern_proc) := std_logic_vector_to_packet(v(sizeof_pkt*5-1 downto sizeof_pkt*4));
--    pv(intern_mem) := std_logic_vector_to_packet(v(sizeof_pkt*6-1 downto sizeof_pkt*5));
--    return pv;
--  end std_logic_vector_to_packet_vector;

end Types;
