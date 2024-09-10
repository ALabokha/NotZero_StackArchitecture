library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

package commands is

constant RAM_chunk_size: integer := 8;
constant RAM_address_width: integer := 6;
subtype RAM_chunk is std_logic_vector(RAM_chunk_size-1 downto 0);
subtype RAM_address_chunk is std_logic_vector(RAM_address_width-1 downto 0);

constant ROM_command_width: integer := 4;
constant ROM_operand_width: integer := RAM_chunk_size;
constant ROM_chunk_size: integer := ROM_command_width + ROM_operand_width;
constant ROM_address_width: integer := 5;
subtype ROM_chunk is std_logic_vector(ROM_chunk_size-1 downto 0);
subtype operand_chunk is std_logic_vector(ROM_operand_width-1 downto 0);
subtype command_chunk is std_logic_vector(ROM_command_width-1 downto 0);
subtype ROM_address_chunk is std_logic_vector(ROM_address_width-1 downto 0);

constant CMD_PUSH_R: command_chunk := (others => '0');	-- 0
constant CMD_INC_R: command_chunk := CMD_PUSH_R + "1";	-- 1
constant CMD_DECR_R: command_chunk := CMD_INC_R + "1";	-- 10
constant CMD_SUB_L: command_chunk := CMD_DECR_R + "1";	-- 11
constant CMD_SUB: command_chunk := CMD_SUB_L + "1";		-- 100
constant CMD_BTFSC: command_chunk := CMD_SUB + "1";		-- 101
constant CMD_BTFSS: command_chunk := CMD_BTFSC + "1";		-- 110
constant CMD_GOTO: command_chunk := CMD_BTFSS + "1";		-- 111
constant CMD_POP: command_chunk := CMD_GOTO + "1";			-- 1000
constant CMD_CLR_R: command_chunk := CMD_POP + "1";		-- 1001
constant CMD_LOAD_R: command_chunk := CMD_CLR_R + "1";	-- 1010
constant CMD_END: command_chunk := CMD_LOAD_R + "1";		-- 1011

constant REGFile_chunk_size: integer := RAM_address_width;
constant REGFile_address_width: integer := 2;
subtype REGFile_chunk is std_logic_vector(REGFile_chunk_size-1 downto 0);
subtype REGFile_address_chunk is std_logic_vector(REGFile_address_width-1 downto 0);

constant RAMAddressMax : integer := 2 ** RAM_address_width - 1;
type RAM_inner_data is array (0 to RAMAddressMax) of RAM_chunk;
constant REGFileAddressMax : integer := 2 ** REGFile_address_width - 1;
type REGFile_inner_data is array (0 to REGFileAddressMax) of REGFile_chunk;
constant ROMAddressMax : integer := 2 ** ROM_address_width - 1;
type ROM_inner_data is array (0 to ROMAddressMax) of ROM_chunk;
constant StackMaxPointer : integer := 7;
type TStack is array (0 to StackMaxPointer) of RAM_chunk;

constant ROM_data_amount: ROM_inner_data := (
0 => CMD_CLR_R & "00000000",		--clear result
1 => CMD_CLR_R & "00000001",		--clear error code
2 => CMD_PUSH_R & "00000011",		--CMD_PUSH_R min_address
3 => CMD_SUB_L & "00000101",		--SUBSTRACT literal from top stack value
4 => CMD_BTFSC & "00000000", 		--BTFSC STATUS, 0
5 => CMD_GOTO & "00011001",			--GOTO SET ERROR CODE
6 => CMD_PUSH_R & "00000100",		--CMD_PUSH_R max_address
7 => CMD_SUB_L & "10000000",		--SUBSTRACT literal from top stack value
8 => CMD_BTFSS & "00000000", 		--BTFSC STATUS, 0
9 => CMD_GOTO & "00011001",			--GOTO SET ERROR CODE
10 => CMD_PUSH_R & "00000011",		--CMD_PUSH_R min address
11 => CMD_SUB & "00000100",			--PUSH value from address to stack and SUBSTRACT stack values, top - second top  --SUB command leaves lowest operand on stack
12 => CMD_BTFSC & "00000000", 		--BTFSC STATUS, 0
13 => CMD_GOTO & "00011001",		--GOTO SET ERROR CODE
14 => CMD_PUSH_R & "00000100",		--CMD_PUSH_R max_address
15 => CMD_POP & "00000010",			--CMD_POP to cur_address
--cycle 10000
16 => CMD_LOAD_R & "00000010",		--CMD_PUSH_R current address
17 => CMD_SUB_L & "00000000",		--substract zero
18 => CMD_BTFSS & "00000001", 		--BTFSC STATUS, 2
19 => CMD_INC_R & "00000000", 		--Inc non zero amount if zero flag isn't set
20 => CMD_DECR_R & "00000010", 		--decr current address
21 => CMD_SUB & "00000010",			--CMD_PUSH_R cur_address
22 => CMD_BTFSS & "00000000", 		--BTFSS STATUS, 0
23 => CMD_GOTO & "00010000", 		--goto cycle
24 => CMD_GOTO & "00011010",		--GOTO WRITE RESULT
--set error code 11001
25 => CMD_INC_R & "00000001",		--set, that error occured
--finish execution 11010
26 => CMD_END & "00000000",			--end
others => (others => '0')
);

constant ROM_data_amount_fast: ROM_inner_data := (
0 => CMD_CLR_R & "00000000",		--clear result
1 => CMD_CLR_R & "00000001",		--clear error code
2 => CMD_PUSH_R & "00000011",		--CMD_PUSH_R min address
3 => CMD_PUSH_R & "00000100",		--CMD_PUSH_R max_address
4 => CMD_POP & "00000010",			--CMD_POP to cur_address
--cycle 00101
5 => CMD_LOAD_R & "00000010",		--CMD_PUSH_R current address
6 => CMD_SUB_L & "00000000",		--substract zero
7 => CMD_BTFSS & "00000001", 		--BTFSC STATUS, 2
8 => CMD_INC_R & "00000000", 		--Inc non zero amount if zero flag isn't set
9 => CMD_DECR_R & "00000010", 		--decr current address
10 => CMD_SUB & "00000010",			--CMD_PUSH_R cur_address
11 => CMD_BTFSS & "00000000", 		--BTFSS STATUS, 0
12 => CMD_GOTO & "00000101", 		--goto cycle
13 => CMD_END & "00000000",			--end
others => (others => '0')
);

constant RAM_data_amount: RAM_inner_data := (
0 => "00000000", 	--result
1 => "00000000", 	--error_code
2 => "00000000", 	--current address
3 => "00000111", 	--min_address
4 => "01111111", 	--max_address
--data array 0 to 7
5 => "00000000",	
6 => "00110000",		
7 => "00010011",
8 => "00000000",
9 => "00000000",
10 => "00000111",
11 => "10000000",
12 => "00001010", 
others => (others => '0')
);

constant RAM_wrong_adresses: RAM_inner_data := (
0 => "00000000", 	--result
1 => "00000000", 	--error_code
2 => "00000000", 	--current address
3 => "00000111", 	--min_address
4 => "00000110", 	--max_address
--data array 0 to 7
5 => "00000000",	
6 => "00110000",		
7 => "00010011",
8 => "00000000",
9 => "00000000",
10 => "00000111",
11 => "10000000",
12 => "00001010", 
others => (others => '0')
);

constant Stack_empty: TStack := (
others => (others => '0')
);


end commands;

--package body commands is
--end commands;
