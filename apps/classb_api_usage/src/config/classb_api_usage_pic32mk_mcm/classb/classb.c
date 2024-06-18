/*******************************************************************************
  Class B Library v1.0.0 Release

  Company:
    Microchip Technology Inc.

  File Name:
    classb.c

  Summary:
    Class B Library main source file

  Description:
    This file provides general functions for the Class B library.

 *******************************************************************************/

/*******************************************************************************
 * Copyright (C) 2024 Microchip Technology Inc. and its subsidiaries.
 *
 * Subject to your compliance with these terms, you may use Microchip software
 * and any derivatives exclusively with Microchip products. It is your
 * responsibility to comply with third party license terms applicable to your
 * use of third party software (including open source software) that may
 * accompany Microchip software.
 *
 * THIS SOFTWARE IS SUPPLIED BY MICROCHIP "AS IS". NO WARRANTIES, WHETHER
 * EXPRESS, IMPLIED OR STATUTORY, APPLY TO THIS SOFTWARE, INCLUDING ANY IMPLIED
 * WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY, AND FITNESS FOR A
 * PARTICULAR PURPOSE.
 *
 * IN NO EVENT WILL MICROCHIP BE LIABLE FOR ANY INDIRECT, SPECIAL, PUNITIVE,
 * INCIDENTAL OR CONSEQUENTIAL LOSS, DAMAGE, COST OR EXPENSE OF ANY KIND
 * WHATSOEVER RELATED TO THE SOFTWARE, HOWEVER CAUSED, EVEN IF MICROCHIP HAS
 * BEEN ADVISED OF THE POSSIBILITY OR THE DAMAGES ARE FORESEEABLE. TO THE
 * FULLEST EXTENT ALLOWED BY LAW, MICROCHIP'S TOTAL LIABILITY ON ALL CLAIMS IN
 * ANY WAY RELATED TO THIS SOFTWARE WILL NOT EXCEED THE AMOUNT OF FEES, IF ANY,
 * THAT YOU HAVE PAID DIRECTLY TO MICROCHIP FOR THIS SOFTWARE.
 *******************************************************************************/

/*----------------------------------------------------------------------------
 *     include files
 *----------------------------------------------------------------------------*/
#include "classb.h"
#include "device.h"

/*----------------------------------------------------------------------------
 *     Constants
 *----------------------------------------------------------------------------*/ 
#define FLASH_START_ADDR 		            (0xBD000000U)
#define FLASH_SIZE       		            (0x100000U)
#define SRAM_RESERVED_START_ADDRESS         (0xa0000400U)
#define CLASSB_RESULT_ADDR                  (0xa0000400U)
#define CLASSB_COMPL_RESULT_ADDR            (0xa0000404U)
#define CLASSB_ONGOING_TEST_VAR_ADDR        (0xa0000408U)
#define CLASSB_TEST_IN_PROG_VAR_ADDR        (0xa000040cU)
#define CLASSB_WDT_TEST_IN_PROG_VAR_ADDR    (0xa0000410U)
#define CLASSB_FLASH_TEST_VAR_ADDR          (0xa0000414U)
#define CLASSB_INTERRUPT_TEST_VAR_ADDR      (0xa0000418U)
#define CLASSB_INTERRUPT_COUNT_VAR_ADDR     (0xa000041cU)
#define CLASSB_SRAM_STARTUP_TEST_SIZE       (2048U)
#define CLASSB_CLOCK_ERROR_PERCENT          (5U)

/* TMR1 is clocked from 32768 Hz Crystal for CPU clock test. 
   One TMR1 cycle is 30517 nano sec*/
#define CLASSB_CLOCK_TEST_TMR1_RATIO_NS      (30517U)
#define CLASSB_CLOCK_TEST_RATIO_NS_MS       (1000000U)
#define CLASSB_CLOCK_DEFAULT_CLOCK_FREQ     (120000000U)
#define CLASSB_INVALID_TEST_ID              (0xFFU)

