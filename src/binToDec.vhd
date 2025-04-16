library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity binToDec is
    Port (
        binary_in : in  std_logic_vector(7 downto 0);
        tens      : out std_logic_vector(3 downto 0);
        ones      : out std_logic_vector(3 downto 0)
    );
end binToDec;

architecture Behavioral of binToDec is
    signal int_val : integer range 0 to 255;
begin
    process(binary_in)
    begin
        int_val <= to_integer(unsigned(binary_in));
        tens  <= std_logic_vector(to_unsigned((int_val / 10), 4));
        ones  <= std_logic_vector(to_unsigned((int_val mod 10), 4));
    end process;
end Behavioral;
