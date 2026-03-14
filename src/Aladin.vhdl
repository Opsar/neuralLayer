library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tt_um_prime_net is
    port (
        ui_in   : in  std_logic_vector(7 downto 0);
        uo_out  : out std_logic_vector(7 downto 0);
        uio_in  : in  std_logic_vector(7 downto 0);
        uio_out : out std_logic_vector(7 downto 0);
        uio_oe  : out std_logic_vector(7 downto 0);
        ena     : in  std_logic;
        clk     : in  std_logic;
        rst_n   : in  std_logic
    );
end tt_um_prime_net;

architecture rtl of tt_um_prime_net is

    -- Active hidden nodes kept from the original network:
    -- old nodes: 0,1,2,3,4,5,6,8,9,10,12,13,14,15

    type weight_row_t is array (0 to 7) of integer range -64 to 55;
    type weight_matrix_t is array (0 to 13) of weight_row_t;
    type bias_array_t is array (0 to 13) of integer range -23 to 29;
    type hidden_array_t is array (0 to 13) of unsigned(7 downto 0);

    constant W0 : weight_matrix_t := (
        0  => (  8,  30,   8,  17,  16,  25, -33, -52 ), -- old 0
        1  => (  9,   9,  15,   5,  12,   2,  12, -17 ), -- old 1
        2  => ( -6,  22,  13,   6,  26,  21,  38, -18 ), -- old 2
        3  => ( 33, -15, -19,  32,  -1, -33, -15, -11 ), -- old 3
        4  => ( 34, -30,  30,  -4,  30, -31,  40,  -5 ), -- old 4
        5  => ( 39,   6,  -4,  -3,  55,   1,  27,   7 ), -- old 5
        6  => (-32,  17, -37,  17,  12, -12, -22,   0 ), -- old 6
        7  => (  4,   4,  13,   1,   9,  -1,  10, -12 ), -- old 8
        8  => (-25,  26,  33,  24, -31,  27, -24, -15 ), -- old 9
        9  => (-30,  47, -30,  37, -30,  47, -30,  20 ), -- old 10
        10 => ( 28,  14, -24,   0,  28,  14, -14,  -3 ), -- old 12
        11 => ( 22, -17, -14, -20,  20, -16, -18,  10 ), -- old 13
        12 => ( 19,   2,  -4,  -4,  26,  -3,  13,  13 ), -- old 14
        13 => ( 13,  27, -64,  12, -13,  41,   3,  -4 )  -- old 15
    );

    constant B0 : bias_array_t := (
        -11, -4, -23, -21, 9, 29, 20, -1, 12, -7, 13, 19, 14, -3
    );

    -- Output bias from original code:
    -- sum_out := B1 * 16 with B1 = -1
    constant OUT_BIAS : signed(15 downto 0) := to_signed(-16, 16);

    -- Convert unsigned hidden activation to signed accumulator width
    function sx(x : unsigned(7 downto 0)) return signed is
    begin
        return resize(signed('0' & x), 16);
    end function;

    -- Hand-optimized constant multipliers
    function mul_w0(x : unsigned(7 downto 0)) return signed is  -- -56
        variable a : signed(15 downto 0);
    begin
        a := sx(x);
        return -shift_left(a, 6) + shift_left(a, 3);
    end function;

    function mul_w1(x : unsigned(7 downto 0)) return signed is  -- -14
        variable a : signed(15 downto 0);
    begin
        a := sx(x);
        return -shift_left(a, 4) + shift_left(a, 1);
    end function;

    function mul_w2(x : unsigned(7 downto 0)) return signed is  -- -37
        variable a : signed(15 downto 0);
    begin
        a := sx(x);
        return -shift_left(a, 5) - shift_left(a, 2) - a;
    end function;

    function mul_w3(x : unsigned(7 downto 0)) return signed is  -- -66
        variable a : signed(15 downto 0);
    begin
        a := sx(x);
        return -shift_left(a, 6) - shift_left(a, 1);
    end function;

    function mul_w4(x : unsigned(7 downto 0)) return signed is  -- -30
        variable a : signed(15 downto 0);
    begin
        a := sx(x);
        return -shift_left(a, 5) + shift_left(a, 1);
    end function;

    function mul_w5(x : unsigned(7 downto 0)) return signed is  -- 41
        variable a : signed(15 downto 0);
    begin
        a := sx(x);
        return shift_left(a, 5) + shift_left(a, 3) + a;
    end function;

    function mul_w6(x : unsigned(7 downto 0)) return signed is  -- -56
        variable a : signed(15 downto 0);
    begin
        a := sx(x);
        return -shift_left(a, 6) + shift_left(a, 3);
    end function;

    function mul_w7(x : unsigned(7 downto 0)) return signed is  -- -10
        variable a : signed(15 downto 0);
    begin
        a := sx(x);
        return -shift_left(a, 3) - shift_left(a, 1);
    end function;

    function mul_w8(x : unsigned(7 downto 0)) return signed is  -- -46
        variable a : signed(15 downto 0);
    begin
        a := sx(x);
        return -shift_left(a, 5) - shift_left(a, 3) - shift_left(a, 2) - shift_left(a, 1);
    end function;

    function mul_w9(x : unsigned(7 downto 0)) return signed is  -- 50
        variable a : signed(15 downto 0);
    begin
        a := sx(x);
        return shift_left(a, 5) + shift_left(a, 4) + shift_left(a, 1);
    end function;

    function mul_w10(x : unsigned(7 downto 0)) return signed is  -- -24
        variable a : signed(15 downto 0);
    begin
        a := sx(x);
        return -shift_left(a, 4) - shift_left(a, 3);
    end function;

    function mul_w11(x : unsigned(7 downto 0)) return signed is  -- -39
        variable a : signed(15 downto 0);
    begin
        a := sx(x);
        return -shift_left(a, 5) - shift_left(a, 2) - shift_left(a, 1) - a;
    end function;

    function mul_w12(x : unsigned(7 downto 0)) return signed is  -- 15
        variable a : signed(15 downto 0);
    begin
        a := sx(x);
        return shift_left(a, 3) + shift_left(a, 2) + shift_left(a, 1) + a;
    end function;

    function mul_w13(x : unsigned(7 downto 0)) return signed is  -- -54
        variable a : signed(15 downto 0);
    begin
        a := sx(x);
        return -shift_left(a, 6) + shift_left(a, 3) + shift_left(a, 1);
    end function;

