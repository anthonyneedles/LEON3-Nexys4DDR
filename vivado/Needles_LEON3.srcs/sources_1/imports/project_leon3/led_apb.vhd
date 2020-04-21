library ieee;
  use ieee.std_logic_1164.all;

library grlib;
  use grlib.amba.all;
  use grlib.stdlib.all;
  use grlib.devices.all;

entity nexys_led_apb is
  generic (
    pindex : integer := 4;
    paddr  : integer := 4;
    pmask  : integer := 16#fff#
  );
  port (
    clk : in std_logic;
    reset : in std_logic;
    apbi : in apb_slv_in_type;
    apbo : out apb_slv_out_type;
    led  : out std_logic_vector(15 downto 0)
  );
end entity nexys_led_apb;

architecture rtl of nexys_led_apb is

  signal led_qq, led_q  : std_logic_vector(15 downto 0);
  signal apb_wr : std_logic;
  constant pconfig : apb_config_type := (
    0 => ahb_device_reg(VENDOR_CONTRIB, CUSTOM_LED, 0, 0, 0),
    1 => apb_iobar(paddr, pmask)
  );

  begin
    apb_wr <= apbi.penable and apbi.psel(pindex) and apbi.pwrite;
    
    apbo.pindex <= pindex;
    apbo.pconfig <= pconfig;
    
    apb_write_proc : process(apbi, apb_wr)
      variable read_led_reg : std_logic_vector(31 downto 0);
      variable write_led    : std_logic_vector(15 downto 0);
      begin
        read_led_reg(31 downto 16) := (others => '0');
        read_led_reg(15 downto 0) := led_qq;
        write_led := led_qq;
        if apb_wr = '1' then
          write_led := apbi.pwdata(15 downto 0);
        end if;
        led_q <= write_led;
        apbo.prdata <= read_led_reg;
        apbo.pirq <= (others => '0');
    end process apb_write_proc;

    reg : process(clk, reset)
    begin
        if (reset = '0') then
          led_qq <= (others => '0');
        elsif rising_edge(clk) then
          led <= led_qq;
          led_qq <= led_q;
        end if;
    end process reg;

end rtl;
