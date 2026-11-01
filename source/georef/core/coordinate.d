/** Coordinates carrying their coordinate-space type at compile time. */
module georef.core.coordinate;

import georef.core.space : isSpace, spaceDimension;

/// A fixed-size coordinate whose `Space` and `Dimension` are part of its type.
///
/// A user creates a space by declaring a type with `id` and `dimension` enum
/// members, then uses that type as the first template argument. Coordinates
/// from different spaces cannot be passed to one another accidentally.
struct Coordinate(Space, T, size_t Dimension = spaceDimension!Space)
if (isSpace!Space && Dimension == spaceDimension!Space)
{
    alias SpaceType = Space;
    alias ValueType = T;
    enum dimension = Dimension;
    /// Coordinate components in the user-defined axis order.
    T[Dimension] values;

    this(T[Dimension] values) @safe pure nothrow
    {
        this.values = values;
    }
}

/// Returns whether `T` has the static coordinate contract.
template isCoordinate(T)
{
    enum bool isCoordinate = __traits(compiles, {
        alias space = T.SpaceType;
        alias value = T.ValueType;
        enum dimension = T.dimension;
    });
}

/// Public, descriptive spelling of `isCoordinate`.
alias isTypedCoordinate = isCoordinate;

/// Returns the compile-time space type carried by coordinate type `C`.
template coordinateSpace(C)
{
    alias coordinateSpace = C.SpaceType;
}

/// Returns the space type carried by a coordinate type.
alias coordinateSpaceOf = coordinateSpace;

/// Returns the numeric component type carried by coordinate type `C`.
template coordinateValue(C)
{
    alias coordinateValue = C.ValueType;
}

/// Returns the component type carried by a coordinate type.
alias coordinateValueTypeOf = coordinateValue;

/// Returns the number of components carried by coordinate type `C`.
template coordinateDimension(C)
{
    enum size_t coordinateDimension = C.dimension;
}

/// Returns the number of components in a coordinate type.
alias coordinateSize = coordinateDimension;
