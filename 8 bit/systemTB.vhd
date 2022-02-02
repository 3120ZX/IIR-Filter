----------------------------------------------------------------------------------
-- Company:
-- Engineer: Edaurdo Trevis Angky
-- 
-- Create Date: 
-- Design Name: 	Highpass IIR Filter
-- Module Name:   system - Behavioral 
-- Project Name: 	UAS Semester 3 (B2024) Binus ASO
-- Target Devices: CPLD CoolRunner-2 XC2C256
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
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
USE ieee.numeric_std.ALL;
 
ENTITY systemTB IS
END systemTB;
 
ARCHITECTURE behavior OF systemTB IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT system
    PORT(
         clock : IN  std_logic;
         reset : IN  std_logic;
         system_input : IN  std_logic;
         system_output : OUT  std_logic;
         t_done_indicator : OUT  std_logic;
         t_active_indicator : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clock : std_logic := '0';
   signal reset : std_logic := '0';
   signal system_input : std_logic := '1';

 	--Outputs
   signal system_output : std_logic;
   signal t_done_indicator : std_logic;
   signal t_active_indicator : std_logic;

   -- Clock period definitions
   constant clock_period : time := 125 ns;
   constant baud_period : time :=  104.67 us; 
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: system PORT MAP (
          clock => clock,
          reset => reset,
          system_input => system_input,
          system_output => system_output,
          t_done_indicator => t_done_indicator,
          t_active_indicator => t_active_indicator
        );

   -- Clock process definitions
   clock_process :process
   begin
		clock <= '0';
		wait for clock_period/2;
		clock <= '1';
		wait for clock_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      wait for baud_period ;
      -- insert stimulus here 
	for i in 1 to 100 loop
	--Start bit
		system_input <= '0';
		wait for baud_period ;
		
	--Data bits
-- 8 bits		
		system_input <= '0';
		wait for baud_period ;

		system_input <= '0';
		wait for baud_period;
		
		system_input <= '0';
		wait for baud_period;
		
		system_input <= '0';
		wait for baud_period;
		
		system_input <= '0';
		wait for baud_period;
		
		system_input <= '1';
		wait for baud_period;
		
		system_input <= '0';
		wait for baud_period;
		
		system_input <= '0';
		wait for baud_period;

--Stop bit	
		system_input <= '1';
		wait for baud_period;
	end loop;

      wait;
   end process;

END;