typedef enum {
    RESET_REASON_NONE = 0x00000000,
    RESET_REASON_POWERON = 0x00000003,
    RESET_REASON_BROWNOUT = 0x00000002,
    RESET_REASON_WDT_TIMEOUT = 0x00000010,
    RESET_REASON_DMT_TIMEOUT = 0x00000020,
    RESET_REASON_SOFTWARE = 0x00000040,
    RESET_REASON_MCLR = 0x00000080,
    RESET_REASON_CONFIG_MISMATCH = 0x00000200,
    RESET_REASON_VBAT = 0x00010000,
    RESET_REASON_VBPOR = 0x00020000,
    RESET_REASON_PORIO = 0x80000000,
    RESET_REASON_PORCORE = 0x40000000,
    RESET_REASON_ALL = 0xC00302F5

} RESET_REASON;

static RESET_REASON resetReason;

/*----------------------------------------------------------------------------
 *     Global Variables
 *----------------------------------------------------------------------------*/
volatile uint8_t * ongoing_sst_id;
volatile uint8_t * classb_test_in_progress;
volatile uint8_t * wdt_test_in_progress;
volatile uint8_t * interrupt_tests_status;
volatile uint32_t * interrupt_count;

/*----------------------------------------------------------------------------
 *     Functions
 *----------------------------------------------------------------------------*/
/*============================================================================
static void sCLASSB_SystemReset(void)
------------------------------------------------------------------------------
Purpose: For software reset.
Input  : None
Output : None
Notes  : None
============================================================================*/
static void sCLASSB_SystemReset(void) 
{
    SYSKEY = 0x00000000U;
    SYSKEY = 0xAA996655U;
    SYSKEY = 0x556699AAU;
    
    RSWRSTSET = _RSWRST_SWRST_MASK;
    RSWRST;
    
    Nop();
    Nop();
    Nop();
    Nop();
}

/*============================================================================
static void sCLASSB_WDT_Clear( void )
------------------------------------------------------------------------------
Purpose: For WDT clear.
Input  : None
Output : None
Notes  : None
============================================================================*/
static void sCLASSB_WDT_Clear( void )
{
    /* Writing specific value to only upper 16 bits of WDTCON register clears WDT counter */
    /* Only write to the upper 16 bits of the register when clearing. */
    /* WDTCLRKEY = 0x5743 */
    WDTCONbits.WDTCLRKEY = 0x5743;
}

/*============================================================================
void CLASSB_SelfTest_FailSafe(CLASSB_TEST_ID test_id) 
------------------------------------------------------------------------------
Purpose: Called if a non-critical self-test is failed.
Input  : The ID of the failed test.
Output : None
Notes  : The application decides the contents of this function. This function
         should perform failsafe operation after checking the 'cb_test_id'.
         This function must not return.
============================================================================*/
void CLASSB_SelfTest_FailSafe(CLASSB_TEST_ID test_id) 
{
#if (defined(__DEBUG) || defined(__DEBUG_D)) && defined(__XC32)
    __builtin_software_breakpoint();
#endif
    // Infinite loop
    while (true) 
    {
        ;
    }
}

/*============================================================================
static void sCLASSB_GlobalsInit(void)
------------------------------------------------------------------------------
Purpose: Initialization of global variables for the classb library.
Input  : None
Output : Returns, if Startup self test performed or not 
Notes  : This function is called before C startup test
============================================================================*/
static void sCLASSB_GlobalsInit(void) 
{
    /* Initialize pointers needed to access variables in SRAM.
     * These variables point to address' in the reserved SRAM for the
     * Class B library.
     */
    ongoing_sst_id = (volatile uint8_t *)CLASSB_ONGOING_TEST_VAR_ADDR;
    classb_test_in_progress = (volatile uint8_t *)CLASSB_TEST_IN_PROG_VAR_ADDR;
    wdt_test_in_progress = (volatile uint8_t *)CLASSB_WDT_TEST_IN_PROG_VAR_ADDR;
    interrupt_tests_status = (volatile uint8_t *)CLASSB_INTERRUPT_TEST_VAR_ADDR;
    interrupt_count = (volatile uint32_t *)CLASSB_INTERRUPT_COUNT_VAR_ADDR;

    // Initialize variables
    *ongoing_sst_id = CLASSB_INVALID_TEST_ID;
    *classb_test_in_progress = (uint8_t)CLASSB_TEST_NOT_STARTED;
    *wdt_test_in_progress = (uint8_t)CLASSB_TEST_NOT_STARTED;
    *interrupt_tests_status = (uint8_t)CLASSB_TEST_NOT_STARTED;
}

