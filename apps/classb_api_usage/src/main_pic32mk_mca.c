/*******************************************************************************
  Main Source File

  Company:
    Microchip Technology Inc.

  File Name:
    main.c

  Summary:
    This is an example application for the Class B library API usage.

  Description:
    This file contains the "main" function for a project.  The
    "main" function calls the "SYS_Initialize" function to initialize the state
    machines of all modules in the system
 *******************************************************************************/

// *****************************************************************************
// *****************************************************************************
// Section: Included Files
// *****************************************************************************
// *****************************************************************************

#include <stddef.h>                     // Defines NULL
#include <stdbool.h>                    // Defines true
#include <stdlib.h>                     // Defines EXIT_FAILURE
#include "definitions.h"                // SYS function prototypes

#define SRAM_RST_SIZE                       (28672U)
#define FLASH_CRC32_ADDR                    (0xBD01E000U)
#define FLASH_START_ADDRESS                 (0xBD000000U)
#define FLASH_TEST_SIZE                     (0x1E000U)
#define CPU_FREQUENCY                 (120000000U)
#define CLOCK_TEST_ERROR_LIMIT              (5U)
#define CLOCK_TEST_TMR1_CYCLE               (163U)

uint32_t crc_val[1] CACHE_ALIGN;
uint32_t crc_val_flash[1];
uint32_t * app_crc_addr = (uint32_t *) FLASH_CRC32_ADDR;
static volatile bool xferDone = false;
char test_status_str[4][25] = {"CLASSB_TEST_NOT_EXECUTED",
    "CLASSB_TEST_PASSED",
    "CLASSB_TEST_FAILED",
    "CLASSB_TEST_INPROGRESS"};

static void eventHandler(uintptr_t context) {
    xferDone = true;
}
// *****************************************************************************
// *****************************************************************************
// Section: Main Entry Point
// *****************************************************************************
// *****************************************************************************

