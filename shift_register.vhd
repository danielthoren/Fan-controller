library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity shift_register is
    Port ( 	shift:		in std_logic;			--Shift register if high (not synchronized)
		shift_in:	in std_logic;			--Data that is shifted in
		write_enable:	in std_logic;			--writes 'data_in' to 'shift_reg' when high
           	clk: 		in std_logic;
		rst:		in std_logic;
	   	data_in:	in std_logic_vector(7 downto 0);

           	data_out: 	out std_logic_vector(7 downto 0);
		shift_out:	out std_logic);
end shift_register;

architecture Behavioral of shift_register is
	signal shift_reg : std_logic_vector(7 downto 0) := X"00";
begin
	--Desynchronized reset
    	process (rst)
	begin
		if rst = '1' then
			shift_reg <= (others=>'0');
			data_out <= (others=>'0');
		end if;
	end process;

    -- shift register
    process (clk, shift)
    begin
	if rising_edge(clk) then
		if write_enable = '1' then
			shift_reg <= data_in;
		end if;

		if shift = '1' then
			shift_out <= shift_reg(0);
            		shift_reg(6 downto 0) <= shift_reg(7 downto 1);
            		shift_reg(7) <= shift_in;
        	end if;
	end if;
    end process;
    
    -- hook up the shift register bits to the output
    data_out <= shift_reg;

end Behavioral;
