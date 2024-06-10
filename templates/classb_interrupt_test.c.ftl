/*******************************************************************************
  Class B Library ${REL_VER} Release

  Company:
    Microchip Technology Inc.

  File Name:
    classb_interrupt_test.c

  Summary:
    Class B Library source file for the Interrupt test

  Description:
    This file provides self-test functions for the Interrupt.

*******************************************************************************/

/*******************************************************************************
* Copyright (C) ${REL_VER} Microchip Technology Inc. and its subsidiaries.
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
#include "classb/classb_interrupt_test.h"
#include "definitions.h"

/*----------------------------------------------------------------------------
 *     Constants
 *----------------------------------------------------------------------------*/

#define CORE_TIMER_FREQ                     60000000
#define CLASSB_INTR_MAX_INT_COUNT           (15U)
#define sCLASSB_enable_interrupt_asm()      __asm__ volatile ("ehb");
#define sCLASSB_disable_interrupt_asm()     __asm__ volatile ("di");

/*----------------------------------------------------------------------------
 *     Global Variables
 *----------------------------------------------------------------------------*/
static uint32_t ebase_org;
static uint32_t off_org;

/*----------------------------------------------------------------------------
 *     Functions
 *----------------------------------------------------------------------------*/

/*============================================================================
static void  __attribute__((interrupt(IPL1SRS))) __attribute__((address(0x9D002200),nomips16,nomicromips) ) sCLASSB_TMR2_Handler(void)
------------------------------------------------------------------------------
Purpose: Custom handler used for Timer Interrupt test. It clears the interrupt
         flag and updates the interrupt count variable.
Input  : None.
Output : None.
Notes  : None.
============================================================================*/
static void  __attribute__((interrupt(IPL1SRS))) __attribute__((address(0x9D002200),nomips16,nomicromips) ) sCLASSB_TMR2_Handler(void)
{
    /* Clear the status flag */
    IFS0CLR = _IFS0_T2IF_MASK;
    (*interrupt_count)++;
}
/*============================================================================
static void sCLASSB_set_ebase(unsigned int value)
------------------------------------------------------------------------------
Purpose: Setting value of Ebase and TMR2 OFF register   
Input  : Ebase value.
Output : None.
============================================================================*/
static void sCLASSB_set_ebase(unsigned int value)
{
    /* unlock system */
    SYSKEY = 0x00000000U;
    SYSKEY = 0xAA996655U;
    SYSKEY = 0x556699AAU;
    
    /*Set the CP0 registers for multi-vector interrupt */
    INTCONCLR = _INTCON_MVEC_MASK;// Set the MVEC bit
    
    unsigned int temp_CP0;// Temporary register for CP0 register storing 
    sCLASSB_disable_interrupt_asm();// Disable all interrupts 
    sCLASSB_enable_interrupt_asm();// Disable all interrupts 
    
    temp_CP0 = _CP0_GET_STATUS();// Get Status 
    temp_CP0 |= 0x00400000U;// Set Bev 
    _CP0_SET_STATUS(temp_CP0);// Update Status
    sCLASSB_enable_interrupt_asm();
    
    _CP0_SET_INTCTL(0x10 << 5);
    sCLASSB_enable_interrupt_asm();
    
    /****************Setting new ebase and offset *****************/
    _CP0_SET_EBASE(value);// Set an EBase value
    sCLASSB_enable_interrupt_asm();
    OFF009 = 0x200;// setting new offset value
    /**********************************/
    
    temp_CP0 = _CP0_GET_CAUSE();// Get Cause 
    temp_CP0 |= 0x00800000U;// Set IV 
    _CP0_SET_CAUSE(temp_CP0);// Update Cause
    sCLASSB_enable_interrupt_asm();
    
    temp_CP0 = _CP0_GET_STATUS();// Get Status 
    //temp_CP0 &= 0xFFBFFFFD;//  
    temp_CP0 &= 0xFFBFFFFFU;//Clear Bev
    _CP0_SET_STATUS(temp_CP0);// Update Status
    sCLASSB_enable_interrupt_asm();
    
    INTCONSET = _INTCON_MVEC_MASK;// Set the MVEC bit
    /* Lock system  */
    SYSKEY = 0x33333333U;
}

