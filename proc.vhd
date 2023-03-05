--Declarando as bibliotecas utilizadas!
LIBRARY ieee; USE ieee.std_logic_1164.all; 
USE ieee.std_logic_signed.all;
---------------------------------------

--Declarando a entidade (Top-level) com entradas DIN, Resetn, Clock e Run.
ENTITY proc IS
	PORT (DIN : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
			Resetn, Clock, Run : IN STD_LOGIC;
			Done : BUFFER STD_LOGIC;
			BusWires : BUFFER STD_LOGIC_VECTOR(15 DOWNTO 0));
END proc;
---------------------------------------------------------------------------
 
ARCHITECTURE Behavior OF proc IS
--Declarando os componentes UPCOUNT (Contador), DEC3TO8 (Mux) e REGN (Comportamento dos registradores)-------------
	COMPONENT upcount IS
		PORT ( Clear, Clock : IN STD_LOGIC;
				Q : OUT STD_LOGIC_VECTOR(1 DOWNTO 0));	
	END COMPONENT;
	
	COMPONENT dec3to8 IS
		PORT ( W : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
				En : IN STD_LOGIC;
				Y : OUT STD_LOGIC_VECTOR(0 TO 7));
	END COMPONENT;
	
	COMPONENT regn IS
		GENERIC (n : INTEGER := 16);
		PORT ( R : IN STD_LOGIC_VECTOR(n-1 DOWNTO 0);
				Rin, Clock : IN STD_LOGIC;
				Q : BUFFER STD_LOGIC_VECTOR(n-1 DOWNTO 0));
	END COMPONENT;
	
	COMPONENT mux10to1 IS
		PORT ( S : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
				D : IN STD_LOGIC_VECTOR (15 DOWNTO 0);
				R0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
				R1 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
				R2 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
				R3 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
				R4 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
				R5 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
				R6 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
				R7 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
				G : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
				O : OUT STD_LOGIC_VECTOR(15 DOWNTO 0));
	END COMPONENT;
		
--------------------------------------------------------------------------------------------------------------------
----------------------------------------------Declarando os sinais--------------------------------------------------
	signal IRin, Ain, Gin, Gout, DINout, AddSub, Clear : std_logic := '0';
			 
	signal Tstep_Q : std_logic_vector(1 DOWNTO 0) := "00";
			 
	signal Rin, Rout, Xreg, Yreg : std_logic_vector(0 TO 7) := "00000000";
			 
	signal QIR : std_logic_vector(1 TO 9) := "000000000";
	
	signal Control : std_logic_vector(1 TO 10) := "0000000000";

	signal I : std_logic_vector(2 DOWNTO 0) := "000";
			 
	signal Q0, Q1, Q2, Q3, Q4, Q5, Q6, Q7, QA, QG, AddSubout : std_logic_vector(15 DOWNTO 0) := "0000000000000000";