begin

    process(ui_in)
        variable hidden     : hidden_array_t;
        variable sum_hidden : signed(8 downto 0);
        variable sum_out    : signed(15 downto 0);
    begin
        -- Hidden layer
        for j in 0 to 13 loop
            sum_hidden := to_signed(B0(j), 9);

            for i in 0 to 7 loop
                if ui_in(7 - i) = '1' then
                    sum_hidden := sum_hidden + to_signed(W0(j)(i), 9);
                end if;
            end loop;

            -- old node 5 and old node 14 are always non-negative
            -- in this reduced index set: j = 5 and j = 12
            if (j = 5) or (j = 12) then
                hidden(j) := unsigned(sum_hidden(7 downto 0));
            else
                if sum_hidden(8) = '1' then
                    hidden(j) := (others => '0');
                else
                    hidden(j) := unsigned(sum_hidden(7 downto 0));
                end if;
            end if;
        end loop;

        -- Output layer with shift/add constant multipliers
        sum_out := OUT_BIAS;

        sum_out := sum_out + mul_w0(hidden(0));
        sum_out := sum_out + mul_w1(hidden(1));
        sum_out := sum_out + mul_w2(hidden(2));
        sum_out := sum_out + mul_w3(hidden(3));
        sum_out := sum_out + mul_w4(hidden(4));
        sum_out := sum_out + mul_w5(hidden(5));
        sum_out := sum_out + mul_w6(hidden(6));
        sum_out := sum_out + mul_w7(hidden(7));
        sum_out := sum_out + mul_w8(hidden(8));
        sum_out := sum_out + mul_w9(hidden(9));
        sum_out := sum_out + mul_w10(hidden(10));
        sum_out := sum_out + mul_w11(hidden(11));
        sum_out := sum_out + mul_w12(hidden(12));
        sum_out := sum_out + mul_w13(hidden(13));

        uo_out <= (others => '0');
        if sum_out(15) = '0' then
            uo_out(0) <= '1';
        else
            uo_out(0) <= '0';
        end if;
    end process;

    uio_out <= (others => '0');
    uio_oe  <= (others => '0');
end rtl;