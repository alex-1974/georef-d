import georef;

struct SourceSpace { enum id = "source"; enum dimension = 2; }
struct TargetSpace { enum id = "target"; enum dimension = 2; }

void main()
{
    alias Source = Coordinate!(SourceSpace, double);
    auto operation = AffineTransform!(SourceSpace, TargetSpace, double, 2)(
        [[1.0, 0.0], [0.0, 1.0]], [4.0, 5.0]);
    auto value = operation.forward(Source([1.0, 2.0]));
    assert(value.values == [5.0, 7.0]);
}
