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

    -- =========================================================
    -- Constrained integer subtypes
    -- =========================================================
    subtype w0_t         is integer range -64 to 55;
    subtype b0_t         is integer range -23 to 29;
    subtype w1_t         is integer range -66 to 50;

    subtype hidden_sum_t is integer range -127 to 164;
    subtype hidden_act_t is integer range 0 to 164;
    subtype output_sum_t is integer range -36932 to 15213;

    -- =========================================================
    -- Types
    -- =========================================================
    type hidden_weight_row_t    is array (0 to 7)  of w0_t;
    type hidden_weight_matrix_t is array (0 to 15) of hidden_weight_row_t;
    type hidden_bias_t          is array (0 to 15) of b0_t;
    type hidden_act_array_t     is array (0 to 15) of hidden_act_t;
    type output_weight_t        is array (0 to 15) of w1_t;

    -- =========================================================
    -- Layer 0 weights: 16 x 8
    -- =========================================================
    constant W0 : hidden_weight_matrix_t := (
        0  => (  8,  30,   8,  17,  16,  25, -33, -52 ),
        1  => (  9,   9,  15,   5,  12,   2,  12, -17 ),
        2  => ( -6,  22,  13,   6,  26,  21,  38, -18 ),
        3  => ( 33, -15, -19,  32,  -1, -33, -15, -11 ),
        4  => ( 34, -30,  30,  -4,  30, -31,  40,  -5 ),
        5  => ( 39,   6,  -4,  -3,  55,   1,  27,   7 ),
        6  => (-32,  17, -37,  17,  12, -12, -22,   0 ),
        7  => ( -2,   3,   4,   4,  -2,   2,   0,  -1 ),
        8  => (  4,   4,  13,   1,   9,  -1,  10, -12 ),
        9  => (-25,  26,  33,  24, -31,  27, -24, -15 ),
        10 => (-30,  47, -30,  37, -30,  47, -30,  20 ),
        11 => ( -2,  -3,   3,  -2,   0,  -1,  -4,  -1 ),
        12 => ( 28,  14, -24,   0,  28,  14, -14,  -3 ),
        13 => ( 22, -17, -14, -20,  20, -16, -18,  10 ),
        14 => ( 19,   2,  -4,  -4,  26,  -3,  13,  13 ),
        15 => ( 13,  27, -64,  12, -13,  41,   3,  -4 )
    );

    -- =========================================================
    -- Layer 0 biases: 16
    -- =========================================================
    constant B0 : hidden_bias_t := (
        -11, -4, -23, -21, 9, 29, 20, 5,
        -1, 12, -7, -5, 13, 19, 14, -3
    );

    -- =========================================================
    -- Output layer weights: 1 x 16
    -- =========================================================
    constant W1 : output_weight_t := (
        -56, -14, -37, -66, -30, 41, -56, -2,
        -10, -46, 50, 0, -24, -39, 15, -54
    );

    -- =========================================================
    -- Output bias
    -- =========================================================
    constant B1 : integer range -1 to -1 := -1;

    begin    
        process(ui_in)
            variable hidden     : hidden_act_array_t;
            variable sum_hidden : hidden_sum_t;
            variable sum_out    : output_sum_t;
            variable result_bit : std_logic;
        begin
            result_bit := '0';
    
            for j in 0 to 15 loop
                sum_hidden := B0(j);
    
                for i in 0 to 7 loop
                    if ui_in(7 - i) = '1' then
                        sum_hidden := sum_hidden + W0(j)(i);
                    end if;
                end loop;
    
                if sum_hidden < 0 then
                    hidden(j) := 0;
                else
                    hidden(j) := sum_hidden;
                end if;
            end loop;
    
            sum_out := B1 * 16;
    
            for j in 0 to 15 loop
                sum_out := sum_out + hidden(j) * W1(j);
            end loop;
    
            if sum_out >= 0 then
                result_bit := '1';
            else
                result_bit := '0';
            end if;
    
            uo_out <= (others => '0');
            uo_out(0) <= result_bit;
        end process;
    
    end architecture;