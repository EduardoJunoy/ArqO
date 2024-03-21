--------------------------------------------------------------------------------
-- EPS - UAM. Laboratorio de ARQ 2023
-- G.Sutter jun2022. LastRev sep23
--
-- ALU simple for RiscV.
-- * Soporta las operaciones: +, -, and, or, xor, not, slt
-- * Genera el flag Zero (ZFlag), flag de Signo (SignFlag) y Carry
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
USE work.RISCV_pack.ALL;

ENTITY alu_RV IS
  PORT (
    OpA : IN STD_LOGIC_VECTOR (31 DOWNTO 0); -- Operando A
    OpB : IN STD_LOGIC_VECTOR (31 DOWNTO 0); -- Operando B
    Control : IN STD_LOGIC_VECTOR (3 DOWNTO 0); -- Codigo de control=op. a ejecutar
    Result : OUT STD_LOGIC_VECTOR (31 DOWNTO 0); -- Resultado
    SignFlag : OUT STD_LOGIC; -- Sign Flag
    CarryOut : OUT STD_LOGIC; -- Carry bit
    ZFlag : OUT STD_LOGIC -- Flag Z
  );
END alu_RV;

ARCHITECTURE rtl OF alu_RV IS
  -- Tipo para los codigos de control de la ALU definidos en package.
  -- Seniales intermedias:
  SIGNAL subExt : STD_LOGIC_VECTOR (32 DOWNTO 0); -- resta extendida a 33 bits
  SIGNAL addExt : STD_LOGIC_VECTOR (32 DOWNTO 0); -- suma extendida a 33 bits
  SIGNAL sigResult : STD_LOGIC_VECTOR (31 DOWNTO 0); -- alias interno de Result

BEGIN

  subExt <= (OpA(31) & OpA) - (OpB(31) & OpB);
  addExt <= (OpA(31) & OpA) + (OpB(31) & OpB);

  alu_mux : PROCESS (Control, OpA, OpB, subExt, addExt)
  BEGIN
    CASE Control IS
      WHEN ALU_OR => sigResult <= OpA OR OpB;
      WHEN ALU_NOT => sigResult <= NOT OpA;
      WHEN ALU_XOR => sigResult <= OpA XOR OpB;
      WHEN ALU_AND => sigResult <= OpA AND OpB;
      WHEN ALU_SUB => sigResult <= subExt (31 DOWNTO 0);
      WHEN ALU_ADD => sigResult <= addExt (31 DOWNTO 0);
      WHEN ALU_SLT => sigResult <= x"0000000" & "000" & subExt(32);
      WHEN OTHERS => sigResult <= (OTHERS => '0');
    END CASE;
  END PROCESS;

  Result <= sigResult;
  SignFlag <= sigResult(31);
  CarryOut <= addExt(32) WHEN (Control = ALU_ADD) ELSE
    subExt(32);
  ZFlag <= '1' WHEN sigResult = x"00000000" ELSE
    '0';

END ARCHITECTURE;