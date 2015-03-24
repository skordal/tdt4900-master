library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity arbiterController is
	generic(n: integer := 34; -- Two extra bits to determine difference between load, store and intterupt. Must be recognized by the output handler. 
			m: integer := 3);
	port (
		-- Clock only used to update internal registers of recently used loads and stores
		clk : in std_logic;
		-- 'Req' for request
		blockReq : in std_logic;
		interruptReq : in std_logic;
		storeReq0: in std_logic;
		storeReq1: in std_logic;
		loadReq0: in std_logic;
		loadReq1: in std_logic;
		-- 'Ack' for acknowledge, used by receiver to know when it has access to pass out data
		interruptAck : out std_logic;
		storeAck0 : out std_logic;
		storeAck1 : out std_logic;
		loadAck0 : out std_logic;
		loadAck1 : out std_logic;
		
		-- Control signals to arbiter dataMux and adrMux
		dataOpt : out std_logic;
		adrOpt : out std_logic_vector(m-1 downto 0)	
	);
end arbiterController;

architecture arch of arbiterController is
	
	signal allInputs : std_logic_vector(5 downto 0); -- One bit for each input signal
	signal allAckOutputs : std_logic_vector (4 downto 0) := "00000"; -- One bit for each output ack signal. WARNING: Only one should be active at the time.
	
	-- Registers used to track least recently channel that had a load, and had a store
	-- Used to arbitrate between tying store requests and load requests
	signal LRL : std_logic := '0'; -- LRL = Least Recent Load
	signal LRS : std_logic := '0'; -- LRS = Least Recent Store
	-- Next-signals
	signal next_LRL : std_logic := '0';
	signal next_LRS : std_logic := '0'; 
	
	signal dataOpt_reg : std_logic := '0';
    signal adrOpt_reg : std_logic_vector(2 downto 0):= "000";
	
	
begin
	
	-- Concatinating the inputs and the outputs for simpler treatment in the case statements
	allInputs <= blockReq & interruptReq & storeReq0 & storeReq1 & loadReq0 & loadReq1;
	interruptAck <= allAckOutputs(4);
	storeAck0 <= allAckOutputs(3);
	storeAck1 <= allAckOutputs(2);
	loadAck0 <= allAckOutputs(1);
	loadAck1 <= allAckOutputs(0);
	
	dataOpt <= dataOpt_reg;
	adrOpt <= adrOpt_reg;
	
	
	update_register : process (clk, next_LRL, next_LRS)
	begin
		if rising_edge(clk) then
			LRL <= next_LRL;
			LRS <= next_LRS;
		end if;
	end process;
	
	-- Priority scheme: Blocking before interrupt, interrupt before stores, stores before loads.
	-- A recently used store log and load log is used to arbitrate between channels 0 and 1 if both are requesting for same operation (load or store), 
	-- and there is no higher priority request that outweights the current stores/loads
	--arbitrate : process (allInputs)
	--begin
--		case? allInputs is
--			when "1-----" => -- Blocking request
--				allAckOutputs <= "00000";
--				dataOpt <= '-';
--				adrOpt <= "---";
--			when "01----" => -- Interrupt request
--				allAckOutputs <= "10000";
--				dataOpt <='0'; 
--				adrOpt <= "000"; 
--			when "0010--" => -- Store request from channel 0 only
--				allAckOutputs <= "01000";
--				dataOpt <='1'; 
--				adrOpt <= "001";
--				next_LRS <= '0';
--			when "0001--" => -- Store request from channel 1 only
--				allAckOutputs <= "00100";
--				dataOpt <='1';
--				adrOpt <= "010";
--				next_LRS <='1';
--			when "0011--" => -- Store request from both channels
--				if LRS = '1' then -- Channel 1 had most recent store, give channel 0 priority
--					allAckOutputs <="01000";
--					adrOpt <= "001";
--					next_LRS <= '0';
--				else -- Vice versa
--					allAckOutputs <="00100";
--					adrOpt <= "010";
--					next_LRS <= '1';
--				end if;
--				dataOpt <= '1';
--			when "000010" => -- Load request from channel 0 only
--				allAckOutputs <= "00010";
--				dataOpt <='0';
--				adrOpt <="011";
--				next_LRL <= '0';
--			when "000001" => -- Load request from channel 1 only
--				allAckOutputs <= "00001";
--				dataOpt <='0';
--				adrOpt<="100"
--				next_LRL <= '1';
--			when "000011" => -- Load request from both channels
--				if LRL = '1' then 
--					allAckOutputs <= "00010";
--					adrOpt <= "011";
--					next_LRL <= '0';
--				else
--					allAckOutputs <= "00001";
--					adrOpt <= "100";
--					next_LRL <= '1';
--				end if;
--				dataOpt <='0';
--			when others => -- Covers for no requests, as well as other combinations that should not happen (since they all should be covered by previous statements)
--			allAckOutputs <= "00000";
--			adrOpt <= "---";
--			dataOpt <= '0';
--		end case;
			
		-- The following if-segments is reserve for the case statements, should it lack 2008 update and thus not treat don't cares correctly, reading '-' as explicit don't cares, instead of ignoring the contents.
	arbitrate : process (blockReq, interruptReq, storeReq0, storeReq1, loadReq0, loadReq1, LRL, LRS)
	   variable var_LRL : std_logic;
       variable var_LRS : std_logic;    
            
	
	begin
           var_LRL := LRL;
           var_LRS := LRS;    
	   if blockReq = '1' then -- Blocking request
			allAckOutputs <= "00000";
		elsif interruptReq = '1' then -- Interrupt request
			allAckOutputs <= "10000";
			dataOpt_reg <='0'; 
			adrOpt_reg <= "000"; 
		elsif (storeReq0 = '1' OR storeReq1 = '1') then 
		-- NOTE: Both channels requesting store data should not happen in channel system with common data buffer. May only happen in private buffer system.
		
			if (storeReq0 = '1' AND (storeReq1 = '0' OR LRS = '1')) then -- If only channel 0 requests, or both channels but channel 1 was least recent, then choose channel 0
				allAckOutputs <="01000";
				adrOpt_reg <= "001";
				var_LRS := '0';
			else --(storeReq1 = '1' AND (storeReq0 = '0' OR LRS = '0')) then -- If only channel 1 requests, or both channels but channel 0 was least recent, then choose channel 1
				allAckOutputs <="00100";
				adrOpt_reg <= "010";
				var_LRS := '1';
			end if;
			dataOpt_reg <= '1';
		elsif (loadReq0 = '1' OR loadReq1 = '1') then
			if (loadReq0 = '1' AND (loadReq1 = '0' OR LRL = '1')) then -- If only channel 0 requests, or both channels but channel 1 was least recent, then choose channel 0
				allAckOutputs <="00010";
				adrOpt_reg <= "011";
				var_LRL :='0';
			else --(loadReq1 = '1' AND (loadReq0 = '0' OR LRL = '0')) then -- If only channel 1 requests, or both channels but channel 0 was least recent, then choose channel 1
				allAckOutputs <="00001";
				adrOpt_reg <= "100";
				var_LRL :='1';
			end if;
			dataOpt_reg <= '0';
		else -- No requests, or other unforseen combinations that somehow does not fit into previous conditions
			allAckOutputs <= "00000";
			adrOpt_reg <= "000";
			dataOpt_reg <= '0';
		end if;
		next_LRL <= var_LRL;
		next_LRS <= var_LRS;
		
	end process;
end arch;