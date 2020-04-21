------------------------------------------------------------------------------
-- EN525.412 Computer architecture
-- Author: Ali Ahmad
-- Final Project
-- Nexys4 LEON3 Implementation
------------------------------------------------------------------------------
-- The HDL within this file is a custom implementation of the LEON3 processor on
-- the Nexys4 board. It utilizes design principles provided by Cobham Gaisler as
-- per the Cobham Gaisler GRLIB IP Library. The design is a very basic Implementation
-- of the LEON3 running on the Nexys4 board.
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
library grlib;
use grlib.amba.all;
use grlib.stdlib.all;
use grlib.devices.all;
library techmap;
use techmap.gencomp.all;
use techmap.allclkgen.all;
library gaisler;
use gaisler.memctrl.all;
use gaisler.leon3.all;
use gaisler.uart.all;
use gaisler.misc.all;
use gaisler.spi.all;
use gaisler.net.all;
use gaisler.jtag.all;
use gaisler.ddrpkg.all;
--pragma translate_off
use gaisler.sim.all;
library unisim;
use unisim.BUFG;
--pragma translate_on
--library esa;
--use esa.memoryctrl.all;
use work.config.all;

--library testgrouppolito;
--use testgrouppolito.dprc_pkg.all;

entity nexys4_top is
  generic (
    fabtech  : integer := CFG_FABTECH;
    memtech  : integer := CFG_MEMTECH;
    padtech  : integer := CFG_PADTECH;
    clktech  : integer := CFG_CLKTECH;
    disas    : integer := CFG_DISAS;     -- Enable disassembly to console
    dbguart  : integer := CFG_DUART;     -- Print UART on console
    pclow    : integer := CFG_PCLOW;
    SIM_BYPASS_INIT_CAL : string := "OFF";
    SIMULATION          : string := "FALSE";
    USE_MIG_INTERFACE_MODEL : boolean := false
    );
  port (
    sys_clk_i             : in    std_ulogic;
    -- onBoard DDR2
    ddr2_dq         : inout   std_logic_vector(15 downto 0);
    ddr2_addr       : out   std_logic_vector(12 downto 0);
    ddr2_ba         : out   std_logic_vector(2 downto 0);
    ddr2_ras_n      : out   std_ulogic;
    ddr2_cas_n      : out   std_ulogic;
    ddr2_we_n       : out   std_ulogic;
    ddr2_cke        : out   std_logic_vector(0 downto 0);
    ddr2_odt        : out   std_logic_vector(0 downto 0);
    ddr2_cs_n       : out   std_logic_vector(0 downto 0);
    ddr2_dm         : out   std_logic_vector(1 downto 0);
    ddr2_dqs_p      : inout   std_logic_vector(1 downto 0);
    ddr2_dqs_n      : inout   std_logic_vector(1 downto 0);
    ddr2_ck_p       : out   std_logic_vector(0 downto 0);
    ddr2_ck_n       : out   std_logic_vector(0 downto 0);

    -- LEDs
    Led             : out   std_logic_vector(15 downto 0);

    btnCpuResetn    : in    std_ulogic;
    uart_txd_in     : in    std_logic;
    uart_rxd_out    : out   std_logic;
    
    sd_reset        : out std_ulogic;
    sd_cd           : in  std_ulogic;
    sd_sclk         : out std_ulogic;
    sd_mosi         : out std_ulogic;
    sd_miso         : in  std_ulogic;
    sd_csn          : out std_ulogic);
end;

