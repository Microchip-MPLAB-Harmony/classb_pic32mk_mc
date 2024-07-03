
# PIC32MK MC Class B Library API Usage Example

This example shows how to use the self-test APIs from the Class B library during startup as well as run-time.
The example contains 3 different Application configurations created for three different Hardware, please refer
"Hardware Setup" section below.

When a self-test is used at startup, it is referred as Startup Self-test (SST) and when it is used at
run-time, it is referred as run-time self-test (RST).
When this demo application starts, it reads the status of startup self-tests and sends them to the UART COM port.
It then executes a few run-time self-tests for different components inside microcontroller and reports
whether the tests are passed or not.
In the demo applications Flash memory self-test during Startup is not enabled, as user needs to store CRC of flash memory 
in a particular location of Flash before Flash memory self-test is performed.   
For the Flash memory self-test during Runtime, CRC-32 for the internal flash memory(memory under test) is calculated
and the CRC value is stored using NVM write command.
Refer the User Guide for the Class B Library for details on the self-tests. 

## Building The Application
The parent folder for the MPLAB X IDE project for this application is given below:

**Application Path** : ..\classb_pic32mk_mc\apps\classb_api_usage

To build the application, open the relevant project file classb_api_usage_pic32mk_mca.X or classb_api_usage_pic32mk_mcj.X or classb_api_usage_pic32mk_mcm.X in MPLABX IDE.


## Hardware Setup

1. Project classb_api_usage_pic32mk_mca.X
    * Hardware Used
        * PIC32MK MCA Curiosity Pro
    * Hardware Setup
        * Ensure the the tested IO pins are kept at specified logic levels.
        * Port-A , Pin-10(RA10) of the board is used.

2. Project classb_api_usage_pic32mk_mcj.X
    * Hardware Used
        * PIC32MK MCJ Curiosity Pro
    * Hardware Setup
        * Ensure the the tested IO pins are kept at specified logic levels.
        * Port-A , Pin-10(RA10) of the board is used. 
        
3. Project classb_api_usage_pic32mk_mcm.X
    * Hardware Used
        * PIC32MK MCM Curiosity Pro Development
    * Hardware Setup
        * Ensure the the tested IO pins are kept at specified logic levels.
        * Port-G , Pin-13(RG13) of the board is used. 

## Running The Application

1. Open the Terminal application (Ex.:Tera Term) on the computer.
2. Connect to the UART Virtual COM port and configure the serial settings as follows:
    * Baud : 115200
    * Data : 8 Bits
    * Parity : None
    * Stop : 1 Bit
    * Flow Control : None
3. Build and Program the application using the MPLAB X IDE.
4. Observe the messages shown on the console.
5. Code for Runtime self-test are included in `main.c` file.

**NOTE:** 

**1) In the application, for runtime flash test, at first `CLASSB_FlashCRCGenerate()` function is being used to generate CRC and then store it in a memory location using Harmony provided NVM component. `CLASSB_FlashCRCGenerate()` function is part of classB library.**
