/** Neutral coordinate-associated value types. */
module georef.core.geometry;

import georef.core.space : isSpace, spaceDimension;

/// A direction or displacement in a user-defined coordinate space.
struct CoordinateVector(Space, T, size_t Dimension = spaceDimension!Space)
if (isSpace!Space && Dimension == spaceDimension!Space)
{
    alias SpaceType = Space;
    alias ValueType = T;
    enum dimension = Dimension;
    enum isCoordinateVectorType = true;
    /// Components in the owning space's axis order.
    T[Dimension] values;

    this(T[Dimension] values) @safe pure nothrow
    {
        this.values = values;
    }
}

/// An axis-aligned extent in a user-defined coordinate space.
struct CoordinateBounds(Space, T, size_t Dimension = spaceDimension!Space)
if (isSpace!Space && Dimension == spaceDimension!Space)
{
    alias SpaceType = Space;
    alias ValueType = T;
    enum dimension = Dimension;
    enum isCoordinateBoundsType = true;
    /// Lower endpoint in the owning space's axis order.
    T[Dimension] minimum;
    /// Upper endpoint in the owning space's axis order.
    T[Dimension] maximum;

    this(T[Dimension] minimum, T[Dimension] maximum)
        @safe pure nothrow
    {
        this.minimum = minimum;
        this.maximum = maximum;
    }
}

/// Returns whether `T` is a coordinate vector type from this package.
template isCoordinateVector(T)
{
    enum bool isCoordinateVector = __traits(compiles, {
        alias space = T.SpaceType;
        alias value = T.ValueType;
        enum dimension = T.dimension;
        enum marker = T.isCoordinateVectorType;
    }) && T.isCoordinateVectorType;
}

/// Returns whether `T` is a coordinate bounds type from this package.
template isCoordinateBounds(T)
{
    enum bool isCoordinateBounds = __traits(compiles, {
        alias space = T.SpaceType;
        alias value = T.ValueType;
        enum dimension = T.dimension;
        enum marker = T.isCoordinateBoundsType;
    }) && T.isCoordinateBoundsType;
}
