
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

	signal sending_fan_data:	std_logic := '0';			--high when sending data, continues to be high untill data for all 8 fans has been sent, then set to low
	signal fan_data_counter:	unsigned(7 downto 0) := (others=>'0');	--Counter for wich data is sent
	
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
	generic (
      		g_CLKS_PER_BIT : integer := 125   -- Needs to be set correctly
      	);
	port(
			i_Clk:			in std_logic;
			i_RX_Serial:		in std_logic;
			o_RX_DV:		out std_logic;				--new data available on high flank
			O_RX_Byte:		out std_logic_vector(7 downto 0)	--output data
		);
end component;

component uart_tx is
	generic (
      		g_CLKS_PER_BIT : integer := 125   -- Needs to be set correctly
      	);
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
	
	--Handles input/output logic. Sets the duty cycle of fans from the input data and sends data
	--on high flank of half_second_clock
	input_logic: process(uart_clk, half_sec_clk)
	begin

		--Sets the 'sending_fan_data' state signal to high indicating that it is time to send
		--speed data to computer
		if rising_edge(half_sec_clk) then
			sending_fan_data <= '1';
		end if;

		--Handle input/output data
		if rising_edge(uart_clk) then

			--reset process
			if (rst = '1') then
				fan_data_counter <= (others=>'0');
				sending_fan_data <= '0';
				tx_wr_enable <= '0';
				tx_data <= (others=>'0');
				fans_duty_cycle <= (others=>'0');
				half_sec_counter <= (others=>'0');
			end if;

			if rx_new_data = '1' then
				case rx_data(2 downto 0) is
					when "000" =>
						fans_duty_cycle(4 downto 0) <= rx_data(4 downto 0);
					when "001" =>
						fans_duty_cycle(9 downto 5) <= rx_data(4 downto 0);
					when "010" =>
						fans_duty_cycle(14 downto 10) <= rx_data(4 downto 0);
					when "011" =>
						fans_duty_cycle(19 downto 15) <= rx_data(4 downto 0);
					when "100" =>
						fans_duty_cycle(24 downto 20) <= rx_data(4 downto 0);
					when "101" =>
						fans_duty_cycle(29 downto 25) <= rx_data(4 downto 0);
					when "110" =>
						fans_duty_cycle(34 downto 30) <= rx_data(4 downto 0);
					when "111" =>
						fans_duty_cycle(39 downto 35) <= rx_data(4 downto 0);
					when others =>
				end case;
			end if;



			--handle output data
			if tx_active = '0' and sending_fan_data = '1' then
				case rx_data(2 downto 0) is
					when "000" =>
						tx_data <= fans_pulses_sec(7 downto 0);
					when "001" =>
						tx_data <= fans_pulses_sec(15 downto 8);
					when "010" =>
						tx_data <= fans_pulses_sec(23 downto 16);		
					when "011" =>
						tx_data <= fans_pulses_sec(31 downto 24);		
					when "100" =>
						tx_data <= fans_pulses_sec(39 downto 32);
					when "101" =>
						tx_data <= fans_pulses_sec(47 downto 40);
					when "110" =>
						tx_data <= fans_pulses_sec(55 downto 48);
					when "111" =>
						tx_data <= fans_pulses_sec(63 downto 56);
					when others =>
				end case;
				
				fan_data_counter <= fan_data_counter + 1;
				
				--if all data is sent, then reseting counter and state
				if fan_data_counter = 7 then
					fan_data_counter <= (others=>'0');
					sending_fan_data <= '0';
				end if;
				
			end if;
		end if;
	end process;			

	--Process block handles clk divider logic
	clk_divider: process(clk)
	begin
		if rising_edge(clk) then
			
			--reset process
			if rst = '1' then
				uart_clk_counter <= (others=>'0');
				half_sec_counter <= (others=>'0');
			end if;

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