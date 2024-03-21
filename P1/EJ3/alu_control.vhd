--------------------------------------------------------------------------------
-- Bloque de control para la ALU RISCV. Arq0 2023.
-- G.Sutter jun2022
--
--
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
USE work.RISCV_pack.ALL;

ENTITY alu_control IS
      PORT (
            -- Entradas:
            ALUOp : IN STD_LOGIC_VECTOR (2 DOWNTO 0); -- Codigo de control desde la unidad de control
            Funct7 : IN STD_LOGIC_VECTOR (6 DOWNTO 0); -- Campo "funct7" de la instruccion (I(31:25))
            Funct3 : IN STD_LOGIC_VECTOR (2 DOWNTO 0); -- Campo "funct3" de la instruccion (I(14:12))
            -- Salida de control para la ALU:
            ALUControl : OUT STD_LOGIC_VECTOR (3 DOWNTO 0) -- Define operacion a ejecutar por la ALU
      );
END alu_control;

ARCHITECTURE rtl OF alu_control IS
      -- Tipo para los codigos de control de la ALU definidos en package.

BEGIN

      AluEfOp : PROCESS (AluOp, funct7, funct3)
      BEGIN
            CASE AluOp IS
                  WHEN R_Type => --R-type (opcode "0110011")
                        CASE funct3 IS
                              WHEN "000" =>
                                    CASE funct7 IS
                                          WHEN "0000000" => --ADD
                                                AluControl <= ALU_ADD;
                                          WHEN "0100000" =>
                                                AluControl <= ALU_SUB; --SUB
                                          WHEN OTHERS => --not included instructions
                                                AluControl <= ALU_NIM;
                                    END CASE;
                              WHEN "001" => --SLL
                                    AluControl <= ALU_NIM;
                              WHEN "010" => --SLT
                                    AluControl <= ALU_NIM;
                              WHEN "100" => --XOR
                                    AluControl <= ALU_XOR;
                              WHEN "101" => --SRL
                                    AluControl <= ALU_NIM;
                              WHEN "110" => --OR
                                    AluControl <= ALU_OR;
                              WHEN "111" => --AND
                                    AluControl <= ALU_AND;
                              WHEN OTHERS =>
                                    AluControl <= ALU_NIM;
                        END CASE; -- case funct3 R_type
                  WHEN I_Type => --I-type immediate arithm (opcode "0010011" )
                        CASE funct3 IS
                              WHEN "000" => --ADDI
                                    AluControl <= ALU_ADD;
                              WHEN "111" => --ANDI
                                    AluControl <= ALU_AND;
                              WHEN "100" => --XORI
                                    AluControl <= ALU_XOR;
                              WHEN "110" => --ORI
                                    AluControl <= ALU_OR;
                              WHEN OTHERS =>
                                    AluControl <= ALU_NIM;
                        END CASE; -- case funct3 I_type
                  WHEN LDST_T => --I-type LOAD or STORE (opcode "0000011" or "0100011")
                        AluControl <= ALU_ADD;
                  WHEN BRCH_T => --Branches
                        AluControl <= ALU_SUB; --SUB
                  WHEN OTHERS =>
                        AluControl <= ALU_NIM;
            END CASE;
      END PROCESS;

END ARCHITECTURE;