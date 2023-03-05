LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_signed.all;

ENTITY upcount IS
	PORT ( Clear, Clock : IN STD_LOGIC;
			Q : OUT STD_LOGIC_VECTOR(1 DOWNTO 0));
END upcount;

--Conta em que step (tempos T0, T1, T2, T3) está!
ARCHITECTURE Behavior OF upcount IS
	SIGNAL Count : STD_LOGIC_VECTOR(1 DOWNTO 0);
	BEGIN
		PROCESS (Clock)
			BEGIN
				IF (Clock'EVENT AND Clock = '1') THEN
					IF (Clear = '1') THEN
						Count <= "00";
					ELSE
						Count <= Count + 1;
					END IF;
				END IF;
		END PROCESS;
	Q <= Count;
END Behavior;
