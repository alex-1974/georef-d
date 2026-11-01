# georef-d

Generic coordinate-space and reference-transformation infrastructure for D.

## Release target: v0.1.0

The first release targets a domain-neutral coordinate-space and transformation
framework. Consumers define their own spaces and transformation mathematics;
the core supplies type safety, composition, runtime registration and graph
execution. The release does not define GIS, CRS, geodesy, raster or OSM
semantics.

The `0.x` API is intentionally pre-stable. A later minor release may still
make breaking API changes before a `1.0.0` contract is established.

`georef-d` is intended to connect arbitrary coordinate spaces: pixels, raster
indices, local metric frames, geographic and projected CRS, game worlds,
scientific frames, screen coordinates and time-aware spaces. Users should be
able to define their own spaces and transformations while the library provides
strongly typed compile-time APIs and a dynamic runtime representation.

## What the library does

- coordinate spaces, axes, dimensions and units;
- typed and dynamic coordinates;
- explicit transformations and transformation pipelines;
- affine raster/image transforms;
- validation, invertibility and uncertainty metadata;
- adapters for `geo-d`, `geodesy-d`, `proj-d`, `raster-d`, `imagery-d` and
  `osm-d` without coupling the core to those libraries.

The core provides user-defined static space
tokens, optional compile-time axis descriptors, space-typed coordinates,
compile-time space/dimension traits, affine transforms and composable
transform pipelines. The core deliberately assigns no meaning to axis names,
units or coordinate values.

The library is pre-1.0. It does not define GIS, geodesy, image or game-world
semantics. Those belong in consumer code or optional future modules.

The release gate is: DMD and LDC library tests, the external consumer smoke
test under `tests/consumer`, and the documented release benchmark harness.

## Development

```sh
dub test
```

## Naming conventions

Consumer-facing introspection names use complete words and an `Of` suffix
where a type is being queried:

```text
isCoordinateSpace   spaceIdentifier   spaceSize
isTypedCoordinate   coordinateSpaceOf coordinateSize
isTransformation    sourceSpaceOf     targetSpaceOf
supportsForward     supportsInverse
```

The shorter implementation trait names remain available for early source
compatibility, but new consumer code should use the descriptive names above.

## Design principle

Compile-time when a coordinate space is known; runtime when it comes from
external metadata or user configuration.

## Define a static coordinate space

```d
import georef;

struct PixelSpace { enum id = "pixels"; enum dimension = 2; }
struct LocalSpace { enum id = "local"; enum dimension = 2; }

alias Pixel = Coordinate!(PixelSpace, double);

auto pixelToLocal = AffineTransform!(PixelSpace, LocalSpace, double, 2)(
    [[2.0, 0.0], [0.0, 3.0]], [10.0, 20.0]);

auto result = pixelToLocal.forward(Pixel([1.0, 2.0]));
assert(result.values == [12.0, 26.0]);
```

`PixelSpace` has no special meaning to `georef`. It is simply a user-defined
type carrying an identity and dimension. A different space is consequently a
different D type, even when it has the same dimension and value type. Axis
descriptors can be added as metadata with `defineSpace` and `AxisDescriptor`;
the core still does not interpret their names.

The metadata helper is useful when a consumer wants readable descriptors:

```d
alias SensorSpace = defineSpace!("sensor",
    AxisDescriptor!"range",
    AxisDescriptor!"azimuth");

alias SensorCoordinate = Coordinate!(SensorSpace, double);
static assert(axisName!(SensorSpace, 0) == "range");
```

Custom transformation models can opt into pipeline validation with the
`transformContract` mixin. Applications provide the actual forward mathematics;
the core only validates the declared source and target spaces.

```d
struct SensorToLab
{
    mixin transformContract!(SensorSpace, LabSpace, double, 2);

    Coordinate!(LabSpace, double, 2) forward(
        Coordinate!(SensorSpace, double, 2) value) const
    {
        return Coordinate!(LabSpace, double, 2)(
            [value.values[0] + 1.0, value.values[1] * 2.0]);
    }
}

auto pipeline = compose(sensorToLocal, SensorToLab());
```

The mixin supplies only compile-time metadata. It does not generate or guess
the transformation mathematics.

## Use runtime spaces and transformations

Runtime users can use `DynamicSpace`, `DynamicCoordinate`,
`DynamicAffineTransform` and `TransformGraph`. Graph execution returns an
explicit `TransformResult` with a `TransformError`; invalid runtime input is
never silently converted to a default coordinate.

```d
DynamicSpace sensor = {"sensor", ["first", "second"]};
DynamicSpace world = {"world", ["x", "y"]};

auto edge = DynamicAffineTransform(
    "sensor", "world", 2,
    [1.0, 0.0, 0.0, 1.0],
    [10.0, 20.0]);

TransformGraph graph;
assert(graph.addSpace(sensor));
assert(graph.addSpace(world));
assert(graph.addTransform(edge));

auto result = graph.transform(
    DynamicCoordinate("sensor", [2.0, 3.0]), "world");
assert(result.success);
assert(result.value.values == [12.0, 23.0]);
```

For non-affine models, construct `DynamicTransform` with a consumer-owned
delegate. The delegate returns `TransformResult` and may also provide an
inverse delegate. The graph uses the declared `cost` to choose among several
valid paths.

`TransformErrorInfo` can additionally carry source/target IDs and expected vs.
actual dimensions, which is useful for diagnostics at file and plugin
boundaries.

Affine transforms can provide inverse edges with `tryInverse`; the graph also
offers `addBidirectionalTransform` for registering both directions when the
matrix is invertible.

Runtime affine edges also expose a neutral `cost` value. `TransformGraph`
uses it to select the lowest-cost path, allowing applications to prefer
accuracy, performance or a particular transformation source without the core
knowing why one edge is better.

For repeated runtime work, prepare a path once and execute it with
`transformAlong`. The prepared path stores the selected edge indices and
avoids running the graph search for every coordinate. Numeric affine loops can
use `DynamicAffineTransform.applyInto` with caller-owned storage; this path is
`@nogc` and does not allocate a result coordinate.

`TransformPath` exposes the selected space sequence, exact transformation
edge indices and total cost for inspection or logging.

For static affine models, `composeAffine` pre-composes two compatible steps
into one matrix and offset. Applications can perform this during CTFE when
the inputs are compile-time values, leaving only the final affine evaluation
at runtime.

Runtime edges may carry consumer-defined `uncertainty`. The graph accumulates
that value on the selected path; its interpretation remains the application's
responsibility. Neutral `CoordinateVector` and `CoordinateBounds` types are
also available without adding GIS semantics.

Runnable consumer examples are available under `examples/`. The repository
contains a GitHub Pages workflow that generates DDox documentation on pushes
to `main`; Pages must be enabled once in the repository settings.

To generate the same documentation locally:

```sh
dub build --build=ddox --force
```

The generated site is written to `docs/`.

An external consumer smoke test is available in `tests/consumer`. The initial
benchmark plan is documented in `benchmarks/`.

