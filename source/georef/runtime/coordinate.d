module georef.runtime.coordinate;

import georef.runtime.space : DynamicSpace;

/// A coordinate whose space is identified at runtime.
struct DynamicCoordinate
{
    /// Identifier of the `DynamicSpace` that owns `values`.
    string spaceId;
    /// Values in the owning space's axis order.
    double[] values;

    /// Checks space identity and component count against `space`.
    bool isValid(const ref DynamicSpace space) const @safe pure nothrow
    {
        return space.isValid && space.id == spaceId
            && values.length == space.dimension;
    }
}
