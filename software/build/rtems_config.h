/* rtems_config.h
 *
 * Minimum rtems config
 *
 * Anthony Needles
 */

#ifndef __RTEMS_CONFIG_H
#define __RTEMS_CONFIG_H

#include <rtems.h>

#define CONFIGURE_INIT

#include <bsp.h> /* for device driver prototypes */

rtems_task Init(rtems_task_argument argument);	/* forward declaration needed */

#define CONFIGURE_APPLICATION_NEEDS_CONSOLE_DRIVER
#define CONFIGURE_APPLICATION_NEEDS_CLOCK_DRIVER
#define CONFIGURE_MAXIMUM_TASKS             4
#define CONFIGURE_RTEMS_INIT_TASKS_TABLE
#define CONFIGURE_LIBIO_MAXIMUM_FILE_DESCRIPTORS 32
#define CONFIGURE_EXTRA_TASK_STACKS         (3 * RTEMS_MINIMUM_STACK_SIZE)

#include <rtems/confdefs.h>

#endif /* __RTEMS_CONFIG_H */
