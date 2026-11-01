import georef;

void main()
{
    TransformGraph graph;
    graph.addSpace(DynamicSpace("sensor", ["x", "y"]));
    graph.addSpace(DynamicSpace("world", ["x", "y"]));
    graph.addTransform(DynamicAffineTransform(
        "sensor", "world", 2, [1.0, 0.0, 0.0, 1.0], [10.0, 20.0]));
    auto path = graph.findPath("sensor", "world");
    auto result = graph.transformAlong(
        DynamicCoordinate("sensor", [1.0, 2.0]), path);
    assert(result.success);
    assert(result.value.values == [11.0, 22.0]);
}
