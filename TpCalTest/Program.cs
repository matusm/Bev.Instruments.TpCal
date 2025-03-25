using Bev.Instruments.TpCal;
using System;
using System.Threading;

namespace TpCalTest
{
    class Program
    {
        static void Main(string[] args)
        {
            string port = "COM114";
            if (args.Length > 0) port = args[0];

            TpCal tpcal = new TpCal(port);

            //tpcal.ReboootAndWait();

            Console.WriteLine($"Com Port:           {tpcal.DevicePort}");
            Console.WriteLine($"Manufacturer:       {tpcal.InstrumentManufacturer}");
            Console.WriteLine($"Type:               {tpcal.InstrumentType}");
            Console.WriteLine($"Serialnumber:       {tpcal.InstrumentSerialNumber}");
            Console.WriteLine($"Firmware version:   {tpcal.InstrumentFirmwareVersion}");
            Console.WriteLine($"Scanner version:    {tpcal.InstrumentScannerVersion}");
            Console.WriteLine($"Number of channels: {tpcal.NumberOfChannels}");
            Console.WriteLine($"Unit:               {tpcal.MeasurementUnit}");

            //tpcal.SetChannelOff(0);
            //tpcal.SetChannelOff(1);
            //tpcal.SetChannelOff(2);
            //tpcal.SetChannelOff(3); 
            //tpcal.SetChannelOff(4); 
            //tpcal.SetChannelOff(5);
            //tpcal.SetChannelOff(6);
            //tpcal.SetChannelOff(7);
            //tpcal.SetChannelOff(8);

            //tpcal.SetChannelOn(0);
            //tpcal.SetChannelOn(1);
            //tpcal.SetChannelOn(2);
            //tpcal.SetChannelOn(3);
            //tpcal.SetChannelOn(4);
            //tpcal.SetChannelOn(5);
            //tpcal.SetChannelOn(6);
            //tpcal.SetChannelOn(7);
            //tpcal.SetChannelOn(8);

            //tpcal.ReboootAndWait();

            Console.WriteLine();

            for (int i = 0; i <=9 ; i++)
            {
                Console.WriteLine($"{i}: {tpcal.GetParameterInfoForChannel(i)}");
            }

            Console.WriteLine();

            for (int i = 0; i < 50; i++)
            {
                Value value = tpcal.GetCurrentValue();
                Console.WriteLine($"{value.Channel}: {value.MeasurementValue:F4}  [{value.RawDataToString()}]");
                Thread.Sleep(250);
            }

            Console.WriteLine("done.");

        }
    }
}
