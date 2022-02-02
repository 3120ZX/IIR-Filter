----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:46:57 01/10/2022 
-- Design Name: 
-- Module Name:    Receiver - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Receiver is
	generic (
	clock_ratio : integer := 833
	);
	
    Port ( clock : in  STD_LOGIC;
--          reset : in  STD_LOGIC;
           receiver_data_in : in  STD_LOGIC;
           receiver_data_out : out  STD_LOGIC_VECTOR (7 downto 0);
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
	signal data_counter : integer range 0 to 7 := 0;
	signal data_output  : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
		
begin

-- Reset button process function
--process(clock,reset)
--	Begin
--		if rising_edge(clock) then
--			if(reset='1') then
--				ready_indicator 			<= '1';
--				data_output		   		<= "00000000";
--			end if;
--		end if;
--	end process;
	
	
-- Input data into temporary memory(data_input_temp) -> data_input
-- Purpose: Double-register the incoming data.
-- This allows it to be used in the UART RX Clock Domain.
-- (It removes problems caused by metastability)
	data_storing : process(clock)
	Begin
		if rising_edge(clock) then 
			data_input_temp <= receiver_data_in;
			data_input		 <= data_input_temp;
--			data_input		 <= receiver_data_in;
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
					data_counter 				<= 0;
					receiver_done_indicator <= '0';
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
					receiver_done_indicator <= '0';
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
						clock_count 				  <= 0;
						data_output(data_counter) <= data_input;
					--Check if all bits have been sent
						if data_counter <7 then
							data_counter 	<= data_counter + 1;
							receiver_state	<= r_receiving;
						else 
							data_counter <= 0;
							receiver_state <= r_stop;
						--Done sending all bits
							receiver_done_indicator <='1';
						end if;
					end if;
					
				when r_stop =>
					receiver_done_indicator <='0';
					ready_indicator <= '0';	
					if clock_count < (clock_ratio - 1) then
						clock_count 	<= (clock_count + 1); 
						receiver_state <= r_stop;
					else 
						clock_count <= 0;
						receiver_state <= r_clean;
					end if;

						
				when r_clean =>
					receiver_state 			<= r_idle;
					receiver_done_indicator <= '1';
					ready_indicator 			<= '1';
--					data_input					<= '1';
--					receiver_data_in			<= '1';
					data_output		 			<= "00000000";
					
				when others =>
					receiver_state <= r_idle;
					receiver_done_indicator <='0';
					ready_indicator <= '1';
					
			end case;
		end if;
	end process state_control;	
	
	receiver_data_out <= data_output;
	
end Behavioral;

