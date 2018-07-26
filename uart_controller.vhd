
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

signal bit_counter:	unsigned(2 downto 0) := (others=>'0');
signal byte_counter:	unsigned(2 downto 0) := (others=>'0');

signal recieving:	std_logic := '0';
signal shift_in:	std_logic := '0';
signal wr_in:		std_logic := '0';
signal in_reg_data:	std_logic_vector(7 downto 0) => (others=>'0');

signal transmitting:	std_logic := '0';
signal shift_out	std_logic := '0';
signal wr_out:		std_logic :='0';
signal out_reg_data:	std_logic_vector(7 downto 0) := (others=>'0');

component shift_register is
	port(
		shift:		in std_logic;			--Shift register if high (every clock)
		shift_in:	in std_logic;			--Data that is shifted in
		write_enable:	in std_logic;			--writes 'data_in' to 'shift_reg' when high
           	clk: 		in std_logic;
	   	data_in:	in std_logic_vector(7 downto 0);

           	data_out: 	out std_logic_vector(7 downto 0));
	); 

begin

	in_reg : shift_register
		port map(
				shift => shift_in;
				shift_in => '0';
				write_enable => wr_in;
				clk => clk;
				rst => rst;	
				data_in => data_out;
				data_out => in_reg_data;
			);
				




end behave;
