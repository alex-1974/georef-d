# georef-d

Generic coordinate-space and reference-transformation infrastructure for D.

`georef-d` is intended to connect arbitrary coordinate spaces: pixels, raster
indices, local metric frames, geographic and projected CRS, game worlds,
scientific frames, screen coordinates and time-aware spaces. Users should be
able to define their own spaces and transformations while the library provides
strongly typed compile-time APIs and a dynamic runtime representation.

## Initial direction

- coordinate spaces, axes, dimensions and units;
- typed and dynamic coordinates;
- explicit transformations and transformation pipelines;
- affine raster/image transforms;
- validation, invertibility and uncertainty metadata;
- adapters for `geo-d`, `geodesy-d`, `proj-d`, `raster-d`, `imagery-d` and
  `osm-d` without coupling the core to those libraries.

The project is currently in architecture and research phase. No public API is
frozen yet.

## Development

```sh
dub test
```

## Design principle

Compile-time when a coordinate space is known; runtime when it comes from
external metadata or user configuration.

