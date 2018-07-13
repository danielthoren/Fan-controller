
----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:51:58 07/13/2018 
-- Design Name: 
-- Module Name:    pwm - Behavioral 
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
use IEEE.std_logic_unsigned.all;
use IEEE.NUMERIC_STD.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity pwm is
	port(
			clk: in std_logic;
			duty_cycle: in std_logic_vector(4 downto 0);
			pwm_signal: out std_logic);
end pwm;

architecture Behavioral of pwm is

signal counter: unsigned(4 downto 0) := "00000";
begin

dutycycleCount:process(clk)
begin
	
	if rising_edge(clk) then
		counter <= counter + 1;
		if counter > unsigned(duty_cycle) then
			pwm_signal <= '1';
		end if;
			
		if counter = "10100" then 
			pwm_signal <= '0';
			counter <= "00000";
		end if;
	
	end if;	
end process;
end Behavioral;
