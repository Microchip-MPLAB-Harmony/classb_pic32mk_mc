/*******************************************************************************
  Class B Library ${REL_VER} Release

  Company:
    Microchip Technology Inc.

  File Name:
    classb_clock_test.c

  Summary:
    Class B Library CPU clock frequency self-test source file

  Description:
    This file provides CPU clock frequency self-test.

*******************************************************************************/

/*******************************************************************************
* Copyright (C) ${REL_YEAR} Microchip Technology Inc. and its subsidiaries.
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
#include "classb/classb_clock_test.h"
#include "definitions.h"
/*----------------------------------------------------------------------------
 *     Constants
 *----------------------------------------------------------------------------*/
#define CLASSB_CLOCK_MAX_CLOCK_FREQ             (${CLASSB_CPU_MAX_CLOCK}U)
#define CLASSB_CLOCK_MAX_SYSTICK_VAL            (0x${CLASSB_SYSTICK_MAXCOUNT}U)
#define CLASSB_CLOCK_MAX_TMR1_PERIOD_VAL        (654U)
#define CLASSB_CLOCK_TMR1_CLK_FREQ              (${CLASSB_TMR1_EXPECTED_CLOCK}U)
#define CLASSB_CLOCK_MAX_TEST_ACCURACY          (${CLASSB_CPU_CLOCK_TEST_ACCUR}U)
/* Since no floating point is used for clock test, multiply intermediate
 * values with 128.
 */
#define CLASSB_CLOCK_MUL_FACTOR                 (128U)

/*----------------------------------------------------------------------------
 *     Global Variables
 *----------------------------------------------------------------------------*/

/*----------------------------------------------------------------------------
 *     Functions
 *----------------------------------------------------------------------------*/


/*============================================================================
static uint32_t sCLASSB_Clock_CoreTimer_GetCount(void)
------------------------------------------------------------------------------
Purpose: Reads the Core Timer count value
Input  : None.
Output : Core Timer count value.
Notes  : None.
============================================================================*/
static uint32_t sCLASSB_Clock_CoreTimer_GetCount( void )
{
    uint32_t count;
    count = _CP0_GET_COUNT();
    return count;
}   

/*============================================================================
static void sCLASSB_Clock_CoreTimer_Start(void)
------------------------------------------------------------------------------
Purpose: Configure the SysTick for clock self-test
Input  : None.
Output : None.
Notes  : If SysTick is used by the application, ensure that it
         is reconfigured after the clock self test.
============================================================================*/
static void sCLASSB_Clock_CoreTimer_Start( void )
{
    // Disable Timer by setting Disable Count (DC) bit
    _CP0_SET_CAUSE(_CP0_GET_CAUSE() | _CP0_CAUSE_DC_MASK);
    // Disable Interrupt
    IEC0CLR=0x1;
    // Clear Core Timer
    _CP0_SET_COUNT(0);
    _CP0_SET_COMPARE(0xFFFFFFFF);
    // Enable Timer by clearing Disable Count (DC) bit
    _CP0_SET_CAUSE(_CP0_GET_CAUSE() & (~_CP0_CAUSE_DC_MASK));
    
}

/*============================================================================
static void sCLASSB_Clock_TMR1_Enable(void)
------------------------------------------------------------------------------
Purpose: Enables the TMR1
Input  : None.
Output : None.
Notes  : None.
============================================================================*/
static void sCLASSB_Clock_TMR1_Enable ( void )
{
    T1CONSET = _T1CON_ON_MASK;
}

/*============================================================================
static void sCLASSB_Clock_TMR1_Init(void)
------------------------------------------------------------------------------
Purpose: Configure TMR1 peripheral
Input  : None.
Output : None.
Notes  : This self-test configures TMR1 to use an external
         32.768kHz Crystal as reference clock. Do not use this self-test
         if the external crystal is not available.
============================================================================*/
static void sCLASSB_Clock_TMR1_Init(void)
{
    /* Disable Timer */
    T1CONCLR = _T1CON_ON_MASK;
    
    /*
    SIDL = 0
    TWDIS = 0
    TECS = 0
    TGATE = 0
    TCKPS = 0
    TSYNC = 1
    TCS = 1
    */
    T1CONSET = 0x6; //Prescaler - 1:1, External clock SOSC, Synchronization mode enabled

    /* Clear counter */
    TMR1 = 0x0;

    /*Set period */
    PR1 = 162; // 5 Ms

    
    /* Wait for SOSC ready */
    while(!(CLKSTAT & 0x00000014)) 
    {
        /*Wait*/
      ;   
    }
}

