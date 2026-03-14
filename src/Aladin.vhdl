library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity prime_net is
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
end prime_net;

architecture rtl of prime_net is

    -- =========================================================
    -- Types
    -- =========================================================
    type hidden_weight_row_t is array (0 to 7) of integer;
    type hidden_weight_matrix_t is array (0 to 15) of hidden_weight_row_t;
    type hidden_bias_t is array (0 to 15) of integer;
    type output_weight_t is array (0 to 15) of integer;

    -- =========================================================
    -- Layer 0 weights: 16 x 8
    -- Quantized integer values from your CSV
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

    -- Output bias
    constant B1 : integer := -1;

begin

    process(all)
        variable hidden     : hidden_bias_t;  -- stores ReLU outputs in Q4 integer form
        variable sum_hidden : integer;
        variable sum_out    : integer;        -- Q8 integer form
    begin

        -- =====================================================
        -- Hidden layer
        -- =====================================================
        for j in 0 to 15 loop
            sum_hidden := B0(j);

            for i in 0 to 7 loop
                -- Choose your bit ordering here.
                -- This version assumes x_in(7) is input 0 from the CSV,
                -- x_in(6) is input 1, ..., x_in(0) is input 7.
                if x_in(7 - i) = '1' then
                    sum_hidden := sum_hidden + W0(j)(i);
                end if;
            end loop;

            -- ReLU
            if sum_hidden < 0 then
                hidden(j) := 0;
            else
                hidden(j) := sum_hidden;
            end if;
        end loop;

        -- =====================================================
        -- Output layer
        -- hidden(j) is Q4, W1(j) is Q4, so product is Q8
        -- B1 is Q4, so shift left by 4 to align to Q8
        -- =====================================================
        sum_out := B1 * 16;

        for j in 0 to 15 loop
            sum_out := sum_out + hidden(j) * W1(j);
        end loop;

        -- logit >= 0  => class 1
        if sum_out >= 0 then
            y_out <= '1';
        else
            y_out <= '0';
        end if;
    end process;

end architecture;