architecture rtl of nexys4_top is

  signal CLKFBOUT      : std_logic;
  signal CLKFBIN       : std_logic;


  signal apbi  : apb_slv_in_type;
  signal apbo  : apb_slv_out_vector := (others => apb_none);
  signal ahbsi : ahb_slv_in_type;
  signal ahbso : ahb_slv_out_vector := (others => ahbs_none);
  signal ahbmi : ahb_mst_in_type;
  signal ahbmo : ahb_mst_out_vector := (others => ahbm_none);

  signal cgi : clkgen_in_type;
  signal cgo, cgo1 : clkgen_out_type;

  signal u1i, dui : uart_in_type;
  signal u1o, duo : uart_out_type;

  signal irqi : irq_in_vector(0 to CFG_NCPU-1);
  signal irqo : irq_out_vector(0 to CFG_NCPU-1);

  signal dbgi : l3_debug_in_vector(0 to CFG_NCPU-1);
  signal dbgo : l3_debug_out_vector(0 to CFG_NCPU-1);

  signal dsui : dsu_in_type;
  signal dsuo : dsu_out_type;
  signal ndsuact : std_ulogic;

  signal gpti : gptimer_in_type;

  signal clkm : std_ulogic;

  signal rstn, clkml  : std_ulogic;
  signal tck, tms, tdi, tdo : std_ulogic;
  signal rstraw             : std_logic;
  signal btnCpuReset        : std_logic;
  signal lock, lock0        : std_logic;

  signal ddr0_clkv        : std_logic_vector(2 downto 0);
  signal ddr0_clkbv       : std_logic_vector(2 downto 0);
  signal ddr0_cke         : std_logic_vector(1 downto 0);
  signal ddr0_csb         : std_logic_vector(1 downto 0);
  signal ddr0_odt         : std_logic_vector(1 downto 0);
  signal ddr0_addr        : std_logic_vector(13 downto 0);
  signal ddr0_clk_fb      : std_logic;

  -- RS232 APB Uart
  signal rxd1 : std_logic;
  signal txd1 : std_logic;

  signal spmi1 : spimctrl_in_type;
  signal spmo1 : spimctrl_out_type;

  attribute keep                     : boolean;
  attribute syn_keep                 : boolean;
  attribute syn_preserve             : boolean;
  attribute syn_keep of lock         : signal is true;
  attribute syn_keep of clkml        : signal is true;
  attribute syn_keep of clkm         : signal is true;
  attribute syn_preserve of clkml    : signal is true;
  attribute syn_preserve of clkm     : signal is true;
  attribute keep of lock             : signal is true;
  attribute keep of clkml            : signal is true;
  attribute keep of clkm             : signal is true;

  constant BOARD_FREQ : integer := 100000;                                -- CLK input frequency in KHz
  constant CPU_FREQ   : integer := BOARD_FREQ * CFG_CLKMUL / CFG_CLKDIV;  -- cpu frequency in KHz

begin

----------------------------------------------------------------------
---  Reset and Clock generation  -------------------------------------
----------------------------------------------------------------------

  btnCpuReset<= not btnCpuResetn;
  cgi.pllctrl <= "00";
  cgi.pllrst <= rstraw;

  rst0 : rstgen generic map (acthigh => 1)
    port map (btnCpuReset, clkm, lock, rstn, rstraw);
  lock <=  cgo.clklock and lock0;

  -- clock generator
    clkgen0 : clkgen
      generic map (fabtech, CFG_CLKMUL, CFG_CLKDIV, 0, 0, 0, 0, 0, BOARD_FREQ, 0)
      port map (sys_clk_i, '0', clkm, open, open, open, open, cgi, cgo, open, open, open);

----------------------------------------------------------------------
---  AHB CONTROLLER --------------------------------------------------
----------------------------------------------------------------------

  ahb0 : ahbctrl
    generic map (defmast => CFG_DEFMST, split => CFG_SPLIT,
                 rrobin  => CFG_RROBIN, ioaddr => CFG_AHBIO, ioen => 1,
                 nahbm => CFG_NCPU+CFG_AHB_UART+CFG_AHB_JTAG+CFG_GRETH+CFG_PRC*2,
                 nahbs => 8)
    port map (rstn, clkm, ahbmi, ahbmo, ahbsi, ahbso);

