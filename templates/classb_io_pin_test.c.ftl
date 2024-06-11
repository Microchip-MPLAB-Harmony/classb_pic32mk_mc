/*******************************************************************************
  Class B Library ${REL_VER} Release

  Company:
    Microchip Technology Inc.

  File Name:
    classb_io_pin_test.c

  Summary:
    Class B Library source file for the IO pin test

  Description:
    This file provides self-test functions for IO pin.

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
#include "classb/classb_io_pin_test.h"
#include "definitions.h"

/*----------------------------------------------------------------------------
 *     Constants
 *----------------------------------------------------------------------------*/

/*----------------------------------------------------------------------------
 *     Global Variables
 *----------------------------------------------------------------------------*/
/* Available GPIO Port and Pin List */
<#list 0..CLASSB_GPIO_CHANNEL_TOTAL-1 as k>
    <#assign pin_channel = "CLASSB_GPIO_CHANNEL_" + k + "_NAME">
    <#assign port_pin_list = "CLASSB_GPIO_CHANNEL_" + k + "_PIN_LIST">
    <#lt>static CLASSB_GPIO_PIN CLASSB_PORT_${.vars[pin_channel]}_PIN_LIST[] = 
    <#lt>{
    <#lt>    ${.vars[port_pin_list]}
    <#lt>};
</#list>

/*----------------------------------------------------------------------------
 *     Functions
 *----------------------------------------------------------------------------*/
bool sCLASSB_GPIO_Validate_PortPin(CLASSB_PORT_INDEX port, CLASSB_GPIO_PIN pin);
uint32_t sCLASSB_GPIO_PortRead(CLASSB_PORT_INDEX port);
/*============================================================================
bool sCLASSB_GPIO_Validate_PortPin(CLASSB_PORT_INDEX port, CLASSB_PORT_PIN pin);
------------------------------------------------------------------------------
Purpose: Validate the given Port and Pin
Input  : GPIO Port.
Output : GPIO Pin.
Notes  : Give a valid Macro value
============================================================================*/
bool sCLASSB_GPIO_Validate_PortPin(CLASSB_PORT_INDEX port, CLASSB_GPIO_PIN pin)
{
    bool pin_found = false;
    uint32_t i = 0, pin_cnt = 0;

    /* GPIO Pin validation */ 
    switch (port) 
    {
    <#list 0..CLASSB_GPIO_CHANNEL_TOTAL-1 as i>
        <#assign pin_channel = "CLASSB_GPIO_CHANNEL_" + i + "_NAME">
        case CLASSB_GPIO_PORT_${.vars[pin_channel]}:
            pin_cnt = sizeof (CLASSB_PORT_${.vars[pin_channel]}_PIN_LIST) 
                    / sizeof (CLASSB_PORT_${.vars[pin_channel]}_PIN_LIST[0]);
            pin_found = false;
            for (i = 0; i < pin_cnt; i++) 
            {
                if (pin == CLASSB_PORT_${.vars[pin_channel]}_PIN_LIST[i]) 
                {
                    pin_found = true;
                    break;
                }
            }
            break;

    </#list>
        default:
            /* Invalid Port */
            pin_found = false;
            break;

    }

   return pin_found;
}

/*============================================================================
uint32_t sCLASSB_GPIO_PortRead(CLASSB_PORT_INDEX port);
------------------------------------------------------------------------------
Purpose: Read the GPIO Port status
Input  : GPIO port.
Output : None.
Notes  : 
============================================================================*/
uint32_t sCLASSB_GPIO_PortRead(CLASSB_PORT_INDEX port)
{
   return (*(volatile uint32_t *)(&PORTA + (port * 0x40)));
}

/*============================================================================
CLASSB_TEST_STATUS CLASSB_RST_IOTest(CLASSB_PORT_INDEX port, CLASSB_GPIO_PIN pin,
    CLASSB_GPIO_PIN_STATE state);
------------------------------------------------------------------------------
Purpose: Check whether the given I/O pin is at specified state
Input  : PORT index, pin number and expected state.
Output : Test status.
Notes  : None.
============================================================================*/
CLASSB_TEST_STATUS CLASSB_RST_IOTest(CLASSB_PORT_INDEX port, CLASSB_GPIO_PIN pin, 
            CLASSB_GPIO_PIN_STATE state)
{
    CLASSB_TEST_STATUS io_test_status = CLASSB_TEST_NOT_EXECUTED;
    CLASSB_GPIO_PIN_STATE pin_read_state = PORT_PIN_INVALID;

    sCLASSB_UpdateTestResult(CLASSB_TEST_TYPE_RST, CLASSB_TEST_IO, 
            CLASSB_TEST_NOT_EXECUTED);

    /* Validate the given GPIO Port and Pin */
    if( sCLASSB_GPIO_Validate_PortPin (port , pin) == false ||
            ((state != PORT_PIN_LOW) && (state != PORT_PIN_HIGH)) )
    {
        io_test_status = CLASSB_TEST_NOT_EXECUTED;
    }
    else
    {
        sCLASSB_UpdateTestResult(CLASSB_TEST_TYPE_RST, CLASSB_TEST_IO,
                CLASSB_TEST_INPROGRESS);
        if ((sCLASSB_GPIO_PortRead(port) & (1 << pin)) == (1 << pin))
        {
            pin_read_state = PORT_PIN_HIGH;
        }
        else
        {
            pin_read_state = PORT_PIN_LOW;
        }
        if (pin_read_state == state)
        {
            io_test_status = CLASSB_TEST_PASSED;
        }
        else
        {
            io_test_status = CLASSB_TEST_FAILED;
        }
    }

    /* Update the Test Result */
    if(io_test_status == CLASSB_TEST_PASSED)
    {
        sCLASSB_UpdateTestResult(CLASSB_TEST_TYPE_RST, CLASSB_TEST_IO,
                CLASSB_TEST_PASSED);
    }
    else if(io_test_status == CLASSB_TEST_FAILED)
    {
        sCLASSB_UpdateTestResult(CLASSB_TEST_TYPE_RST, CLASSB_TEST_IO,
                CLASSB_TEST_FAILED);
    }
    else
    {
        /* Do nothing */
        ;
    }

    return io_test_status;
}