/*============================================================================
static void sCLASSB_BuildVectorTable(void)
------------------------------------------------------------------------------
Purpose: Build the vector table for Interrupt self-test . Internally it will call sCLASSB_set_ebase function to set new ebase value and timer2 OFF register value
Input  : None.
Output : None.
============================================================================*/
static void sCLASSB_BuildVectorTable(void)
{
    ebase_org = _CP0_GET_EBASE();
    off_org = OFF009;
    sCLASSB_set_ebase( ((uint32_t)&sCLASSB_TMR2_Handler) - 0x200 );
}

/*============================================================================
static void sCLASSB_set_ebase_org(unsigned int value)
------------------------------------------------------------------------------
Purpose: Setting original value of Ebase and TMR2 OFF register   
Input  : Ebase value.
Output : None.
============================================================================*/
static void sCLASSB_set_ebase_org(unsigned int value)
{
    /* unlock system */
    SYSKEY = 0x00000000U;
    SYSKEY = 0xAA996655U;
    SYSKEY = 0x556699AAU;
    
    /*Set the CP0 registers for multi-vector interrupt */
    INTCONCLR = _INTCON_MVEC_MASK;// Set the MVEC bit
    
    unsigned int temp_CP0;// Temporary register for CP0 register storing 
    sCLASSB_disable_interrupt_asm();// Disable all interrupts 
    sCLASSB_enable_interrupt_asm();// Disable all interrupts 
    
    temp_CP0 = _CP0_GET_STATUS();// Get Status 
    temp_CP0 |= 0x00400000U;// Set Bev 
    _CP0_SET_STATUS(temp_CP0);// Update Status
    sCLASSB_enable_interrupt_asm();
    
    _CP0_SET_INTCTL(0x10 << 5);
    sCLASSB_enable_interrupt_asm();
    
    /****************Setting new ebase and offset *****************/
    _CP0_SET_EBASE(value);// Set an EBase value
    sCLASSB_enable_interrupt_asm();
    OFF009 = off_org;// setting new offset value
    /**********************************/
    
    temp_CP0 = _CP0_GET_CAUSE();// Get Cause 
    temp_CP0 |= 0x00800000U;// Set IV 
    _CP0_SET_CAUSE(temp_CP0);// Update Cause
    sCLASSB_enable_interrupt_asm();
    
    temp_CP0 = _CP0_GET_STATUS();// Get Status 
    //temp_CP0 &= 0xFFBFFFFD;//  
    temp_CP0 &= 0xFFBFFFFFU;//Clear Bev
    _CP0_SET_STATUS(temp_CP0);// Update Status
    sCLASSB_enable_interrupt_asm();
    
    INTCONSET = _INTCON_MVEC_MASK;// Set the MVEC bit
    /* Lock system  */
    SYSKEY = 0x33333333U;
}

/*============================================================================
static void sCLASSB_INT_CLK_Initialize(void)
------------------------------------------------------------------------------
Purpose: Configure clock for Interrupt self-test
Input  : None.
Output : None.
============================================================================*/
static void sCLASSB_INT_CLK_Initialize(void)
{
    /* unlock system for clock configuration */
    SYSKEY = 0x00000000U;
    SYSKEY = 0xAA996655U;
    SYSKEY = 0x556699AAU;

    /* Peripheral Module Disable Configuration */
    CFGCONbits.PMDLOCK = 0;
    
    PMD4bits.T1MD = 0;
    PMD4bits.T2MD = 0;

    CFGCONbits.PMDLOCK = 1;

    /* Lock system since done with clock configuration */
    SYSKEY = 0x33333333U; 
}

/*============================================================================
static bool sCLASSB_INT_EVIC_SourceStatusGet( CLASSB_INT_SOURCE source )
------------------------------------------------------------------------------
Purpose: Get EVIC source status
Input  : Interrupt source.
Output : bool.
Notes  : None.
============================================================================*/
static bool sCLASSB_INT_EVIC_SourceStatusGet( CLASSB_INT_SOURCE source )
{
    volatile uint32_t *IFSx = (volatile uint32_t *)(&IFS0 + ((0x10 * (source / 32)) / 4));
    return (bool)((*IFSx >> (source & (uint32_t)0x1f)) & (uint32_t)0x1);
}

/*============================================================================
static void sCLASSB_INT_EVIC_SourceStatusClear( CLASSB_INT_SOURCE source )
------------------------------------------------------------------------------
Purpose: Clear EVIC source status
Input  : Interrupt source.
Output : None.
Notes  : None.
============================================================================*/
static void sCLASSB_INT_EVIC_SourceStatusClear( CLASSB_INT_SOURCE source )
{
    volatile uint32_t *IFSx = (volatile uint32_t *) (&IFS0 + ((0x10U * (source / 32U)) / 4U));
    volatile uint32_t *IFSxCLR = (volatile uint32_t *)(IFSx + 1U);
    *IFSxCLR = (uint32_t)1UL << (source & (uint32_t)0x1fU);
}

