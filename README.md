# Embedded Systems Design Studio
An exhibition of my labs and projects for my second-year electrical engineering firmware design course. *Note that for most files uploaded, only the main and/or final version of the code is shown. Supporting make files and/or header files are **not** uploaded.* 

**Microcontrollers Used:** *AT89LP51RC2*, *EFM8LB1*, *PIC32MX130*, *ATMEGA328P*. 

## LCD Experimentation
Displays my name and student number on a seven-segment liquid crystal display (LCD). For privacy reasons, my name and number are replaced with a space of type '*char*'.

## Alarm Clock
Built a beeping digital alarm clock that works in both twelve-hour intervals (AM & PM).

## LM335 Thermometer
Uses the serial port to connect the microcontroller with the computer to interchange information—temperature and voltage, in this case. 32-bit unsigned arithmetic was performed to convert voltage to temperature to be displayed on a live temperature stripchart, programmed with Python.  

## Capacitance Meter with EFM8LB1
Utilizes the LM555 timer to build a capacitance meter that works in the range of 1 nanofarad to 1 microfarad.

## Phasor Analysis
Built, programmed, and tested an AC-based voltmeter that displays both the magnitude and the phase.

## Capacitance Meter with PIC32MX130
Refer *Capacitance meter with EFM8LB1*.

## RC Car Design
Created an autonomous robot that is controlled remotely using a varying magnetic field. The robot is powered by batteries and controlled using the *PIC32MX130* microcontroller. The robot is designed, built, programmed, and tested to operate in two modes. In the first mode, called tracker mode, the robot should be able to maintain a constant distance from the magnetic transmitter. If the remote moves, the robot should adjust its position to maintain a fixed distance from it. In the second mode, called command mode, the robot receives commands from the remote (controlled with the *ATMEGA328P* microcontroller) via the magnetic field and executes them accordingly.
