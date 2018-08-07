
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fan_controller is
	port(
			clk: 		in std_logic;		--6MHz clock
			rst:		in std_logic;
			
			--Fan io section
			tacho:			in std_logic_vector(7 downto 0);	--tachometer input from all 8 fans
			pwm_sig:		out std_logic_vector(7 downto 0);	--pwm output for all 8 fans

			--Uart io
			i_rx_serial:		in std_logic;
			o_tx_serial:		out std_logic
		);
end fan_controller;

architecture behave of fan_controller is

	--