/*============================================================================
static void sCLASSB_App_WDT_Recovery(void) 
------------------------------------------------------------------------------
Purpose: Called if a WDT reset is caused by the application
Input  : None
Output : None
Notes  : The application decides the contents of this function.
============================================================================*/
static void sCLASSB_App_WDT_Recovery(void) 
{
#if (defined(__DEBUG) || defined(__DEBUG_D)) && defined(__XC32)
    __builtin_software_breakpoint();
#endif
    // Infinite loop
    while (true) 
    {
        ;
    }
}

/*============================================================================
static void sCLASSB_SST_WDT_Recovery(void) 
------------------------------------------------------------------------------
Purpose: Called after WDT reset, to indicate that a Class B function is stuck.
Input  : None
Output : None
Notes  : The application decides the contents of this function.
============================================================================*/
static void sCLASSB_SST_WDT_Recovery(void) 
{
#if (defined(__DEBUG) || defined(__DEBUG_D)) && defined(__XC32)
    __builtin_software_breakpoint();
#endif
    // Infinite loop
    while (true) 
    {
        ;
    }
}

/*============================================================================
static void sCLASSB_TestWDT(void)
------------------------------------------------------------------------------
Purpose: Function to check WDT after a device reset.
Input  : None
Output : None
Notes  : None
============================================================================*/
static void sCLASSB_TestWDT(void) 
{
    /* This persistent flag is checked after reset */
    *wdt_test_in_progress = (uint8_t)CLASSB_TEST_STARTED;
    
    /* If WDT ALWAYSON is set, wait till WDT resets the device */
    if (DEVCFG1bits.FWDTEN == 1U) 
    {
        // Infinite loop
        while (true) 
        {
            ;
        }
    } 
    else 
    {
        // If WDT is not enabled, enable WDT and wait
        if (WDTCONbits.ON == 0U) 
        {
            WDTCONbits.ON = 1;
            // Infinite loop
            while (true) 
            {
                ;
            }
        } 
        else 
        {
            // Infinite loop
            while (true) 
            {
                ;
            }
        }
    }
}

/*============================================================================
static RESET_REASON sCLASSB_SYS_RESET_ReasonGet(void) 
------------------------------------------------------------------------------
Purpose: To check System reset reason
Input  : None
Output : None
Notes  : This function is executed to know the sytem reset reason.
============================================================================*/
static RESET_REASON sCLASSB_SYS_RESET_ReasonGet(void) 
{
    uint32_t reset_reason = RCON & ((uint32_t)_RCON_CMR_MASK | (uint32_t)_RCON_EXTR_MASK |
            (uint32_t)_RCON_SWR_MASK | (uint32_t)_RCON_DMTO_MASK | (uint32_t)_RCON_WDTO_MASK |
            (uint32_t)_RCON_BOR_MASK | (uint32_t)_RCON_POR_MASK | (uint32_t)_RCON_VBPOR_MASK |
            (uint32_t)_RCON_VBAT_MASK | (uint32_t)_RCON_PORIO_MASK | (uint32_t)_RCON_PORCORE_MASK);
    
    return  (RESET_REASON)(reset_reason);
}

/*============================================================================
static void sCLASSB_SYS_RESET_ReasonClear(RESET_REASON reason) 
------------------------------------------------------------------------------
Purpose: To clear RCON register.
Input  : None
Output : None
Notes  : This function is executed to clear RCON register.
============================================================================*/
static void sCLASSB_SYS_RESET_ReasonClear(RESET_REASON reason) 
{
    RCONCLR = (uint32_t)reason;
}

