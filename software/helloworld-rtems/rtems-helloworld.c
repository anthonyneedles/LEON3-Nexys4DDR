/* helloworld-rtems.c
 *
 * Tests rtems and io functionality
 *
 * Anthony Needles
 */

#include "../build/rtems_config.h"
#include <gaisler/ambapp.h>
#include <ambapp_ids.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#define ioread32(baseaddr, offset) \
    (*((volatile uint32_t*)(baseaddr + offset)))

#define iowrite32(baseaddr, offset, value) \
    (*((volatile uint32_t*)(baseaddr + offset)) = value)

#define LED_REG (0x80000900)

#define ANY_AMBA_VENDOR (-1)
#define ANY_AMBA_DEVICE (-1)

void wait_cycles(unsigned cycles)
{
    volatile unsigned i = 0;
    while (i < cycles) {
        ++i;
    }
}

int main(void)
{
    unsigned led_val = 0;

    printf("RTEMS Program\n");

    struct ambapp_dev *adev;
    adev = (struct ambapp_dev *)ambapp_for_each(
            &ambapp_plb,
            (OPTIONS_ALL | OPTIONS_APB_SLVS),
            ANY_AMBA_VENDOR, ANY_AMBA_DEVICE,
            ambapp_find_by_dx,
            0);

    if (!adev) {
        printf("could not find ambapp ahb device (%d)\n", adev);
    } else {
        struct ambapp_apb_info *apb_dev = DEV_TO_APB(adev);
        printf("addr: %p\n", apb_dev->start);
    }

    while (1) {
        iowrite32(LED_REG, 0, led_val);
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
