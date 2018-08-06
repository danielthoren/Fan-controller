library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity shift_register is
    Port ( 	shift:		in std_logic;			--Shift register on high flank if high (not synchronized)
		shift_in:	in std_logic;			--Data that is shifted in
		write_enable:	in std_logic;			--writes 'data_in' to 'shift_reg' when high
           	clk: 		in std_logic;
		rst:		in std_logic;
	   	data_in:	in std_logic_vector(7 downto 0);

           	data_out: 	out std_logic_vector(7 downto 0)
	);
end shift_register;

architecture Behavioral of shift_register is
	signal shift_reg : std_logic_vector(7 downto 0) := X"00";
begin
    -- shift register
    process (clk, shift, rst)
    begin
	if rising_edge(clk) then
		if rst = '1' then
			shift_reg <= (others=>'0');
		end if;

		if write_enable = '1' then
			shift_reg <= data_in;
		end if;

		if shift = '1' then
            		shift_reg(6 downto 0) <= shift_reg(7 downto 1);
            		shift_reg(7) <= shift_in;
        	end if;
	end if;
    end process;
    
    -- hook up the shift register bits to the output
    data_out <= shift_reg;

end Behavioral;
