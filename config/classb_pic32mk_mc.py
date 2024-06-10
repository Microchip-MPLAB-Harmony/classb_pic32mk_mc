# coding: utf-8
"""*****************************************************************************
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
*****************************************************************************"""
import xml.etree.ElementTree as ET
import os.path
import inspect
################################################################################
#### Globals ####
port_pin_list = []
pioSymChannel = []
port_dict = {}
processor = ""
################################################################################

################################################################################
#### Call-backs ####
################################################################################
#Update Symbol Visibility
def setClassB_SymbolVisibility(MySymbol, event):
    MySymbol.setVisible(event["value"])

################################################################################
#### Function to parse pin_xml files ####
################################################################################
def parse_io_port_pin():
    global port_pin_list, pioSymChannel , port_dict
    currentPath = os.path.dirname(os.path.abspath(inspect.stack()[0][1]))
    processor = Variables.get("__PROCESSOR")
    print("Loading CLASS B Pin Parser for " + processor)
    deviceXmlPath = os.path.join(currentPath, "../plugin/pin_xml/components/" + processor + ".xml")
    deviceXmlTree = ET.parse(deviceXmlPath)
    deviceXmlRoot = deviceXmlTree.getroot()
    pinoutXmlName = deviceXmlRoot.get("pins")
    pinoutXmlPath = os.path.join(currentPath, "../plugin/pin_xml/pins/" + pinoutXmlName + ".xml")
    pinoutXmlPath = os.path.normpath(pinoutXmlPath)
    tree = ET.parse(pinoutXmlPath)
    root = tree.getroot()
    pins_element = root.find('pins')
    # Iterate over all <pin> elements inside <pins>
    for pin in pins_element.findall('pin'):
        pin_name = pin.attrib['name']
        if pin_name.startswith("R") and pin_name[2:].isnumeric():
            port_pin_list.append(pin_name)
            if  pin_name[1] in pioSymChannel:
                port_dict[pin_name[1]].append(int(pin_name[2:]))
                port_dict[pin_name[1]].sort()
            else:
                pioSymChannel.append(pin_name[1])
                pioSymChannel.sort()
                port_dict[pin_name[1]] = [int(pin_name[2:])]
  
