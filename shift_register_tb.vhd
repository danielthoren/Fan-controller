library ieee;
use ieee.std_logic_1164.all;

entity shift_register_tb is
end shift_register_tb;

architecture behave of shift_register_tb is

	-- Procedure for clock generation
  	procedure clk_gen(signal clk : out std_logic; constant FREQ : real) is
    		constant PERIOD    : time := 1 sec / FREQ;        -- Full period
    		constant HIGH_TIME : time := PERIOD / 2;          -- High time
    		constant LOW_TIME  : time := PERIOD - HIGH_TIME;  -- Low time; always >= HIGH_TIME
  	begin
    		-- Check the arguments
    		assert (HIGH_TIME /= 0 fs) report "clk_plain: High time is zero; time resolution to large for frequency" severity FAILURE;
    		-- Generate a clock cycle
    		loop
      			clk <= '1';
      			wait for HIGH_TIME;
      			clk <= '0';
      			wait for LOW_TIME;
    		end loop;
  	end procedure clk_gen;

	signal i_shift:		std_logic := '0';
	signal i_shift_in:	std_logic := '0';
	signal i_write_enable:	std_logic := '0';
	signal i_clk:		std_logic := '0';
	signal i_rst:		std_logic := '0';
	signal i_data_in:	std_logic_vector(7 downto 0);
		
	signal i_data_out:	std_logic_vector(7 downto 0);
	signal i_shift_out:	std_logic;

component shift_register is
    Port ( 	shift:		in std_logic;			--Shift register if high (not synchronized)
		shift_in:	in std_logic;			--Data that is shifted in
		write_enable:	in std_logic;			--writes 'data_in' to 'shift_reg' when high
           	clk: 		in std_logic;
		rst:		in std_logic;
	   	data_in:	in std_logic_vector(7 downto 0);

           	data_out: 	out std_logic_vector(7 downto 0);
		shift_out:	out std_logic);
end component;

begin
	clk_gen(i_clk, 76800.000); --baud rate of 9600 -> clk = 8 * 9600


	-- Time resolution show
  	assert FALSE report "Time resolution: " & time'image(time'succ(0 fs)) severity NOTE;

	
	reg: shift_register
		port map(
			shift => i_shift,
			shift_in => i_shift_in,
			clk => i_clk,
			rst => i_rst,
			data_in => i_data_in,
			data_out => i_data_out,
			shift_out => i_shift_out,
			write_enable => i_write_enable
			);

	process is
	begin
		--First test if write enable works by writing value to data_in and
		--setting write_enable = '0'
		i_data_in <= "10101010";
		i_write_enable <= '0';
		i_rst <= '0';
		i_shift <= '1';
		i_shift_in <= '0';
		wait for 10ns;
	
		--write data ro in register
		i_write_enable <= '1';
		wait for 1ns;		
		i_write_enable <= '0';

		wait for 5ns;
		i_shift_in <= '1';
		wait for 5ns;
		i_shift_in <= '0';

		wait for 5ns;
		i_rst <= '1';
		wait for 5ns;
	end process;
end behave;


			




















			