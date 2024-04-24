/*******************************************************************************
  Class B Library ${REL_VER} Release

  Company:
    Microchip Technology Inc.

  File Name:
    classb_io_pin_test.h

  Summary:
    Header file for I/O pin self-tests

  Description:
    This file provides function prototypes, macros and datatypes for the
    I/O pin test.

*******************************************************************************/

/*******************************************************************************
Copyright (c) ${REL_YEAR} released Microchip Technology Inc.  All rights reserved.

Microchip licenses to you the right to use, modify, copy and distribute
Software only when embedded on a Microchip microcontroller or digital signal
controller that is integrated into your product or third party product
(pursuant to the sublicense terms in the accompanying license agreement).

You should refer to the license agreement accompanying this Software for
additional information regarding your rights and obligations.

SOFTWARE AND DOCUMENTATION ARE PROVIDED AS IS  WITHOUT  WARRANTY  OF  ANY  KIND,
EITHER EXPRESS  OR  IMPLIED,  INCLUDING  WITHOUT  LIMITATION,  ANY  WARRANTY  OF
MERCHANTABILITY, TITLE, NON-INFRINGEMENT AND FITNESS FOR A  PARTICULAR  PURPOSE.
IN NO EVENT SHALL MICROCHIP OR  ITS  LICENSORS  BE  LIABLE  OR  OBLIGATED  UNDER
CONTRACT, NEGLIGENCE, STRICT LIABILITY, CONTRIBUTION,  BREACH  OF  WARRANTY,  OR
OTHER LEGAL  EQUITABLE  THEORY  ANY  DIRECT  OR  INDIRECT  DAMAGES  OR  EXPENSES
INCLUDING BUT NOT LIMITED TO ANY  INCIDENTAL,  SPECIAL,  INDIRECT,  PUNITIVE  OR
CONSEQUENTIAL DAMAGES, LOST  PROFITS  OR  LOST  DATA,  COST  OF  PROCUREMENT  OF
SUBSTITUTE  GOODS,  TECHNOLOGY,  SERVICES,  OR  ANY  CLAIMS  BY  THIRD   PARTIES
(INCLUDING BUT NOT LIMITED TO ANY DEFENSE  THEREOF),  OR  OTHER  SIMILAR  COSTS.
*******************************************************************************/

#ifndef CLASSB_IO_PIN_TEST_H
#define CLASSB_IO_PIN_TEST_H

// DOM-IGNORE-BEGIN
#ifdef __cplusplus  // Provide C++ Compatibility

    extern "C" {

#endif
// DOM-IGNORE-END

/*----------------------------------------------------------------------------
 *     Include files
 *----------------------------------------------------------------------------*/
#include "classb/classb_common.h"

/*----------------------------------------------------------------------------
 *     Constants
 *----------------------------------------------------------------------------*/

/*----------------------------------------------------------------------------
 *     Data types
 *----------------------------------------------------------------------------*/
// *****************************************************************************
/* PORT index definitions

  Summary:
    PORT index definitions for Class B library I/O pin test

  Description:
    This can be used in the I/O pin test.

  Remarks:
    None.
*/
typedef enum classb_port_index
{
    <#list 0..GPIO_CHANNEL_TOTAL-1 as i>
        <#assign channel = "GPIO_CHANNEL_" + i + "_NAME">
        <#if .vars[channel]?has_content> 
            <#lt>   CLASSB_GPIO_PORT_${.vars[channel]} = ${i}U,
        </#if>
    </#list>
} CLASSB_PORT_INDEX;

// *****************************************************************************
/* PIN definitions

  Summary:
    PIN definitions for Class B library I/O pin test

  Description:
    This can be used in the I/O pin test.
  
  Remarks:
    None.
*/
<#list 0..GPIO_CHANNEL_TOTAL-1 as j>
    <#assign pin_channel = "GPIO_CHANNEL_" + j + "_NAME">
    <#if .vars[pin_channel]?has_content>
      <#assign pin_cnt = "GPIO_CHANNEL_" + j + "_PIN_CNT">
      <#if .vars[pin_cnt]?has_content>
        <#list 0..<.vars[pin_cnt] as i>
            <#assign pin_name = "GPIO_CHANNEL_" + j + "_PIN_" + i >
            <#if .vars[pin_name]?has_content>
              <#lt>#define   CLASSB_GPIO_PIN_R${.vars[pin_channel]}${.vars[pin_name]}  (${.vars[pin_name]}U)
            </#if>
        </#list>
      </#if>
    </#if>
</#list>

typedef uint32_t CLASSB_GPIO_PIN;

// *****************************************************************************
/* PORT pin state

  Summary:
    PORT pin state

  Description:
    This can be used in the I/O pin test.

  Remarks:
    None.
*/
typedef enum classb_gpio_pin_state
{
    PORT_PIN_LOW  = 0U,
    PORT_PIN_HIGH = 1U,
    PORT_PIN_INVALID = 2U
} CLASSB_GPIO_PIN_STATE;

/*----------------------------------------------------------------------------
 *     Functions
 *----------------------------------------------------------------------------*/
CLASSB_TEST_STATUS CLASSB_RST_IOTest(CLASSB_PORT_INDEX port, CLASSB_GPIO_PIN pin,
        CLASSB_GPIO_PIN_STATE state);

// DOM-IGNORE-BEGIN
#ifdef __cplusplus  // Provide C++ Compatibility
    }

#endif
// DOM-IGNORE-END
#endif // CLASSB_IO_PIN_TEST_H