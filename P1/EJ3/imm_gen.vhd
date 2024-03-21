--------------------------------------------------------------------------------
-- Unidad Generador del operando inmediato del RISCV. Arq0 2023
-- G.Sutter jun 2022. Last Rev. Sep23
--
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;
USE work.RISCV_pack.ALL;

ENTITY Imm_Gen IS
    PORT (
        instr : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        imm : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
END ENTITY Imm_Gen;

ARCHITECTURE rtl OF Imm_Gen IS

    SIGNAL opcode : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL ItypeImm, StypeImm : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL UtypeImm : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL BtypeImm, JtypeImm : STD_LOGIC_VECTOR(31 DOWNTO 0);

BEGIN

    ItypeImm <= X"00000" & instr(31 DOWNTO 20) WHEN instr(31) = '0' ELSE
        (X"FFFFF" & instr(31 DOWNTO 20));
    StypeImm <= X"00000" & (instr(31 DOWNTO 25) & instr(11 DOWNTO 7)) WHEN instr(31) = '0' ELSE
        (X"FFFFF" & (instr(31 DOWNTO 25) & instr(11 DOWNTO 7)));
    BtypeImm <= X"00000" & (instr(7) & instr(30 DOWNTO 25) & instr(11 DOWNTO 8) & '0') WHEN instr(31) = '0' ELSE
        (X"FFFFF" & (instr(7) & instr(30 DOWNTO 25) & instr(11 DOWNTO 8) & '0')); -- instr(31) implicit at position 12
    JtypeImm <= X"000" & (instr(19 DOWNTO 12) & instr(20) & instr(30 DOWNTO 21) & '0') WHEN instr(31) = '0' ELSE
        (X"FFF" & (instr(19 DOWNTO 12) & instr(20) & instr(30 DOWNTO 21)) & '0'); -- instr(31) implicit at position 20
    UtypeImm <= instr(31 DOWNTO 12) & X"000"; --for LUI & AUIPC

    opcode <= instr(6 DOWNTO 0);

    PROCESS (opcode, ItypeImm, StypeImm, BtypeImm, JtypeImm, UtypeImm)
    BEGIN
        CASE opcode IS
            WHEN OP_ITYPE => imm <= ItypeImm; --Imm arith 
            WHEN OP_LD => imm <= ItypeImm; --loads
            WHEN OP_ST => imm <= StypeImm; --stores
            WHEN OP_LUI => imm <= UtypeImm; --LUI
            WHEN OP_AUIPC => imm <= UtypeImm; --AUIPC
            WHEN OP_BRANCH => imm <= BtypeImm; --branches
            WHEN OP_JALR => imm <= ItypeImm; --JALR
            WHEN OP_JAL => imm <= JtypeImm; --JAL
            WHEN OTHERS => imm <= (OTHERS => '0');
        END CASE;
    END PROCESS;

END ARCHITECTURE rtl;