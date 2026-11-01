/** Compile-time descriptions for user-defined coordinate spaces. */
module georef.core.space;

/// Minimal compile-time space descriptor for callers without axis metadata.
struct SpaceDescriptor(string Id, size_t Dimension)
{
    enum id = Id;
    enum dimension = Dimension;
}

/// An axis label is metadata only. The core assigns it no semantics.
/// Describes one axis by a caller-defined label. The core does not interpret it.
struct AxisDescriptor(string Name)
{
    enum name = Name;
    enum isAxisDescriptor = true;
}

/// Compile-time space definition assembled from user-provided axis metadata.
/// Compile-time space assembled from an identifier and axis descriptors.
struct SpaceDefinition(string Id, Axes...)
if (allAxes!Axes)
{
    enum id = Id;
    enum dimension = Axes.length;
    alias axes = Axes;
}

template allAxes(Axes...)
{
    static if (Axes.length == 0)
        enum bool allAxes = true;
    else
        enum bool allAxes = __traits(compiles,
            { enum valid = Axes[0].isAxisDescriptor; })
            && Axes[0].isAxisDescriptor
            && allAxes!(Axes[1 .. $]);
}

/// Creates a compile-time space type from an identifier and axis descriptors.
template defineSpace(string Id, Axes...)
{
    alias defineSpace = SpaceDefinition!(Id, Axes);
}

/// Returns the label of axis `Index` when the space has axis metadata.
template axisName(Space, size_t Index)
if (isSpace!Space && Index < spaceDimension!Space)
{
    alias Axis = Space.axes[Index];
    enum string axisName = Axis.name;
}

/// Returns whether `T` satisfies the minimal static space contract.
template isSpace(T)
{
    enum bool isSpace = __traits(compiles, { enum x = T.dimension; })
        && __traits(compiles, { enum y = T.id; });
}

/// Public, descriptive spelling of `isSpace`.
alias isCoordinateSpace = isSpace;

/// Returns the caller-defined identifier of a static space.
template spaceId(Space)
{
    static assert(isSpace!Space, "Space must provide id and dimension");
    enum string spaceId = Space.id;
}

/// Returns the identifier of a coordinate space.
alias spaceIdentifier = spaceId;

/// Returns the number of components in a static space.
template spaceDimension(Space)
{
    static assert(isSpace!Space, "Space must provide id and dimension");
    enum size_t spaceDimension = Space.dimension;
}

/// Returns the number of axes in a coordinate space.
alias spaceSize = spaceDimension;