/*============================================================================
static CLASSB_INIT_STATUS sCLASSB_Init(void) 
------------------------------------------------------------------------------
Purpose: To check reset cause and decide the startup flow.
Input  : None
Output : None
Notes  : This function is executed on every device reset. This shall be
         called right after the reset, before any other initialization is
         performed.
============================================================================*/
static CLASSB_INIT_STATUS sCLASSB_Init(void) 
{
    /* Initialize pointers needed to access variables in SRAM.
     * These variables point to address' in the reserved SRAM for the
     * Class B library.
     */
    ongoing_sst_id = (volatile uint8_t *)CLASSB_ONGOING_TEST_VAR_ADDR;
    classb_test_in_progress = (volatile uint8_t *)CLASSB_TEST_IN_PROG_VAR_ADDR;
    wdt_test_in_progress = (volatile uint8_t *)CLASSB_WDT_TEST_IN_PROG_VAR_ADDR;
    interrupt_tests_status = (volatile uint8_t *)CLASSB_INTERRUPT_TEST_VAR_ADDR;
    interrupt_count = (volatile uint32_t *)CLASSB_INTERRUPT_COUNT_VAR_ADDR;
    CLASSB_INIT_STATUS ret_val = CLASSB_SST_NOT_DONE;
    resetReason = (RESET_REASON)sCLASSB_SYS_RESET_ReasonGet();
    sCLASSB_SYS_RESET_ReasonClear(RESET_REASON_ALL);
    
    /*Check if reset was triggered by WDT */
    if (((uint32_t)resetReason & (uint32_t)RESET_REASON_WDT_TIMEOUT) == (uint32_t)RESET_REASON_WDT_TIMEOUT) 
    {
        if (*wdt_test_in_progress == (uint32_t)CLASSB_TEST_STARTED) 
        {
            *wdt_test_in_progress = (uint8_t)CLASSB_TEST_NOT_STARTED;
        } 
        else if (*classb_test_in_progress == (uint32_t)CLASSB_TEST_STARTED) 
        {
            sCLASSB_SST_WDT_Recovery();
        } 
        else 
        {
            sCLASSB_App_WDT_Recovery();
        }
    } 
    else 
    {
        /* If it is a software reset and the Class B library has issued it */
        if ((*classb_test_in_progress == (uint32_t)CLASSB_TEST_STARTED) &&
                (((uint32_t)resetReason & (uint32_t)RESET_REASON_SOFTWARE) == (uint32_t)RESET_REASON_SOFTWARE)) 
        {
            *classb_test_in_progress = (uint8_t)CLASSB_TEST_NOT_STARTED;
            ret_val = CLASSB_SST_DONE;
        } 
        else 
        {
            /* For all other reset causes,
             * test the reserved SRAM,
             * initialize Class B variables
             * clear the test results and test WDT
             */
            bool result_area_test_ok = false;
            bool ram_buffer_test_ok = false;
            // Test the reserved SRAM
            result_area_test_ok = CLASSB_RAMMarchC((uint32_t *) SRAM_RESERVED_START_ADDRESS, CLASSB_SRAM_TEST_BUFFER_SIZE);
            ram_buffer_test_ok = CLASSB_RAMMarchC((uint32_t *) SRAM_RESERVED_START_ADDRESS + CLASSB_SRAM_TEST_BUFFER_SIZE, CLASSB_SRAM_TEST_BUFFER_SIZE);
            if ((result_area_test_ok == true) && (ram_buffer_test_ok == true)) 
            {
                // Initialize all Class B variables
                sCLASSB_GlobalsInit();
                CLASSB_ClearTestResults(CLASSB_TEST_TYPE_SST);
                CLASSB_ClearTestResults(CLASSB_TEST_TYPE_RST);
                // Perform WDT test
                sCLASSB_TestWDT();
            } 
            else 
            {
                while (true) 
                {
                    ;
                }
            }
        }
    }

    return ret_val;
}

