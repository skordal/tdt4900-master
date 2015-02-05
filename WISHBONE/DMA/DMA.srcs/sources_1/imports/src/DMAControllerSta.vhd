library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

-- PROBLEMS: MAY NEED FIFO-BUFFER BEFORE TESTING



entity DMAControllerSta is
	generic( n : integer := 32; -- 32-bit addresses
			 m : integer := 32;	-- ReqDetails, 32 bit set as standard
			 i : integer := 2	-- 2-bit register
	);
	
	port(
		-- INPUTS
		-- Clock & reset
		clk : in STD_LOGIC;
		reset : in STD_LOGIC;
									   						
		-- From Request buffer
		req : in std_logic; -- New data ready from request buffer
		reqDetails : in std_logic_vector(m-1 downto 0);	-- Details, including requestor ID, count, mode
		loadDetails : in std_logic_vector(n-1 downto 0); -- Beginning load address
		storeDetails : in std_logic_vector(n-1 downto 0); -- Beginning store address
		-- From channels
		activeCh0 : in std_logic; -- Channel 0 signals active
		activeCh1 : in std_logic; -- Channel 1 signals active
		-- From arbiter
		interruptAck : in std_logic;	 -- Access to interrupt output granted
		
		-- OUTPUTS
		-- To request buffer
		reqUpdate : out std_logic; --Signals buffer that data is read, and to prepare next data
		-- To Channels
		set0 : out std_logic; -- Set channel 0
		set1 : out std_logic; -- Set channel 1
		FLAOut : out std_logic_vector (n-1 downto 0); -- Final Load Address to channels
		FSAOut : out std_logic_vector (n-1 downto 0); -- Final Store Address to channels
		counterOut : out std_logic_vector (n-1 downto 0); -- Output to counter
		decrementOut : out std_logic_vector (2 downto 0); -- Output for decrementvalue (should be "001" or "100")
		--LModeOut : out std_logic;	-- Set to 1 for this project
		--SModeOut : out std_logic; -- Set to 1 for this project
		-- To arbiter
		interruptReq : out std_logic;
		interruptDetails : out std_logic_vector((n-1)+2 downto 0)
	    );
end DMAControllerSta;

architecture controller of DMAControllerSta is
	-- Defining state machine
	type state IS (IDLE, PROCESSING, WAITING, INTERRUPT);		   	   			 
	signal pr_state, next_state : state;
	attribute enum_encoding: string;
	attribute enum_encoding of state: type is "sequential";
	
	-- Internal registers
	signal interruptDetails_internal : std_logic_vector((n-1)+2 downto 0) := ((n-1)+2 downto 0 => '0'); -- Internal version of output signal
--	signal loadAddress : std_logic_vector(n-1 downto 0) := (n-1 downto 0 => '0');  -- Assumption: Starting address.
--	signal storeAddress : std_logic_vector(n-1 downto 0) := (n-1 downto 0 => '0'); -- Assumption: Starting address.
--	signal counter : std_logic_vector(n-1 downto 0) := (n-1 downto 0 => '0');
	signal set0_internal : std_logic := '0'; -- Internal version of set0
	signal set1_internal : std_logic := '0'; -- Internal version of set1
	
	-- For job handeling, and recognizing who the jobs are done on behalf of
	signal occupied : std_logic_vector (1 downto 0) := "00"; -- Occupy register, compared with channel active signals in order to know when a job is done
	signal requestID0 : std_logic_vector(6 downto 0) := "0000000"; -- 7 bits used for ID	for requestor for job at channel 0
	signal requestID1 : std_logic_vector(6 downto 0) := "0000000"; -- 7 bits used for ID	for requestor for job at channel 1
	
	-- Next-signals, outputs
	signal next_reqUpdate : std_logic := '0';
	
	signal next_set0 : std_logic := '0';
	signal next_set1 : std_logic := '0';
	signal next_FLAOut : std_logic_vector (n-1 downto 0) := (n-1 downto 0 => '0');
	signal next_FSAOut : std_logic_vector (n-1 downto 0) := (n-1 downto 0 => '0');
	signal next_counterOut : std_logic_vector (n-1 downto 0) := (n-1 downto 0 => '0');
	signal next_decrementOut : std_logic_vector (2 downto 0) := "001";
	
	signal next_interruptReq  : std_logic := '0';
	signal next_interruptDetails : std_logic_vector((n-1)+2 downto 0) := ((n-1)+2 downto 0 => '0');
	
	-- Next-signals, internal registers
	--signal next_loadAddress : std_logic_vector(n-1 downto 0) := (n-1 downto 0 => '0');
