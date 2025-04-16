library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity parser_top is
    Port (
        clk   : in  std_logic;
        rst   : in  std_logic;
        rx    : in  std_logic;
        an    : out std_logic_vector(3 downto 0);
        seg   : out std_logic_vector(6 downto 0)
    );
end parser_top;

architecture Behavioral of parser_top is

    -- COMPONENTS
    component uart_rx
        Port (
            clk, en, rx, rst : in std_logic;
            newChar          : out std_logic;
            char             : out std_logic_vector(7 downto 0)
        );
    end component;

    component packet_parser
        Port (
            clk, rst, en, newChar : in std_logic;
            charIn                : in std_logic_vector(7 downto 0);
            price, volume         : out std_logic_vector(7 downto 0);
            valid_pkt             : out std_logic
        );
    end component;

    component binToDec
        Port (
            binary_in : in std_logic_vector(7 downto 0);
            tens      : out std_logic_vector(3 downto 0);
            ones      : out std_logic_vector(3 downto 0)
        );
    end component;

    component seg7
        Port (
            hex : in std_logic_vector(3 downto 0);
            seg : out std_logic_vector(6 downto 0)
        );
    end component;

    -- SIGNALS
    signal received_char : std_logic_vector(7 downto 0);
    signal new_char      : std_logic;
    signal price_wire, volume_wire : std_logic_vector(7 downto 0);
    signal price_reg, volume_reg   : std_logic_vector(7 downto 0);
    signal valid_pkt : std_logic;

    signal p_tens, p_ones : std_logic_vector(3 downto 0);
    signal v_tens, v_ones : std_logic_vector(3 downto 0);
    signal s_p_tens, s_p_ones, s_v_tens, s_v_ones : std_logic_vector(6 downto 0);

    signal digit_index : integer range 0 to 3 := 0;
    signal refresh_counter : integer := 0;

begin

    -- UART Receive
    uart_rx_inst : uart_rx
        port map (
            clk => clk,
            en => '1',
            rx => rx,
            rst => rst,
            newChar => new_char,
            char => received_char
        );

    -- Packet parser
    parser : packet_parser
        port map (
            clk => clk,
            rst => rst,
            en => '1',
            newChar => new_char,
            charIn => received_char,
            price => price_wire,
            volume => volume_wire,
            valid_pkt => valid_pkt
        );

    -- Registering valid packets
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                price_reg  <= (others => '0');
                volume_reg <= (others => '0');
            elsif valid_pkt = '1' then
                price_reg  <= price_wire;
                volume_reg <= volume_wire;
            end if;
        end if;
    end process;

    -- Convert to decimal
    binToDec_price : binToDec port map(binary_in => price_reg,  tens => p_tens, ones => p_ones);
    binToDec_vol   : binToDec port map(binary_in => volume_reg, tens => v_tens, ones => v_ones);

    -- Convert to 7-seg
    seg7_p_ones : seg7 port map(hex => p_ones, seg => s_p_ones);
    seg7_p_tens : seg7 port map(hex => p_tens, seg => s_p_tens);
    seg7_v_ones : seg7 port map(hex => v_ones, seg => s_v_ones);
    seg7_v_tens : seg7 port map(hex => v_tens, seg => s_v_tens);

    -- Refresh logic
    process(clk)
    begin
        if rising_edge(clk) then
            refresh_counter <= refresh_counter + 1;
            if refresh_counter = 10000 then
                refresh_counter <= 0;
                digit_index <= (digit_index + 1) mod 4;
            end if;
        end if;
    end process;

    -- Digit switching
    process(digit_index)
    begin
        case digit_index is
            when 0 => seg <= s_p_ones; an <= "1110";
            when 1 => seg <= s_p_tens; an <= "1101";
            when 2 => seg <= s_v_ones; an <= "1011";
            when 3 => seg <= s_v_tens; an <= "0111";
            when others => seg <= "1111111"; an <= "1111";
        end case;
    end process;

end Behavioral;