/*============================================================================
void sCLASSB_CLock_TMR1_IntSourceEnable( void )
------------------------------------------------------------------------------
Purpose: Enable TMR1 EVIC source for CPU clock self-test
Input  : None.
Output : None.
Notes  : None.
============================================================================*/
static void sCLASSB_CLock_TMR1_IntSourceEnable( void )
{
    volatile uint32_t *IECx = (volatile uint32_t *) (&IEC0 + ((0x10 * (_TIMER_1_VECTOR / 32)) / 4));
    volatile uint32_t *IECxSET = (volatile uint32_t *)(IECx + 2);

    *IECxSET = 1 << (_TIMER_1_VECTOR & 0x1f);
}

/*============================================================================
static void sCLASSB_Clock_TMR1_Period_Set(void)
------------------------------------------------------------------------------
Purpose: Configure TMR1 peripheral for CPU clock self-test
Input  : None.
Output : None.
Notes  : The clocks required for TMR1 are configured in a separate function.
============================================================================*/
static void sCLASSB_Clock_TMR1_PeriodSet(uint32_t period)
{
    PR1 = period;
}

/*============================================================================
static void sCLASSB_Clock_CLK_Initialize(void)
------------------------------------------------------------------------------
Purpose: Configure clock for CPU clock self-test
Input  : None.
Output : None.
============================================================================*/
static void sCLASSB_Clock_CLK_Initialize(void)
{
    /* unlock system for clock configuration */
    SYSKEY = 0x00000000U;
    SYSKEY = 0xAA996655U;
    SYSKEY = 0x556699AAU;


    PMD4bits.T1MD = 0;


    /* Lock system since done with clock configuration */
    SYSKEY = 0x33333333U;
}

/*============================================================================
static void sCLASSB_EVIC_Initialize(void)
------------------------------------------------------------------------------
Purpose: Initialize EVIC register set
Input  : None.
Output : None.
Notes  : None.
============================================================================*/
static void sCLASSB_Clock_EVIC_Initialize(void)
{
    INTCONSET = _INTCON_MVEC_MASK;
    
    /* Configure Shadow Register Set */
    PRISS = 0x76543210;
}

/*============================================================================
bool sCLASSB_Clock_TMR1_GetIntFlagStatus( void )
------------------------------------------------------------------------------
Purpose: Get TMR1 EVIC source status
Input  : TMR1 interrupt flag status.
Output : None.
Notes  : None.
============================================================================*/
static bool sCLASSB_Clock_TMR1_GetIntFlagStatus( void )
{
    volatile uint32_t *IFSx = (volatile uint32_t *)(&IFS0 + ((0x10 * (_TIMER_1_VECTOR / 32)) / 4));

    return (bool)((*IFSx >> (_TIMER_1_VECTOR & 0x1f)) & 0x1);
}

/*============================================================================
static void sCLASSB_Clock_TMR1_ClearIntFlagStatus( void )
------------------------------------------------------------------------------
Purpose: Clear EVIC source status
Input  : None.
Output : None.
Notes  : None.
============================================================================*/
static void sCLASSB_Clock_TMR1_ClearIntFlagStatus( void )
{
    volatile uint32_t *IFSx = (volatile uint32_t *) (&IFS0 + ((0x10 * (_TIMER_1_VECTOR / 32)) / 4));
    volatile uint32_t *IFSxCLR = (volatile uint32_t *)(IFSx + 1);

    *IFSxCLR = 1 << (_TIMER_1_VECTOR & 0x1f);
}

/*============================================================================
CLASSB_TEST_STATUS CLASSB_ClockTest(uint32_t cpu_clock_freq,
    uint8_t error_limit,
    uint8_t clock_test_tmr1_cycles,
    bool running_context);
------------------------------------------------------------------------------
Purpose: Check whether CPU clock frequency is within acceptable limits.
Input  : Expected CPU clock frequency value, acceptable error percentage,
         test duration (in TMR1 cycles) and running context.
Output : Test status.
Notes  : None.
============================================================================*/


