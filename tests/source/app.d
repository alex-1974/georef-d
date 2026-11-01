import georef;

void main() {
    alias DeclaredSpace = defineSpace!("declared",
        AxisDescriptor!"first", AxisDescriptor!"second");
    static assert(isCoordinateSpace!DeclaredSpace);
    static assert(spaceSize!DeclaredSpace == 2);
    static assert(axisName!(DeclaredSpace, 0) == "first");
    static assert(axisName!(DeclaredSpace, 1) == "second");
    static assert(!__traits(compiles,
        defineSpace!("invalid", int)));
    alias DeclaredVector = CoordinateVector!(DeclaredSpace, double);
    alias DeclaredBounds = CoordinateBounds!(DeclaredSpace, double);
    static assert(DeclaredVector.init.values.length == 2);
    static assert(DeclaredBounds.init.minimum.length == 2);
    static assert(isCoordinateVector!DeclaredVector);
    static assert(isCoordinateBounds!DeclaredBounds);
    static assert(!isCoordinateVector!Pixel);
    static assert(!isCoordinateBounds!Pixel);
    auto vector = DeclaredVector([1.0, 2.0]);
    auto bounds = DeclaredBounds([0.0, 0.0], [10.0, 20.0]);
    assert(vector.values == [1.0, 2.0]);
    assert(bounds.maximum == [10.0, 20.0]);

    struct PixelSpace { enum id = "pixels"; enum dimension = 2; }
    struct LocalSpace { enum id = "local"; enum dimension = 2; }
    struct WorldSpace { enum id = "world"; enum dimension = 2; }

    struct NonLinearTransform
    {
        mixin transformContract!(LocalSpace, WorldSpace, double, 2);

        Coordinate!(WorldSpace, double, 2) forward(
            Coordinate!(LocalSpace, double, 2) value) const
        {
            return Coordinate!(WorldSpace, double, 2)(
                [value.values[0] * value.values[0], value.values[1] + 1.0]);
        }
    }

    alias Pixel = Coordinate!(PixelSpace, double);
    alias Local = Coordinate!(LocalSpace, double);
    alias World = Coordinate!(WorldSpace, double);

    static assert(isCoordinateSpace!PixelSpace);
    static assert(spaceSize!PixelSpace == 2);
    static assert(isTypedCoordinate!Pixel);
    static assert(coordinateSpaceOf!Pixel == PixelSpace);
    static assert(coordinateSize!Pixel == 2);
    static assert(!__traits(compiles, Local(Pixel.init.values)));

    auto pixelToLocal = AffineTransform!(PixelSpace, LocalSpace, double, 2)(
        [[2.0, 0.0], [0.0, 3.0]], [10.0, 20.0]);
    auto localToWorld = AffineTransform!(LocalSpace, WorldSpace, double, 2)(
        [[1.0, 0.0], [0.0, 1.0]], [100.0, -5.0]);
    auto nonlinear = NonLinearTransform();
    auto pixel = Pixel([1.0, 2.0]);
    static assert(isTransformation!(typeof(pixelToLocal)));
    static assert(sourceSpaceOf!(typeof(pixelToLocal)) == PixelSpace);
    static assert(targetSpaceOf!(typeof(pixelToLocal)) == LocalSpace);
    static assert(transformationSize!(typeof(pixelToLocal)) == 2);
    static assert(isTransformation!NonLinearTransform);
    static assert(supportsForward!NonLinearTransform);
    static assert(!supportsInverse!NonLinearTransform);
    static assert(supportsForward!(typeof(pixelToLocal)));
    static assert(!__traits(compiles, compose(localToWorld, pixelToLocal)));
    assert(pixelToLocal.forward(pixel).values == [12.0, 26.0]);
    AffineTransform!(LocalSpace, PixelSpace, double, 2) inverse;
    assert(pixelToLocal.tryInverse(inverse));
    assert(inverse.forward(local).values == [1.0, 2.0]);
    auto pipeline = compose(pixelToLocal, localToWorld);
    World world = pipeline.forward(pixel);
    assert(world.values == [112.0, 21.0]);
    enum combined = composeAffine(pixelToLocal, localToWorld);
    static assert(combined.matrix[0][0] == 2.0);
    static assert(combined.matrix[1][1] == 3.0);
    static assert(combined.offset[0] == 110.0);
    static assert(combined.offset[1] == 15.0);
    assert(combined.forward(pixel).values == [112.0, 21.0]);
    auto nonlinearResult = compose(pixelToLocal, nonlinear).forward(pixel);
    assert(nonlinearResult.values == [144.0, 27.0]);

    DynamicSpace runtimeSpace = {"runtime-sensor", ["a", "b", "c"]};
    DynamicCoordinate runtimeValue = {"runtime-sensor", [1.0, 2.0, 3.0]};
    assert(runtimeSpace.isValid);
    assert(runtimeValue.isValid(runtimeSpace));
    runtimeValue.values = [1.0, 2.0];
    assert(!runtimeValue.isValid(runtimeSpace));

    DynamicSpace runtimeTarget = {"runtime-world", ["x", "y", "z"]};
    auto runtimeTransform = DynamicAffineTransform(
        "runtime-sensor", "runtime-world", 3,
        [2.0, 0.0, 0.0, 0.0, 2.0, 0.0, 0.0, 0.0, 2.0],
        [10.0, 20.0, 30.0]);
    assert(runtimeTransform.isValid(runtimeSpace, runtimeTarget));
    runtimeValue.values = [1.0, 2.0, 3.0];
    auto runtimeResult = runtimeTransform.forward(runtimeValue);
    assert(runtimeResult.isValid(runtimeTarget));
    assert(runtimeResult.values == [12.0, 24.0, 36.0]);
    double[3] outputBuffer;
    assert(runtimeTransform.applyInto(outputBuffer[], runtimeValue.values[]));
    assert(outputBuffer[] == [12.0, 24.0, 36.0]);

    TransformGraph graph;
    assert(graph.addSpace(runtimeSpace));
    assert(graph.addSpace(runtimeTarget));
    assert(graph.addTransform(runtimeTransform));
    auto runtimeInverse = runtimeTransform;
    assert(runtimeTransform.tryInverse(runtimeInverse));
    assert(runtimeInverse.forward(runtimeResult).values == [1.0, 2.0, 3.0]);
    auto path = graph.findPath("runtime-sensor", "runtime-world");
    assert(path.spaces == ["runtime-sensor", "runtime-world"]);
    assert(path.transformIndices.length == 1);
    assert(path.totalCost == 1.0);
    auto graphResult = graph.transform(runtimeValue, "runtime-world");
    assert(graphResult.success);
    assert(graphResult.value.values == [12.0, 24.0, 36.0]);
    auto preparedResult = graph.transformAlong(runtimeValue, path);
    assert(preparedResult.success);
    assert(preparedResult.value.values == [12.0, 24.0, 36.0]);
    auto custom = DynamicTransform("runtime-sensor", "runtime-world", 3, 0.5,
        (const ref DynamicCoordinate value) {
            return TransformResult(
                DynamicCoordinate("runtime-world", value.values.dup),
                TransformError.none);
        },
        (const ref DynamicCoordinate value) {
            return TransformResult(
                DynamicCoordinate("runtime-sensor", value.values.dup),
                TransformError.none);
        });
    TransformGraph customGraph;
    assert(customGraph.addSpace(runtimeSpace));
    assert(customGraph.addSpace(runtimeTarget));
    assert(customGraph.addTransform(custom));
    assert(customGraph.transform(runtimeValue, "runtime-world").success);
    assert(custom.hasInverse);
    assert(customGraph.addBidirectionalTransform(custom));

    assert(!graph.addSpace(runtimeSpace));
    DynamicSpace detour = {"detour", ["x", "y", "z"]};
    assert(customGraph.addSpace(detour));
    auto invalidEdge = DynamicTransform("detour", "runtime-world", 2, 1.0,
        (const ref DynamicCoordinate value) {
            return TransformResult(value, TransformError.none);
        });
    assert(!customGraph.addTransform(invalidEdge));

    TransformGraph weighted;
    assert(weighted.addSpace(runtimeSpace));
    assert(weighted.addSpace(runtimeTarget));
    assert(weighted.addSpace(detour));
    auto expensive = runtimeTransform;
    expensive.cost = 10.0;
    assert(weighted.addTransform(expensive));
    auto cheapDetour = DynamicTransform("runtime-sensor", "detour", 3, 1.0,
        (const ref DynamicCoordinate value) {
            return TransformResult(DynamicCoordinate("detour", value.values.dup),
                TransformError.none);
        });
    auto cheapWorld = DynamicTransform("detour", "runtime-world", 3, 1.0,
        (const ref DynamicCoordinate value) {
            return TransformResult(DynamicCoordinate("runtime-world", value.values.dup),
                TransformError.none);
        });
    assert(weighted.addTransform(cheapDetour));
    assert(weighted.addTransform(cheapWorld));
    auto weightedPath = weighted.findPath("runtime-sensor", "runtime-world");
    assert(weightedPath.spaces == ["runtime-sensor", "detour", "runtime-world"]);
    assert(weightedPath.totalCost == 2.0);

    auto missingPath = graph.transform(runtimeValue, "missing");
    assert(!missingPath.success && missingPath.error == TransformError.invalidSpace);
    assert(missingPath.info.sourceId == "runtime-sensor");
    assert(missingPath.info.targetId == "missing");
}

