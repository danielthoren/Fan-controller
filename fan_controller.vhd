
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

	--Clock signals and dividers
	signal uart_clk:		std_logic;		--clock for uart logic (6MHz / 5 = 1.2MHz -> 125 clocks per bit at 9600bps)
	signal uart_clk_counter:	unsigned(2 downto 0);	--counter for uart divider
	signal half_sec_clk:		std_logic;		--clock with half sec period (2Hz)
	signal half_sec_counter:	unsigned(20 downto 0);	--counter for clock divider

	--uart signals
	signal rx_new_data:		std_logic;			--new data available on high flank
	signal rx_data:			std_logic_vector(7 downto 0);	--data recieved

	signal tx_wr_enable:		std_logic;			--tx_write_enable, write data to tx_data when high
	signal tx_data:			std_logic_vector(7 downto 0);	--data to be sent
	signal tx_active:		std_logic;			--high when transmission in progress
	signal tx_done:			std_logic;			--driven high when transmission complete

	--fan signals
	signal fans_pwm:		std_logic_vector(7 downto 0);	--internal fans pwm output signal
	signal fans_duty_cycle:		std_logic_vector(39 downto 0);	--internal fans duty cycle register (5 bits per fan, decimal value 0-21 representing 0-100%)
	signal fans_pulses_sec:		std_logic_vector(63 downto 0);	--internal fans speed in rotations per seconds

component uart_rx is
	port(
			i_Clk:			in std_logic;
			i_RX_Serial:		in std_logic;
			o_RX_DV:		out std_logic;				--new data available on high flank
			O_RX_Byte:		out std_logic_vector(7 downto 0)	--output data
		);
end component;

component uart_tx is
	port(
			i_Clk:			in std_logic;
			i_TX_DV:		in std_logic;				--write enable, write new data to out reg if high
			i_TX_Byte:		in std_logic_vector(7 downto 0);	--output data
			o_TX_Active:		out std_logic;				--High if transmitting
			o_TX_Serial:		out std_logic;				--output signal
			o_TX_Done:		out std_logic				--Driven high when transmit complete, ready to write new value to data reg
		);
end component;

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

	uart_rx_instance: uart_rx
		port map(
			i_Clk => uart_clk,
			i_RX_Serial => i_rx_serial,
			o_RX_DV	=> rx_new_data,
			o_RX_Byte => rx_data
			);

	uart_tx_instance: uart_tx
		port map(
			i_Clk => uart_clk,
			i_TX_DV => tx_wr_enable,
			i_tx_Byte => tx_data,
			o_TX_Active => tx_active,
			o_TX_Serial => o_tx_serial,
			o_TX_Done => tx_done
			);

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