/*============================================================================
static CLASSB_STARTUP_STATUS sCLASSB_Startup_Tests(void) 
------------------------------------------------------------------------------
Purpose: Call all startup self-tests.
Input  : None
Output : None
Notes  : This function calls all the configured self-tests during startup.
         The MPLAB Harmony Configurator (MHC) has options to configure
         the startup self-tests. If startup tests are not enabled via MHC,
         this function enables the WDT and returns CLASSB_STARTUP_TEST_NOT_EXECUTED.
============================================================================*/
static CLASSB_STARTUP_STATUS sCLASSB_Startup_Tests(void) 
{
    CLASSB_STARTUP_STATUS cb_startup_status = CLASSB_STARTUP_TEST_NOT_EXECUTED;
    CLASSB_STARTUP_STATUS cb_temp_startup_status = CLASSB_STARTUP_TEST_NOT_EXECUTED;
    CLASSB_TEST_STATUS cb_test_status = CLASSB_TEST_NOT_EXECUTED;
    uint16_t clock_test_tmr1_cycles = ((5U * CLASSB_CLOCK_TEST_RATIO_NS_MS) / CLASSB_CLOCK_TEST_TMR1_RATIO_NS);

    //Enable watchdog if it is not enabled via fuses
    if ( DEVCFG1bits.FWDTEN == 0U )
    {
        if(WDTCONbits.ON == 0U)
        {
            WDTCONbits.ON = 1;
        }
    }
    // Update the flag before running any self-test
    *classb_test_in_progress = (uint8_t)CLASSB_TEST_STARTED;	
    sCLASSB_WDT_Clear();
    
    // Test processor core registers
    *ongoing_sst_id = (uint8_t)CLASSB_TEST_CPU;
    cb_test_status = CLASSB_CPU_RegistersTest(false);

    if (cb_test_status == CLASSB_TEST_PASSED) 
    {
        cb_temp_startup_status = CLASSB_STARTUP_TEST_PASSED;
    } 
    else if (cb_test_status == CLASSB_TEST_FAILED) 
    {
        cb_temp_startup_status = CLASSB_STARTUP_TEST_FAILED;
    }
    else
    {
       /*do nothing*/
       ;
    }
    sCLASSB_WDT_Clear();
        
    // Program Counter test
    *ongoing_sst_id = (uint8_t)CLASSB_TEST_PC;
    cb_test_status = CLASSB_CPU_PCTest(false);

    if (cb_test_status == CLASSB_TEST_PASSED) 
    {
        cb_temp_startup_status = CLASSB_STARTUP_TEST_PASSED;
    } 
    else if (cb_test_status == CLASSB_TEST_FAILED) 
    {
        cb_temp_startup_status = CLASSB_STARTUP_TEST_FAILED;
    }
    else
    {
       /*do nothing*/
       ;
    }
    sCLASSB_WDT_Clear();    
    
    // Test processor FPU registers
    *ongoing_sst_id = (uint8_t)CLASSB_TEST_FPU;
    cb_test_status = CLASSB_FPU_RegistersTest(false);

    if (cb_test_status == CLASSB_TEST_PASSED) 
    {
        cb_temp_startup_status = CLASSB_STARTUP_TEST_PASSED;
    } 
    else if (cb_test_status == CLASSB_TEST_FAILED) 
    {
        cb_temp_startup_status = CLASSB_STARTUP_TEST_FAILED;
    }
    else
    {
       /*do nothing*/
       ;
    }   
    sCLASSB_WDT_Clear();
    
    //SRAM test
    // Clear WDT before test
    sCLASSB_WDT_Clear();
    *ongoing_sst_id = (uint8_t)CLASSB_TEST_RAM;
            
    cb_test_status = CLASSB_SRAM_MarchTestInit((uint32_t *)CLASSB_SRAM_APP_AREA_START,
        CLASSB_SRAM_STARTUP_TEST_SIZE, CLASSB_SRAM_MARCH_C, false);
    if (cb_test_status == CLASSB_TEST_PASSED) 
    {
        cb_temp_startup_status = CLASSB_STARTUP_TEST_PASSED;
    } 
    else if (cb_test_status == CLASSB_TEST_FAILED) 
    {
        cb_temp_startup_status = CLASSB_STARTUP_TEST_FAILED;
    }
    else
    {
        /*do nothing*/
        ;
    }           
    sCLASSB_WDT_Clear();
    
    
    // Clock Test
    *ongoing_sst_id = (uint8_t)CLASSB_TEST_CLOCK;

    cb_test_status = CLASSB_ClockTest(CLASSB_CLOCK_DEFAULT_CLOCK_FREQ, CLASSB_CLOCK_ERROR_PERCENT, clock_test_tmr1_cycles, false);
            
    if (cb_test_status == CLASSB_TEST_PASSED)
    {
        cb_temp_startup_status = CLASSB_STARTUP_TEST_PASSED;
    }
    else if (cb_test_status == CLASSB_TEST_FAILED)
    {

        cb_temp_startup_status = CLASSB_STARTUP_TEST_FAILED;
    }
    else
    {
        /*do nothing*/
        ;
    }
    sCLASSB_WDT_Clear();
      
    // Interrupt Test
    *ongoing_sst_id = (uint8_t)CLASSB_TEST_INTERRUPT;
    // Clear WDT before test
    sCLASSB_WDT_Clear();
            
    cb_test_status = CLASSB_SST_InterruptTest();
    if (cb_test_status == CLASSB_TEST_PASSED)
    {
        cb_temp_startup_status = CLASSB_STARTUP_TEST_PASSED;
    }
    else if (cb_test_status == CLASSB_TEST_FAILED)
    {
        cb_temp_startup_status = CLASSB_STARTUP_TEST_FAILED;
    }
    else
    {
        /*do nothing*/
        ;
    }
    sCLASSB_WDT_Clear();

    if (cb_temp_startup_status == CLASSB_STARTUP_TEST_PASSED) 
    {
        cb_startup_status = CLASSB_STARTUP_TEST_PASSED;
    } 
    else 
    {
        cb_startup_status = CLASSB_STARTUP_TEST_FAILED;
    }
    return cb_startup_status;
}

