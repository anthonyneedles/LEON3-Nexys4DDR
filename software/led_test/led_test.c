#include <stdio.h>
#include <stdlib.h>

#define ioread32(baseaddr, offset) \
    (*((volatile uint32_t*)(baseaddr + offset)))

#define iowrite32(baseaddr, offset, value) \
    (*((volatile uint32_t*)(baseaddr + offset)) = value)

#define LED_REG (0x80000900)

void wait_cycles(unsigned cycles) 
{
    unsigned i = 0;
    while (i < cycles) {
        ++i;
    }
}

int main(void) 
{
    unsigned led_val = 0;

    printf("reeeeeeeeee\n");

    while (1) {
        iowrite32(LED_REG, 0, led_val);
        wait_cycles(7000000);
        if (led_val < 65535) {
            led_val++;
        } else {
            led_val = 0;
        }
    }        
}