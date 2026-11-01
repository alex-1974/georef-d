module georef.runtime.graph;

import georef.runtime.coordinate : DynamicCoordinate;
import georef.runtime.space : DynamicSpace;
import georef.runtime.transform : DynamicAffineTransform;
import georef.runtime.model : DynamicTransform;
import georef.runtime.result : TransformResult, TransformError, failure;

/// A selected graph path, including its exact edges and accumulated cost.
struct TransformPath
{
    string[] spaces;
    size_t[] transformIndices;
    double totalCost;
    double totalUncertainty;

    @property bool empty() const @safe pure nothrow
    {
        return spaces.length == 0;
    }
}

/// Registry and weighted directed graph for runtime spaces and transforms.
struct TransformGraph
{
    DynamicSpace[] spaces;
    DynamicTransform[] transforms;

    /// Registers a unique valid space.
    bool addSpace(DynamicSpace space)
    {
        if (!space.isValid || findSpace(space.id) !is null)
            return false;
        spaces ~= space;
        return true;
    }

    /// Registers an affine edge between already registered spaces.
    bool addTransform(DynamicAffineTransform transform)
    {
        auto source = findSpace(transform.sourceId);
        auto target = findSpace(transform.targetId);
        if (source is null || target is null
            || !transform.isValid(*source, *target))
            return false;
        transforms ~= transform.asTransform;
        return true;
    }

    /// Registers any consumer-supplied runtime transformation.
    bool addTransform(DynamicTransform transform)
    {
        auto source = findSpace(transform.sourceId);
        auto target = findSpace(transform.targetId);
        if (source is null || target is null || !transform.isValid
            || source.dimension != transform.dimension
            || target.dimension != transform.dimension)
            return false;
        transforms ~= transform;
        return true;
    }

    /// Registers both directions when an affine inverse exists.
    bool addBidirectionalTransform(DynamicAffineTransform transform)
    {
        DynamicAffineTransform inverse;
        if (!transform.tryInverse(inverse) || !addTransform(transform))
            return false;
        return addTransform(inverse);
    }

    /// Registers both directions when an inverse delegate was supplied.
    bool addBidirectionalTransform(DynamicTransform transform)
    {
        if (!transform.hasInverse || !addTransform(transform))
            return false;
        return addTransform(transform.inverse);
    }

    /// Finds and executes the lowest-cost path to `targetId`.
    TransformResult transform(DynamicCoordinate value, string targetId) const
    {
        auto source = findSpace(value.spaceId);
        auto target = findSpace(targetId);
        if (source is null || target is null)
            return failure(TransformError.invalidSpace, value.spaceId, targetId);
        if (!value.isValid(*source))
            return failure(TransformError.invalidCoordinate, value.spaceId, targetId,
                source.dimension, value.values.length);
        if (value.spaceId == targetId)
            return TransformResult(value, TransformError.none);

        auto path = findPath(value.spaceId, targetId);
        if (path.empty)
            return failure(TransformError.noPath, value.spaceId, targetId);

        return transformAlong(value, path);
    }

    /// Executes an already prepared path without running path finding.
    TransformResult transformAlong(DynamicCoordinate value,
        const ref TransformPath path) const
    {
        if (path.empty || value.spaceId != path.spaces[0])
            return failure(TransformError.invalidCoordinate, value.spaceId,
                path.empty ? "" : path.spaces[0]);
        DynamicCoordinate current = value;
        foreach (step; 1 .. path.spaces.length)
        {
            auto result = transforms[path.transformIndices[step - 1]].apply(current);
            if (!result.success) return result;
            current = result.value;
        }
        return TransformResult(current, TransformError.none);
    }

    /// Returns the shortest directed path without executing transformations.
    /// Finds the lowest-cost directed path without executing it.
    TransformPath findPath(string sourceId, string targetId) const
    {
        if (findSpace(sourceId) is null || findSpace(targetId) is null)
            return TransformPath.init;
        if (sourceId == targetId)
            return TransformPath([sourceId], [], 0.0, 0.0);

        bool[] visited = new bool[](spaces.length);
        size_t[] predecessor = new size_t[](spaces.length);
        double[] distance = new double[](spaces.length);
        double[] uncertainty = new double[](spaces.length);
        size_t[] predecessorEdge = new size_t[](spaces.length);
        distance[] = double.infinity;
        uncertainty[] = double.infinity;
        predecessor[] = size_t.max;
        predecessorEdge[] = size_t.max;
        size_t sourceIndex = indexOf(sourceId);
        size_t targetIndex = indexOf(targetId);
        distance[sourceIndex] = 0;
        uncertainty[sourceIndex] = 0;
        foreach (iteration; 0 .. spaces.length)
        {
            size_t current = size_t.max;
            double best = double.infinity;
            foreach (i; 0 .. spaces.length)
                if (!visited[i] && distance[i] < best)
                {
                    current = i;
                    best = distance[i];
                }
            if (current == size_t.max) break;
            visited[current] = true;
            foreach (edgeIndex, edge; transforms)
            {
                if (edge.sourceId != spaces[current].id) continue;
                auto next = indexOf(edge.targetId);
                if (next == size_t.max || visited[next]) continue;
                auto candidate = distance[current] + edge.cost;
                if (candidate < distance[next])
                {
                    distance[next] = candidate;
                    uncertainty[next] = uncertainty[current] + edge.uncertainty;
                    predecessor[next] = current;
                    predecessorEdge[next] = edgeIndex;
                }
            }
        }
        if (distance[targetIndex] == double.infinity) return TransformPath.init;

        string[] reversed;
        size_t[] reversedEdges;
        for (auto at = targetIndex; at != size_t.max; at = predecessor[at])
        {
            reversed ~= spaces[at].id;
            if (predecessorEdge[at] != size_t.max)
                reversedEdges ~= predecessorEdge[at];
        }
        string[] result;
        foreach_reverse (id; reversed) result ~= id;
        size_t[] edges;
        foreach_reverse (edge; reversedEdges) edges ~= edge;
        return TransformPath(result, edges, distance[targetIndex], uncertainty[targetIndex]);
    }

private:
    const(DynamicSpace)* findSpace(string id) const
    {
        foreach (ref space; spaces)
            if (space.id == id) return &space;
        return null;
    }

    size_t indexOf(string id) const
    {
        foreach (i, space; spaces)
            if (space.id == id) return i;
        return size_t.max;
    }
}
