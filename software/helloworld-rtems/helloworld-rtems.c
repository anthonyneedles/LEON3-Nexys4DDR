/* helloworld-rtems.c
 *
 * Tests rtems and io functionality
 *
 * Anthony Needles
 */

#include "../build/rtems_config.h"
#include <grlib/ambapp.h>
#include <grlib/ambapp_ids.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#define ioread32(baseaddr, offset) \
    (*((volatile uint32_t*)(baseaddr + offset)))

#define iowrite32(baseaddr, offset, value) \
    (*((volatile uint32_t*)(baseaddr + offset)) = value)

#define GET_APB_DEV(ven, dev) ((struct ambapp_dev *)ambapp_for_each( \
            &ambapp_plb, \
            (OPTIONS_ALL | OPTIONS_APB_SLVS), \
            ven, dev, \
            ambapp_find_by_idx, 0))

#define GET_AHB_DEV(ven, dev) ((struct ambapp_dev *)ambapp_for_each( \
            &ambapp_plb, \
            (OPTIONS_ALL | OPTIONS_AHB_SLVS | OPTIONS_AHB_MSTS), \
            ven, dev, \
            ambapp_find_by_idx, 0))

#define LED_DEVICE_NUM (1)

void wait_cycles(unsigned cycles)
{
    volatile unsigned i = 0;
    while (i < cycles) {
        ++i;
    }
}

int main(void)
{
    struct ambapp_apb_info *apb_dev;
    struct ambapp_ahb_info *ahb_dev;
    char *led_reg;
    unsigned led_val = 0;

    ahb_dev = DEV_TO_AHB(GET_AHB_DEV(VENDOR_GAISLER, GAISLER_SPIMCTRL));
    printf("SPI MCTRL (AHB MEM)\n");
    printf("  Addr:  0x%08x - 0x%08x\n  Size:  %dMB\n  IRQ #: %d\n",
            ahb_dev->start[1], ahb_dev->start[1] + ahb_dev->mask[1],
            ahb_dev->mask[1]/1024/1024, ahb_dev->irq);

    ahb_dev = DEV_TO_AHB(GET_AHB_DEV(VENDOR_GAISLER, GAISLER_DDR2SP));
    printf("DDR2 MCTRL (AHB MEM)\n");
    printf("  Addr:  0x%08x - 0x%08x\n  Size:  %dMB\n",
            ahb_dev->start[0], ahb_dev->start[0] + ahb_dev->mask[0],
            ahb_dev->mask[0]/1024/1024);

    ahb_dev = DEV_TO_AHB(GET_AHB_DEV(VENDOR_GAISLER, GAISLER_APBMST));
    printf("AHB/APB BRIDGE (AHB MEM)\n");
    printf("  Addr:  0x%08x - 0x%08x\n  Size:  %dMB\n",
            ahb_dev->start[0], ahb_dev->start[0] + ahb_dev->mask[0],
            ahb_dev->mask[0]/1024/1024);

    apb_dev = DEV_TO_APB(GET_APB_DEV(VENDOR_GAISLER, GAISLER_APBUART));
    printf("APB UART (APB IO)\n");
    printf("  Addr:  0x%08x - 0x%08x\n  Size:  %dB\n  IRQ #: %d\n",
            apb_dev->start, apb_dev->start + apb_dev->mask, apb_dev->mask,
            apb_dev->irq);

    apb_dev = DEV_TO_APB(GET_APB_DEV(VENDOR_GAISLER, GAISLER_IRQMP));
    printf("IRQ CTRL (APB IO)\n");
    printf("  Addr:  0x%08x - 0x%08x\n  Size:  %dB\n",
            apb_dev->start, apb_dev->start + apb_dev->mask, apb_dev->mask);

    apb_dev = DEV_TO_APB(GET_APB_DEV(VENDOR_GAISLER, GAISLER_GPTIMER));
    printf("GP TIMER (APB IO)\n");
    printf("  Addr:  0x%08x - 0x%08x\n  Size:  %dB\n  IRQ #: %d\n",
            apb_dev->start, apb_dev->start + apb_dev->mask, apb_dev->mask,
            apb_dev->irq);

    apb_dev = DEV_TO_APB(GET_APB_DEV(VENDOR_GAISLER, GAISLER_AHBUART));
    printf("AHB UART (APB IO)\n");
    printf("  Addr:  0x%08x - 0x%08x\n  Size:  %dB\n",
            apb_dev->start, apb_dev->start + apb_dev->mask, apb_dev->mask);

    apb_dev = DEV_TO_APB(GET_APB_DEV(VENDOR_CONTRIB, LED_DEVICE_NUM));
    led_reg = (char *)apb_dev->start;
    printf("LED DEVICE (APB IO)\n");
    printf("  Addr:  0x%08x - 0x%08x\n  Size:  %dB\n",
            apb_dev->start, apb_dev->start + apb_dev->mask, apb_dev->mask);

    ahb_dev = DEV_TO_AHB(GET_AHB_DEV(VENDOR_GAISLER, GAISLER_LEON3DSU));
    printf("LEON3 DSU (AHB MEM)\n");
    printf("  Addr:  0x%08x - 0x%08x\n  Size:  %dMB\n",
            ahb_dev->start[0], ahb_dev->start[0] + ahb_dev->mask[0],
            ahb_dev->mask[0]/1024/1024);

    ahb_dev = DEV_TO_AHB(GET_AHB_DEV(VENDOR_GAISLER, GAISLER_DDR2SP));
    printf("DDR2 MCTRL (AHB IO)\n");
    printf("  Addr:  0x%08x - 0x%08x\n  Size:  %dB\n",
            ahb_dev->start[1], ahb_dev->start[1] + ahb_dev->mask[1],
            ahb_dev->mask[1]);

    ahb_dev = DEV_TO_AHB(GET_AHB_DEV(VENDOR_GAISLER, GAISLER_SPIMCTRL));
    printf("SPI MCTRL (AHB IO)\n");
    printf("  Addr:  0x%08x - 0x%08x\n  Size:  %dB\n  IRQ #: %d\n",
            ahb_dev->start[0], ahb_dev->start[0] + ahb_dev->mask[0],
            ahb_dev->mask[0], ahb_dev->irq);

    while (1) {
        iowrite32(led_reg, 0, led_val);
        wait_cycles(700000);
        if (led_val < 65535) {
            led_val++;
        } else {
            led_val = 0;
        }
    }
}

rtems_task Init(rtems_task_argument ignored)
{
    (void)ignored;
    int ret = main();
    exit(ret);
}
