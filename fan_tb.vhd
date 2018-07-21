library ieee;
use ieee.std_logic_1164.all;

entity fan_tb is
end fan_tb;

architecture behave of fan_tb is
	signal i_clk: 		std_logic := '0';
	signal i_rst: 		std_logic := '0';
	signal i_half_sec_clk: 	std_logic := '0';
	signal i_tacho:		std_logic := '0';
	signal i_duty_cycle:	std_logic_vector(4 downto 0) := "01010";

	signal o_pwm_signal:	std_logic := '0';
	signal o_pulses_sec:	std_logic_vector(7 downto 0) := (others=>'0');

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
	clk_gen(i_clk, 500000.000);
	clk_gen(i_half_sec_clk, 2.000);
	clk_gen(i_tacho, 14.000);

	-- Time resolution show
  	assert FALSE report "Time resolution: " & time'image(time'succ(0 fs)) severity NOTE;

	fan_1: fan
		port map(
			clk => i_clk,
			rst => i_rst,
			half_sec_clk => i_half_sec_clk,
			tacho => i_tacho,
			duty_cycle => i_duty_cycle,
			pwm_signal => o_pwm_signal,
			pulses_sec => o_pulses_sec
			);

	process is
	begin
	wait for 1 ms;
	i_duty_cycle <= "00101";
	wait for 1 ms;
		

	end process;
end behave;