/*============================================================================
static void sCLASSB_INT_EVIC_SourceEnable( CLASSB_INT_SOURCE source )
------------------------------------------------------------------------------
Purpose: Enable EVIC source for Interrupt self-test
Input  : Interrupt source.
Output : None.
Notes  : None.
============================================================================*/
static void sCLASSB_INT_EVIC_SourceEnable( CLASSB_INT_SOURCE source )
{
    volatile uint32_t *IECx = (volatile uint32_t *) (&IEC0 + ((0x10 * (source / 32)) / 4));
    volatile uint32_t *IECxSET = (volatile uint32_t *)(IECx + 2);
    *IECxSET = (uint32_t)1U << (source & (uint32_t)0x1fU);
}

/*============================================================================
static void sCLASSB_TMR1_Initialize(void)
------------------------------------------------------------------------------
Purpose: Configure TMR1 peripheral for Interrupt self-test
Input  : None.
Output : None.
Notes  : The TMR1 is reset after successfully performing the test.
============================================================================*/
static void sCLASSB_TMR1_Initialize(void)
{
    /* Disable Timer */
    T1CONCLR = _T1CON_ON_MASK;
    /*
    SIDL = 0 - Continue operation even in Idle mode
    TWDIS = 0 - Back-to-back writes are enabled (Legacy Asynchronous Timer functionality)
    TECS = 2 - External clock comes from the LPRC
    TGATE = 0 - Gated time accumulation is disabled
    TCKPS = 3 - 1:256 prescale value
    TSYNC = 0 - External clock input is not synchronized
    TCS = 0 - Internal peripheral clock
    */
    T1CONbits.TCS = 0;
    T1CONSET = 0x00;
    T1CONSET = 0x230; // Prescaler - 1:256, Internal peripheral Clock

    /* Clear counter */
    TMR1 = 0x0;

    sCLASSB_INT_EVIC_SourceEnable(INT_SOURCE_TIMER_1);
}

/*============================================================================
static void sCLASSB_EVIC_Initialize(void)
------------------------------------------------------------------------------
Purpose: Initializes the EVIC
Input  : None.
Output : None.
Notes  : None.
============================================================================*/
static void sCLASSB_EVIC_Initialize( void )
{
    INTCONSET = _INTCON_MVEC_MASK;
    /* Set up priority and subpriority of enabled interrupts */
    IPC2SET = 0x400 | 0x0;  /* TIMER_2:  Priority 1 / Subpriority 0 */
    /* Configure Shadow Register Set */
    PRISS = 0x76543210;
}

/*============================================================================
static void sCLASSB_TMR2_Initialize(void)
------------------------------------------------------------------------------
Purpose: Configure TMR2 peripheral for Interrupt self-test
Input  : None.
Output : None.
Notes  : The TMR2 is reset after successfully performing the test.
============================================================================*/
static void sCLASSB_TMR2_Initialize(void)
{
    /* Disable Timer */
    T2CONCLR = _T2CON_ON_MASK;

    /*
    SIDL = 0
    TCKPS =7
    T32   = 0
    TCS = 0
    */
    T2CONSET = 0x70; // prescaler - 1:256, Internal peripheral clock,

    /* Clear counter */
    TMR2 = 0x0;

    /*Set period */
    PR2 = 2342U; // 10 Ms

    /* Enable TMR Interrupt */
    IEC0SET = _IEC0_T2IE_MASK;
    
    /*Clear the status flag*/
    IFS0CLR = _IFS0_T2IF_MASK;
}

/*============================================================================
static void sCLASSB_INT_TMR1_Period_Set(uint32_t period)
------------------------------------------------------------------------------
Purpose: Configure TMR1 peripheral for Interrupt self-test
Input  : TMR1 period.
Output : None.
Notes  : The clocks required for TMR1 are configured in a separate function.
============================================================================*/
static void sCLASSB_INT_TMR1_Period_Set(uint32_t period)
{
    PR1 = period;
}

/*============================================================================
static void sCLASSB_INT_TMR1_Start(void)
------------------------------------------------------------------------------
Purpose: Starts the TMR1
Input  : None.
Output : None.
Notes  : None.
============================================================================*/
static void sCLASSB_INT_TMR1_Start ( void )
{
    T1CONSET = _T1CON_ON_MASK;
}

