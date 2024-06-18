/*******************************************************************************
  Class B Library v1.0.0 Release

  Company:
    Microchip Technology Inc.

  File Name:
    classb_cpu_reg_test.c

  Summary:
    Class B Library CPU register self-test source file

  Description:
    This file provides CPU register self-test.

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
#include "classb/classb_cpu_reg_test.h"
#include "classb/classb_reg_common.h"
#include "definitions.h"

/*----------------------------------------------------------------------------
 *     Global Variables
 *----------------------------------------------------------------------------*/

/*----------------------------------------------------------------------------
 *     Functions
 *----------------------------------------------------------------------------*/
 
/*============================================================================
CLASSB_TEST_STATUS CLASSB_CPU_RegistersTest(bool running_context)
------------------------------------------------------------------------------
Purpose: Perform stuck at fault to check CPU registers.
Input  : context (startup or run-time)
Output : Test status.
Notes  : This function calls 'sCLASSB_CPURegistersTest()' to check the CPU registers.
============================================================================*/
CLASSB_TEST_STATUS CLASSB_CPU_RegistersTest(bool running_context)
{
    int ret;
    if (running_context == true)
    {
        sCLASSB_UpdateTestResult(CLASSB_TEST_TYPE_RST, CLASSB_TEST_CPU,
            CLASSB_TEST_INPROGRESS);
    }
    else
    {
        sCLASSB_UpdateTestResult(CLASSB_TEST_TYPE_SST, CLASSB_TEST_CPU,
            CLASSB_TEST_INPROGRESS);
    }
    
    ret = sCLASSB_CPURegistersTest();
    if ((CLASSB_TEST_STATUS)ret == CLASSB_TEST_PASSED)
    {
        if (running_context == true)
        {
            sCLASSB_UpdateTestResult(CLASSB_TEST_TYPE_RST, CLASSB_TEST_CPU,
                    CLASSB_TEST_PASSED);
        }
        else
        {
            sCLASSB_UpdateTestResult(CLASSB_TEST_TYPE_SST, CLASSB_TEST_CPU,
                    CLASSB_TEST_PASSED);
        }
    }
    else
    {
        if (running_context == true)
        {
            sCLASSB_UpdateTestResult(CLASSB_TEST_TYPE_RST, CLASSB_TEST_CPU,
                    CLASSB_TEST_FAILED);
        }
        else
        {
            sCLASSB_UpdateTestResult(CLASSB_TEST_TYPE_SST, CLASSB_TEST_CPU,
                    CLASSB_TEST_FAILED);
        }
        /* Remain in infinite loop if a register test is failed */
        while(true)
        {
            ;
        }    
        
    }
    return (CLASSB_TEST_STATUS)ret;
}


/*******************************************************************************
 End of File
 */
