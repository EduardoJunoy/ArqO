--------------------------------------------------------------------------------
-- Package for RISCV. Arq0 2023
-- G.Sutter jun2022
--
-- Define constantes para diferntes módulos
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

PACKAGE RISCV_pack IS

    -- Tipo para los codigos de operacion:
    SUBTYPE t_opCode IS STD_LOGIC_VECTOR (6 DOWNTO 0);
    -- Codigos de operacion para las diferentes instrucciones:
    CONSTANT OP_RTYPE : t_opCode := "0110011";
    CONSTANT OP_ITYPE : t_opCode := "0010011"; -- I-Type Arithm
    CONSTANT OP_BRANCH : t_opCode := "1100011";
    CONSTANT OP_ST : t_opCode := "0100011";
    CONSTANT OP_LD : t_opCode := "0000011";
    CONSTANT OP_LUI : t_opCode := "0110111"; -- Load Upper Inmediate
    CONSTANT OP_AUIPC : t_opCode := "0010111"; -- Load Upper Inmediate + PC
    CONSTANT OP_JAL : t_opCode := "1101111"; -- Jump and Link
    CONSTANT OP_JALR : t_opCode := "1100111"; -- Jump and Link Register

    -- Tipo para los codigos de control de la ALU:
    SUBTYPE t_aluControl IS STD_LOGIC_VECTOR (3 DOWNTO 0);
    SUBTYPE t_aluOP IS STD_LOGIC_VECTOR (2 DOWNTO 0);

    -- Codigos ALUOP
    CONSTANT R_Type : t_aluOP := "010";
    CONSTANT I_Type : t_aluOP := "011";
    CONSTANT LDST_T : t_aluOP := "000";
    CONSTANT BRCH_T : t_aluOP := "001";

    -- Codigos de control:
    CONSTANT ALU_ADD : t_aluControl := "0010";
    CONSTANT ALU_SUB : t_aluControl := "0110";
    CONSTANT ALU_AND : t_aluControl := "0000";
    CONSTANT ALU_OR : t_aluControl := "0001";
    CONSTANT ALU_NOT : t_aluControl := "0101";
    CONSTANT ALU_XOR : t_aluControl := "0111";
    CONSTANT ALU_SLT : t_aluControl := "1010";
    CONSTANT ALU_S12 : t_aluControl := "1101";
    CONSTANT ALU_NIM : t_aluControl := "XXXX"; --ALU not implemented yet

    -- Tipo para los codigos func3 en branches
    SUBTYPE t_funct3_branch IS STD_LOGIC_VECTOR (2 DOWNTO 0);
    CONSTANT BR_F3_BEQ : t_funct3_branch := "000";
    CONSTANT BR_F3_BNE : t_funct3_branch := "001";
    CONSTANT BR_F3_BLT : t_funct3_branch := "100";
    CONSTANT BR_F3_BGE : t_funct3_branch := "101";

END PACKAGE RISCV_pack;

PACKAGE BODY RISCV_pack IS
    -- declare common fnctions and procedures
END PACKAGE BODY;