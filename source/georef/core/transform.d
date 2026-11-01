/** Static transformation contracts and compile-time composition. */
module georef.core.transform;

import georef.core.coordinate;
import georef.core.space : isSpace, spaceDimension;
import std.math : abs;

/// Adds the metadata required for a user-defined transformation model.
/// The model still owns the actual forward/inverse mathematics.
/// Mixin that gives a user-defined transform its static metadata contract.
template transformContract(Source, Target, T, size_t Dimension)
if (isSpace!Source && isSpace!Target)
{
    alias SourceSpace = Source;
    alias TargetSpace = Target;
    alias ValueType = T;
    enum dimension = Dimension;
}

/// Applies `matrix * value + offset` between two user-defined spaces.
struct AffineTransform(Source, Target, T, size_t Dimension)
if (isSpace!Source && isSpace!Target
    && spaceDimension!Source == Dimension
    && spaceDimension!Target == Dimension)
{
    mixin transformContract!(Source, Target, T, Dimension);

    T[Dimension][Dimension] matrix;
    T[Dimension] offset;

    Coordinate!(Target, T, Dimension) forward(
        Coordinate!(Source, T, Dimension) value) const @safe pure nothrow @nogc
    {
        T[Dimension] result = offset;
        foreach (row; 0 .. Dimension)
            foreach (column; 0 .. Dimension)
                result[row] += matrix[row][column] * value.values[column];
        return Coordinate!(Target, T, Dimension)(result);
    }

    /// Returns the inverse for a non-singular affine matrix.
    bool tryInverse(out AffineTransform!(Target, Source, T, Dimension) result)
        const @safe pure nothrow
    {
        result = AffineTransform!(Target, Source, T, Dimension).init;
        T[Dimension][Dimension] augmented;
        foreach (row; 0 .. Dimension)
        {
            foreach (column; 0 .. Dimension)
                augmented[row][column] = matrix[row][column];
            augmented[row][Dimension .. $] = 0;
            augmented[row][row] = 1;
        }
        foreach (column; 0 .. Dimension)
        {
            size_t pivot = column;
            foreach (row; column + 1 .. Dimension)
                if (abs(augmented[row][column]) > abs(augmented[pivot][column]))
                    pivot = row;
            if (augmented[pivot][column] == 0) return false;
            auto temp = augmented[column];
            augmented[column] = augmented[pivot];
            augmented[pivot] = temp;
            auto scale = augmented[column][column];
            augmented[column][] /= scale;
            foreach (row; 0 .. Dimension)
                if (row != column)
                {
                    auto factor = augmented[row][column];
                    foreach (j; 0 .. Dimension * 2)
                        augmented[row][j] -= factor * augmented[column][j];
                }
        }
        foreach (row; 0 .. Dimension)
            foreach (column; 0 .. Dimension)
                result.matrix[row][column] = augmented[row][Dimension + column];
        foreach (row; 0 .. Dimension)
        {
            T value;
            foreach (column; 0 .. Dimension)
                value += result.matrix[row][column] * offset[column];
            result.offset[row] = -value;
        }
        return true;
    }
}

/// A statically validated composition of two forward transformations.
struct Pipeline(First, Second)
if (isTransform!First && isTransform!Second
    && hasForward!First && hasForward!Second
    && is(transformTarget!First == transformSource!Second))
{
    First first;
    Second second;

    auto forward(Value)(Value value) const
        @nogc
    {
        return second.forward(first.forward(value));
    }
}

/// Returns whether `T` declares the static transformation metadata contract.
template isTransform(T)
{
    enum bool isTransform = __traits(compiles, {
        alias source = T.SourceSpace;
        alias target = T.TargetSpace;
        alias value = T.ValueType;
        enum dimension = T.dimension;
    });
}

/// Public, descriptive spelling of `isTransform`.
alias isTransformation = isTransform;

template transformSource(T)
{
    static assert(isTransform!T, "Type is not a georef transformation");
    alias transformSource = T.SourceSpace;
}

/// Returns the source space of a transformation type.
alias sourceSpaceOf = transformSource;

template transformTarget(T)
{
    static assert(isTransform!T, "Type is not a georef transformation");
    alias transformTarget = T.TargetSpace;
}

/// Returns the target space of a transformation type.
alias targetSpaceOf = transformTarget;

template transformDimension(T)
{
    static assert(isTransform!T, "Type is not a georef transformation");
    enum size_t transformDimension = T.dimension;
}

/// Returns the dimension handled by a transformation type.
alias transformationSize = transformDimension;

template transformValue(T)
{
    static assert(isTransform!T, "Type is not a georef transformation");
    alias transformValue = T.ValueType;
}

/// Returns the component type handled by a transformation type.
alias transformationValueTypeOf = transformValue;

/// Returns whether `T` exposes a correctly typed `forward` operation.
template hasForward(T)
{
    enum bool hasForward = isTransform!T && __traits(compiles, {
        auto value = T.init.forward(Coordinate!(transformSource!T,
            transformValue!T, transformDimension!T).init);
        static assert(is(typeof(value) == Coordinate!(transformTarget!T,
            transformValue!T, transformDimension!T)));
    });
}

/// Returns whether a transformation provides a valid forward operation.
alias supportsForward = hasForward;

/// Returns whether `T` exposes a correctly typed `inverse` operation.
template hasInverse(T)
{
    enum bool hasInverse = isTransform!T && __traits(compiles, {
        auto value = T.init.inverse(Coordinate!(transformTarget!T,
            transformValue!T, transformDimension!T).init);
        static assert(is(typeof(value) == Coordinate!(transformSource!T,
            transformValue!T, transformDimension!T)));
    });
}

/// Returns whether a transformation provides a valid inverse operation.
alias supportsInverse = hasInverse;

/// Composes two statically compatible transformations.
auto compose(First, Second)(First first, Second second)
{
    static assert(isTransform!First && isTransform!Second,
        "compose requires transformation objects");
    static assert(hasForward!First && hasForward!Second,
        "compose requires forward transformations");
    static assert(is(transformTarget!First == transformSource!Second),
        "transform pipeline spaces do not connect");
    return Pipeline!(First, Second)(first, second);
}

/// Combines two compatible affine transforms into one transform.
/// The returned value contains the already-composed matrix and offset.
/// Pre-composes two affine steps into one matrix and offset.
auto composeAffine(Source, Middle, Target, T, size_t Dimension)(
    AffineTransform!(Source, Middle, T, Dimension) first,
    AffineTransform!(Middle, Target, T, Dimension) second)
{
    AffineTransform!(Source, Target, T, Dimension) result;
    foreach (row; 0 .. Dimension)
    {
        foreach (column; 0 .. Dimension)
            foreach (inner; 0 .. Dimension)
                result.matrix[row][column] += second.matrix[row][inner]
                    * first.matrix[inner][column];
        result.offset[row] = second.offset[row];
        foreach (inner; 0 .. Dimension)
            result.offset[row] += second.matrix[row][inner] * first.offset[inner];
    }
    return result;
}
