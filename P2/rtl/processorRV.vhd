--------------------------------------------------------------------------------
-- Procesador RISC V uniciclo curso Arquitectura Ordenadores 2023
-- Initial Release G.Sutter jun 2022. Last Rev. sep2023
-- AUTORES: PABLO ANTÓN ALAMILLO Y EDUARDO JUNOY ORTEGA
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
USE work.RISCV_pack.ALL;

ENTITY processorRV IS
  PORT (
    Clk : IN STD_LOGIC; -- Reloj activo en flanco subida
    Reset : IN STD_LOGIC; -- Reset asincrono activo nivel alto
    -- Instruction memory
    IAddr : OUT STD_LOGIC_VECTOR(31 DOWNTO 0); -- Direccion Instr
    IDataIn : IN STD_LOGIC_VECTOR(31 DOWNTO 0); -- Instruccion leida
    -- Data memory
    DAddr : OUT STD_LOGIC_VECTOR(31 DOWNTO 0); -- Direccion
    DRdEn : OUT STD_LOGIC; -- Habilitacion lectura
    DWrEn : OUT STD_LOGIC; -- Habilitacion escritura
    DDataOut : OUT STD_LOGIC_VECTOR(31 DOWNTO 0); -- Dato escrito
    DDataIn : IN STD_LOGIC_VECTOR(31 DOWNTO 0) -- Dato leido
  );
END processorRV;

