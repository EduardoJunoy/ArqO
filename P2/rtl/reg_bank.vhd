--------------------------------------------------------------------------------
-- EPS - UAM. Laboratorio de Arq0 2023
--
-- Banco completo de registros del microprocesador MIPS/RISCV (el mismo)
----------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
USE ieee.std_logic_arith.ALL;

ENTITY reg_bank IS
   PORT (
      Clk : IN STD_LOGIC; -- Reloj activo en flanco de subida
      Reset : IN STD_LOGIC; -- Reset as�ncrono a nivel alto
      A1 : IN STD_LOGIC_VECTOR(4 DOWNTO 0); -- Direcci�n para el puerto Rd1
      Rd1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0); -- Dato del puerto Rd1
      A2 : IN STD_LOGIC_VECTOR(4 DOWNTO 0); -- Direcci�n para el puerto Rd2
      Rd2 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0); -- Dato del puerto Rd2
      A3 : IN STD_LOGIC_VECTOR(4 DOWNTO 0); -- Direcci�n para el puerto Wd3
      Wd3 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); -- Dato de entrada Wd3
      We3 : IN STD_LOGIC -- Habilitaci�n de la escritura de Wd3
   );
END reg_bank;

ARCHITECTURE rtl OF reg_bank IS

   -- Tipo y senial para almacenar los registros
   TYPE regs_type IS ARRAY (0 TO 31) OF STD_LOGIC_VECTOR(31 DOWNTO 0);
   SIGNAL regs : regs_type;

BEGIN

   ------------------------------------------------------
   -- Escritura de registro
   ------------------------------------------------------

   PROCESS (Clk, Reset)
   BEGIN
      IF Reset = '1' THEN
         FOR i IN 0 TO 31 LOOP
            regs(i) <= (OTHERS => '0');
         END LOOP;
      ELSIF rising_edge(Clk) THEN
         IF We3 = '1' THEN
            IF A3 /= "00000" THEN -- El R0 siempre es cero
               regs(conv_integer(A3)) <= Wd3;
            END IF;
         END IF;
      END IF;
   END PROCESS;

   ------------------------------------------------------
   -- Lectura as�ncrona de registros
   ------------------------------------------------------
   Rd1 <= Wd3 when We3 = '1' and (A3 /= "00000") and A1 = A3 else regs(conv_integer(A1));
   Rd2 <= Wd3 when We3 = '1' and (A3 /= "00000") and A2 = A3 else regs(conv_integer(A2));

END ARCHITECTURE;
