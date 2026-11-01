module georef.runtime.model;

import georef.runtime.coordinate : DynamicCoordinate;
import georef.runtime.result : TransformResult, TransformError, failure;

alias ForwardFunction = TransformResult delegate(
    const ref DynamicCoordinate value);
alias InverseFunction = TransformResult delegate(
    const ref DynamicCoordinate value);

/// General runtime transformation contract.
/// General runtime transformation supplied by the consumer.
///
/// The delegate contains all domain mathematics. The framework only checks
/// its declared endpoint identifiers and dimension before invocation.
struct DynamicTransform
{
    string sourceId;
    string targetId;
    size_t dimension;
    double cost = 1.0;
    ForwardFunction forwardFunction;
    InverseFunction inverseFunction;
    /// Consumer-defined uncertainty or quality score; zero means unspecified.
    double uncertainty;

    /// Returns whether the endpoint metadata and forward delegate are usable.
    bool isValid() const @safe pure nothrow
    {
        return sourceId.length != 0 && targetId.length != 0
            && dimension != 0 && cost >= 0 && forwardFunction !is null;
    }

    /// Applies the transform and returns an explicit success or failure.
    TransformResult apply(const ref DynamicCoordinate value) const
    {
        if (!isValid)
            return failure(TransformError.invalidTransform, sourceId, targetId,
                dimension, value.values.length);
        if (value.spaceId != sourceId || value.values.length != dimension)
            return failure(TransformError.invalidCoordinate, sourceId, targetId,
                dimension, value.values.length);
        return forwardFunction(value);
    }

    /// Returns whether an inverse delegate was supplied.
    bool hasInverse() const @safe pure nothrow
    {
        return inverseFunction !is null;
    }

    /// Creates the reverse edge from the supplied forward/inverse delegates.
    DynamicTransform inverse() const
    {
        return DynamicTransform(targetId, sourceId, dimension, cost,
            inverseFunction, forwardFunction, uncertainty);
    }
}
