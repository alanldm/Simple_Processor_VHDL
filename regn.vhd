LIBRARY ieee;
USE ieee.std_logic_1164.all;

--Componente responsável por pegar o que está no barramento (BusWires) e colocar em um registrador!
ENTITY regn IS
	GENERIC (n : INTEGER := 16);
	PORT ( R : IN STD_LOGIC_VECTOR(n-1 DOWNTO 0);
			Rin, Clock : IN STD_LOGIC;
			Q : BUFFER STD_LOGIC_VECTOR(n-1 DOWNTO 0));
END regn;

ARCHITECTURE Behavior OF regn IS
	BEGIN
		PROCESS (Clock)
			BEGIN
				IF (Clock'EVENT AND Clock = '1') THEN
					IF (Rin = '1') THEN
						Q <= R;
					END IF;
				END IF;
		END PROCESS;
END Behavior;
