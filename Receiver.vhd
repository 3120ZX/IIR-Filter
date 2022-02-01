library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Receiver is
	generic (
	clock_ratio : integer := 833
	);
	
    Port ( clock : in  STD_LOGIC;
--         reset : in  STD_LOGIC;
           receiver_data_in : in  STD_LOGIC;
           receiver_data_out : out  STD_LOGIC_VECTOR (15 downto 0);
			  receiver_done_indicator: out STD_LOGIC);
end Receiver;

architecture Behavioral of Receiver is

--Declaring states of the recievers
	type r_states is (r_idle, r_start, r_receiving, 
							r_stop, r_clean);

--Declaring signals
	signal receiver_state : r_states := r_idle;
	
	signal data_input_temp	: STD_LOGIC := '1';
	signal data_input 		: STD_LOGIC := '1';
	signal ready_indicator	: STD_LOGIC := '1';

	signal clock_count  : integer range 0 to (clock_ratio - 1) := 0;
	signal data_counter : integer range 0 to 15 := 0;
	signal data_counter_2 : integer range 0 to 7 := 0;
	signal data_output_1  : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
	signal data_output_2  : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
	signal r_done_indicator : std_logic := '0';
begin

-- Reset button process function
--reset_proc : process(clock,reset)
--	Begin
--		if rising_edge(clock)
--			if(reset='1') then
--				ready_indicator 			<= '1';
--				data_output		   		<= "00000000";
--			end if;
--		end if;
--	end process reset_proc;
	
	
-- Input data into temporary memory(data_input_temp) -> data_input
-- Purpose: Double-register the incoming data.
-- This allows it to be used in the UART RX Clock Domain.
-- (It removes problems caused by metastability)
	data_storing : process(clock)
	Begin
		if rising_edge(clock) then 
			data_input_temp <= receiver_data_in;
			data_input		 <= data_input_temp;
		end if;
	end process data_storing;
	
	
--State control
	state_control : process(clock)
	Begin
		if rising_edge(clock) then
			
			case receiver_state is
			
			--Case when idle
				when r_idle =>
					clock_count  				<= 0;
					r_done_indicator <= '0';
					ready_indicator 			<= '1';
				--Detecting start-bit
					if data_input <= '0' then
						receiver_state <= r_start;
					else
						receiver_state <= r_idle;
					end if;
			
			--Case when start
				when r_start =>
					ready_indicator <= '0';
					r_done_indicator <= '0';
				--Check middle of start bit to make sure it's still low
					if clock_count = ((clock_ratio-1)/2) then
						if data_input <= '0'	then
						-- reset counter since we found the middle
							clock_count 	<= 0; 
							receiver_state <= r_receiving;
						else
							receiver_state <= r_idle;
						end if;
					else
						clock_count <= clock_count + 1;
						receiver_state <= r_start;
					end if;
					
			--Wait (clock_ratio - 1) clock cycle to sample serial data
				when r_receiving =>
					ready_indicator <= '0';	
					if clock_count 	< (clock_ratio-1) then 
							clock_count 	<= (clock_count + 1);
							receiver_state <= r_receiving;
					else
						if data_counter < 8	then								
							clock_count 				  <= 0;
							data_output_1(data_counter) <= data_input;
						--Check if all bits have been sent
							if data_counter < 7 then
								data_counter 	<= data_counter + 1;
								receiver_state	<= r_receiving;
							else 
								receiver_state <= r_stop;
								data_counter 	<= data_counter + 1;
							--Done sending all bits
								r_done_indicator <='0';
							end if;
						elsif data_counter > 7 then
							clock_count 						<= 0;
							data_output_2(data_counter_2) <= data_input;
						--Check if all bits have been sent
							if data_counter < 15 then
								data_counter 	<= data_counter + 1;
								data_counter_2 <= data_counter_2 + 1;
								receiver_state	<= r_receiving;
							else
								receiver_state <= r_stop;
								r_done_indicator <='1';
							end if;
						end if;
					end if;

				when r_stop =>
					r_done_indicator <='0';
					ready_indicator <= '0';	
					if clock_count < (clock_ratio - 1) then
						clock_count 	<= (clock_count + 1); 
						receiver_state <= r_stop;
					else 
						if data_counter < 15 then
							clock_count <= 0;
							receiver_state <= r_idle;
						else
							clock_count <= 0;
							receiver_state <= r_clean;
						end if;
					end if;


				when r_clean =>
					receiver_state 			<= r_idle;
					r_done_indicator 			<= '0';
					ready_indicator 			<= '1';
					data_counter 	<= 0;
					data_counter_2 <= 0;
					data_output_1		 			<= "00000000";
					data_output_2		 			<= "00000000";
				
				when others =>
					receiver_state <= r_idle;
					r_done_indicator <='0';
					ready_indicator <= '1';
					
			end case;
		end if;
	end process state_control;	
	
	receiver_done_indicator <= r_done_indicator;
	receiver_data_out <= data_output_2 & data_output_1;
	
end Behavioral;