################################################################################
#### Component ####
################################################################################
def instantiateComponent(classBComponent):
    global processor 
    processor = Variables.get("__PROCESSOR")
    print("Instantiating CLASS B Component for %s..." % ( processor))
    parse_io_port_pin()
    configName = Variables.get("__CONFIGURATION_NAME")
    classBMenu = classBComponent.createMenuSymbol("CLASSB_MENU", None)
    classBMenu.setLabel("Class B Startup Test Configuration")
    execfile(Module.getPath() +"/config/interface.py")
    
    #Device params
    classBFlashNode = ATDF.getNode("/avr-tools-device-file/devices/device/address-spaces/address-space/memory-segment@[name=\"code\"]")
    if classBFlashNode != None:
        #Flash size
        classB_FLASH_SIZE = classBComponent.createHexSymbol("CLASSB_FLASH_SIZE", None)
        classB_FLASH_SIZE.setVisible(False)
        classB_FLASH_SIZE.setDefaultValue( int(classBFlashNode.getAttribute("size"), 16))
        
        #FLASH address
        classB_FLASH_KSEG1_START_ADDR = classBComponent.createHexSymbol("CLASSB_FLASH_KSEG1_START_ADDR", None)
        classB_FLASH_KSEG1_START_ADDR.setVisible(False)
        classB_FLASH_KSEG1_START_ADDR.setDefaultValue(int(classBFlashNode.getAttribute("start"), 16) + (0xA0000000))
        
    classBSRAMNode = ATDF.getNode("/avr-tools-device-file/devices/device/address-spaces/address-space/memory-segment@[name=\"kseg0_data_mem\"]")
    if classBSRAMNode != None:
        #SRAM size
        classB_SRAM_SIZE = classBComponent.createIntegerSymbol("CLASSB_SRAM_SIZE", None)
        classB_SRAM_SIZE.setVisible(False)
        classB_SRAM_SIZE.setDefaultValue(int(classBSRAMNode.getAttribute("size"), 16))
        
        #SRAM address
        classB_SRAM_ADDR = classBComponent.createHexSymbol("CLASSB_SRAM_RESERVED_START_ADDRESS", None)
        classB_SRAM_ADDR.setVisible(False)
        classB_SRAM_ADDR.setDefaultValue(int(classBSRAMNode.getAttribute("start"), 16)  + (0xA0000400))
        
        #SRAM address MSB 24 bits
        classB_SRAM_START_MSB = classBComponent.createHexSymbol("CLASSB_SRAM_START_MSB", None)
        classB_SRAM_START_MSB.setVisible(False)
        classB_SRAM_START_MSB.setDefaultValue((int(classBSRAMNode.getAttribute("start"), 16) >> 8) + (0xA0000400 >> 8))
        
        # SRAM reserve size is 1K bytes
        classB_SRAM_RESERVE_SIZE = classBComponent.createIntegerSymbol("CLASSB_SRAM_RESERVE_SIZE", None)
        classB_SRAM_RESERVE_SIZE.setVisible(False)
        classB_SRAM_RESERVE_SIZE.setDefaultValue(int("1024", 10))
        
    # Insert CPU test
    classB_UseCPUTest = classBComponent.createBooleanSymbol("CLASSB_CPU_TEST_OPT", classBMenu)
    classB_UseCPUTest.setLabel("Test CPU Registers?")
    classB_UseCPUTest.setVisible(True)
    classB_UseCPUTest.setDefaultValue(False)
    classB_UseCPUTest.setHelp("Harmony_ClassB_Library_for_PIC32MK_MC")

    # Insert FPU Register Test
    classB_UseCPUTest = classBComponent.createBooleanSymbol("CLASSB_FPU_TEST_OPT", classBMenu)
    classB_UseCPUTest.setLabel("Test FPU Registers?")
    classB_UseCPUTest.setVisible(True)
    classB_UseCPUTest.setDefaultValue(False)
    classB_UseCPUTest.setHelp("Harmony_ClassB_Library_for_PIC32MK_MC")
    
    # Insert SRAM test
    classB_UseSRAMTest = classBComponent.createBooleanSymbol("CLASSB_SRAM_TEST_OPT", classBMenu)
    classB_UseSRAMTest.setLabel("Test SRAM?")
    classB_UseSRAMTest.setVisible(True)
    classB_UseSRAMTest.setDefaultValue(False)
    classB_UseSRAMTest.setHelp("Harmony_ClassB_Library_for_PIC32MK_MC")
    
    # Select March algorithm for SRAM test
    classb_Ram_marchAlgo = classBComponent.createKeyValueSetSymbol("CLASSB_SRAM_MARCH_ALGORITHM", classB_UseSRAMTest)
    classb_Ram_marchAlgo.setLabel("Select RAM March algorithm")
    classb_Ram_marchAlgo.addKey("CLASSB_SRAM_MARCH_C", "0", "March C")
    classb_Ram_marchAlgo.addKey("CLASSB_SRAM_MARCH_C_MINUS", "1", "March C minus")
    classb_Ram_marchAlgo.addKey("CLASSB_SRAM_MARCH_B", "2", "March B")
    classb_Ram_marchAlgo.setOutputMode("Key")
    classb_Ram_marchAlgo.setDisplayMode("Description")
    classb_Ram_marchAlgo.setDescription("Selects the SRAM March algorithm to be used during startup")
    classb_Ram_marchAlgo.setDefaultValue(0)
    classb_Ram_marchAlgo.setVisible(False)
    classb_Ram_marchAlgo.setHelp("Harmony_ClassB_Library_for_PIC32MK_MC")
    #This should be enabled based on the above configuration
    classb_Ram_marchAlgo.setDependencies(setClassB_SymbolVisibility, ["CLASSB_SRAM_TEST_OPT"])
    
    # Size of the area to be tested
    classb_Ram_marchSize = classBComponent.createIntegerSymbol("CLASSB_SRAM_MARCH_SIZE", classB_UseSRAMTest)
    classb_Ram_marchSize.setLabel("Size of the tested area (bytes)")
    if classB_SRAM_SIZE.getValue() <= 32768:
        classb_Ram_marchSize.setDefaultValue(classB_SRAM_SIZE.getValue() / 64)
    else:
        classb_Ram_marchSize.setDefaultValue(classB_SRAM_SIZE.getValue() / 128)
    classb_Ram_marchSize.setVisible(False)
    classb_Ram_marchSize.setMin(0)
    classb_Ram_marchSize.setHelp("Harmony_ClassB_Library_for_PIC32MK_MC")
    # 1024 bytes are reserved for the use of Class B library
    classb_Ram_marchSize.setMax(classB_SRAM_SIZE.getValue() - 1024)
    classb_Ram_marchSize.setDescription("Size of the SRAM area to be tested starting from 0x20000400")
    classb_Ram_marchSize.setDependencies(setClassB_SymbolVisibility, ["CLASSB_SRAM_TEST_OPT"])
    
    # CRC-32 checksum availability
    classB_FlashCRC_Option = classBComponent.createBooleanSymbol("CLASSB_FLASH_CRC_CONF", classBMenu)
    classB_FlashCRC_Option.setLabel("Test Internal Flash?")
    classB_FlashCRC_Option.setVisible(True)
    classB_FlashCRC_Option.setDefaultValue(False)
    classB_FlashCRC_Option.setHelp("Harmony_ClassB_Library_for_PIC32MK_MC")
    classB_FlashCRC_Option.setDescription("Enable this option if the CRC-32 checksum of the application image is stored at a specific address in the Flash")
    
    # Address at which CRC-32 of the application image is stored
    classB_CRC_address = classBComponent.createHexSymbol("CLASSB_FLASHCRC_ADDR", classB_FlashCRC_Option)
    classB_CRC_address.setLabel("Flash CRC location")
    # classB_CRC_address.setDefaultValue(0xFE000)
    classB_CRC_address.setDefaultValue(classB_FLASH_KSEG1_START_ADDR.getValue() + classB_FLASH_SIZE.getValue() - 4)
    classB_CRC_address.setMin(classB_FLASH_KSEG1_START_ADDR.getValue())
    classB_CRC_address.setMax(classB_FLASH_KSEG1_START_ADDR.getValue() + classB_FLASH_SIZE.getValue() - 4)
    classB_CRC_address.setVisible(False)
    classB_CRC_address.setHelp("Harmony_ClassB_Library_for_PIC32MK_MC")
    # This should be enabled based on the above configuration
    classB_CRC_address.setDependencies(setClassB_SymbolVisibility, ["CLASSB_FLASH_CRC_CONF"])
    
    # Insert Clock test
    classB_UseClockTest = classBComponent.createBooleanSymbol("CLASSB_CLOCK_TEST_OPT", classBMenu)
    classB_UseClockTest.setLabel("Test CPU Clock?")
    classB_UseClockTest.setVisible(True)
    classB_UseClockTest.setHelp("Harmony_ClassB_Library_for_PIC32MK_MC")
    
    # Acceptable CPU clock frequency error at startup
    classb_ClockTestPercentage = classBComponent.createKeyValueSetSymbol("CLASSB_CLOCK_TEST_PERCENT", classB_UseClockTest)
    classb_ClockTestPercentage.setLabel("Permitted CPU clock error at startup")
    classb_ClockTestPercentage.addKey("CLASSB_CLOCK_5PERCENT", "5", "+-5 %")
    classb_ClockTestPercentage.addKey("CLASSB_CLOCK_10PERCENT", "10", "+-10 %")
    classb_ClockTestPercentage.addKey("CLASSB_CLOCK_15PERCENT", "15", "+-15 %")
    classb_ClockTestPercentage.setOutputMode("Value")
    classb_ClockTestPercentage.setDisplayMode("Description")
    classb_ClockTestPercentage.setDescription("Selects the permitted CPU clock error at startup")
    classb_ClockTestPercentage.setDefaultValue(0)
    classb_ClockTestPercentage.setVisible(False)
    classb_ClockTestPercentage.setHelp("Harmony_ClassB_Library_for_PIC32MK_MC")
    classb_ClockTestPercentage.setDependencies(setClassB_SymbolVisibility, ["CLASSB_CLOCK_TEST_OPT"])
    
    # Clock test duration
    classb_ClockTestDuration = classBComponent.createIntegerSymbol("CLASSB_CLOCK_TEST_DURATION", classB_UseClockTest)
    classb_ClockTestDuration.setLabel("Clock Test Duration (ms)")
    classb_ClockTestDuration.setDefaultValue(5)
    classb_ClockTestDuration.setVisible(False)
    classb_ClockTestDuration.setHelp("Harmony_ClassB_Library_for_PIC32MK_MC")
    classb_ClockTestDuration.setMin(5)
    classb_ClockTestDuration.setMax(20)
    classb_ClockTestDuration.setDependencies(setClassB_SymbolVisibility, ["CLASSB_CLOCK_TEST_OPT"])
    
    # Insert Interrupt test
    classB_UseInterTest = classBComponent.createBooleanSymbol("CLASSB_INTERRUPT_TEST_OPT", classBMenu)
    classB_UseInterTest.setLabel("Test Interrupts?")
    classB_UseInterTest.setVisible(True)
    classB_UseInterTest.setHelp("Harmony_ClassB_Library_for_PIC32MK_MC")
    classB_UseInterTest.setDefaultValue(False)
    classB_UseInterTest.setDescription("This self-test check interrupts operation with the help of NVIC, RTC and TC0")
    
    classBReadOnlyParams = classBComponent.createMenuSymbol("CLASSB_ADDR_MENU", None)
    classBReadOnlyParams.setLabel("Build parameters (read-only) used by the library")
    
    # Read-only symbol for start of non-reserved SRAM
    classb_AppRam_start = classBComponent.createHexSymbol("CLASSB_SRAM_APP_START", classBReadOnlyParams)
    classb_AppRam_start.setLabel("Start address of non-reserved SRAM")
    classb_AppRam_start.setDefaultValue(classB_SRAM_ADDR.getValue() + classB_SRAM_RESERVE_SIZE.getValue())
    classb_AppRam_start.setReadOnly(True)
    classb_AppRam_start.setHelp("Harmony_ClassB_Library_for_PIC32MK_MC")
    classb_AppRam_start.setMin(classB_SRAM_ADDR.getValue() + classB_SRAM_RESERVE_SIZE.getValue())
    classb_AppRam_start.setMax(classB_SRAM_ADDR.getValue() + classB_SRAM_RESERVE_SIZE.getValue())
    classb_AppRam_start.setDescription("Initial 1kB of SRAM is used by the Class B library")
    
    #SRAM last word address
    classB_SRAM_lastWordAddr = classBComponent.createHexSymbol("CLASSB_SRAM_LASTWORD_ADDR", classBReadOnlyParams)
    classB_SRAM_lastWordAddr.setLabel("Address of the last word in SRAM")
    classB_SRAM_lastWordAddr.setReadOnly(True)
    classB_SRAM_lastWordAddr.setHelp("Harmony_ClassB_Library_for_PIC32MK_MC")
    classB_SRAM_lastWordAddr.setDefaultValue((0xA0000000 + classB_SRAM_SIZE.getValue() - 4))
    classB_SRAM_lastWordAddr.setMin((0xA0000000 + classB_SRAM_SIZE.getValue() - 4))
    classB_SRAM_lastWordAddr.setMax((0xA0000000 + classB_SRAM_SIZE.getValue() - 4))
    sram_top = hex(classB_SRAM_lastWordAddr.getValue() + 4)
    classB_SRAM_lastWordAddr.setDescription("The SRAM memory address range is 0x00000000 to " + str(sram_top))
    
    # Read-only symbol for CRC-32 polynomial
    classb_FlashCRCPoly = classBComponent.createHexSymbol("CLASSB_FLASH_CRC32_POLY", classBReadOnlyParams)
    classb_FlashCRCPoly.setLabel("CRC-32 polynomial for Flash test")
    classb_FlashCRCPoly.setDefaultValue(0xEDB88320)
    classb_FlashCRCPoly.setReadOnly(True)
    classb_FlashCRCPoly.setHelp("Harmony_ClassB_Library_for_PIC32MK_MC")
    classb_FlashCRCPoly.setMin(0xEDB88320)
    classb_FlashCRCPoly.setMax(0xEDB88320)
    classb_FlashCRCPoly.setDescription("The CRC-32 polynomial used for Flash self-test is " + str(hex(classb_FlashCRCPoly.getValue())))
    
    # Read-only symbol for max SysTick count
    classb_SysTickMaxCount = classBComponent.createHexSymbol("CLASSB_SYSTICK_MAXCOUNT", classBReadOnlyParams)
    classb_SysTickMaxCount.setLabel("Maximum SysTick count")
    classb_SysTickMaxCount.setDefaultValue(0xFFFFFFFF)
    classb_SysTickMaxCount.setReadOnly(True)
    classb_SysTickMaxCount.setHelp("Harmony_ClassB_Library_for_PIC32MK_MC")
    classb_SysTickMaxCount.setMin(0xFFFFFFFF)
    classb_SysTickMaxCount.setMax(0xFFFFFFFF)
    classb_SysTickMaxCount.setDescription("The SysTick is a 32-bit counter with max count value " + str(hex(classb_SysTickMaxCount.getValue())))
    
    # Read-only symbol for max CPU clock frequency
    classb_CPU_MaxClock = classBComponent.createIntegerSymbol("CLASSB_CPU_MAX_CLOCK", classBReadOnlyParams)
    classb_CPU_MaxClock.setLabel("Maximum CPU clock frequency")
    classb_CPU_MaxClock.setDefaultValue(120000000)
    classb_CPU_MaxClock.setReadOnly(True)
    classb_CPU_MaxClock.setHelp("Harmony_ClassB_Library_for_PIC32MK_MC")
    classb_CPU_MaxClock.setMin(120000000)
    classb_CPU_MaxClock.setMax(120000000)
    classb_CPU_MaxClock.setDescription("The self-test for CPU clock frequency assumes that the maximum CPU clock frequency is " + str(classb_CPU_MaxClock.getValue()) + "Hz")
    
    # Read-only symbol for expected RTC clock frequency
    classb_TMR_Clock = classBComponent.createIntegerSymbol("CLASSB_TMR1_EXPECTED_CLOCK", classBReadOnlyParams)
    classb_TMR_Clock.setLabel("Expected RTC clock frequency")
    classb_TMR_Clock.setDefaultValue(32768)
    classb_TMR_Clock.setReadOnly(True)
    classb_TMR_Clock.setHelp("Harmony_ClassB_Library_for_PIC32MK_MC")
    classb_TMR_Clock.setMin(32768)
    classb_TMR_Clock.setMax(32768)
    classb_TMR_Clock.setDescription("The self-test for CPU clock frequency expects the RTC clock frequency to be " + str(classb_TMR_Clock.getValue()) + "Hz")
    
    # Read-only symbol for maximum configurable accuracy for CPU clock self-test
    classb_MaxAccuracy = classBComponent.createIntegerSymbol("CLASSB_CPU_CLOCK_TEST_ACCUR", classBReadOnlyParams)
    classb_MaxAccuracy.setLabel("Maximum accuracy for CPU clock test")
    classb_MaxAccuracy.setDefaultValue(5)
    classb_MaxAccuracy.setReadOnly(True)
    classb_MaxAccuracy.setHelp("Harmony_ClassB_Library_for_PIC32MK_MC")
    classb_MaxAccuracy.setMin(5)
    classb_MaxAccuracy.setMax(5)
    classb_MaxAccuracy.setDescription("Error percentage selected for CPU clock frequency test must be " + str(classb_MaxAccuracy.getValue()) + "% or higher")
    
    # Creating Symbols for io_pin_test code generation
    gpioChannelName = []
    gpioChannelCnt = []
    gpioChannelPin = []
    PORT_PIN_LIST_CFG = []
    PORT_LIST = ""
    USE_PIN_MACRO = True
    # GPIO Total channel number
    gpioTotalChannels = classBComponent.createIntegerSymbol("CLASSB_GPIO_CHANNEL_TOTAL" , classBReadOnlyParams)
    gpioTotalChannels.setVisible(False)
    gpioTotalChannels.setDefaultValue(len(pioSymChannel))

    # GPIO_CHANNEL_" + i + "_NAME
    for i in range(0, len(pioSymChannel)):
        gpioChannelName.append(i)
        gpioChannelCnt.append(i)
        # GPIO Channel name
        gpioChannelName[i] = classBComponent.createStringSymbol("CLASSB_GPIO_CHANNEL_" + str( i ) + "_NAME" , classBReadOnlyParams)
        gpioChannelName[i].setVisible(False)
        gpioChannelName[i].setDefaultValue(pioSymChannel[i])
        # GPIO Channel pin count
        gpioChannelCnt[i] = classBComponent.createIntegerSymbol("CLASSB_GPIO_CHANNEL_" + str( i ) + "_PIN_CNT" , classBReadOnlyParams)
        gpioChannelCnt[i].setVisible(False)
        gpioChannelCnt[i].setDefaultValue(len(port_dict[pioSymChannel[i]]))
        # Constuct GPIO Port List
        if USE_PIN_MACRO:
            PORT_LIST += "CLASSB_GPIO_PORT_" + str( pioSymChannel[i] ) + ",\r\n    "
        else:
            PORT_LIST +=  str( i ) + "U, "
        gpioChannelPin = []
        PORT_PIN_LIST = ""
        for j in range(len(port_dict[pioSymChannel[i]])):
            gpioChannelPin.append(i)
            # GPIO Channel Pin name
            gpioChannelPin[j] = classBComponent.createIntegerSymbol("CLASSB_GPIO_CHANNEL_" + str( i ) + "_PIN_" + str( j ) , classBReadOnlyParams)
            gpioChannelPin[j].setVisible(False)
            gpioChannelPin[j].setDefaultValue(port_dict[pioSymChannel[i]][j])
            # Construct GPIO PORT Pin List
            if USE_PIN_MACRO:
                PORT_PIN_LIST += "CLASSB_GPIO_PIN_R" + str ( pioSymChannel[i] ) + str( port_dict[pioSymChannel[i]][j] ) + ",\r\n    "
            else:
                PORT_PIN_LIST += str( port_dict[pioSymChannel[i]][j] ) + "U, "
        PORT_PIN_LIST_CFG.append(i)
        # GPIO PORT Pin List
        PORT_PIN_LIST_CFG[i] = classBComponent.createStringSymbol("CLASSB_GPIO_CHANNEL_" + str( i ) + "_PIN_LIST", classBReadOnlyParams)
        PORT_PIN_LIST_CFG[i].setVisible(False)
        if USE_PIN_MACRO:
            PORT_PIN_LIST_CFG[i].setDefaultValue(PORT_PIN_LIST[0:len(PORT_PIN_LIST)-7] )
        else:
            PORT_PIN_LIST_CFG[i].setDefaultValue(PORT_PIN_LIST[0:len(PORT_PIN_LIST)-2] )
    # Constuct GPIO Port List
    PORT_LIST_CFG = classBComponent.createStringSymbol("CLASSB_GPIO_CHANNEL_LIST" , classBReadOnlyParams)
    PORT_LIST_CFG.setVisible(False)
    if USE_PIN_MACRO:
        PORT_LIST_CFG.setDefaultValue(PORT_LIST[0:len(PORT_LIST)-7])
    else:
        PORT_LIST_CFG.setDefaultValue(PORT_LIST[0:len(PORT_LIST)-2])
    