/*============================================================================
void _on_bootstrap(void)
------------------------------------------------------------------------------
Purpose: Handle reset causes and perform start-up self-tests.
Input  : None
Output : None
Notes  : This function is called from Reset_Handler.
============================================================================*/

/* MISRA C-2012 Rule 21.2 violated 2 times below. Deviation record ID - MISRAC_2012_R_21_2_DR_01*/
void _on_bootstrap(void);/* Declaration required to avoid MISRA error Rule 8.4 */ 

void _on_bootstrap(void) 
{
    CLASSB_STARTUP_STATUS startup_tests_status = CLASSB_STARTUP_TEST_FAILED;
    CLASSB_INIT_STATUS init_status = sCLASSB_Init();
    if (init_status == CLASSB_SST_NOT_DONE) 
    {
        // Run all startup self-tests
        startup_tests_status = sCLASSB_Startup_Tests();
        if (startup_tests_status == CLASSB_STARTUP_TEST_PASSED) 
        {
            // Reset the device if all tests are passed.
            sCLASSB_SystemReset();
        } 
        else if (startup_tests_status == CLASSB_STARTUP_TEST_FAILED) 
        {
#if (defined(__DEBUG) || defined(__DEBUG_D)) && defined(__XC32)
            __builtin_software_breakpoint();
#endif            
            // Infinite loop
            while (true) 
            {
                ;
            }
        } 
        else 
        {
            // If startup tests are not enabled via MHC, do nothing.
            ;
        }
    } 
    else if (init_status == CLASSB_SST_DONE) 
    {
        // Clear flags
        *classb_test_in_progress = (uint8_t)CLASSB_TEST_NOT_STARTED;
    } 
    else
    {
        // The init_status is neither CLASSB_SST_NOT_DONE nor CLASSB_SST_DONE, do nothing.
        ;
    }
}
/* MISRAC 2012 deviation block end */
