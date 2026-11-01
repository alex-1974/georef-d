# georef-d benchmarks

The benchmark harness compares a static pipeline, a CTFE-composed affine
transform, a runtime direct edge and a runtime graph path.
Record compiler, compiler version, build mode, CPU and dimension for every
result. The harness is deliberately outside the public package API.
