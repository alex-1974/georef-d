module georef.runtime.space;

/// Runtime counterpart of a user-defined coordinate space.
/// Axis names remain descriptive metadata; the core does not interpret them.
/// A coordinate space described at runtime, for example from a file.
struct DynamicSpace
{
    /// Stable caller-defined identifier.
    string id;
    /// Axis labels in the coordinate value order. Labels have no core semantics.
    string[] axisNames;

    /// Number of coordinate components.
    @property size_t dimension() const @safe pure nothrow @nogc
    {
        return axisNames.length;
    }

    /// Returns whether the descriptor has an identifier and at least one axis.
    bool isValid() const @safe pure nothrow @nogc
    {
        return id.length != 0 && axisNames.length != 0;
    }
}
