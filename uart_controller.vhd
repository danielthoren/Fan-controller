
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity uart_reciever is
	port(
		clk:		in std_logic;				--Clock at 8 times the baud rate
		rst:		in std_logic;				--reset, active high
		data_in:	in std_logic_vector(7 downto 0);	--data to be sent

		data_recieved:	out std_logic;				--Signaling that a byte of data has been recieved, active high
		ready_to_send:	out std_logic;				--Signaling that a new byte may be sent
		data_out:	out std_logic_vector(7 downto 0);	--data received

		--Physical input ports (UART interface)
		rx:		in std_logic;				--Recieving line
		cts:		in std_logic;				--'Clear to send' handshake signal	
		
		--Physical output ports (UART interface)
		rts:		out std_logic;				--'Request to send' handshake signal
		tx:		out std_logic				--Trancieving line
	);
end uart_reciever;

architecture behave of uart_reciever is

signal baud_counter:	unsigned(2 downto 0) := (others=>'0');
signal byte_counter:	unsigned(2 downto 0) := (others=>'0');
signal baud_clock:	std_logic := 0;

signal sampled_input:	std_logic := '1';
signal recieving:	std_logic := '0';
signal shift_in:	std_logic := '0';
signal wr_in:		std_logic := '0';
signal in_reg_data:	std_logic_vector(7 downto 0) := (others=>'0');

signal transmitting:	std_logic := '0';
signal wr_out:		std_logic :='0';
signal out_reg_data:	std_logic_vector(7 downto 0) := (others=>'0');

signal data_out_int:	std_logic_vector(7 downto 0) := (others=>'0');		--Internal signal for data out, used as a buffer between this entity and out_reg

component shift_register is
	port(
		shift:		in std_logic;			--Shift register if high (every clock)
		shift_in:	in std_logic;			--Data that is shifted in
		write_enable:	in std_logic;			--writes 'data_in' to 'shift_reg' when high
           	clk: 		in std_logic;
		rst:		in std_logic;
	   	data_in:	in std_logic_vector(7 downto 0);

           	data_out: 	out std_logic_vector(7 downto 0)
	); 
end component;

begin

	in_reg : shift_register
		port map(
				shift => shift_in,
				shift_in => '0',
				write_enable => wr_in,
				clk => clk,
				rst => rst,
				data_in => (others=>'0'),
				data_out => in_reg_data
			);

	out_reg : shift_register
		port map(
				shift => shift_in,
				shift_in => '0',
				write_enable => wr_out,
				clk => clk,
				rst => rst,
				data_in => data_out_int,
				data_out => out_reg_data
			);

	data_out <= data_out_int;

	process(clk, rst)
	begin
		if rising_edge(clk) then
			baud_counter <= baud_counter + 1;	--Keeping track of when baud clock is

			--Sampling signal if in middle of baud clock (=4)
			if baud_counter = "100" then
				sample_input <= data_recieved;
			end if;

			--Baud clock event, handle transfer logic
			if baud_counter = "111" then
				baud_counter <= "000";

				--If in recieving state, handle recieve logic
				if recieving = '1' then
					if byte_counter < 7 then
						byte_counter <= byte_counter + 1;
						shift_in <= sample_input;		--shift in recieved bit to in_reg
					else

				elsif sample_input = '1' then
					recieving <= '1';
					byte_counter <= "000";
				end if;
			end if;
				

		end if;
	end process;

	process(clk)
	begin
		if rising_edge(clk) then
			if baude_counter = "111" then
				baud_counter = 
		end if;
	end process;

end behave;