---------------------------------------------------------------------------------------------------------------------

	BEGIN
		Clear <= (NOT(Resetn))OR(Done)OR(NOT(Run)AND(NOT(Tstep_Q(1)))AND(NOT(Tstep_Q(0))));
		Tstep: upcount PORT MAP (Clear, Clock, Tstep_Q);
		I <= QIR(1 TO 3);
		decX: dec3to8 PORT MAP (QIR(4 TO 6), '1', Xreg);
		decY: dec3to8 PORT MAP (QIR(7 TO 9), '1', Yreg);

	controlsignals: PROCESS (Tstep_Q, I, Xreg, Yreg)
		BEGIN -- Iniciando tudo zerado
			IRin <= '0';
			Rout <= "00000000";
			Gout <= '0';
			DINout <= '0';
			Rin <= "00000000";
			Ain <= '0';
			Gin <= '0';
			AddSub <= '0';
			Done <= '0';
			CASE Tstep_Q IS
				WHEN "00" =>
						IRin <= '1';
					
				WHEN "01" => -- Tempo T1
					CASE I IS
						WHEN "000" => -- Instrução mv
							Rout <= Yreg;
							Rin <= Xreg;
							Done <= '1';
							
						WHEN "001" => -- Instrução mvi
							DINout <= '1';
							Rin <= Xreg;
							Done <= '1';
							
						WHEN "010" => -- Instrução add
							Rout <= Xreg;
							Ain <= '1';
							
						WHEN "011" => -- Instrução sub
							Rout <= Xreg;
							Ain <= '1';

						WHEN OTHERS => -- Qualquer outra situação zera todas as variáveis de controle
							IRin <= '0';
							Rout <= "00000000";
							Gout <= '0';
							DINout <= '0';
							Rin <= "00000000";
							Ain <= '0';
							Gin <= '0';
							AddSub <= '0';
							Done <= '0';
					END CASE;
					
				WHEN "10" => -- Tempo T2
					CASE I IS
						WHEN "010" => -- Instrução add
							Rout <= Yreg;
							Gin <= '1';
							
						WHEN "011" => -- Instrução sub
							Rout <= Yreg;
							Gin <= '1';
							AddSub <= '1';

						WHEN OTHERS => -- Padrão de zerar para qualquer outra instrução
							IRin <= '0';
							Rout <= "00000000";
							Gout <= '0';
							DINout <= '0';
							Rin <= "00000000";
							Ain <= '0';
							Gin <= '0';
							AddSub <= '0';
							Done <= '0';
					END CASE;
					
				WHEN "11" => -- Tempo T3
					CASE I IS
						WHEN "010" => -- Instrução add
							Gout <= '1';
							Rin <= Xreg;
							Done <= '1';
						
						WHEN "011" => -- Instrução sub
							Gout <= '1';
							Rin <= Xreg;
							Done <= '1';

						WHEN OTHERS => -- Padrão de zerar para qualquer outra instrução
							IRin <= '0';
							Rout <= "00000000";
							Gout <= '0';
							DINout <= '0';
							Rin <= "00000000";
							Ain <= '0';
							Gin <= '0';
							AddSub <= '0';
							Done <= '0';
					END CASE;
			END CASE;
		END PROCESS;
		
	PROCESS (AddSub, QA, BusWires)
		BEGIN
			-- Soma e Subtração do que está no registrador A e no barramento BUS
			IF (AddSub = '0') THEN
				AddSubout <= QA + BusWires;
			ELSE
				AddSubout <= QA - BusWires;
			END IF;
			--------------------------------------------------------------------
	END PROCESS;
	
	Control <= Rout & Gout & DINout; -- Variável que será o seletor do que estará no BusWires
	bus_wires: mux10to1 PORT MAP(Control, DIN, Q0, Q1, Q2, Q3, Q4, Q5, Q6, Q7, QG, BusWires); --Lógica do BusWires
	-- Registradores
	reg_0: regn PORT MAP (BusWires, Rin(0), Clock, Q0);
	reg_1: regn PORT MAP (BusWires, Rin(1), Clock, Q1);
	reg_2: regn PORT MAP (BusWires, Rin(2), Clock, Q2);
	reg_3: regn PORT MAP (BusWires, Rin(3), Clock, Q3);
	reg_4: regn PORT MAP (BusWires, Rin(4), Clock, Q4);
	reg_5: regn PORT MAP (BusWires, Rin(5), Clock, Q5);
	reg_6: regn PORT MAP (BusWires, Rin(6), Clock, Q6);
	reg_7: regn PORT MAP (BusWires, Rin(7), Clock, Q7);
	reg_A: regn PORT MAP (BusWires, Ain, Clock, QA);
	reg_G: regn PORT MAP (AddSubout, Gin, Clock, QG);
	reg_IR: regn GENERIC MAP (n=>9) PORT MAP (DIN(15 DOWNTO 7), IRin, Clock, QIR);
END Behavior;
