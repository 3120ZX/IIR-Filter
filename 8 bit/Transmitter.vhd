----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    00:27:39 01/31/2022 
-- Design Name: 
-- Module Name:    Transmitter - Behavioral 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Transmitter is
	 generic (
			  clock_ratio : integer := 833
	 );
	
    Port ( clock 						: in  STD_LOGIC;
           transmitter_input 		: in  STD_LOGIC_VECTOR (7 downto 0);
           transmitter_output 	: out  STD_LOGIC;
           filter_done_indicator : in  STD_LOGIC;
			  t_active_indicator		: out  STD_LOGIC;
			  t_done_indicator		: out  STD_LOGIC
			  );
end Transmitter;

architecture Behavioral of Transmitter is

--Declaring states of the transmitter
	type t_states is (t_idle, t_start, t_sending,t_stop ,t_clean);
	
	signal transmitter_state : t_states := t_idle;
	
	signal clock_count	 	: integer range 0 to (clock_ratio - 1) := 0;
	signal counter		: integer range 0 to 7 := 0;
	signal data_input  	: STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
	signal done_indicator: STD_LOGIC;
begin

	state_control : process(clock)
	begin
	if rising_edge(clock) then
		
		case transmitter_state is
		
			when t_idle	=>
				transmitter_output	<=	'1';
				t_active_indicator	<=	'0';
				done_indicator			<=	'0';
				clock_count				<=	0;

				
				if filter_done_indicator ='1' then
					data_input				<= transmitter_input;
					transmitter_state	<=	t_start;
				else
					transmitter_state	<= t_idle;
				end if;
				
			--Sending Start Bit
			when t_start	=>
				t_active_indicator	<=	'1';
				transmitter_output	<=	'0';
				
				if clock_count < clock_ratio - 1 then
					clock_count 			<= clock_count + 1;
					transmitter_state	<=	t_start;
				else
					clock_count <=	0;
					transmitter_state	<=	t_sending;
				end if;
			
			--Sending Data Bits
			when t_sending	=>
				transmitter_output <= data_input(counter);
				
				if (clock_count < clock_ratio - 1) then
					clock_count 		<= clock_count + 1;
					transmitter_state	<=	t_sending;
				else
					clock_count <=	0;
					if counter < 7 then 
						counter 	<=	counter + 1;
						transmitter_state	<=	t_sending;
					else
						counter <= 0;
						transmitter_state	<=	t_stop;
					end if;
				end if;
			
			--Sending Stop Bit
			when t_stop		=>
				transmitter_output 	<=	'1';
				done_indicator	<=	'0';
				if clock_count < clock_ratio - 1 then
					clock_count 		<= clock_count + 1;
					transmitter_state	<=	t_stop;
				else
					clock_count 	<=	0;
					transmitter_state	<=	t_clean;
				end if;
				
			
			
			when t_clean	=>
				t_active_indicator	<=	'0';
				done_indicator			<=	'1';
				transmitter_state	<=	t_idle;
				
		end case;
	end if;
	end process state_control;
	t_done_indicator	<= done_indicator;
	
end Behavioral;