----------------------------------------------------------------------
---  LEON3 processor and DSU -----------------------------------------
----------------------------------------------------------------------

  -- LEON3 processor
    cpu : for i in 0 to CFG_NCPU-1 generate
      u0 : leon3s
        generic map (i, fabtech, memtech, CFG_NWIN, CFG_DSU, CFG_FPU, CFG_V8,
                     0, CFG_MAC, pclow, CFG_NOTAG, CFG_NWP, CFG_ICEN, CFG_IREPL, CFG_ISETS, CFG_ILINE,
                     CFG_ISETSZ, CFG_ILOCK, CFG_DCEN, CFG_DREPL, CFG_DSETS, CFG_DLINE, CFG_DSETSZ,
                     CFG_DLOCK, CFG_DSNOOP, CFG_ILRAMEN, CFG_ILRAMSZ, CFG_ILRAMADDR, CFG_DLRAMEN,
                     CFG_DLRAMSZ, CFG_DLRAMADDR, CFG_MMUEN, CFG_ITLBNUM, CFG_DTLBNUM, CFG_TLB_TYPE, CFG_TLB_REP,
                     CFG_LDDEL, disas, CFG_ITBSZ, CFG_PWD, CFG_SVT, CFG_RSTADDR,
                     CFG_NCPU-1, CFG_DFIXED, CFG_SCAN, CFG_MMU_PAGE, CFG_BP, CFG_NP_ASI, CFG_WRPSR)
        port map (clkm, rstn, ahbmi, ahbmo(i), ahbsi, ahbso, irqi(i), irqo(i), dbgi(i), dbgo(i));
    end generate;

    -- LEON3 Debug Support Unit
      dsu0 : dsu3
        generic map (hindex => 2, haddr => 16#900#, hmask => 16#F00#, ahbpf => CFG_AHBPF,
                     ncpu   => CFG_NCPU, tbits => 30, tech => memtech, irq => 0, kbytes => CFG_ATBSZ)
        port map (rstn, clkm, ahbmi, ahbsi, ahbso(2), dbgo, dbgi, dsui, dsuo);

      dsui.enable <= '1';

  -- Debug UART
    dcom0 : ahbuart
      generic map (hindex => CFG_NCPU, pindex => 4, paddr => 7)
      port map (rstn, clkm, dui, duo, apbi, apbo(4), ahbmi, ahbmo(CFG_NCPU));
    dsurx_pad : inpad generic map (tech  => padtech) port map (uart_txd_in, dui.rxd);
    dsutx_pad : outpad generic map (tech => padtech) port map (uart_rxd_out, duo.txd);

    ahbjtag0 : ahbjtag generic map(tech => fabtech, hindex => CFG_NCPU+CFG_AHB_UART)
      port map(rstn, clkm, tck, tms, tdi, tdo, ahbmi, ahbmo(CFG_NCPU+CFG_AHB_UART),
               open, open, open, open, open, open, open, '0');

----------------------------------------------------------------------
---  DDR2 Memory controller ------------------------------------------
----------------------------------------------------------------------
    ddrc : ddr2spa generic map (fabtech => fabtech, memtech => memtech,
             hindex => 5, haddr => 16#400#, hmask => 16#F80#, ioaddr => 1, rstdel => 200, -- iomask generic default value
             MHz => CPU_FREQ/1000, TRFC => CFG_DDR2SP_TRFC, clkmul => 12,
             clkdiv => 6, col => CFG_DDR2SP_COL, Mbyte => CFG_DDR2SP_SIZE,
             pwron => CFG_DDR2SP_INIT, ddrbits => CFG_DDR2SP_DATAWIDTH, raspipe => 0,
             ahbfreq => CPU_FREQ/1000, readdly => 0, rskew => 0, oepol => 0,
             ddelayb0 => CFG_DDR2SP_DELAY0, ddelayb1 => CFG_DDR2SP_DELAY1,
             ddelayb2 => CFG_DDR2SP_DELAY2, ddelayb3 => CFG_DDR2SP_DELAY3,
             ddelayb4 => CFG_DDR2SP_DELAY4, ddelayb5 => CFG_DDR2SP_DELAY5,
             ddelayb6 => CFG_DDR2SP_DELAY6, ddelayb7 => CFG_DDR2SP_DELAY7, -- cbdelayb0-3 generics not used in non-ft mode
             numidelctrl => 1, norefclk => 1, -- dqsse, ahbbits, bigmem, nclk, scantest and octen default
             nosync => CFG_DDR2SP_NOSYNC, eightbanks => 1, odten => 3, dqsgating => 0,
             burstlen => 8, ft => CFG_DDR2SP_FTEN, ftbits => CFG_DDR2SP_FTWIDTH)
            port map (
              btnCpuResetn, rstn, clkm, clkm, clkm, lock0, clkml, clkml, ahbsi, ahbso(5),
              ddr0_clkv, ddr0_clkbv, ddr0_clk_fb, ddr0_clk_fb,
              ddr0_cke, ddr0_csb, ddr2_we_n, ddr2_ras_n, ddr2_cas_n,
              ddr2_dm, ddr2_dqs_p, ddr2_dqs_n, ddr0_addr, ddr2_ba, ddr2_dq, ddr0_odt,open);

    ddr2_addr <= ddr0_addr(12 downto 0);
    ddr2_cke  <= ddr0_cke(0 downto 0);
    ddr2_cs_n  <= ddr0_csb(0 downto 0);
    ddr2_ck_p(0) <= ddr0_clkv(0);
    ddr2_ck_n(0) <= ddr0_clkbv(0);
    ddr2_odt  <= ddr0_odt(0 downto 0);

