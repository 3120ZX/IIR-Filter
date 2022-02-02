library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Filter is
    Port ( clock : in  STD_LOGIC;
	   reset : in  STD_LOGIC;
           filter_input : in  STD_LOGIC_VECTOR (15 downto 0);
           filter_output : out  STD_LOGIC_VECTOR (15 downto 0);
	   filter_done_indicator : out  STD_LOGIC;
           receiver_done_indicator : in  STD_LOGIC);
end Filter;

architecture Behavioral of Filter is

--Declaring Signal & Coefficients
	
	--Coefficients
	constant s1  : signed(15 downto 0) :="0011110101100011";
	constant cb2 : signed(15 downto 0) :="1000000000000000";
	constant ca2 : signed(15 downto 0) :="1000010101010101";
	constant ca3 : signed(15 downto 0) :="0011101011100010"; 
	
	--Signal for system
	signal data_input  	: signed(15 downto 0):=(others => '0');
	signal delay1			: signed(15 downto 0):=(others => '0');
	signal delay2			: signed(15 downto 0):=(others => '0');
	signal data_output 	: signed(15 downto 0):=(others => '0');
	signal f_done_indicator : STD_LOGIC :='0';
	signal c_done_indicator : STD_LOGIC :='0';
	
	--Signals for multiplier and adders
	signal suma2  : signed(15 downto 0):=(others => '0'); 
	signal suma3  : signed(15 downto 0):=(others => '0');
	signal sumb2  : signed(15 downto 0):=(others => '0');
	signal sumb3  : signed(15 downto 0):=(others => '0');
	signal mults1 : signed(15 downto 0):=(others => '0');
	signal multa2 : signed(15 downto 0):=(others => '0');
	signal multa3 : signed(15 downto 0):=(others => '0');
	signal multb2 : signed(15 downto 0):=(others => '0');
	
	--Temporary Signals to prevent overflow
	signal tsuma2  : signed(15 downto 0):=(others => '0');
	signal tsuma3  : signed(15 downto 0):=(others => '0');
	signal tsumb2  : signed(15 downto 0):=(others => '0');
	signal tsumb3  : signed(15 downto 0):=(others => '0');
	signal tmults1 : signed(31 downto 0):=(others => '0');
	signal tmulta2 : signed(31 downto 0):=(others => '0');
	signal tmulta3 : signed(31 downto 0):=(others => '0');
	signal tmultb2 : signed(31 downto 0):=(others => '0');
	
	
	--Procedure for adder
	procedure temp_adder (	signal TA_A : in signed(15 downto 0);	--First Number
									signal TA_B : in signed(15 downto 0);	--Second Number
									signal TA_C : inout signed(15 downto 0)--Temporary Signals
								 ) is
	begin
		TA_C <= TA_A + TA_B;
	end temp_adder;
	
	--Procedure for Adder overflow checking
	procedure adder (	signal A_A : in signed(15 downto 0);	--First Number
							signal A_B : in signed(15 downto 0);	--Second Number
							signal A_C : inout signed(15 downto 0);	--Temporary Signals
							signal A_D: out signed(15 downto 0)	--Results
							) is     
	begin
		--If positive + positive = negative
		if (A_A(15)= '0' and A_B(15)= '0' and A_C(15)= '1') then
			A_D <= "0111111111111111";
		--If negative + negative = positive
		elsif (A_A(15)= '1' and A_B(15)= '1' and A_C(15)= '0') then
			A_D <= "1000000000000000";
		--else results = temporary signals
		else
			A_D <= A_C;
		end if;
	end adder;
	
	--Procedure for Subtractor	
	procedure temp_subtractor (	signal TS_A : in signed(15 downto 0);	--First Number
											signal TS_B : in signed(15 downto 0);	--Second Number
											signal TS_C : inout signed(15 downto 0)--Temporary Signals
										) is
	begin
		TS_C <= TS_A + TS_B;
	end temp_subtractor;
	
	--Procedure for Subtractor overflow checking
	procedure subtractor(	signal S_A : in signed(15 downto 0);	--First Number
									signal S_B : in signed(15 downto 0);	--Second Number
									signal S_C: inout signed(15 downto 0);	--Temporary Signals
									signal S_D: out signed(15 downto 0)	--Results
									) is     
	begin
		--If positive - negative = negative
		if ((S_A(15)= '0' and S_B(15)= '1' and S_C(15)= '1')) then
			S_D <= "0111111111111111";
		--If negative - positive = positive
		elsif (S_A(15)= '1' and S_B(15)= '0' and S_C(15)= '0') then
			S_D <= "1000000000000000";
		--else results = temporary signals
		else
			S_D <= S_C;
		end if;
	end subtractor;
	
	--Procedure for Multiplier
	procedure temp_multiplier (	signal 	TM_A : in  signed(15 downto 0);	--First Number
											constant TM_B : in  signed(15 downto 0);	--Second Number
											signal 	TM_C : inout signed(31 downto 0)--Temporary Signals
										) is
	begin
		TM_C <= TM_A * TM_B;
	end temp_multiplier;
	
	--Procedure for Multiplier overflow checking
	procedure multiplier	(	signal 	M_A : in  signed(15 downto 0);	--First Number
									constant M_B : in  signed(15 downto 0);	--Second Number
									signal 	M_C : inout signed(31 downto 0);--Temporary Signals
									signal 	M_D : out signed(15 downto 0)	--Results
									) is     
	begin

		--If -1 x -1 = 0.9...... (because 1 is not available)
		if (M_A = "1111111111111111" and M_B = "1111111111111111") then
			M_D <= "0111111111111111";
		--else results = temporary signals
		else
			M_D <= M_C (30 downto 15);
		end if;
	end multiplier;
		
	
begin
	process(clock,reset) is
		
		
	begin
		if reset ='1' then
			data_input 	<=	"0000000000000000";
		elsif rising_edge(clock) then
			if receiver_done_indicator	= '1' then
				data_input	<=	signed(filter_input);
				temp_multiplier(data_input,s1,tmults1);
				multiplier(data_input,s1,tmults1,mults1);
				temp_subtractor(mults1,multa2,tsuma2);
				subtractor(mults1,multa2,tsuma2,suma2);
				temp_subtractor(suma2,multa3,tsuma3);
				subtractor(suma2,multa3,tsuma3,suma3);
				delay1 <= suma3;
				temp_multiplier(delay1,ca2,tmulta2);
				multiplier(delay1,ca2,tmulta2,multa2);
				temp_multiplier(delay1,cb2,tmultb2);
				multiplier(delay1,cb2,tmultb2,multb2);
				temp_adder(delay1,multb2,tsumb2);
				adder(delay1,multb2,tsumb2,sumb2);
				delay2 <= delay1;
				temp_multiplier(delay2,ca3,tmulta3);
				multiplier(delay2,ca3,tmulta3,multa3);
				temp_adder(sumb2,delay2,tsumb3);
				adder(sumb2,delay2,tsumb3,sumb3);	
				c_done_indicator <= '1';
			else 
				c_done_indicator <= '0';
			end if;
		end if;
	end process;
	
	process(clock) is
	begin
		if rising_edge(clock) then
			f_done_indicator <=c_done_indicator;
			if (c_done_indicator = '1')then
				data_output  <= sumb3;
			end if;
		end if;
	end process;

filter_done_indicator <= f_done_indicator;		
filter_output <= STD_LOGIC_VECTOR(data_output);
end Behavioral;

