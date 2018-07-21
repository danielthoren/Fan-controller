
----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:51:58 07/13/2018 
-- Design Name: 
-- Module Name:    fan - Behavioral 
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
use IEEE.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity fan is
	port(
			clk: 			in std_logic;				--clock must be 500kHz for correct pwm frequency (25kHz)
			rst: 			in std_logic;				--Reset
			half_sec_clk: 		in std_logic;				--Clock with 2Hz rate (high flank every 0.5 seconds). Used to measure speed
			tacho: 			in std_logic;				--Tachometer input
			duty_cycle: 		in std_logic_vector(4 downto 0);	--Dutycycle of pwm, decimal value between 0 and 20 (unsigned)

			pwm_signal: 		out std_logic;				--PWM output
			pulses_sec: 		out std_logic_vector(7 downto 0)	--Pulses per second, used to calculate fan speed (RPM = pulses_sec * 60)
		);
end fan;

architecture Behavioral of fan is

signal pwm_counter: 	unsigned(4 downto 0) := (others=>'0');	--Used for PWM output, counts to 20 then restarts
signal pin_4: 		std_logic := '0';			--True if the connected fan is of 4-pin type

signal tacho_counter: 	unsigned(7 downto 0) := (others=>'0');	--Counts amount of pulses from fan tachometer during halv a second

begin

--Process block that measures the amount of times the tachometer pulses during a second. Since there are two pulses per
--revolution it is enough to measure a halv second (0.5) and use measured value as rotations per whole second. 
--This is used to calculate the speed of the fan in RPM on the computer side. 
--@clk: The clocksignal driving the reset functionality
--@half_sec_clk: The clock at which the counter value is written to the output 'pulses_sec' (half a second)
--@rst: Resets the count
--@tacho: The tachometer signal (square wave)
--@tacho_counter: The counter that counts the tacho pulses
tacho_count: process(clk, half_sec_clk, rst, tacho, tacho_counter)
begin
	if rising_edge(clk) then
		if rst = '1' then
			tacho_counter <= (others=>'0');
			pulses_sec <= (others=>'0');
		end if;
	end if;

	--Not synchronized using 'clk' since 'half_sec_clk' is synchronized already
	if rising_edge(half_sec_clk) then
		pulses_sec <= std_logic_vector(tacho_counter);
		tacho_counter <= (others=>'0');
	elsif rising_edge(tacho) then
		tacho_counter <= tacho_counter + 1;
	end if;
end process;

--Process block that generates the PWM output.
--@clk: The clocksignal driving the pwm generator process. It must be (25 * 20)kHz (+- 3kHz) thus generating a
--			 PWM frequency of between 21kHz and 28kHz.
--@rst: Resets pwm driver.
--@pwm_counter: 5-bit counter used to generate pwm signal.
--@duty_cycle: 5-bit 'std_logic_vector' holding a binary value between 0 and 20 (unsigned value)
pwm: process(clk, rst, pwm_counter, duty_cycle)
begin
	if rising_edge(clk) then
		pwm_counter <= pwm_counter + 1;
		--Reset if sig 'rst' goes high
		if rst = '1' then
			pwm_counter <= (others=>'0');
			pwm_signal <= '0';
		end if;
		
		if pwm_counter = unsigned(duty_cycle) then
			pwm_signal <= '1';
		end if;
			
		if pwm_counter = "10100" then 
			pwm_signal <= '0';
			pwm_counter <= (others=>'0');
		end if;
	
	end if;	
end process;
end Behavioral;
