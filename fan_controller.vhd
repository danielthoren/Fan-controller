
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fan_controller is
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
end fan_controller;

architecture behave of fan_controller is

	signal uart_clk:		std_logic;		--clock for uart logic (6MHz / 5 = 1.2MHz)
	signal uart_clk_counter:	unsigned(2 downto 0);	--counter for uart divider
	signal half_sec_clk:		std_logic;		--clock with half sec period (2Hz)
	signal half_sec_counter:	unsigned(20 downto 0);	--counter for clock divider

	signal fans_pwm:		std_logic_vector(7 downto 0);	--internal fans pwm output signal
	signal fans_duty_cycle:		std_logic_vector(39 downto 0);	--internal fans duty cycle register (5 bits per fan, decimal value 0-21 representing 0-100%)
	signal fans_pulses_sec:		std_logic_vector(63 downto 0);	--internal fans speed in rotations per seconds

component fan is
	port(
			clk: 			in std_logic;				--clock must be 500kHz for correct pwm frequency (25kHz)
			rst: 			in std_logic;				--Reset
			half_sec_clk: 		in std_logic;				--Clock with 2Hz rate (high flank every 0.5 seconds). Used to measure speed
			tacho: 			in std_logic;				--Tachometer input
			duty_cycle: 		in std_logic_vector(4 downto 0);	--Dutycycle of pwm, decimal value between 0 and 20 (unsigned)

			pwm_signal: 		out std_logic;				--PWM output
			pulses_sec: 		out std_logic_vector(7 downto 0)	--Pulses per second, used to calculate fan speed (RPM = pulses_sec * 60)
		);
end component;
	

begin

	--declaring all fans
	fan_0: fan
		port map(
			clk => clk,
			rst => rst,
			half_sec_clk => half_sec_clk,
			tacho => i_fans_tacho(0),
			duty_cycle => fans_duty_cycle(4 downto 0),
			pwm_signal => o_fans_pwm_sig(0),
			pulses_sec => fans_pulses_sec(7 downto 0)
			);

	--Process block handles clk divider logic
	clk_divider: process(clk)
	begin
		if rising_edge(clk) then
			uart_clk_counter <= uart_clk_counter + 1;
			if uart_clk_counter = 5 then
				uart_clk_counter <= (others=>'0');	--incrementing uart counter
				if uart_clk = '0' then
					uart_clk <= '1';
					half_sec_counter <= half_sec_counter + 1;	--incrementing half sec divider on high flank of uart_clk (saving registers)
				else
					uart_clk <= '0';
					
				end if;
			end if;

		end if;
	end process;

	

	

end behave;