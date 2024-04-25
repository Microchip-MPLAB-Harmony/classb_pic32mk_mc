/*******************************************************************************
  Class B Library v1.0.0 Release

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
Copyright (c) 2024 released Microchip Technology Inc.  All rights reserved.

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
   CLASSB_GPIO_PORT_A = 0U,
   CLASSB_GPIO_PORT_B = 1U,
   CLASSB_GPIO_PORT_C = 2U,
   CLASSB_GPIO_PORT_D = 3U,
   CLASSB_GPIO_PORT_E = 4U,
   CLASSB_GPIO_PORT_F = 5U,
   CLASSB_GPIO_PORT_G = 6U,
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
#define   CLASSB_GPIO_PIN_RA0  (0U)
#define   CLASSB_GPIO_PIN_RA1  (1U)
#define   CLASSB_GPIO_PIN_RA4  (4U)
#define   CLASSB_GPIO_PIN_RA7  (7U)
#define   CLASSB_GPIO_PIN_RA8  (8U)
#define   CLASSB_GPIO_PIN_RA10  (10U)
#define   CLASSB_GPIO_PIN_RA11  (11U)
#define   CLASSB_GPIO_PIN_RA12  (12U)
#define   CLASSB_GPIO_PIN_RA14  (14U)
#define   CLASSB_GPIO_PIN_RA15  (15U)
#define   CLASSB_GPIO_PIN_RB0  (0U)
#define   CLASSB_GPIO_PIN_RB1  (1U)
#define   CLASSB_GPIO_PIN_RB2  (2U)
#define   CLASSB_GPIO_PIN_RB3  (3U)
#define   CLASSB_GPIO_PIN_RB4  (4U)
#define   CLASSB_GPIO_PIN_RB5  (5U)
#define   CLASSB_GPIO_PIN_RB6  (6U)
#define   CLASSB_GPIO_PIN_RB7  (7U)
#define   CLASSB_GPIO_PIN_RB8  (8U)
#define   CLASSB_GPIO_PIN_RB9  (9U)
#define   CLASSB_GPIO_PIN_RB10  (10U)
#define   CLASSB_GPIO_PIN_RB11  (11U)
#define   CLASSB_GPIO_PIN_RB12  (12U)
#define   CLASSB_GPIO_PIN_RB13  (13U)
#define   CLASSB_GPIO_PIN_RB14  (14U)
#define   CLASSB_GPIO_PIN_RB15  (15U)
#define   CLASSB_GPIO_PIN_RC0  (0U)
#define   CLASSB_GPIO_PIN_RC1  (1U)
#define   CLASSB_GPIO_PIN_RC2  (2U)
#define   CLASSB_GPIO_PIN_RC6  (6U)
#define   CLASSB_GPIO_PIN_RC7  (7U)
#define   CLASSB_GPIO_PIN_RC8  (8U)
#define   CLASSB_GPIO_PIN_RC9  (9U)
#define   CLASSB_GPIO_PIN_RC10  (10U)
#define   CLASSB_GPIO_PIN_RC11  (11U)
#define   CLASSB_GPIO_PIN_RC12  (12U)
#define   CLASSB_GPIO_PIN_RC13  (13U)
#define   CLASSB_GPIO_PIN_RC15  (15U)
#define   CLASSB_GPIO_PIN_RD5  (5U)
#define   CLASSB_GPIO_PIN_RD6  (6U)
#define   CLASSB_GPIO_PIN_RD8  (8U)
#define   CLASSB_GPIO_PIN_RE0  (0U)
#define   CLASSB_GPIO_PIN_RE1  (1U)
#define   CLASSB_GPIO_PIN_RE12  (12U)
#define   CLASSB_GPIO_PIN_RE13  (13U)
#define   CLASSB_GPIO_PIN_RE14  (14U)
#define   CLASSB_GPIO_PIN_RE15  (15U)
#define   CLASSB_GPIO_PIN_RF0  (0U)
#define   CLASSB_GPIO_PIN_RF1  (1U)
#define   CLASSB_GPIO_PIN_RG6  (6U)
#define   CLASSB_GPIO_PIN_RG7  (7U)
#define   CLASSB_GPIO_PIN_RG8  (8U)
#define   CLASSB_GPIO_PIN_RG9  (9U)

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