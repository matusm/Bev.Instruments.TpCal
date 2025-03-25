namespace Bev.Instruments.TpCal
{
    public static class MeasUnit
    {
        public static Unit ToUnit(int code) => ToUnit((byte)code);

        public static Unit ToUnit(byte code)
        {
            switch (code)
            {
                case 0x00:
                    return Unit.Ohm;
                case 0x01:
                    return Unit.Celsius;
                case 0x02:
                    return Unit.Kelvin;
                case 0x03:
                    return Unit.Fahrenheit;
                default:
                    return Unit.None;
            }
        }
    }

    public enum Unit
    {
        None,
        Ohm,
        Celsius,
        Kelvin,
        Fahrenheit
    }
}
