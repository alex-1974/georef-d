import georef;
import std.datetime.stopwatch : StopWatch;
import std.stdio : writefln;

struct SourceSpace { enum id = "benchmark-source"; enum dimension = 2; }
struct MiddleSpace { enum id = "benchmark-middle"; enum dimension = 2; }
struct TargetSpace { enum id = "benchmark-target"; enum dimension = 2; }

enum iterations = 1_000_000;

void main()
{
    alias Value = Coordinate!(SourceSpace, double);
    auto first = AffineTransform!(SourceSpace, MiddleSpace, double, 2)(
        [[1.25, 0.0], [0.0, 0.75]], [2.0, 3.0]);
    auto second = AffineTransform!(MiddleSpace, TargetSpace, double, 2)(
        [[0.5, 0.0], [0.0, 1.5]], [4.0, -2.0]);
    auto pipeline = compose(first, second);
    enum combined = composeAffine(
        AffineTransform!(SourceSpace, MiddleSpace, double, 2)(
            [[1.25, 0.0], [0.0, 0.75]], [2.0, 3.0]),
        AffineTransform!(MiddleSpace, TargetSpace, double, 2)(
            [[0.5, 0.0], [0.0, 1.5]], [4.0, -2.0]));
    auto input = Value([10.0, 20.0]);
    DynamicSpace runtimeSource = {"benchmark-source", ["x", "y"]};
    DynamicSpace runtimeTarget = {"benchmark-target", ["x", "y"]};
    auto runtimeEdge = DynamicAffineTransform(
        "benchmark-source", "benchmark-target", 2,
        [1.25, 0.0, 0.0, 0.75], [2.0, 3.0]);
    TransformGraph graph;
    graph.addSpace(runtimeSource);
    graph.addSpace(runtimeTarget);
    graph.addTransform(runtimeEdge);
    auto runtimeInput = DynamicCoordinate("benchmark-source", [10.0, 20.0]);
    double[2] outputBuffer;
    auto preparedPath = graph.findPath("benchmark-source", "benchmark-target");

    void measure(string name, void delegate() operation)
    {
        StopWatch timer;
        timer.start();
        operation();
        timer.stop();
        writefln("%-24s %8.3f ms", name, timer.peek.total!"msecs");
    }

    measure("static pipeline", {
        foreach (_; 0 .. iterations) pipeline.forward(input);
    });
    measure("CTFE affine", {
        foreach (_; 0 .. iterations) combined.forward(input);
    });
    measure("runtime direct", {
        foreach (_; 0 .. iterations) runtimeEdge.apply(runtimeInput);
    });
    measure("runtime affine into", {
        foreach (_; 0 .. iterations) runtimeEdge.applyInto(outputBuffer[], runtimeInput.values[]);
    });
    measure("runtime graph", {
        foreach (_; 0 .. iterations) graph.transform(runtimeInput, "benchmark-target");
    });
    measure("prepared graph path", {
        foreach (_; 0 .. iterations) graph.transformAlong(runtimeInput, preparedPath);
    });
}