----------------------------------------------------------------------
---  SPI Memory Controller (SD Card)   -------------------------------
----------------------------------------------------------------------

spimctrl1 : spimctrl
    generic map (hindex => 4, hirq => 4, faddr => 16#000#, fmask => 16#ff0#,
                 ioaddr => 2, iomask => 16#fff#, spliten => CFG_SPLIT,
                 sdcard => 0, readcmd => 16#0B#, dummybyte => 1, dualoutput => 0,
                 scaler => 1, altscaler => 1)
    port map (rstn, clkm, ahbsi, ahbso(4), spmi1, spmo1);
    
    spi_miso_pad : inpad generic map (tech => padtech)
        port map (sd_miso, spmi1.miso);
    spi_mosi_pad : outpad generic map (tech => padtech)
        port map (sd_mosi, spmo1.mosi);
    spi_sck_pad : outpad generic map (tech => padtech)
        port map (sd_sclk, spmo1.sck);
    spi_slvsel0_pad : outpad generic map (tech => padtech)
        port map (sd_csn, spmo1.csn);

----------------------------------------------------------------------
---  APB Bridge and various periherals -------------------------------
----------------------------------------------------------------------

  -- APB Bridge
  apb0 : apbctrl
    generic map (hindex => 1, haddr => CFG_APBADDR)
    port map (rstn, clkm, ahbsi, ahbso(1), apbi, apbo);

  -- Interrupt controller
    irqctrl0 : irqmp
      generic map (pindex => 2, paddr => 2, ncpu => CFG_NCPU)
      port map (rstn, clkm, apbi, apbo(2), irqo, irqi);

  -- Time Unit
    timer0 : gptimer
      generic map (pindex => 3, paddr => 3, pirq => CFG_GPT_IRQ,
                   sepirq => CFG_GPT_SEPIRQ, sbits => CFG_GPT_SW,
                   ntimers => CFG_GPT_NTIM, nbits  => CFG_GPT_TW)
      port map (rstn, clkm, apbi, apbo(3), gpti, open);
    gpti <= gpti_dhalt_drive(dsuo.tstop);

  U_LED : entity work.nexys_led_apb
    generic map (pindex => 5, paddr => 9)
    port map (clkm, rstn, apbi, apbo(5), Led);

    uart1 : apbuart                     -- UART 1
      generic map (pindex   => 1, paddr => 1, pirq => 2, console => dbguart, fifosize => CFG_UART1_FIFO)
      port map (rstn, clkm, apbi, apbo(1), u1i, u1o);
    u1i.rxd    <= rxd1;
    u1i.ctsn   <= '0';
    u1i.extclk <= '0';
    txd1       <= u1o.txd;
  noua0 : if CFG_UART1_ENABLE = 0 generate apbo(1) <= apb_none; end generate;
-----------------------------------------------------------------------
---  Drive unused bus elements  ---------------------------------------
-----------------------------------------------------------------------

  nam1 : for i in (CFG_NCPU+CFG_AHB_UART+CFG_AHB_JTAG+CFG_GRETH+CFG_PRC*2+1) to NAHBMST-1 generate
    ahbmo(i) <= ahbm_none;
  end generate;

end rtl;
