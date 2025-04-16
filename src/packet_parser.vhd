library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity packet_parser is
    Port (
        clk         : in  std_logic;
        rst         : in  std_logic;
        en          : in  std_logic;
        newChar     : in  std_logic;
        charIn      : in  std_logic_vector(7 downto 0);
        price       : out std_logic_vector(7 downto 0);
        volume      : out std_logic_vector(7 downto 0);
        valid_pkt   : out std_logic
    );
end packet_parser;

architecture Behavioral of packet_parser is
    type state_type is (IDLE, GET_PRICE, GET_VOLUME, GET_CHECKSUM);
    signal state : state_type := IDLE;

    signal price_reg  : std_logic_vector(7 downto 0);
    signal volume_reg : std_logic_vector(7 downto 0);
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state <= IDLE;
                valid_pkt <= '0';
                price <= (others => '0');
                volume <= (others => '0');
            elsif en = '1' and newChar = '1' then
                case state is
                    when IDLE =>
                        valid_pkt <= '0';
                        if charIn = x"AA" then
                            state <= GET_PRICE;
                        end if;

                    when GET_PRICE =>
                        price_reg <= charIn;
                        state <= GET_VOLUME;

                    when GET_VOLUME =>
                        volume_reg <= charIn;
                        state <= GET_CHECKSUM;

                    when GET_CHECKSUM =>
                        if charIn = (price_reg xor volume_reg) then
                            price <= price_reg;
                            volume <= volume_reg;
                            valid_pkt <= '1';
                        else
                            valid_pkt <= '0';
                        end if;
                        state <= IDLE;

                    when others =>
                        state <= IDLE;
                end case;
            end if;
        end if;
    end process;

end Behavioral;
