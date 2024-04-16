/*******************************************************************************
  Class B Library ${REL_VER} Release

  Company:
    Microchip Technology Inc.

  File Name:
    classb_fpu_reg_test_asm.S

  Summary:
    Assembly functions to test FPU Registers.

  Description:
    This file provides Assembly functions to test FPU Registers.
    
*******************************************************************************/
//DOM-IGNORE-BEGIN
/*******************************************************************************
Copyright (c) ${REL_VER} released Microchip Technology Inc.  All rights reserved.

Microchip licenses to  you  the  right  to  use,  modify,  copy  and  distribute
Software only when embedded on a Microchip  microcontroller  or  digital  signal
controller  that  is  integrated  into  your  product  or  third  party  product
(pursuant to the  sublicense  terms  in  the  accompanying  license  agreement).

You should refer  to  the  license  agreement  accompanying  this  Software  for
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
// DOM-IGNORE-END
#include "xc.h"

/* global defines */
.equ   FPU_REGISTER_TEST_PASS,  1
.equ   FPU_REGISTER_TEST_FAIL,  2
.global sCLASSB_FPURegistersTest

    .text
ROM_AA_WORD:
    .word    0xaaaaaaaa;
ROM_55_WORD:
    .word    0x55555555;

#; define a macro to perform the basic register check
#; on one of the additional registers provided by the 
#; FPU module.
#; In case of error a jump to err_label is performed
.macro check_FPU_register FPU_reg temp1_reg temp2_reg err_label
    la      \temp1_reg, ROM_AA_WORD;
    lw      \temp1_reg, 0(\temp1_reg);              # Fill Temp registers with test pattern.
    mtc1    \temp1_reg, \FPU_reg
    mfc1    \temp2_reg, \FPU_reg
    bne     \temp1_reg, \temp2_reg, \err_label
    nop;
    
    la      \temp1_reg, ROM_55_WORD;
    lw      \temp1_reg, 0(\temp1_reg);              # Fill Temp registers with test pattern.
    mtc1    \temp1_reg, \FPU_reg
    mfc1    \temp2_reg, \FPU_reg
    bne     \temp1_reg, \temp2_reg, \err_label
    nop;
    
.endm
    
.set    noreorder
.set    noat

.text

/*******************************************************************************
  Function:
    int sCLASSB_FPURegistersTest ( void )

  Summary:
    The FPU Register test implements the functional test
    H.2.16.5 as defined by the IEC 60730 standard.
    

  Description:
    This routine detects stuck-at Faults in the FPU registers.
    This ensures that the bits in the registers are not stuck at
    a value ?0? or ?1?.

  Precondition:
    None.

  Parameters:
    None.
    
  Returns:
    Result identifying the pass/fail status of the test:
    * FPU_REGISTER_TEST_PASS    - The test passed. FPU registers have not been detected to have stuck bits. 
    * FPU_REGISTER_TEST_FAIL    - The test failed. Some FPU register(s) has been detected to have stuck bits. 

  Example:
    <code>
    int testRes=sCLASSB_FPURegistersTest();
    if(testRes==FPU_REGISTER_TEST_PASS)
    {
        // process test success
    }
    else
    {
        // process tests failure
    }
    </code>

  Remarks:
    This is a non-destructive test.
    Interrupts should be disabled when calling this test function.
    Refer to the AN1229 for details regarding the sCLASSB_FPURegistersTest()
    and the Class B Software Library.
  *****************************************************************************/
.ent    sCLASSB_FPURegistersTest
sCLASSB_FPURegistersTest:

#if defined (__PIC32_HAS_FPU64)
#;*********************************
#; Test $f0-$f31 registers
   check_FPU_register $f0 t0 t1 FpuTestError
   check_FPU_register $f1 t0 t1 FpuTestError
   check_FPU_register $f2 t0 t1 FpuTestError
   check_FPU_register $f3 t0 t1 FpuTestError
   check_FPU_register $f4 t0 t1 FpuTestError
   check_FPU_register $f5 t0 t1 FpuTestError
   check_FPU_register $f6 t0 t1 FpuTestError
   check_FPU_register $f7 t0 t1 FpuTestError
   check_FPU_register $f8 t0 t1 FpuTestError
   check_FPU_register $f9 t0 t1 FpuTestError
   check_FPU_register $f10 t0 t1 FpuTestError
   check_FPU_register $f11 t0 t1 FpuTestError
   check_FPU_register $f12 t0 t1 FpuTestError
   check_FPU_register $f13 t0 t1 FpuTestError
   check_FPU_register $f14 t0 t1 FpuTestError
   check_FPU_register $f15 t0 t1 FpuTestError
   check_FPU_register $f16 t0 t1 FpuTestError
   check_FPU_register $f17 t0 t1 FpuTestError
   check_FPU_register $f18 t0 t1 FpuTestError
   check_FPU_register $f19 t0 t1 FpuTestError
   check_FPU_register $f20 t0 t1 FpuTestError
   check_FPU_register $f21 t0 t1 FpuTestError
   check_FPU_register $f22 t0 t1 FpuTestError
   check_FPU_register $f23 t0 t1 FpuTestError
   check_FPU_register $f24 t0 t1 FpuTestError
   check_FPU_register $f25 t0 t1 FpuTestError
   check_FPU_register $f26 t0 t1 FpuTestError
   check_FPU_register $f27 t0 t1 FpuTestError
   check_FPU_register $f28 t0 t1 FpuTestError
   check_FPU_register $f29 t0 t1 FpuTestError
   check_FPU_register $f30 t0 t1 FpuTestError
   check_FPU_register $f31 t0 t1 FpuTestError
#endif


FpuTestSuccess:
    b       FpuTestDone;     # done
    addiu   v0, zero, FPU_REGISTER_TEST_PASS   #return Success code (Branch slot)
    
FpuTestError:
    addiu   v0, zero, FPU_REGISTER_TEST_FAIL   #return Error code

FpuTestDone:
#   return
    jr ra  
    nop


.end sCLASSB_FPURegistersTest

.set    at
.set    reorder
