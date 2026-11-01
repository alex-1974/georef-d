import georef;

struct SensorSpace { enum id = "sensor"; enum dimension = 2; }
struct CalibratedSpace { enum id = "calibrated"; enum dimension = 2; }

struct Calibration
{
    mixin transformContract!(SensorSpace, CalibratedSpace, double, 2);

    Coordinate!(CalibratedSpace, double) forward(
        Coordinate!(SensorSpace, double) value) const
    {
        return Coordinate!(CalibratedSpace, double)(
            [value.values[0] + 0.5, value.values[1] * 2.0]);
    }
}

void main()
{
    auto result = Calibration().forward(
        Coordinate!(SensorSpace, double)([1.0, 3.0]));
    assert(result.values == [1.5, 6.0]);

    auto region = CoordinateBounds!(CalibratedSpace, double)(
        [0.0, 0.0], [10.0, 10.0]);
    assert(region.maximum[0] == 10.0);
}
