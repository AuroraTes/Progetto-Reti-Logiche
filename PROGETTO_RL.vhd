-------------------------------------------------------------------------------
---- Prova Finale (Progetto di Reti Logiche)
-- Prof. Palermo - Anno 2021/2022
--
-- Aurora Tesin (Codice Persona 10652280 Matricola 913494)
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity project_reti_logiche is
port (
    i_clk : in std_logic;
    i_rst : in std_logic;
    i_start : in std_logic;
    i_data : in std_logic_vector(7 downto 0);
    o_address : out std_logic_vector(15 downto 0);
    o_done : out std_logic;
    o_en : out std_logic;
    o_we : out std_logic;
    o_data : out std_logic_vector (7 downto 0)
);
end project_reti_logiche;


architecture Behavior of project_reti_logiche is
  type STATE_TYPE is (
    START, READ_SIZE, WAIT_READ_SIZE, READ_BYTE, WAIT_READ_BYTE, WRITE_BYTE, WAIT_WRITE_BYTE, ELABORATE_BYTE, DONE );

  -- State register.
  signal state : STATE_TYPE := START;

  -- State flag registers.
  signal has_byte_number : boolean := false; -- Read number of bytes flag.
  signal set_address    : boolean := false; -- init addresses.
  signal done_read : boolean := false; 

  -- Process registers.
  signal last_byte_address : std_logic_vector(15 downto 0) := (others => '0'); 
  signal current_byte      : std_logic_vector(15 downto 0) := (others => '0'); 


  signal outdata: std_logic_vector ( 15 downto 0 ) := (others => '0');
  signal write2: boolean := false;
  
  signal out_address: std_logic_vector(15 downto 0 ) := "0000001111101000";

  
  -- Init the read loop of byte.
  procedure init_loop (
    signal o_address      : out std_logic_vector(15 downto 0);
    signal current_byte  : out std_logic_vector(15 downto 0)) is
  begin
    o_address     <= "0000000000000001";
    current_byte <= "0000000000000001";
  end procedure;
  
  
begin
  transitions: process (i_clk)
    variable addr, var , var2 : unsigned(15 downto 0) := (others => '0'); --variable to help to manage addresses.
    variable last1, last2, temp : std_logic := '0'; --variables to help elaborate the bytes.
  begin
  
    if rising_edge(i_clk) then
      o_done    <= '0';
      o_en      <= '0';
      o_we      <= '0';
      o_data    <= (others => '0');
      o_address <= (others => '0');
      
      if i_rst = '1' then
        state <= START;
        
      else  
        case state is
          when START =>
            has_byte_number  <= false;
            set_address       <= false;
            done_read  <= false;
            write2 <= false;
            last1 := '0';
            last2 := '0';
            temp := '0';
            last_byte_address  <= (others => '0');
            current_byte       <= (others => '0');
            if i_start = '1' then
              state <= READ_SIZE;
            else
              state <= START;
            end if;

          when READ_SIZE =>
            o_en <= '1';
            if not has_byte_number then
              o_address <= "0000000000000000";
              state <= WAIT_READ_SIZE;
              has_byte_number <= true;
            elsif not set_address  then
              last_byte_address <= "00000000" & i_data;
              state <= WAIT_READ_SIZE;
              set_address  <= true;
            else
              var := unsigned(last_byte_address);
              if not (var = "0000000000000000") then
                init_loop(o_address, current_byte);
                state <= WAIT_READ_BYTE;
              else
                o_done <= '1';
                state <= DONE;
              end if;
            end if;

          when WAIT_READ_SIZE =>
            state <= READ_SIZE;

          when READ_BYTE =>
            var := unsigned(current_byte) + 1;
            if not (std_logic_vector(var) = last_byte_address + 1) then
              current_byte <= std_logic_vector(var);
              o_address <= std_logic_vector(var);
              o_en <= '1';
              state <= WAIT_READ_BYTE;  
            else
              if not done_read then
                done_read <= true;
                o_en <= '1';
                state <= WAIT_READ_BYTE;
              else
                o_done <= '1';
                state <= DONE;
              end if;
            end if;

          when WAIT_READ_BYTE => 
              if not done_read then   
              state <= ELABORATE_BYTE;
              else
              state <= READ_BYTE;
              end if;
            
            when ELABORATE_BYTE =>
               outdata(15) <= i_data(7) xor last2;
               outdata(14) <= i_data(7) xor last1 xor last2;
               last1 := i_data(7);
               last2 := temp;
               outdata(13) <= i_data(6) xor last2;
               outdata(12) <= i_data(6) xor last1 xor last2;
               last2 := last1;
               last1 := i_data(6);
               outdata(11) <= i_data(5) xor last2;
               outdata(10) <= i_data(5) xor last1 xor last2;
               last2 := last1;
               last1 := i_data(5);
               outdata(9) <= i_data(4) xor last2;
               outdata(8) <= i_data(4) xor last1 xor last2;
               last2 := last1;
               last1 := i_data(4);
               outdata(7) <= i_data(3) xor last2;
               outdata(6) <= i_data(3) xor last1 xor last2;
               last2 := last1;
               last1 := i_data(3);
               outdata(5) <= i_data(2) xor last2;
               outdata(4) <= i_data(2) xor last1 xor last2;
               last2 := last1;
               last1 := i_data(2);
               outdata(3) <= i_data(1) xor last2;
               outdata(2) <= i_data(1) xor last1 xor last2;
               last2 := last1;
               last1 := i_data(1);
               outdata(1) <= i_data(0) xor last2;
               outdata(0) <= i_data(0) xor last1 xor last2;
               last2 := last1;
               last1 := i_data(0);
               temp := i_data(0);
               state <= WRITE_BYTE;
 
 
            when WRITE_BYTE =>
               o_en <= '1';
               o_we <= '1';
               if(not write2) then
                    o_address <= out_address;
                    o_data <= outdata(15 downto 8);
                    state <= WAIT_WRITE_BYTE;
               else 
                    addr := unsigned(out_address) +1;
                    o_address <= std_logic_vector(addr);
                    o_data <= outdata(7 downto 0);
                    state <= WAIT_WRITE_BYTE;
             end if;   
            
           

            when WAIT_WRITE_BYTE =>
              if not write2 then
                write2 <= true;
                state <= WRITE_BYTE;
              else
                out_address <= std_logic_vector(addr) + 1;
                write2 <= false;
                state <= READ_BYTE;
              end if;

            when DONE =>
              if i_start = '0' then
                state <= START;
              else
                o_done <= '1';
                state <= DONE;
            end if;

        end case;
      end if;
    end if;
  end process;
end architecture;