int main ( void )
{
    /* Initialize all modules */
    SYS_Initialize ( NULL );

    printf("\r\n\r\n        Class B API Usage Demo      \r\n");
    printf("\r\n\r\n Class B startup self-test results \r\n");
    CLASSB_TEST_STATUS classb_test_status = CLASSB_TEST_NOT_EXECUTED;
    classb_test_status = CLASSB_GetTestResult(CLASSB_TEST_TYPE_SST, CLASSB_TEST_CPU);
    printf("\r\n\tResult of CPU SST is %s\r\n", test_status_str[classb_test_status]);
    classb_test_status = CLASSB_GetTestResult(CLASSB_TEST_TYPE_SST, CLASSB_TEST_PC);
    printf("\r\n\tResult of PC SST is %s\r\n", test_status_str[classb_test_status]);
    classb_test_status = CLASSB_GetTestResult(CLASSB_TEST_TYPE_SST, CLASSB_TEST_FPU);
    printf("\r\n\tResult of FPU SST is %s\r\n", test_status_str[classb_test_status]);
    classb_test_status = CLASSB_GetTestResult(CLASSB_TEST_TYPE_SST, CLASSB_TEST_RAM);
    printf("\r\n\tResult of SRAM SST is %s\r\n", test_status_str[classb_test_status]);
    classb_test_status = CLASSB_GetTestResult(CLASSB_TEST_TYPE_SST, CLASSB_TEST_FLASH);
    printf("\r\n\tResult of Flash SST is %s\r\n", test_status_str[classb_test_status]);
    classb_test_status = CLASSB_GetTestResult(CLASSB_TEST_TYPE_SST, CLASSB_TEST_CLOCK);
    printf("\r\n\tResult of Clock SST is %s\r\n", test_status_str[classb_test_status]);
    classb_test_status = CLASSB_GetTestResult(CLASSB_TEST_TYPE_SST, CLASSB_TEST_INTERRUPT);
    printf("\r\n\tResult of Interrupt SST is %s\r\n", test_status_str[classb_test_status]);
    
    printf("\r\n\r\n Class B run-time self-tests (RST) \r\n");
    
    /* CPU self test */
    classb_test_status = CLASSB_TEST_FAILED;
    classb_test_status = CLASSB_CPU_RegistersTest(true);
    printf("\r\n\tResult of CPU RST is %s\r\n", test_status_str[classb_test_status]);

    /* Program Counter self test */
    classb_test_status = CLASSB_TEST_FAILED;
    classb_test_status = CLASSB_CPU_PCTest(true);
    printf("\r\n\tResult of PC RST is %s\r\n", test_status_str[classb_test_status]);

    /* FPU self test */
    classb_test_status = CLASSB_TEST_FAILED;
    classb_test_status = CLASSB_FPU_RegistersTest(true);
    printf("\r\n\tResult of FPU RST is %s\r\n", test_status_str[classb_test_status]);
    
    /* NVM self test */
    NVM_CallbackRegister(eventHandler, (uintptr_t) NULL);
    while (NVM_IsBusy() == true);
    xferDone = false;
    while (NVM_IsBusy() == true);
    /* Erase the Page */
    NVM_PageErase(FLASH_CRC32_ADDR);
    while (xferDone == false);
    xferDone = false;
    /* Generate CRC-32 over internal flash address 0 (Virtual address : FLASH_START_ADDRESS) to 
     * 0x7E000 (Virtual address : FLASH_START_ADDRESS + 0x7E000) */
    crc_val[0] = CLASSB_FlashCRCGenerate(FLASH_START_ADDRESS, FLASH_TEST_SIZE);
    while (NVM_IsBusy() == true);
    /* Use NVMCTRL to write the calculated CRC into a Flash location */
    NVM_RowWrite((uint32_t *) crc_val, FLASH_CRC32_ADDR);
    while (xferDone == false);
    xferDone = false;
    NVM_Read((uint32_t *) & crc_val_flash, sizeof (crc_val_flash), FLASH_CRC32_ADDR);
    classb_test_status = CLASSB_TEST_FAILED;
    classb_test_status = CLASSB_FlashCRCTest(FLASH_START_ADDRESS, FLASH_TEST_SIZE,
            *(uint32_t *) crc_val_flash, true);
    printf("\r\n\tResult of Flash RST is %s\r\n", test_status_str[classb_test_status]);
    
    /* SRAM self test */
    /* Disable global interrupts */
    __builtin_disable_interrupts();
    classb_test_status = CLASSB_SRAM_MarchTestInit((uint32_t *) CLASSB_SRAM_APP_AREA_START,
            SRAM_RST_SIZE, CLASSB_SRAM_MARCH_C, true);
    /* Enable global interrupts */
    __builtin_enable_interrupts();
    printf("\r\n\tResult of SRAM RST is %s\r\n", test_status_str[classb_test_status]);
    
    /* CPU Clock self test */
    __builtin_disable_interrupts();
    classb_test_status = CLASSB_ClockTest(CPU_FREQUENCY, CLOCK_TEST_ERROR_LIMIT, CLOCK_TEST_TMR1_CYCLE, true);
    __builtin_enable_interrupts();
    printf("\r\n\tResult of CPU Clock RST is %s\r\n", test_status_str[classb_test_status]);
    
    /* GPIO self test */
    LED1_On();
    CLASSB_RST_IOTest(CLASSB_GPIO_PORT_A, CLASSB_GPIO_PIN_RA10, PORT_PIN_LOW);
    classb_test_status = CLASSB_GetTestResult(CLASSB_TEST_TYPE_RST, CLASSB_TEST_IO);
    printf("\r\n\tResult of GPIO RST test is %s\r\n", test_status_str[classb_test_status]);
    
    while ( true )
    {
        /* Maintain state machines of all polled MPLAB Harmony modules. */
        SYS_Tasks ( );
    }

    /* Execution should not come here during normal operation */

    return ( EXIT_FAILURE );
}


/*******************************************************************************
 End of File
*/