/*============================================================================
static void sCLASSB_INT_TMR2_Start(void)
------------------------------------------------------------------------------
Purpose: Enables the TMR2
Input  : None.
Output : None.
Notes  : None.
============================================================================*/
static void sCLASSB_INT_TMR2_Start(void)
{
    T2CONSET = _T2CON_ON_MASK;
}

/*============================================================================
static void sCLASSB_INT_TMR1_Stop(void)
------------------------------------------------------------------------------
Purpose: Stops the TMR1
Input  : None.
Output : None.
Notes  : None.
============================================================================*/
static void sCLASSB_INT_TMR1_Stop (void)
{
    T1CONCLR = _T1CON_ON_MASK;
}

/*============================================================================
static void sCLASSB_INT_TMR2_Stop(void)
------------------------------------------------------------------------------
Purpose: Stops the TMR2
Input  : None.
Output : None.
Notes  : None.
============================================================================*/
static void sCLASSB_INT_TMR2_Stop (void)
{
    T2CONCLR = _T2CON_ON_MASK;
}

/*============================================================================
CLASSB_TEST_STATUS CLASSB_SST_InterruptTest(void)
------------------------------------------------------------------------------
Purpose: Test interrupt generation and handling.
Input  : None.
Output : Test status.
Notes  : None.
============================================================================*/
CLASSB_TEST_STATUS CLASSB_SST_InterruptTest(void)
{
    
    CLASSB_TEST_STATUS intr_test_status = CLASSB_TEST_INPROGRESS;
    uint32_t interrupt_count_l = 0U;
    sCLASSB_INT_EVIC_SourceStatusClear(INT_SOURCE_TIMER_1); 
    // Reset the counter
    *interrupt_count = 0U;
    sCLASSB_UpdateTestResult(CLASSB_TEST_TYPE_SST, CLASSB_TEST_INTERRUPT,
        CLASSB_TEST_INPROGRESS);
    /* Disable global interrupts */
    (void) __builtin_disable_interrupts();
    sCLASSB_BuildVectorTable();
    sCLASSB_INT_CLK_Initialize();
    sCLASSB_TMR2_Initialize();
    sCLASSB_TMR1_Initialize();
    sCLASSB_EVIC_Initialize();
    /* Enable global interrupts */
    (void) __builtin_enable_interrupts();
    /*Set period for 100 ms*/
    sCLASSB_INT_TMR1_Period_Set(23436U);
    sCLASSB_INT_EVIC_SourceStatusClear(CLASSB_INT_SOURCE_TIMER_1);
    while(sCLASSB_INT_EVIC_SourceStatusGet(CLASSB_INT_SOURCE_TIMER_1))
    {
        ;
    }
    sCLASSB_INT_TMR1_Start();
    sCLASSB_INT_TMR2_Start();
    while(sCLASSB_INT_EVIC_SourceStatusGet(CLASSB_INT_SOURCE_TIMER_1) == false)
    {
        ;
    }
    sCLASSB_INT_EVIC_SourceStatusClear(CLASSB_INT_SOURCE_TIMER_1);
    sCLASSB_INT_EVIC_SourceStatusClear(CLASSB_INT_SOURCE_TIMER_2);
    sCLASSB_INT_TMR2_Stop();
    sCLASSB_INT_TMR1_Stop();
    /* Assign value to interrupt_count_l local variable and validate*/
    interrupt_count_l = *interrupt_count;
    if ((interrupt_count_l < CLASSB_INTR_MAX_INT_COUNT)
        &&  (interrupt_count_l > 0U))
    {
        T1CONCLR = _T1CON_ON_MASK;// stop timer1
        intr_test_status = CLASSB_TEST_PASSED;
        sCLASSB_UpdateTestResult(CLASSB_TEST_TYPE_SST, CLASSB_TEST_INTERRUPT,
            CLASSB_TEST_PASSED);
        sCLASSB_set_ebase_org(((uint32_t)ebase_org));
    }
    else
    {
        intr_test_status = CLASSB_TEST_FAILED;
        sCLASSB_UpdateTestResult(CLASSB_TEST_TYPE_SST, CLASSB_TEST_INTERRUPT,
            CLASSB_TEST_FAILED);
        sCLASSB_set_ebase_org(((uint32_t)ebase_org));
        // The failsafe function must not return.
        CLASSB_SelfTest_FailSafe(CLASSB_TEST_INTERRUPT);
    }
    return intr_test_status;
}