ARCHITECTURE rtl OF processorRV IS
  ----------------------------------------------------------------------------
  --Fase IF

  SIGNAL PC_next : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL PC_reg : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL PC_plus4 : STD_LOGIC_VECTOR(31 DOWNTO 0);

  SIGNAL Instruction : STD_LOGIC_VECTOR(31 DOWNTO 0); -- La instrucción desde la mem de instr
  ----------------------------------------------------------------------------
  --Fase ID
  SIGNAL Instruction_ID : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL PC_reg_ID : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL PC_plus4_ID : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL OP_CODE : STD_LOGIC_VECTOR(6 DOWNTO 0);

  SIGNAL reg_RD_data : STD_LOGIC_VECTOR(31 DOWNTO 0); --WB to ID

  SIGNAL Ctrl_Jal, Ctrl_Jalr, Ctrl_Branch, Ctrl_MemWrite, Ctrl_MemRead, Ctrl_ALUSrc, Ctrl_RegWrite : STD_LOGIC;

  SIGNAL Ctrl_ALUOp : STD_LOGIC_VECTOR(2 DOWNTO 0);
  SIGNAL Ctrl_PcLui : STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL Ctrl_ResSrc : STD_LOGIC_VECTOR(1 DOWNTO 0);

  SIGNAL Imm_ext : STD_LOGIC_VECTOR(31 DOWNTO 0); -- La parte baja de la instrucción extendida de signo

  SIGNAL reg_RS1 : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL reg_RS2 : STD_LOGIC_VECTOR(31 DOWNTO 0);

  SIGNAL PC_We : STD_LOGIC;
  SIGNAL ID_IF_We : STD_LOGIC;
  SIGNAL Ctrl_Mux : STD_LOGIC;

  COMPONENT reg_bank
    PORT (
      Clk : IN STD_LOGIC; -- Reloj activo en flanco de subida
      Reset : IN STD_LOGIC; -- Reset asincrono a nivel alto
      A1 : IN STD_LOGIC_VECTOR(4 DOWNTO 0); -- Direccion para el primer registro fuente (rs1)
      Rd1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0); -- Dato del primer registro fuente (rs1)
      A2 : IN STD_LOGIC_VECTOR(4 DOWNTO 0); -- Direccion para el segundo registro fuente (rs2)
      Rd2 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0); -- Dato del segundo registro fuente (rs2)
      A3 : IN STD_LOGIC_VECTOR(4 DOWNTO 0); -- Direccion para el registro destino (rd)
      Wd3 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); -- Dato de entrada para el registro destino (rd)
      We3 : IN STD_LOGIC -- Habilitacion de la escritura de Wd3 (rd)
    );
  END COMPONENT reg_bank;

  COMPONENT Imm_Gen IS
    PORT (
      instr : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      imm : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
  END COMPONENT Imm_Gen;

  COMPONENT control_unit
    PORT (
      -- Entrada = codigo de operacion en la instruccion:
      OpCode : IN STD_LOGIC_VECTOR (6 DOWNTO 0);
      -- Seniales para el PC
      Branch : OUT STD_LOGIC; -- 1 = Ejecutandose instruccion branch
      Ins_Jal : OUT STD_LOGIC; -- 1 = jal , 0 = otra instruccion, 
      Ins_Jalr : OUT STD_LOGIC; -- 1 = jalr, 0 = otra instruccion, 
      -- Seniales relativas a la memoria y seleccion dato escritura registros
      ResultSrc : OUT STD_LOGIC_VECTOR(1 DOWNTO 0); -- 00 salida Alu; 01 = salida de la mem.; 10 PC_plus4
      MemWrite : OUT STD_LOGIC; -- Escribir la memoria
      MemRead : OUT STD_LOGIC; -- Leer la memoria
      -- Seniales para la ALU
      ALUSrc : OUT STD_LOGIC; -- 0 = oper.B es registro, 1 = es valor inm.
      AuipcLui : OUT STD_LOGIC_VECTOR (1 DOWNTO 0); -- 0 = PC. 1 = zeros, 2 = reg1.
      ALUOp : OUT STD_LOGIC_VECTOR (2 DOWNTO 0); -- Tipo operacion para control de la ALU
      -- Seniales para el GPR
      RegWrite : OUT STD_LOGIC -- 1 = Escribir registro
    );
  END COMPONENT;

  ----------------------------------------------------------------------------
  --Fase EX

  SIGNAL Alu_Op1 : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL Alu_Op2 : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL Alu_ZERO : STD_LOGIC;
  SIGNAL Alu_SIGN : STD_LOGIC;
  SIGNAL AluControl : STD_LOGIC_VECTOR(3 DOWNTO 0);

  SIGNAL PC_reg_EX : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL PC_plus4_EX : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL Funct3_EX : STD_LOGIC_VECTOR(2 DOWNTO 0);
  SIGNAL Addr_BranchJal : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL Addr_Jalr : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL Addr_Jump_dest : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL OpCode_EX : STD_LOGIC_VECTOR(6 DOWNTO 0);
  SIGNAL RD2_EX : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL RD1_EX : STD_LOGIC_VECTOR(31 DOWNTO 0);

  SIGNAL RD_EX : STD_LOGIC_VECTOR(4 DOWNTO 0);

  SIGNAL imm_EX : STD_LOGIC_VECTOR(31 DOWNTO 0);

  SIGNAL Funct7_EX : STD_LOGIC_VECTOR(6 DOWNTO 0);

  SIGNAL Branch_EX : STD_LOGIC;
  SIGNAL ResSrc_EX : STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL MemRead_EX : STD_LOGIC;
  SIGNAL MemWrite_EX : STD_LOGIC;
  SIGNAL ALUOp_EX : STD_LOGIC_VECTOR (2 DOWNTO 0);
  SIGNAL ALUSrc_EX : STD_LOGIC;
  SIGNAL AuipcLui_EX : STD_LOGIC_VECTOR (1 DOWNTO 0);
  SIGNAL Jal_EX : STD_LOGIC;
  SIGNAL Jalr_EX : STD_LOGIC;
  SIGNAL RegWrite_EX : STD_LOGIC;

  SIGNAL Forward_B_EX : STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL Forward_A_EX : STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL FWD2 : STD_LOGIC_VECTOR (31 DOWNTO 0);
  SIGNAL FWD1 : STD_LOGIC_VECTOR (31 DOWNTO 0);

  SIGNAL RS1_EX : STD_LOGIC_VECTOR(4 DOWNTO 0);
  SIGNAL RS2_EX : STD_LOGIC_VECTOR(4 DOWNTO 0);

  SIGNAL Alu_Res : STD_LOGIC_VECTOR(31 DOWNTO 0);

  COMPONENT alu_RV
    PORT (
      OpA : IN STD_LOGIC_VECTOR (31 DOWNTO 0); -- Operando A
      OpB : IN STD_LOGIC_VECTOR (31 DOWNTO 0); -- Operando B
      Control : IN STD_LOGIC_VECTOR (3 DOWNTO 0); -- Codigo de control=op. a ejecutar
      Result : OUT STD_LOGIC_VECTOR (31 DOWNTO 0); -- Resultado
      SignFlag : OUT STD_LOGIC; -- Sign Flag
      CarryOut : OUT STD_LOGIC; -- Carry bit
      ZFlag : OUT STD_LOGIC -- Flag Z
    );
  END COMPONENT;

  COMPONENT alu_control IS
    PORT (
      -- Entradas:
      ALUOp : IN STD_LOGIC_VECTOR (2 DOWNTO 0); -- Codigo de control desde la unidad de control
      Funct3 : IN STD_LOGIC_VECTOR (2 DOWNTO 0); -- Campo "funct3" de la instruccion (I(14:12))
      Funct7 : IN STD_LOGIC_VECTOR (6 DOWNTO 0); -- Campo "funct7" de la instruccion (I(31:25))     
      -- Salida de control para la ALU:
      ALUControl : OUT STD_LOGIC_VECTOR (3 DOWNTO 0) -- Define operacion a ejecutar por la ALU
    );
  END COMPONENT alu_control;

  ----------------------------------------------------------------------------
  --Fase MEM
  SIGNAL Branch_MEM : STD_LOGIC;
  SIGNAL Jal_MEM : STD_LOGIC;
  SIGNAL Jalr_MEM : STD_LOGIC;
  SIGNAL ResSrc_MEM : STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL MemWrite_MEM : STD_LOGIC;
  SIGNAL MemRead_MEM : STD_LOGIC;
  SIGNAL RegWrite_MEM : STD_LOGIC;

  SIGNAL Alu_Res_MEM : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL Alu_ZERO_MEM : STD_LOGIC;
  SIGNAL Alu_SIGN_MEM : STD_LOGIC;

  SIGNAL RD_MEM : STD_LOGIC_VECTOR(4 DOWNTO 0);
  SIGNAL PC_plus4_MEM : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL Func3_MEM : STD_LOGIC_VECTOR(2 DOWNTO 0);
  SIGNAL RD2_MEM : STD_LOGIC_VECTOR(31 DOWNTO 0);

  SIGNAL Addr_Jump_dest_MEM : STD_LOGIC_VECTOR(31 DOWNTO 0);

  SIGNAL branch_true : STD_LOGIC;
  SIGNAL decision_Jump : STD_LOGIC; -- desde MEM hasta IF
  ----------------------------------------------------------------------------
  --Fase WB
  SIGNAL PC_plus4_WB : STD_LOGIC_VECTOR(31 DOWNTO 0);

  SIGNAL ResSrc_WB : STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL RegWrite_WB : STD_LOGIC;

  SIGNAL RD_WB : STD_LOGIC_VECTOR(11 DOWNTO 7);
  SIGNAL dataIn_Mem : STD_LOGIC_VECTOR(31 DOWNTO 0); -- Dato desde memoria

  SIGNAL Alu_Res_WB : STD_LOGIC_VECTOR(31 DOWNTO 0);

  SIGNAL dataIn_WB : STD_LOGIC_VECTOR(31 DOWNTO 0);
  ----------------------------------------------------------------------------

BEGIN

  -- Program Counter
  ----------------------------------------------------------------------------
  --Fase IF
  PC_reg_proc : PROCESS (Clk, Reset)
  BEGIN
    IF Reset = '1' THEN
      PC_reg <= (22 => '1', OTHERS => '0'); -- 0040_0000
    ELSIF rising_edge(Clk) THEN
      IF PC_We = '1' THEN
        PC_reg <= PC_next;
      END IF;
    END IF;
  END PROCESS;

  PC_plus4 <= PC_reg + 4;
  IAddr <= PC_reg;
  Instruction <= IDataIn;

  --Mux de antes del PC
  PC_next <= Addr_Jump_dest_MEM WHEN decision_Jump = '1' ELSE
    PC_plus4;

  ----------------------------------------------------------------------------
  --Registro IF/ID
  PROCESS (Clk, Reset)
  BEGIN
    IF Reset = '1' THEN
      Instruction_ID <= x"00000013";--codigo de nop para evitar instruccion no soportado
      PC_reg_ID <= (OTHERS => '0');
      PC_plus4_ID <= (OTHERS => '0');
    ELSIF rising_edge(Clk) AND ID_IF_We = '1' THEN
      IF (Branch_MEM AND branch_true) THEN
        Instruction_ID <= x"00000013";--codigo de nop para evitar instruccion no soportado
        PC_reg_ID <= (OTHERS => '0');
        PC_plus4_ID <= (OTHERS => '0');
      ELSE
        PC_reg_ID <= PC_reg;
        PC_plus4_ID <= PC_plus4;
        Instruction_ID <= Instruction;
      END IF;
    END IF;
  END PROCESS;

  ----------------------------------------------------------------------------
  --Fase ID
  Op_CODE <= Instruction_ID(6 DOWNTO 0);
  RegsRISCV : reg_bank
  PORT MAP(
    Clk => Clk,
    Reset => Reset,
    A1 => Instruction_ID(19 DOWNTO 15), --Instruction(19 downto 15), --rs1
    Rd1 => reg_RS1,
    A2 => Instruction_ID(24 DOWNTO 20), --Instruction(24 downto 20), --rs2
    Rd2 => reg_RS2,
    A3 => RD_WB, --Instruction(11 downto 7),,
    Wd3 => reg_RD_data,
    We3 => RegWrite_WB
  );

  UnidadControl : control_unit
  PORT MAP(
    OpCode => Instruction_ID(6 DOWNTO 0),
    -- Señales para el PC
    Branch => Ctrl_Branch,
    Ins_Jal => Ctrl_Jal,
    Ins_Jalr => Ctrl_Jalr,
    -- Señales para la memoria y seleccion dato escritura registros
    ResultSrc => Ctrl_ResSrc,
    MemWrite => Ctrl_MemWrite,
    MemRead => Ctrl_MemRead,
    -- Señales para la ALU
    ALUSrc => Ctrl_ALUSrc,
    AuipcLui => Ctrl_PcLui,
    ALUOp => Ctrl_ALUOp,
    -- Señales para el GPR
    RegWrite => Ctrl_RegWrite
  );

  immed_op : Imm_Gen
  PORT MAP(
    instr => Instruction_ID,
    imm => Imm_ext
  );
  PC_We <= '0' WHEN ((MemRead_EX = '1') AND ((RD_EX = Instruction_ID(19 DOWNTO 15)) OR (RD_EX = Instruction_ID(24 DOWNTO 20)))) ELSE
    '1';
  ID_IF_We <= '0' WHEN ((MemRead_EX = '1') AND ((RD_EX = Instruction_ID(19 DOWNTO 15)) OR (RD_EX = Instruction_ID(24 DOWNTO 20)))) ELSE
    '1';
  Ctrl_Mux <= '1' WHEN ((MemRead_EX = '1') AND ((RD_EX = Instruction_ID(19 DOWNTO 15)) OR (RD_EX = Instruction_ID(24 DOWNTO 20)))) ELSE
    '0';

  ----------------------------------------------------------------------------
  --Registro :ID/EX

  PROCESS (Clk, Reset)
  BEGIN
    IF Reset = '1' THEN
      PC_reg_EX <= (OTHERS => '0');
      PC_plus4_EX <= (OTHERS => '0');
      RD_EX <= (OTHERS => '0');
      Funct3_EX <= (OTHERS => '0');
      Funct7_EX <= (OTHERS => '0');
      OpCode_EX <= (OTHERS => '0');
      RD1_EX <= (OTHERS => '0');
      RD2_EX <= (OTHERS => '0');
      imm_EX <= (OTHERS => '0');
      RS1_EX <= (OTHERS => '0');
      RS2_EX <= (OTHERS => '0');
      --control
      MemWrite_EX <= '0';
      MemRead_EX <= '0';
      ALUOp_EX <= (OTHERS => '0');
      RegWrite_EX <= '0';
      Branch_EX <= '0';
      ALUSrc_EX <= '0';
      Jalr_EX <= '0';
      ResSrc_EX <= (OTHERS => '0');
      AuipcLui_EX <= (OTHERS => '0');
      Jal_EX <= '0';
    ELSIF rising_edge(Clk) THEN
      PC_reg_EX <= PC_reg_ID;
      PC_plus4_EX <= PC_plus4_ID;
      Funct3_EX <= instruction_ID(14 DOWNTO 12);
      Funct7_EX <= instruction_ID(31 DOWNTO 25);
      OpCode_EX <= OP_Code;
      RD1_EX <= reg_RS1;
      RD2_EX <= reg_RS2;
      RS2_EX <= Instruction_ID(24 DOWNTO 20);
      RS1_EX <= Instruction_ID(19 DOWNTO 15);

      imm_EX <= Imm_ext;
      IF Ctrl_Mux = '1' OR (Branch_MEM = '1' AND branch_true = '1') THEN
        Branch_EX <= '0';
        Jal_EX <= '0';
        Jalr_EX <= '0';
        ResSrc_EX <= (OTHERS => '0');
        MemWrite_EX <= '0';
        MemRead_EX <= '0';
        ALUSrc_EX <= '0';
        AuipcLui_EX <= (OTHERS => '0');
        ALUOp_EX <= (OTHERS => '0');
        RegWrite_EX <= '0';
      ELSE
        Branch_EX <= Ctrl_Branch;
        MemWrite_EX <= Ctrl_MemWrite;
        MemRead_EX <= Ctrl_MemRead;
        ALUSrc_EX <= Ctrl_ALUSrc;
        RegWrite_EX <= Ctrl_RegWrite;
        AuipcLui_EX <= Ctrl_PcLui;
        ALUOp_EX <= Ctrl_ALUOp;
        Jal_EX <= Ctrl_Jal;
        Jalr_EX <= Ctrl_Jalr;
        ResSrc_EX <= Ctrl_ResSrc;
      END IF;
      RD_EX <= Instruction_ID(11 DOWNTO 7);
    END IF;
  END PROCESS;

  ----------------------------------------------------------------------------
  --Fase EX
  --Multiplexor operando 1 Forwarding unit
  FWD2 <= RD2_EX WHEN Forward_B_EX = "00" ELSE
    Alu_Res_MEM WHEN Forward_B_EX = "10" ELSE
    reg_RD_data WHEN Forward_B_EX = "01";

  --Multiplexor operando 2 Forwarding unit
  FWD1 <= RD1_EX WHEN Forward_A_EX = "00" ELSE
    Alu_Res_MEM WHEN Forward_A_EX = "10" ELSE
    reg_RD_data WHEN Forward_A_EX = "01";

  --añadir señales fwd (cambiar nombre) y Ctrl_Forward
  Alu_Op1 <= PC_reg_EX WHEN AuipcLui_EX = "00" ELSE
    (OTHERS => '0') WHEN AuipcLui_EX = "01" ELSE
    FWD1;
  Alu_Op2 <= FWD2 WHEN ALUSrc_EX = '0' ELSE
    Imm_EX;

  Forward_A_EX <= "10" WHEN (Regwrite_MEM = '1' AND (RD_MEM /= "0000") AND (RD_MEM = RS1_EX)) ELSE
    "01" WHEN (Regwrite_WB = '1' AND (RD_WB /= "0000") AND (RD_WB = RS1_EX)) ELSE
    "00";

  Forward_B_EX <= "10" WHEN (Regwrite_MEM = '1' AND (RD_MEM /= "0000") AND (RD_MEM = RS2_EX)) ELSE
    "01" WHEN (Regwrite_WB = '1' AND (RD_WB /= "0000") AND (RD_WB = RS2_EX)) ELSE
    "00";
  Addr_BranchJal <= PC_reg_EX + Imm_EX;
  Addr_Jalr <= RD1_EX + Imm_EX;
  --Multiplexor de saltos
  Addr_Jump_dest <= Addr_Jalr WHEN Jalr_EX = '1' ELSE
    Addr_BranchJal WHEN (Branch_EX = '1') OR (Jal_EX = '1') ELSE
    (OTHERS => '0');
  Alu_control_i : alu_control
  PORT MAP(
    -- Entradas:
    ALUOp => ALUOp_EX, -- Codigo de control desde la unidad de control
    Funct3 => Funct3_EX, -- Campo "funct3" de la instruccion
    Funct7 => Funct7_EX, -- Campo "funct7" de la instruccion
    -- Salida de control para la ALU:
    ALUControl => AluControl -- Define operacion a ejecutar por la ALU
  );

  Alu_RISCV : alu_RV
  PORT MAP(
    OpA => Alu_Op1,
    OpB => Alu_Op2,
    Control => AluControl,
    Result => Alu_Res,
    Signflag => Alu_SIGN,
    CarryOut => OPEN,
    Zflag => Alu_ZERO
  );
  ----------------------------------------------------------------------------
  --Registro :EX/MEM

  PROCESS (Clk, Reset)
  BEGIN
    IF Reset = '1' THEN
      RD_MEM <= (OTHERS => '0');
      PC_plus4_MEM <= (OTHERS => '0');
      Func3_MEM <= (OTHERS => '0');
      RD2_MEM <= (OTHERS => '0');

      Branch_MEM <= '0';
      Jal_MEM <= '0';
      Jalr_MEM <= '0';
      ResSrc_MEM <= (OTHERS => '0');
      MemWrite_MEM <= '0';
      MemRead_MEM <= '0';
      RegWrite_MEM <= '0';

      Alu_Res_MEM <= (OTHERS => '0');

      Alu_ZERO_MEM <= '0';
      Alu_SIGN_MEM <= '0';

      Addr_Jump_dest_MEM <= (OTHERS => '0');
    ELSIF rising_edge(Clk) THEN
      IF (Branch_MEM AND branch_true) THEN
        RD_MEM <= (OTHERS => '0');
        PC_plus4_MEM <= (OTHERS => '0');
        Func3_MEM <= (OTHERS => '0');
        RD2_MEM <= (OTHERS => '0');

        Branch_MEM <= '0';
        Jal_MEM <= '0';
        Jalr_MEM <= '0';
        ResSrc_MEM <= (OTHERS => '0');
        MemWrite_MEM <= '0';
        MemRead_MEM <= '0';
        RegWrite_MEM <= '0';

        Alu_Res_MEM <= (OTHERS => '0');

        Alu_ZERO_MEM <= '0';
        Alu_SIGN_MEM <= '0';

        Addr_Jump_dest_MEM <= (OTHERS => '0');

      ELSE
        PC_plus4_MEM <= PC_plus4_EX;
        Func3_MEM <= Funct3_EX;
        RD2_MEM <= FWD2;

        Branch_MEM <= Branch_EX;
        Jal_MEM <= Jal_EX;
        RegWrite_MEM <= RegWrite_EX;
        Jalr_MEM <= Jalr_EX;
        ResSrc_MEM <= ResSrc_EX;
        MemWrite_MEM <= MemWrite_EX;
        MemRead_MEM <= MemRead_EX;

        Alu_Res_MEM <= Alu_Res;
        Alu_ZERO_MEM <= Alu_ZERO;
        Alu_SIGN_MEM <= Alu_SIGN;
        RD_MEM <= RD_EX;

        Addr_Jump_dest_MEM <= Addr_Jump_dest;
      END IF;
    END IF;
  END PROCESS;

  ----------------------------------------------------------------------------
  --Fase MEM

  decision_Jump <= Jal_MEM OR Jalr_MEM OR (Branch_MEM AND branch_true);

  branch_true <= '1' WHEN (((Func3_MEM = BR_F3_BEQ) AND (Alu_ZERO_MEM = '1')) OR
    ((Func3_MEM = BR_F3_BNE) AND (Alu_ZERO_MEM = '0')) OR
    ((Func3_MEM = BR_F3_BLT) AND (Alu_SIGN_MEM = '1')) OR
    ((Func3_MEM = BR_F3_BGE) AND (Alu_SIGN_MEM = '0'))) ELSE
    '0';
  dataIn_Mem <= DDataIn;

  DAddr <= Alu_Res_MEM;
  DDataOut <= RD2_MEM;

  DWrEn <= MemWrite_MEM;
  DRdEn <= MemRead_MEM;
  ----------------------------------------------------------------------------
  --Registro :MEM/WB

  PROCESS (Clk, reset)
  BEGIN
    IF reset = '1' THEN
      PC_plus4_WB <= (OTHERS => '0');

      ResSrc_WB <= (OTHERS => '0');
      RegWrite_WB <= '0';
      Alu_Res_WB <= (OTHERS => '0');

      dataIn_WB <= (OTHERS => '0');

      RD_WB <= (OTHERS => '0');
    ELSIF rising_edge(Clk) THEN
      PC_plus4_WB <= PC_plus4_MEM;

      ResSrc_WB <= ResSrc_MEM;
      RegWrite_WB <= RegWrite_MEM;
      Alu_Res_WB <= Alu_Res_MEM;

      dataIn_WB <= dataIn_MEM;

      RD_WB <= RD_MEM;
    END IF;
  END PROCESS;
  ----------------------------------------------------------------------------
  --Fase WB
  reg_RD_data <= dataIn_WB WHEN ResSrc_WB = "01" ELSE
    PC_plus4_WB WHEN ResSrc_WB = "10" ELSE
    Alu_Res_WB; -- When 00
  ----------------------------------------------------------------------------

END ARCHITECTURE;