library ieee;
use ieee.std_logic_1164.all;

entity fan_controller_tb is
end fan_controller_tb;

architecture behave of fan_controller_tb is

  	-- Test Bench uses a 12 00 00000 Hz Clock
  	-- Want to interface to 9600 baud UART
  	-- 1200 000 / 9600 = 125 Clocks Per Bit.al
  	constant c_CLKS_PER_BIT : integer := 125;
 
  	constant c_BIT_PERIOD : time := 104166 ns;

	signal tb_clk:			std_logic;
	signal tb_rst:			std_logic := '0';
	signal tb_i_fans_tacho:		std_logic_vector(7 downto 0) := (others=>'0');
	signal tb_o_fans_pwm_sig:	std_logic_vector(7 downto 0) := (others=>'0');
	signal tb_o_serial:		std_logic := '1';
	signal tb_i_serial:		std_logic;

	--fan input
	signal tb_fans_tacho:		std_logic_vector(7 downto 0);
	signal tb_rx_serial:		std_logic;

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

  	-- Low-level byte-write
  	procedure UART_WRITE_BYTE (
  	  i_data_in       : in  std_logic_vector(7 downto 0);
  	  signal o_serial : out std_logic) is
  	begin
 	
  	  -- Send Start Bit
  	  o_serial <= '0';
  	  wait for c_BIT_PERIOD;
 	
  	  -- Send Data Byte
  	  for ii in 0 to 7 loop
  	    o_serial <= i_data_in(ii);
  	    wait for c_BIT_PERIOD;
  	  end loop;  -- ii
 	
  	  -- Send Stop Bit
  	  o_serial <= '1';
  	  wait for c_BIT_PERIOD;
  	end UART_WRITE_BYTE;

	component fan_controller is
		port(
			clk: 		in std_logic;		--6MHz clock
			rst:		in std_logic;
			
			--Fan io section
			i_fans_tacho:		in std_logic_vector(7 downto 0);	--tachometer input from all 8 fans
			o_fans_pwm_sig:		out std_logic_vector(7 downto 0);	--pwm output for all 8 fans

			--Uart io
			i_rx_serial:		in std_logic;
			o_tx_serial:		out std_logic
		);
	end component;

begin

	clk_gen(tb_clk, 1200000.000);

	--fans tacho speed
	clk_gen(tb_fans_tacho(0), 14.000);
	clk_gen(tb_fans_tacho(1), 12.000);

	fan_controller1: fan_controller
		port map(
				clk => tb_clk,
				rst => tb_rst,
				i_fans_tacho => tb_i_fans_tacho,
				o_fans_pwm_sig => tb_o_fans_pwm_sig,
				i_rx_serial => tb_o_serial,
				o_tx_serial => tb_i_serial
			);

	process is
	begin

		wait for c_BIT_PERIOD;
		uart_write_byte("00001010", tb_o_serial);

  		--assert false report "Tests Complete" severity failure;

	end process;
end behave;
