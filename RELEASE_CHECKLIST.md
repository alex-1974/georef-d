# v0.1.0 release checklist

## Scope

- [x] Domain-neutral static coordinate spaces and coordinates
- [x] User-defined static transformation contract
- [x] Affine transforms and compile-time composition
- [x] Dynamic spaces, coordinates and transformations
- [x] Weighted runtime graph and prepared paths
- [x] Explicit runtime errors and diagnostics
- [x] Neutral vectors and bounds
- [x] DDox generated successfully with `dub build --build=ddox`
- [x] Static, runtime and custom-transform examples compile and run
- [x] GitHub Pages workflow uses the verified DUB/DDox build path

## Deliberate non-goals

- [x] No built-in GIS or CRS semantics
- [x] No EPSG catalogue or projection implementation
- [x] No raster warping or geometry algorithms
- [x] No mandatory dependency on geodesy, imagery, OSM or PROJ libraries

## Verification

```sh
dub test --compiler=dmd --force
dub test --compiler=ldc2 --force
(cd tests/consumer && dub run --compiler=dmd --force)
(cd benchmarks && dub run --compiler=ldc2 --build=release --force)
```

The benchmark output is evidence for a build/environment, not a compatibility
guarantee. Record compiler, version, CPU and build mode with published results.
