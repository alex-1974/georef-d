import georef;

alias SensorSpace = defineSpace!("sensor", AxisDescriptor!"x", AxisDescriptor!"y");
struct WorldSpace { enum id = "world"; enum dimension = 2; }

void main()
{
    alias Sensor = Coordinate!(SensorSpace, double);
    auto toWorld = AffineTransform!(SensorSpace, WorldSpace, double, 2)(
        [[2.0, 0.0], [0.0, 2.0]], [10.0, 20.0]);
    auto result = toWorld.forward(Sensor([1.0, 2.0]));
    assert(result.values == [12.0, 24.0]);
}
