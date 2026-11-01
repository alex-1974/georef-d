# Changelog

## 0.1.0 - unreleased

First framework release candidate.

### Added

- user-defined compile-time coordinate spaces and typed coordinates;
- compile-time axis metadata and validation;
- affine transforms, custom transform contracts and pipelines;
- CTFE affine composition and allocation-free affine execution;
- dynamic spaces, coordinates and consumer-defined transforms;
- weighted runtime transform graph with prepared paths;
- inverse affine and custom inverse edges;
- explicit runtime errors and diagnostic context;
- neutral coordinate vectors and bounds;
- external consumer smoke test and benchmark harness.

### Scope

This release intentionally contains no built-in GIS, CRS, geodesy, raster,
imagery or OSM semantics. Those belong in later optional modules or consumers.