############################################################################
#### Code Generation ####
############################################################################

    # Main Header File
    classBHeaderFile = classBComponent.createFileSymbol("CLASSB_HEADER", None)
    classBHeaderFile.setSourcePath("/templates/classb.h.ftl")
    classBHeaderFile.setOutputName("classb.h")
    classBHeaderFile.setDestPath("/classb")
    classBHeaderFile.setProjectPath("config/" + configName + "/classb")
    classBHeaderFile.setType("HEADER")
    classBHeaderFile.setMarkup(True)
    
    # Main Source File
    classBSourceFile = classBComponent.createFileSymbol("CLASSB_SOURCE", None)
    classBSourceFile.setSourcePath("/templates/classb.c.ftl")
    classBSourceFile.setOutputName("classb.c")
    classBSourceFile.setDestPath("/classb")
    classBSourceFile.setProjectPath("config/" + configName + "/classb")
    classBSourceFile.setType("SOURCE")
    classBSourceFile.setMarkup(True)
    
    
    # Header File common for all tests
    classBCommHeaderFile = classBComponent.createFileSymbol("CLASSB_COMMON_HEADER", None)
    classBCommHeaderFile.setSourcePath("/templates/classb_common.h.ftl")
    classBCommHeaderFile.setOutputName("classb_common.h")
    classBCommHeaderFile.setDestPath("/classb")
    classBCommHeaderFile.setProjectPath("config/" + configName +"/classb")
    classBCommHeaderFile.setType("HEADER")
    classBCommHeaderFile.setMarkup(True)
    
    # Source File for result handling
    classBSourceResultMgmt = classBComponent.createFileSymbol("CLASSB_SOURCE_RESULT_MGMT_S", None)
    classBSourceResultMgmt.setSourcePath("/templates/classb_result_management.S.ftl")
    classBSourceResultMgmt.setOutputName("classb_result_management.S")
    classBSourceResultMgmt.setDestPath("/classb")
    classBSourceResultMgmt.setProjectPath("config/" + configName + "/classb")
    classBSourceResultMgmt.setType("SOURCE")
    classBSourceResultMgmt.setMarkup(True)
    
    # Header File for result handling
    classBHeaderResultMgmt = classBComponent.createFileSymbol("CLASSB_HEADER_RESULT_MGMT", None)
    classBHeaderResultMgmt.setSourcePath("/templates/classb_result_management.h.ftl")
    classBHeaderResultMgmt.setOutputName("classb_result_management.h")
    classBHeaderResultMgmt.setDestPath("/classb")
    classBHeaderResultMgmt.setProjectPath("config/" + configName +"/classb")
    classBHeaderResultMgmt.setType("HEADER")
    classBHeaderResultMgmt.setMarkup(True)

    # Source File for CPU test
    classBSourceCpuTestAsm = classBComponent.createFileSymbol("CLASSB_SOURCE_CPUTEST_S", None)
    classBSourceCpuTestAsm.setSourcePath("/templates/classb_cpu_reg_test_asm.S.ftl")
    classBSourceCpuTestAsm.setOutputName("classb_cpu_reg_test_asm.S")
    classBSourceCpuTestAsm.setDestPath("/classb")
    classBSourceCpuTestAsm.setProjectPath("config/" + configName + "/classb")
    classBSourceCpuTestAsm.setType("SOURCE")
    classBSourceCpuTestAsm.setMarkup(True)
    
    # Source File for CPU test
    classBSourceCpuTest = classBComponent.createFileSymbol("CLASSB_SOURCE_CPUTEST", None)
    classBSourceCpuTest.setSourcePath("/templates/classb_cpu_reg_test.c.ftl")
    classBSourceCpuTest.setOutputName("classb_cpu_reg_test.c")
    classBSourceCpuTest.setDestPath("/classb")
    classBSourceCpuTest.setProjectPath("config/" + configName + "/classb")
    classBSourceCpuTest.setType("SOURCE")
    classBSourceCpuTest.setMarkup(True)
    
    # Header File for CPU test
    classBHeaderCpuTest = classBComponent.createFileSymbol("CLASSB_HEADER_CPU_TEST", None)
    classBHeaderCpuTest.setSourcePath("/templates/classb_cpu_reg_test.h.ftl")
    classBHeaderCpuTest.setOutputName("classb_cpu_reg_test.h")
    classBHeaderCpuTest.setDestPath("/classb")
    classBHeaderCpuTest.setProjectPath("config/" + configName +"/classb")
    classBHeaderCpuTest.setType("HEADER")
    classBHeaderCpuTest.setMarkup(True)

    # Header File for CPU test common
    classBHeaderCpuTest = classBComponent.createFileSymbol("CLASSB_HEADER_CPU_COMMON_TEST", None)
    classBHeaderCpuTest.setSourcePath("/templates/classb_reg_common.h.ftl")
    classBHeaderCpuTest.setOutputName("classb_reg_common.h")
    classBHeaderCpuTest.setDestPath("/classb")
    classBHeaderCpuTest.setProjectPath("config/" + configName +"/classb")
    classBHeaderCpuTest.setType("HEADER")
    classBHeaderCpuTest.setMarkup(True)

    # Source File for FPU test
    classBSourceFpuTestAsm = classBComponent.createFileSymbol("CLASSB_SOURCE_FPUTEST_S", None)
    classBSourceFpuTestAsm.setSourcePath("/templates/classb_fpu_reg_test_asm.S.ftl")
    classBSourceFpuTestAsm.setOutputName("classb_fpu_reg_test_asm.S")
    classBSourceFpuTestAsm.setDestPath("/classb")
    classBSourceFpuTestAsm.setProjectPath("config/" + configName + "/classb")
    classBSourceFpuTestAsm.setType("SOURCE")
    classBSourceFpuTestAsm.setMarkup(True)

    # Source File for FPU test
    classBSourceFpuTest = classBComponent.createFileSymbol("CLASSB_SOURCE_FPUTEST", None)
    classBSourceFpuTest.setSourcePath("/templates/classb_fpu_reg_test.c.ftl")
    classBSourceFpuTest.setOutputName("classb_fpu_reg_test.c")
    classBSourceFpuTest.setDestPath("/classb")
    classBSourceFpuTest.setProjectPath("config/" + configName + "/classb")
    classBSourceFpuTest.setType("SOURCE")
    classBSourceFpuTest.setMarkup(True)
    
    # Header File for FPU test
    classBHeaderFpuTest = classBComponent.createFileSymbol("CLASSB_HEADER_FPU_TEST", None)
    classBHeaderFpuTest.setSourcePath("/templates/classb_fpu_reg_test.h.ftl")
    classBHeaderFpuTest.setOutputName("classb_fpu_reg_test.h")
    classBHeaderFpuTest.setDestPath("/classb")
    classBHeaderFpuTest.setProjectPath("config/" + configName +"/classb")
    classBHeaderFpuTest.setType("HEADER")
    classBHeaderFpuTest.setMarkup(True)
    
    # Source File for CPU PC test
    classBSourceCpuPCTest = classBComponent.createFileSymbol("CLASSB_SOURCE_CPUPC_TEST", None)
    classBSourceCpuPCTest.setSourcePath("/templates/classb_cpu_pc_test.c.ftl")
    classBSourceCpuPCTest.setOutputName("classb_cpu_pc_test.c")
    classBSourceCpuPCTest.setDestPath("/classb")
    classBSourceCpuPCTest.setProjectPath("config/" + configName + "/classb")
    classBSourceCpuPCTest.setType("SOURCE")
    classBSourceCpuPCTest.setMarkup(True)
    
    # Source File for SRAM test
    classBSourceSRAMTest = classBComponent.createFileSymbol("CLASSB_SOURCE_SRAM_TEST", None)
    classBSourceSRAMTest.setSourcePath("/templates/classb_sram_test.c.ftl")
    classBSourceSRAMTest.setOutputName("classb_sram_test.c")
    classBSourceSRAMTest.setDestPath("/classb")
    classBSourceSRAMTest.setProjectPath("config/" + configName + "/classb")
    classBSourceSRAMTest.setType("SOURCE")
    classBSourceSRAMTest.setMarkup(True)
    
    # Header File for SRAM test
    classBHeaderSRAMTest = classBComponent.createFileSymbol("CLASSB_HEADER_SRAM_TEST", None)
    classBHeaderSRAMTest.setSourcePath("/templates/classb_sram_test.h.ftl")
    classBHeaderSRAMTest.setOutputName("classb_sram_test.h")
    classBHeaderSRAMTest.setDestPath("/classb")
    classBHeaderSRAMTest.setProjectPath("config/" + configName +"/classb")
    classBHeaderSRAMTest.setType("HEADER")
    classBHeaderSRAMTest.setMarkup(True)
    
    # Source File for SRAM test algorithms
    classBSourceSRAMAlgo = classBComponent.createFileSymbol("CLASSB_SOURCE_SRAM_ALGO", None)
    classBSourceSRAMAlgo.setSourcePath("/templates/classb_sram_algorithm.c.ftl")
    classBSourceSRAMAlgo.setOutputName("classb_sram_algorithm.c")
    classBSourceSRAMAlgo.setDestPath("/classb")
    classBSourceSRAMAlgo.setProjectPath("config/" + configName + "/classb")
    classBSourceSRAMAlgo.setType("SOURCE")
    classBSourceSRAMAlgo.setMarkup(True)
    
    # Header File for SRAM test algorithms
    classBHeaderSRAMAlgo = classBComponent.createFileSymbol("CLASSB_HEADER_SRAM_ALGO", None)
    classBHeaderSRAMAlgo.setSourcePath("/templates/classb_sram_algorithm.h.ftl")
    classBHeaderSRAMAlgo.setOutputName("classb_sram_algorithm.h")
    classBHeaderSRAMAlgo.setDestPath("/classb")
    classBHeaderSRAMAlgo.setProjectPath("config/" + configName +"/classb")
    classBHeaderSRAMAlgo.setType("HEADER")
    classBHeaderSRAMAlgo.setMarkup(True)
    
    # Source File for Flash test
    classBSourceFLASHTest = classBComponent.createFileSymbol("CLASSB_SOURCE_FLASH_TEST", None)
    classBSourceFLASHTest.setSourcePath("/templates/classb_flash_test.c.ftl")
    classBSourceFLASHTest.setOutputName("classb_flash_test.c")
    classBSourceFLASHTest.setDestPath("/classb")
    classBSourceFLASHTest.setProjectPath("config/" + configName + "/classb")
    classBSourceFLASHTest.setType("SOURCE")
    classBSourceFLASHTest.setMarkup(True)
    
    # Header File for Flash test
    classBHeaderFLASHTest = classBComponent.createFileSymbol("CLASSB_HEADER_FLASH_TEST", None)
    classBHeaderFLASHTest.setSourcePath("/templates/classb_flash_test.h.ftl")
    classBHeaderFLASHTest.setOutputName("classb_flash_test.h")
    classBHeaderFLASHTest.setDestPath("/classb")
    classBHeaderFLASHTest.setProjectPath("config/" + configName +"/classb")
    classBHeaderFLASHTest.setType("HEADER")
    classBHeaderFLASHTest.setMarkup(True)
    
    # Source File for Clock test
    classBSourceClockTest = classBComponent.createFileSymbol("CLASSB_SOURCE_CLOCK_TEST", None)
    classBSourceClockTest.setSourcePath("/templates/classb_clock_test.c.ftl")
    classBSourceClockTest.setOutputName("classb_clock_test.c")
    classBSourceClockTest.setDestPath("/classb")
    classBSourceClockTest.setProjectPath("config/" + configName + "/classb")
    classBSourceClockTest.setType("SOURCE")
    classBSourceClockTest.setMarkup(True)
    
    # Header File for Clock test
    classBHeaderClockTest = classBComponent.createFileSymbol("CLASSB_HEADER_CLOCK_TEST", None)
    classBHeaderClockTest.setSourcePath("/templates/classb_clock_test.h.ftl")
    classBHeaderClockTest.setOutputName("classb_clock_test.h")
    classBHeaderClockTest.setDestPath("/classb")
    classBHeaderClockTest.setProjectPath("config/" + configName +"/classb")
    classBHeaderClockTest.setType("HEADER")
    classBSourceClockTest.setMarkup(True)
    
    # Source File for Interrupt test
    classBSourceInterruptTest = classBComponent.createFileSymbol("CLASSB_SOURCE_INTERRUPT_TEST", None)
    classBSourceInterruptTest.setSourcePath("/templates/classb_interrupt_test.c.ftl")
    classBSourceInterruptTest.setOutputName("classb_interrupt_test.c")
    classBSourceInterruptTest.setDestPath("/classb")
    classBSourceInterruptTest.setProjectPath("config/" + configName + "/classb")
    classBSourceInterruptTest.setType("SOURCE")
    classBSourceInterruptTest.setMarkup(True)
    
    # Header File for Interrupt test
    classBHeaderInterruptTest = classBComponent.createFileSymbol("CLASSB_HEADER_INTERRUPT_TEST", None)
    classBHeaderInterruptTest.setSourcePath("/templates/classb_interrupt_test.h.ftl")
    classBHeaderInterruptTest.setOutputName("classb_interrupt_test.h")
    classBHeaderInterruptTest.setDestPath("/classb")
    classBHeaderInterruptTest.setProjectPath("config/" + configName +"/classb")
    classBHeaderInterruptTest.setType("HEADER")
    classBHeaderInterruptTest.setMarkup(True)
    
    # Source File for IO pin test
    classBSourceIOpinTest = classBComponent.createFileSymbol("CLASSB_SOURCE_IOPIN_TEST", None)
    classBSourceIOpinTest.setSourcePath("/templates/classb_io_pin_test.c.ftl")
    classBSourceIOpinTest.setOutputName("classb_io_pin_test.c")
    classBSourceIOpinTest.setDestPath("/classb")
    classBSourceIOpinTest.setProjectPath("config/" + configName + "/classb")
    classBSourceIOpinTest.setType("SOURCE")
    classBSourceIOpinTest.setMarkup(True)
    
    # Header File for IO pin test
    classBHeaderIOpinTest = classBComponent.createFileSymbol("CLASSB_HEADER_IOPIN_TEST", None)
    classBHeaderIOpinTest.setSourcePath("/templates/classb_io_pin_test.h.ftl")
    classBHeaderIOpinTest.setOutputName("classb_io_pin_test.h")
    classBHeaderIOpinTest.setDestPath("/classb")
    classBHeaderIOpinTest.setProjectPath("config/" + configName +"/classb")
    classBHeaderIOpinTest.setType("HEADER")
    classBHeaderIOpinTest.setMarkup(True)
    
    # System Definition
    classBSystemDefFile = classBComponent.createFileSymbol("CLASSB_SYS_DEF", None)
    classBSystemDefFile.setType("STRING")
    classBSystemDefFile.setOutputName("core.LIST_SYSTEM_DEFINITIONS_H_INCLUDES")
    classBSystemDefFile.setSourcePath("/templates/system/definitions.h.ftl")
    classBSystemDefFile.setMarkup(True)

    # Linker option to reserve 1kB of SRAM
    classB_xc32ld_reserve_sram = classBComponent.createSettingSymbol("CLASSB_XC32LD_RESERVE_SRAM", None)
    classB_xc32ld_reserve_sram.setCategory("C32-LD")
    classB_xc32ld_reserve_sram.setKey("oXC32ld-extra-opts")
    classB_xc32ld_reserve_sram.setAppend(True, ";")
    
    classB_xc32ld_reserve_sram.setValue("-mreserve=data@0x00000400:0x000007ff")
   
    