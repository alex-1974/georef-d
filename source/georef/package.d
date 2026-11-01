/**
 * Generic coordinate-space and reference-transformation infrastructure.
 *
 * The public API is intentionally minimal while the architecture is being
 * researched. Coordinate spaces are not restricted to geographic systems.
 */
module georef;

public import georef.core.coordinate;
public import georef.core.space;
public import georef.core.transform;
public import georef.core.geometry;
public import georef.runtime.coordinate;
public import georef.runtime.space;
public import georef.runtime.transform;
public import georef.runtime.result;
public import georef.runtime.model;
public import georef.runtime.graph;

