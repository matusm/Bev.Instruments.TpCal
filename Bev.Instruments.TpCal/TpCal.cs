// the channel numbering schema is not consistent!
// "h" enumerates the channels from 0 to 8: 0=A, 1=Scanner1, ... 8=Scanner8
// other queries use 0 to 9: 0=A, 1=B, 2=Scanner1, ... 9=Scanner9

using System;
using System.Collections.Generic;
using System.IO.Ports;
using System.Text;
using System.Threading;

namespace Bev.Instruments.TpCal
{
    public class TpCal
    {
        protected readonly SerialPort comPort;
        protected const int waitAfterClose = 150;   // in ms
        protected const int waitForResponse = 200;  // delay between .Write and .Read in ms
        protected const string undefinedText = "<undefined>";

        public TpCal(string portName)
        {
            DevicePort = portName.Trim();
            comPort = new SerialPort(DevicePort, 9600, Parity.None, 8, StopBits.One);
            comPort.RtsEnable = true;
            comPort.DtrEnable = false;
        }

        public string DevicePort { get; }
        public string InstrumentManufacturer => "Dr. Denker Messtechnik"; // Dostmann electronic GmbH
        public string InstrumentType => "TPCAL 100/25"; // DDM 900
        public string InstrumentSerialNumber => GetInstrumentSerialNumber();
        public string InstrumentFirmwareVersion => GetInstrumentVersion();
        public string InstrumentScannerVersion => GetScannerVersion();
        public string InstrumentID => $"{InstrumentType} {InstrumentSerialNumber} {InstrumentFirmwareVersion}";
        public int NumberOfChannels => GetNumberOfChannels();
        public Unit MeasurementUnit => GetUnit();

        public Value GetCurrentValue()
        {
            var bytes = Query("h");
            return new Value(bytes);
        }

        public void ReboootAndWait()
        {
            Reboot();
            while (!IsReady())
                Thread.Sleep(waitForResponse); // just a random value
        }

        public void Reboot() => Query("o");

        public bool IsReady()
        {
            byte[] response = Query("a");
            if (response.Length == 1)
                if (response[0] == ACK)
                    return true;
            return false;
        }

        public string GetParameterInfoForChannel(int channel)
        {
            //TODO check bounds
            byte[] code = { 0xF8, 0x00 };
            code[1] = (byte)channel;
            byte[] response = Query(code);
            if(response.Length==1)
                return GetParameterInfo(response[0]);
            return undefinedText;
        }

        public string GetParameterInfo(int index)
        {
            if (index < 0 || index > 20) return undefinedText;
            byte[] response = Query("f", (byte)index);
            if (response.Length <=1) return undefinedText;
            return Encoding.ASCII.GetString(response);
        }

        public void SetChannelOn(int channel)
        {
            byte[] code = {0x77, 0x00, 0x01};
            code[1] = (byte)channel;
            Query(code);
        }

        public void SetChannelOff(int channel)
        {
            byte[] code = { 0x77, 0x00, 0x00};
            code[1] = (byte)channel;
            Query(code);
        }

        private string GetScannerVersion()
        {
            var ver1 = Parse2ByteResponse(Query(0xE3));
            var ver2 = Parse2ByteResponse(Query(0xE4));
            if (ver1 == -1 || ver2 == -1) return undefinedText;
            return $"V{ver1}.{ver2}";
        }

        private int Parse2ByteResponse(byte[] response)
        {
            if (response.Length != 2) return -1;
            if (response[0] != ACK) return -1;
            return response[1];
        }

        private string GetInstrumentSerialNumber()
        {
            var bytes = Query("b");
            if (bytes.Length != 16) return undefinedText;
            return Encoding.ASCII.GetString(bytes);
        }

        private string GetInstrumentVersion()
        {
            var bytes = Query("c");
            if (bytes.Length != 6) return undefinedText;
            return Encoding.ASCII.GetString(bytes);
        }
        
        private int GetNumberOfChannels()
        {
            var bytes = Query("d");
            if (bytes.Length != 1) return -1;
            return bytes[0];
        }

        private Unit GetUnit()
        {
            var bs = Query(0xF5);
            byte b = 0xFF;
            if (bs.Length > 0) b = bs[0];
            return MeasUnit.ToUnit(b);
        }

        private byte[] Query(string command, byte index)
        {
            byte[] ba1 = Encoding.ASCII.GetBytes(command);
            Array.Resize(ref ba1, ba1.Length + 1);
            ba1[ba1.Length-1] = index;
            return Query(ba1);
        }

        private byte[] Query(byte command)
        {
            byte[] code = new byte[1];
            code[0] = command;
            return Query(code);
        }

        private byte[] Query(byte[] command)
        {
            List<byte> response = new List<byte>();
            OpenPort();
            try
            {
                comPort.Write(command, 0, command.Length);
                Thread.Sleep(waitForResponse);
                while (comPort.BytesToRead > 0)
                {
                    int b = comPort.ReadByte();
                    if (b == -1) break;
                    response.Add((byte)b);
                }
            }
            catch (Exception e)
            {
                Console.WriteLine("exception in Query: " + e.Message);
            }
            ClosePort();
            Thread.Sleep(waitAfterClose);
            return response.ToArray();
        }

        private byte[] Query(string command) => Query(Encoding.ASCII.GetBytes(command));

        private void OpenPort()
        {
            try
            {
                if (!comPort.IsOpen)
                    comPort.Open();
            }
            catch (Exception)
            { }
        }

        private void ClosePort()
        {
            try
            {
                if (comPort.IsOpen)
                {
                    comPort.Close();
                    Thread.Sleep(waitAfterClose);
                }
            }
            catch (Exception)
            { }
        }

        private const byte ACK = 0x6;
        private const byte NAK = 0x15;

    }
}
