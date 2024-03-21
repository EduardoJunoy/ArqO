--------------------------------------------------------------------------------
-- Unidad de control principal del RISCV. ArqO 2023
-- G.Sutter jun2022. LastRev sep23.
--
-- Implementa set reducido de instrucciones
-- R-type, lw, sw, branches (beq, bnq), jal, AuiPC, Lui
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
USE work.RISCV_pack.ALL;

ENTITY control_unit IS
   PORT (
      -- Entrada = codigo de operacion en la instruccion:
      OpCode : IN STD_LOGIC_VECTOR (6 DOWNTO 0);
      -- Seniales para el PC
      Branch : OUT STD_LOGIC; -- 1 = Ejecutandose instruccion branch
      Ins_Jal : OUT STD_LOGIC; -- 1 = jal , 0 = otra instruccion, 
      Ins_Jalr : OUT STD_LOGIC; -- 1 = jalr, 0 = otra instruccion, 
      -- Seniales relativas a memoria y seleccion dato escritura registros
      ResultSrc : OUT STD_LOGIC_VECTOR(1 DOWNTO 0); -- 00 salida Alu; 01 = salida de la mem.; 10 PC_plus4
      MemWrite : OUT STD_LOGIC; -- Escribir la memoria
      MemRead : OUT STD_LOGIC; -- Leer la memoria
      -- Seniales para la ALU                    
      ALUSrc : OUT STD_LOGIC; -- 0 = oper.B es registro, 1 = es valor inm.
      AuipcLui : OUT STD_LOGIC_VECTOR (1 DOWNTO 0); -- 0 = PC. 1 = zeros, 2 = reg1.
      ALUOp : OUT STD_LOGIC_VECTOR (2 DOWNTO 0); -- Tipo operacion para control de la ALU
      -- Seniales para el GPR
      RegWrite : OUT STD_LOGIC -- 1=Escribir registro
   );
END control_unit;

ARCHITECTURE rtl OF control_unit IS
   -- Tipo para los codigos de operacion definidos en package
BEGIN
   -- OPCode <= Instr(6 downto 0); -- 7 least significant bits

   Branch <= '1' WHEN opCode = OP_BRANCH ELSE
      '0';

   ALUSrc <= '0' WHEN opCode = OP_RTYPE ELSE -- R-type
      '0' WHEN opCode = OP_BRANCH ELSE -- beq
      '1'; -- lw, sw, Itype

   AuipcLui <= "00" WHEN opCode = OP_AUIPC ELSE -- add PC
      "01" WHEN opCode = OP_LUI ELSE -- LUI, connects to zero
      "10"; -- default for most instructions
   RegWrite <= '0' WHEN opCode = OP_ST ELSE -- sw
      '0' WHEN opCode = OP_BRANCH ELSE -- any branch
      '1'; -- R-type, lw, I-type, lui , jal

   MemRead <= '1' WHEN opCode = OP_LD ELSE --lw
      '0';

   MemWrite <= '1' WHEN opCode = OP_ST ELSE -- sw
      '0';

   ResultSrc <= "01" WHEN opCode = OP_LD ELSE -- lw
      "10" WHEN opCode = OP_JAL ELSE -- jal
      "10" WHEN opCode = OP_JALR ELSE -- jalr
      "00"; -- R-type, sw, beq, lui I-type

   ALUOp <= LDST_T WHEN opCode = OP_LD ELSE -- ld
      LDST_T WHEN opCode = OP_ST ELSE -- sd
      LDST_T WHEN opCode = OP_LUI ELSE -- lui (add to zero)
      LDST_T WHEN opCode = OP_AUIPC ELSE -- AuiPC (add PC)
      LDST_T WHEN opCode = OP_JAL ELSE -- jal  (actually ALU does not make anything with this instruction)
      LDST_T WHEN opCode = OP_JALR ELSE -- jalr (actually ALU does not make anything with this instruction)
      BRCH_T WHEN opCode = OP_BRANCH ELSE -- any branch
      R_Type WHEN opCode = OP_RTYPE ELSE -- R-type;
      I_Type WHEN opCode = OP_ITYPE ELSE -- I-type;
      "111"; --Senial de no reconocido o no opera ALU

   Ins_jal <= '1' WHEN opCode = OP_JAL ELSE
      '0';
   Ins_jalr <= '1' WHEN opCode = OP_JALR ELSE
      '0';

END ARCHITECTURE;