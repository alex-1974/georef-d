module georef.runtime.result;

import georef.runtime.coordinate : DynamicCoordinate;

/// Stable categories returned by runtime transformation operations.
enum TransformError
{
    none,
    invalidSpace,
    invalidCoordinate,
    noPath,
    invalidTransform
}

/// Diagnostic context accompanying a failed runtime operation.
struct TransformErrorInfo
{
    TransformError code;
    string sourceId;
    string targetId;
    size_t expectedDimension;
    size_t actualDimension;
}

/// Either a transformed coordinate or an explicit runtime failure.
struct TransformResult
{
    DynamicCoordinate value;
    TransformError error;
    TransformErrorInfo info;

    @property bool success() const @safe pure nothrow
    {
        return error == TransformError.none;
    }
}

/// Creates a failed result with optional diagnostic context.
TransformResult failure(TransformError code, string sourceId = "",
    string targetId = "", size_t expectedDimension = 0,
    size_t actualDimension = 0)
{
    return TransformResult(DynamicCoordinate.init, code,
        TransformErrorInfo(code, sourceId, targetId,
            expectedDimension, actualDimension));
}