--	signal next_storeAddress : std_logic_vector(n-1 downto 0) := (n-1 downto 0 => '0');
--	signal next_counter : std_logic_vector(n-1 downto 0) := (n-1 downto 0 => '0');
	
	signal next_occupied : std_logic_vector(1 downto 0) := "00";
	signal next_requestID0 : std_logic_vector(6 downto 0) := "0000000";
	signal next_requestID1 : std_logic_vector(6 downto 0) := "0000000";
	
	-- Combinatoric signals, used to make coding more simple
	signal counterInput : std_logic_vector(n-1 downto 0) := (n-1 downto 0 => '0');
	signal addressingMode : std_logic; 
	signal requestIDInput : std_logic_vector(6 downto 0) := "0000000";
	signal FLAConvert : std_logic_vector(n-1 downto 0) := (n-1 downto 0 => '0');
	signal FSAConvert : std_logic_vector(n-1 downto 0) := (n-1 downto 0 => '0');
	signal totalActive : std_logic_vector(1 downto 0) := "00";
	signal workDone : std_logic_vector(1 downto 0);

	--
	
	
begin 
	
	-- Setting up combinatoric signals
	counterInput <= (n-1 downto 12 => '0') & reqDetails(m-1 downto (m-1)-11); -- Uses 0's & 12 first bits of reqDetails
	addressingMode <= reqDetails((m-1)-12);                                   -- Next bit is used to choose between word-addressing or byte-addressing. 1 if byte, 0 if word
	requestIDInput <= reqDetails((m-1)-13	downto (m-1)-(13+6));			  -- Uses 7 next bits of reqDetails
	FLAConvert <= std_logic_vector(unsigned(loadDetails)+unsigned(counterInput));-- -- Adds Load address and counter to generate FLA
	FSAConvert <= std_logic_vector(unsigned(storeDetails)+unsigned(counterInput));-- Adds Store address and counter to generate FSA
	--totalActive <= (activeCh1 OR set1_internal) & (activeCh0 OR set0_internal);; -- Concatinates active-signals from channels into single vector signal. Also uses set-signals due to delay from active-signals
	totalActive(1) <= activeCh1 OR set1_internal;
	totalActive(0) <= activeCh0 OR set0_internal;
	workDone <= std_logic_vector(unsigned(occupied)-unsigned(totalActive)); -- Used to know when a channel is done 
	--(difference between occupied register and active signals (1 -> 0 = work done).
	interruptDetails <= interruptDetails_internal;
	
	-- Internal signals to outputs
	set1 <= set1_internal;
    set0 <= set0_internal;

	
	-- Other combinatorics:
	
	--FLAConvert <= std_logic_vector(unsigned(loadDetails)+unsigned(counterInput)+(unsigned(counterInput)*3*addressingMode)); -- Adds Load address and counter to generate FLA
    --FSAConvert <= std_logic_vector(unsigned(storeDetails)+unsigned(counterInput)+(unsigned(counterInput)*3*addressingMode)); -- Adds Store address and counter to generate FSA
	
	
	-- Lower section of FSM
	-- Updating state and output signals based on next-signals
	updateFSM : process(clk, next_state, next_set0, next_set1, next_FLAOut, next_FSAOut, next_counterOut, next_decrementOut, next_interruptReq, next_interruptDetails, next_occupied, next_requestID0, next_requestID1)
	begin
		if rising_edge(clk) then
			-- State
			pr_state <= next_state;
			-- Outputs
			--reqUpdate <= next_reqUpdate;
			
			--set0 <= next_set0;
			--set1 <= next_set1;
			set0_internal <= next_set0;
			set1_internal <= next_set1;
			
			FLAOut <= next_FLAOut;
			FSAOut <= next_FSAOut;
			counterOut <= next_counterOut;
			decrementOut <= next_decrementOut;
			
			interruptReq <= next_interruptReq;
			interruptDetails_internal <= next_interruptDetails;
			
			-- Internal signals
			occupied <= next_occupied;
			requestID0 <= next_requestID0;
			requestID1 <= next_requestID1;
			
			--loadAddress <= next_loadAddress;
			--storeAddress <= next_storeAddress;
			--counter => next_counter;
		end if;
	end process;
		
	
	-- Upper section of FSM
	
	setNext : process(req, reset, pr_state, FLAConvert, FSAConvert, counterInput, addressingMode, requestIDInput, totalActive, 
						activeCh0, activeCh1, workDone, occupied, interruptDetails_internal, interruptAck, requestID0, requestID1)
		-- Variables for each next-signal
		variable var_reqUpdate : std_logic;
		variable var_set0 : std_logic;
		variable var_set1 : std_logic;
		variable var_FLAOut : std_logic_vector (n-1 downto 0);						
		variable var_FSAOut : std_logic_vector (n-1 downto 0);
		variable var_counterOut : std_logic_vector (n-1 downto 0);
		variable var_decrementOut : std_logic_vector (2 downto 0);
		variable var_interruptReq  : std_logic;
		variable var_interruptDetails : std_logic_vector((n-1)+2 downto 0);
		variable var_occupied : std_logic_vector(1 downto 0);
		variable var_requestID0 : std_logic_vector(6 downto 0);
		variable var_requestID1 : std_logic_vector(6 downto 0);
	begin
		var_reqUpdate := '0';
		var_set0 := '0';	 
		var_set1 := '0';
		var_FLAOut := (n-1 downto 0 => '0');
		var_FSAOut := (n-1 downto 0 => '0');
		var_counterOut := (n-1 downto 0 => '0');
		var_decrementOut := "001";
		var_interruptReq := '0';
		var_interruptDetails := ((n+2)-1 downto 0 => '0');
		var_occupied := occupied;
		var_requestID0 := requestID0; 
		var_requestID1 := requestID1;
		
		if reset = '1' then
		  var_occupied := "00";
		  var_requestID0 := (6 downto 0 => '0'); 
            var_requestID1 :=  (6 downto 0 => '0');
            next_state <= IDLE;
		else
		
		case pr_state is
			when IDLE => -- Idle, not working
				if req = '1' then -- Request detected
					-- Set state
					next_state <= PROCESSING;
					
					-- Set outputs
					var_reqUpdate := '1';
					
					var_set0 := '1'; -- Since both channels are innactive at IDLE, set first channel (MAY BE UP FOR CHANGE)
					--next_set1 <= '0'; -- '0' at default at this point, should not need to set
					var_FLAOut := FLAConvert;
					var_FSAOut := FSAConvert;
					var_counterOut := counterInput;
					if (addressingMode = '1') then
					   var_decrementOut := "100";
					   var_counterOut := counterInput(n-3 downto 0) & "00";
					   var_FLAOut := FLAConvert(n-3 downto 0) & "00";
                       var_FSAOut := FSAConvert(n-3 downto 0) & "00";
					end if;
					
					
					-- Set internal registers
					var_occupied(0) := '1';
					var_requestID0 := requestIDInput;
					--next_loadAddress <= loadDetails;
					--next_storeAddress <= storeDetails;
					--next_counter <= (n-1 downto 12 => '0') & reqDetails(n-1 downto (n-1)-12);
				else
					next_state <= IDLE;	   					
				end if;
			
			when PROCESSING =>
				-- A set signal should be active, and a channel is set. Must handle another request if one channel is still free
				
				-- Directed mode: Input details selects channel
				-- IF Channel 0 is free and next details wants channel 0
				-- ELSIF Channel 1 is free and next details wants channel 1
				
				-- Dynamic mode: Assign to any free channel (0 before 1)	
				if req = '1' and totalActive /= "11" then -- Request AND channel free
					next_state <= PROCESSING;
					
					-- Set common outputs
					var_reqUpdate := '1';
					var_FLAOut := FLAConvert; 
					var_FSAOut := FSAConvert;
					var_counterOut := counterInput;
					if (addressingMode = '1') then
                        var_decrementOut := "100";
                        var_counterOut := counterInput(n-3 downto 0) & "00";
                        var_FLAOut := FLAConvert(n-3 downto 0) & "00";
                        var_FSAOut := FSAConvert(n-3 downto 0) & "00";
                    end if;
                                        
					
					if activeCh0 = '0' then	-- Channel 0 is free, prioritized above channel 1 in dynamic mode
						-- Set specific outputs
						var_set0 := '1';  
						-- Set specific internal registers
						var_occupied(0) := '1';
						var_requestID0 := requestIDInput;	
					elsif activeCh1 = '0' then -- Channel 1 is free
						-- Set specific outputs		
						var_set1 := '1';
						-- Set specific internal registers
						var_occupied(1) := '1';
						var_requestID1 := requestIDInput;	
					else
						-- Do nothing (should not happen)
					end if;
				
				else  -- No request or no channel free
					next_state <= WAITING;	   	
				end if;
			
			when WAITING =>
			-- Channels active, no request or no free channels
			
				if workDone /= "00" then 
					-- A channel has finished. Go to interrupt mode. Send out intterupt request to arbiter, and update values + correct registers
					next_state <= INTERRUPT;
					var_interruptReq := '1';
					if occupied(0) = '1' and activeCh0 = '0' then -- Channel 0 is done
						var_interruptDetails := "11" & requestID0 & "1111000011110000111100001";
						var_occupied(0) := '0';
					elsif occupied(1) = '1' and activeCh1 = '0' then -- Channel 1 is done
						var_interruptDetails := "11" & requestID1 & "1111000011110000111100001";
						var_occupied(1) := '0';
					else
						-- Do nothing (should not happen)
					end if;
				  
					
					
				elsif req = '1' and totalActive /= "11" then -- A channel was free, and a new request has arrived
					next_state <= PROCESSING;
					-- Set common outputs
					var_reqUpdate := '1';
					var_FLAOut := FLAConvert; 
					var_FSAOut := FSAConvert;
					var_counterOut := counterInput;
					if (addressingMode = '1') then
                        var_decrementOut := "100";
                        var_counterOut := counterInput(n-3 downto 0) & "00";
                        var_FLAOut := FLAConvert(n-3 downto 0) & "00";
                        var_FSAOut := FSAConvert(n-3 downto 0) & "00";
                    end if;
					
					
					if activeCh0 = '0' then	-- Channel 0 is free, prioritized above channel 1 in dynamic mode
						-- Set specific outputs
						var_set0 := '1'; 
						-- Set specific internal registers
						var_occupied(0) := '1';
						var_requestID0 := requestIDInput;	
					elsif activeCh1 = '0' then -- Channel 1 is free
						-- Set specific outputs	
						var_set1 := '1';
						-- Set specific internal registers
						var_occupied(1) := '1';
						var_requestID1 := requestIDInput;	
					else
						-- Do nothing (should not happen)
					end if;
				
				
				else -- req = '0' OR totalActive = "11". Stay in wait-mode until either a channel finishes, or a new request arrives
					next_state <= WAITING;
				end if;
				
			when INTERRUPT =>
				-- Requesting arbiter to send out intterupt signal. Even if a channel finishes while this occurs, 
				-- a new DMA process is not set in order to avoid possible overlaps in registers (Must verify)
				if interruptAck = '1' then -- Ack-signal is received from arbiter. Contents from interruptDetails are sent through arbiter
					
					-- Decide next action:
					-- Job done? => New intterupt.
					-- New request to handle? => Process new request
					-- No new request, but still any active channel? => Go to waiting mode
					-- No new reqest, no channels active? => Go to IDLE
					
					if workDone /= "00" then -- Another job managed to be done during the interrupt
						next_state <= INTERRUPT;
						var_interruptReq := '1';
						if occupied(0) = '1' and activeCh0 = '0' then -- Channel 0 is done
							var_interruptDetails := "11" & requestID0 & "1111000011110000111100001";
							var_occupied(0) := '0';
						elsif occupied(1) = '1' and activeCh1 = '0' then -- Channel 1 is done
							var_interruptDetails := "11" & requestID1 & "1111000011110000111100001";
							var_occupied(1) :='0';
						else
						-- Do nothing (should not happen)
						end if;
					
						
					
					elsif req = '1' then -- Process next request, at least one channel is free now
						next_state <= PROCESSING; 
						
						var_reqUpdate := '1';
						var_FLAOut := FLAConvert; 
						var_FSAOut := FSAConvert;
						var_counterOut := counterInput;
						if (addressingMode = '1') then
                            var_decrementOut := "100";
                            var_counterOut := counterInput(n-3 downto 0) & "00";
                            var_FLAOut := FLAConvert(n-3 downto 0) & "00";
                            var_FSAOut := FSAConvert(n-3 downto 0) & "00";
                        end if;
					
						if activeCh0 = '0' then	-- Channel 0 is free, prioritized above channel 1 in dynamic mode
							-- Set specific outputs
							var_set0 := '1'; 
							-- Set specific internal registers
							var_occupied(0) := '1';
							var_requestID0 := requestIDInput;	
						elsif activeCh1 = '0' then -- Channel 1 is free
							-- Set specific outputs	
							var_set1 := '1';
							-- Set specific internal registers
							var_occupied(1) := '1';
							var_requestID1 := requestIDInput;	
						else
							-- Do nothing (should not happen)
						end if;
					
					
					elsif totalActive /= "00" then -- There is still a channel active.
						next_state <= WAITING;	 
						
					else  -- No new job done, no new request to process, and no other active channels. In other words: Nothing more.
						next_state <= IDLE;		 
					end if;
				else 
					-- Access from arbiter not given, wait until access is given.
					-- (Should usually take 1 cycle, but different implementations of arbiter may behave differently)
					next_state <= INTERRUPT;
					var_interruptReq := '1';
					var_interruptDetails := interruptDetails_internal;
				end if;
			when OTHERS => -- Should not happen, but follows good coding convention
				next_state <= IDLE;	
		end case;
		end if;		   
		--next_reqUpdate <= var_reqUpdate;
        -- Immediate reqUpdate signal is needed when request is received and may be processed. 
        -- Waiting for setting it at next cycle is inefficient
        reqUpdate <= var_reqUpdate;
		
		
		next_set0 <= var_set0;	 
		next_set1 <= var_set1;
		next_FLAOut <= var_FLAOut;
		next_FSAOut <= var_FSAOut;
		next_counterOut <= var_counterOut;
		next_decrementOut <= var_decrementOut;
		next_interruptReq <= var_interruptReq;
		next_interruptDetails <= var_interruptDetails;
		next_occupied <= var_occupied;
		next_requestID0 <= var_requestID0; 
		next_requestID1 <= var_requestID1;
		
	end process;
	
	
end controller;