CLASSB_TEST_STATUS CLASSB_ClockTest(uint32_t cpu_clock_freq,
    uint8_t error_limit,
    uint32_t clock_test_tmr1_cycles,
    bool running_context)
{
    
    CLASSB_TEST_STATUS clock_test_status = CLASSB_TEST_NOT_EXECUTED;
    uint64_t expected_ticks = (uint64_t)(((uint64_t)cpu_clock_freq / CLASSB_CLOCK_TMR1_CLK_FREQ) * clock_test_tmr1_cycles);
    volatile uint32_t systick_count_a = 0U;
    volatile uint32_t systick_count_b = 0U;
    uint32_t ticks_passed = 0;
    uint8_t calculated_error_limit = 0U;
    
    if (running_context == true)
    {
        sCLASSB_UpdateTestResult(CLASSB_TEST_TYPE_RST, CLASSB_TEST_CLOCK,
            CLASSB_TEST_NOT_EXECUTED);
    }
    else
    {
        sCLASSB_UpdateTestResult(CLASSB_TEST_TYPE_SST, CLASSB_TEST_CLOCK,
            CLASSB_TEST_NOT_EXECUTED);
    }
    
    if ((clock_test_tmr1_cycles > CLASSB_CLOCK_MAX_TMR1_PERIOD_VAL)
        ||(expected_ticks > CLASSB_CLOCK_MAX_SYSTICK_VAL)
        || (cpu_clock_freq > CLASSB_CLOCK_MAX_CLOCK_FREQ)
        || (error_limit < CLASSB_CLOCK_MAX_TEST_ACCURACY))
    {
        ;
    }
    else
    {
        
        if (running_context == true)
        {
            sCLASSB_UpdateTestResult(CLASSB_TEST_TYPE_RST, CLASSB_TEST_CLOCK,
                CLASSB_TEST_INPROGRESS);
        }
        else
        {
            sCLASSB_UpdateTestResult(CLASSB_TEST_TYPE_SST, CLASSB_TEST_CLOCK,
                CLASSB_TEST_INPROGRESS);
        }
        
        /*Below initialization required for TMR1 module and system clock to operate properly */
        (void)__builtin_disable_interrupts();
        sCLASSB_Clock_CLK_Initialize();
        (void)__builtin_enable_interrupts();

        sCLASSB_Clock_TMR1_Init();
        sCLASSB_Clock_TMR1_PeriodSet(clock_test_tmr1_cycles);
        sCLASSB_CLock_TMR1_IntSourceEnable();
        sCLASSB_Clock_CoreTimer_Start();
        sCLASSB_Clock_TMR1_Enable();
        
        while(!sCLASSB_Clock_TMR1_GetIntFlagStatus())
        {
            ;
        }
        sCLASSB_Clock_TMR1_ClearIntFlagStatus();
        
        systick_count_a = sCLASSB_Clock_CoreTimer_GetCount();
        while(!sCLASSB_Clock_TMR1_GetIntFlagStatus())
        {
            ;
        }
        
        systick_count_b = sCLASSB_Clock_CoreTimer_GetCount();
        
        /*Core timer increments at half the system clock frequency (SYSCLK).*/
        expected_ticks = expected_ticks/2 ;
        
        ticks_passed = (systick_count_b); //to avoid MISRA C violation
        ticks_passed -= (systick_count_a);//to avoid MISRA C violation


        if (ticks_passed < expected_ticks)
        {
            // The CPU clock is slower than expected
            calculated_error_limit = (uint8_t)((((expected_ticks - ticks_passed) * CLASSB_CLOCK_MUL_FACTOR)/ (expected_ticks)) * 100) / CLASSB_CLOCK_MUL_FACTOR;
        }
        else
        {
            // The CPU clock is faster than expected
            calculated_error_limit = (uint8_t)((((ticks_passed - expected_ticks) * CLASSB_CLOCK_MUL_FACTOR)/ (expected_ticks)) * 100) / CLASSB_CLOCK_MUL_FACTOR;
        }

        if (error_limit > calculated_error_limit)
        {
            clock_test_status = CLASSB_TEST_PASSED;
            if (running_context == true)
            {
                sCLASSB_UpdateTestResult(CLASSB_TEST_TYPE_RST, CLASSB_TEST_CLOCK,
                    CLASSB_TEST_PASSED);
            }
            else
            {
                sCLASSB_UpdateTestResult(CLASSB_TEST_TYPE_SST, CLASSB_TEST_CLOCK,
                    CLASSB_TEST_PASSED);
            }
        }
        else
        {
            clock_test_status = CLASSB_TEST_FAILED;
            if (running_context == true)
            {
                sCLASSB_UpdateTestResult(CLASSB_TEST_TYPE_RST, CLASSB_TEST_CLOCK,
                    CLASSB_TEST_FAILED);
            }
            else
            {
                sCLASSB_UpdateTestResult(CLASSB_TEST_TYPE_SST, CLASSB_TEST_CLOCK,
                    CLASSB_TEST_FAILED);
            }
            CLASSB_SelfTest_FailSafe(CLASSB_TEST_CLOCK);
        }
    }

    return clock_test_status;
}
