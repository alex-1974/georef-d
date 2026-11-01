module georef.runtime.transform;

import georef.runtime.coordinate : DynamicCoordinate;
import georef.runtime.space : DynamicSpace;
import georef.runtime.result : TransformResult, TransformError, failure;
import georef.runtime.model : DynamicTransform;
import std.math : abs;

/// Runtime affine transform. Matrix rows are stored consecutively.
/// Runtime affine transformation convenience type.
struct DynamicAffineTransform
{
    DynamicTransform asTransform() const
    {
        auto copy = this;
        return DynamicTransform(sourceId, targetId, dimension, cost,
            (const ref DynamicCoordinate value) => copy.apply(value), null,
            uncertainty);
    }
    string sourceId;
    string targetId;
    size_t dimension;
    double[] matrix;
    double[] offset;
    /// Lower values are preferred by the graph. The default is one edge.
    double cost = 1.0;
    /// Consumer-defined uncertainty or quality score; zero means unspecified.
    double uncertainty;

    /// Checks matrix shape, endpoint identifiers and cost.
    bool isValid() const @safe pure nothrow @nogc
    {
        return sourceId.length != 0 && targetId.length != 0
            && dimension != 0
            && matrix.length == dimension * dimension
            && offset.length == dimension && cost >= 0;
    }

    /// Checks this transform against two registered runtime spaces.
    bool isValid(const ref DynamicSpace source,
        const ref DynamicSpace target) const @safe pure nothrow @nogc
    {
        return isValid && source.id == sourceId && target.id == targetId
            && source.dimension == dimension && target.dimension == dimension;
    }

    /// Applies the affine operation, returning an init coordinate on mismatch.
    /// Prefer `apply` when the caller needs explicit error information.
    DynamicCoordinate forward(const ref DynamicCoordinate value) const
    {
        DynamicCoordinate result;
        result.spaceId = targetId;
        result.values = offset.dup;
        if (value.spaceId != sourceId || value.values.length != dimension)
            return DynamicCoordinate.init;

        foreach (row; 0 .. dimension)
            foreach (column; 0 .. dimension)
                result.values[row] += matrix[row * dimension + column]
                    * value.values[column];
        return result;
    }

    /// Applies the transform into caller-owned storage without allocating.
    bool applyInto(scope double[] destination, scope const double[] source)
        const @safe pure nothrow @nogc
    {
        if (!isValid || destination.length != dimension
            || source.length != dimension)
            return false;
        destination[] = offset;
        foreach (row; 0 .. dimension)
            foreach (column; 0 .. dimension)
                destination[row] += matrix[row * dimension + column]
                    * source[column];
        return true;
    }

    /// Applies the transform with explicit validation and error information.
    TransformResult apply(const ref DynamicCoordinate value) const
    {
        if (!isValid)
            return failure(TransformError.invalidTransform, sourceId, targetId,
                dimension, value.values.length);
        if (value.spaceId != sourceId || value.values.length != dimension)
            return failure(TransformError.invalidCoordinate, sourceId, targetId,
                dimension, value.values.length);
        return TransformResult(forward(value), TransformError.none);
    }

    /// Builds an inverse affine edge when the matrix is non-singular.
    bool tryInverse(out DynamicAffineTransform inverse) const
    {
        inverse = DynamicAffineTransform.init;
        if (!isValid) return false;
        double[] a = matrix.dup;
        double[] inv = new double[](dimension * dimension);
        foreach (i; 0 .. dimension) inv[i * dimension + i] = 1;
        foreach (column; 0 .. dimension)
        {
            size_t pivot = column;
            foreach (row; column + 1 .. dimension)
                if (abs(a[row * dimension + column]) > abs(a[pivot * dimension + column]))
                    pivot = row;
            if (a[pivot * dimension + column] == 0) return false;
            foreach (j; 0 .. dimension)
            {
                auto t = a[column * dimension + j];
                a[column * dimension + j] = a[pivot * dimension + j];
                a[pivot * dimension + j] = t;
                t = inv[column * dimension + j];
                inv[column * dimension + j] = inv[pivot * dimension + j];
                inv[pivot * dimension + j] = t;
            }
            auto scale = a[column * dimension + column];
            foreach (j; 0 .. dimension)
            {
                a[column * dimension + j] /= scale;
                inv[column * dimension + j] /= scale;
            }
            foreach (row; 0 .. dimension)
                if (row != column)
                {
                    auto factor = a[row * dimension + column];
                    foreach (j; 0 .. dimension)
                    {
                        a[row * dimension + j] -= factor * a[column * dimension + j];
                        inv[row * dimension + j] -= factor * inv[column * dimension + j];
                    }
                }
        }
        inverse.sourceId = targetId;
        inverse.targetId = sourceId;
        inverse.dimension = dimension;
        inverse.matrix = inv;
        inverse.offset.length = dimension;
        inverse.cost = cost;
        inverse.uncertainty = uncertainty;
        foreach (row; 0 .. dimension)
            foreach (column; 0 .. dimension)
                inverse.offset[row] -= inv[row * dimension + column] * offset[column];
        return true;
    }
}
