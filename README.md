Bev.Instruments.TpCal
=====================

A lightweight C# library for controlling the high precision thermometer TPCAL 100/25 via the serial bus.

## Overview

The TPCAL 100/25 by Dr. Denker Messtechnik is a high precision bench instrument for Pt25 and Pt100 temperature probes. Although the design of this instrument is quite old, it offers measurement advantages that make its use attractive. The device can be connected to a computer via a serial bus. This interface must be able to provide +/-12 V

### Constructor

The constructor `TpCal(string)` creates a new instance of this class taking a string as the single argument. The string is interpreted as the name of the serial port. 

### Methods

* `Value GetCurrentValue()`
Gets a `Value` object which contains properties like temperature, channel, unit and timestamp. The last unread value is returned. It is not possible to choose a specific channel. Over time, each channel will be read once.
 
* `void RebootAndWait()`
Soft reboot of the instrument. Returns when the instrument is ready.
 
### Properties

All properties are getters only.

* `InstrumentManufacturer`
Returns the string "Dr. Denker Messtechnik".

* `InstrumentType`
Returns the string "TPCAL 100/25".

* `InstrumentSerialNumber`
Returns the unique serial number of the instrument as a string.

* `InstrumentFirmwareVersion`
Returns a string for the firmware version.

* `InstrumentScannerVersion`
Returns a string for the scanner firmware version.

* `InstrumentID`
Returns a combination of the previous properties which unambiguously identifies the instrument.

* `DevicePort`
The port name as passed to the constructor.

* `NumberOfChannels`
As the name implies.

* `MeasurementUnit`
Gives the system wide unit for the returned value. (°C, Ohm, K, °F)


## Usage

The following code fragment demonstrate the use of this class.

```cs
using Bev.Instruments.TpCal;
using System;

namespace TempPlayground
{
    class MainClass
    {
        public static void Main(string[] args)
        {
            TpCal device = new TpCal("COM1");

            Console.WriteLine($"Instrument: {device.InstrumentID}");
            
            for (int i = 0; i < 10; i++)
            {
                Value value = device.GetCurrentValue();
                Console.WriteLine($"{i,3} : {value.MeasurementValue:F3} for channel {value.Channel}");
            }
        }
    }
}
```

## Value Class

This is a simple container class for handling the measurement parameters (temperature, channel, ...) obtained by a device query. Once created the values are immutable. For new measurement values one has to create a new object of this class. 

### Members

The relevant values are provided by getters

* `TimeStamp`
Returns the time of the query.

* `MeasurementValue`
Returns numerical value or `double.NaN` for invalid calls.

* `Channel`
Returns the channel number or -1 for invalid calls.

* `MeasurementUnit`
Returns unit for the measurement value as member of an enumeration.

* `RawData`
The byte field as returned by the instrument. For diagnostic use only.

There is no public constructor, objects of this class can only by created by a call to `TpCal.GetCurrentValue()`.
