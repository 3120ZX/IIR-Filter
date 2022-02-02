----------------------------------------------------------------------------------
-- Company:
-- Engineer: Eduardo Trevis Angky
-- 
-- Create Date: 
-- Design Name: 	Highpass IIR Filter
-- Module Name:   System - Behavioral 
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
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity System is
	port(
		clock					:in STD_LOGIC;
		reset					:in STD_LOGIC;
		system_input		:in STD_LOGIC;
		system_output		:out STD_LOGIC;
		t_done_indicator	:out STD_LOGIC;
		t_active_indicator:out STD_LOGIC
	);
end System;

architecture Behavioral of System is

--Declaring Components

--Receiver
component Receiver is
	generic (
		clock_ratio : integer := 833
	);
	
	Port ( 
		clock 						: in  STD_LOGIC;
		receiver_data_in 			: in  STD_LOGIC;
		receiver_data_out 		: out  STD_LOGIC_VECTOR (15 downto 0);
		receiver_done_indicator	: out STD_LOGIC
	);
	
end component;

--Filter
component Filter is
	Port ( 
		clock 						: in  STD_LOGIC;
		reset 						: in  STD_LOGIC;
		filter_input				: in  STD_LOGIC_VECTOR (15 downto 0);
		filter_output 				: out  STD_LOGIC_VECTOR (15 downto 0);
		filter_done_indicator 	: out  STD_LOGIC;
		receiver_done_indicator : in  STD_LOGIC
	);
end component;

--Transmitter
component Transmitter is
	generic (
		clock_ratio : integer := 833
	);
	
    Port (
		clock 						: in  STD_LOGIC;
		transmitter_input 		: in  STD_LOGIC_VECTOR (15 downto 0);
		transmitter_output 		: out  STD_LOGIC;
		filter_done_indicator	: in  STD_LOGIC;
		t_active_indicator		: out  STD_LOGIC;
		t_done_indicator			: out  STD_LOGIC
	);
end component;

--Declaring signals to connects each of component's port
	signal r_done_indicator	:	STD_LOGIC;
	signal f_done_indicator	:	STD_LOGIC;
	signal receiver_output	:	STD_LOGIC_VECTOR(15 downto 0);
	signal filter_output		:	STD_LOGIC_VECTOR(15 downto 0);

begin

	RX_UART		:	Receiver
	port map(
		clock 						=> clock,
		receiver_data_in 			=>	system_input,
		receiver_data_out 		=> receiver_output,
		receiver_done_indicator	=>	r_done_indicator
	);

	IIR_Filter	:	Filter
	Port map( 
		clock 						=>	clock,
		reset 						=>	reset,
		filter_input				=>	receiver_output,
		filter_output 				=>	filter_output,
		filter_done_indicator 	=>	f_done_indicator,
		receiver_done_indicator =>	r_done_indicator
	);
	
	TX_UART		:	Transmitter
	Port map(
		clock 						=>	clock,
		transmitter_input 		=>	filter_output,
		transmitter_output 		=>	system_output,
		filter_done_indicator	=>	f_done_indicator,
		t_active_indicator		=>	t_active_indicator,
		t_done_indicator			=>	t_done_indicator
	);
	
end Behavioral;

