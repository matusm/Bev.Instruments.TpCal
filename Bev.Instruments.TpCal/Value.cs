using System;

namespace Bev.Instruments.TpCal
{
    public class Value
    {
        public int Channel { get; private set; } = -1;
        public double MeasurementValue { get; private set; } = double.NaN;
        public Unit MeasurementUnit { get; private set; } = Unit.None;
        public DateTime TimeStamp { get; private set; }
        public byte[] RawData { get; }

        internal Value(byte[] bytes)
        {
            RawData = bytes;
            ParseInstrumentResponse(bytes);
        }

        // this works for the TPCAL 100/25 but not for DMM 900!
        private void ParseInstrumentResponse(byte[] bytes)
        {
            if (bytes.Length < 7) return;
            if (bytes[0] != ACK) return;
            Channel = bytes[1];
            MeasurementValue = BitConverter.ToSingle(bytes, 2);
            MeasurementUnit = MeasUnit.ToUnit(bytes[6]);
            TimeStamp = DateTime.UtcNow;
        }

        public string RawDataToString()
        {
            string str = string.Empty;
            if (RawData.Length == 0) return str;
            foreach (var b in RawData)
            {
                str += $"{b:X2} ";
            }
            return str.Trim();
        }

        public override string ToString()
        {
            return $"Value[TimeStamp={TimeStamp} Channel={Channel} Value={MeasurementValue:F3} Unit={MeasurementUnit}]";
        }

        private const byte ACK = 0x6;

    }
}
