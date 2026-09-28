Xdelta3 3.2.0 is the Apache-2.0 VCDIFF codec used for .mcprof patches.

Upstream: https://github.com/jmacd/xdelta/releases/tag/v3.2.0
Linux x86-64 release archive SHA-256: ef65aafaa6daaf1f04ebe0028609f4eddf470cc1f7588fcf8298b65e1cfd5fd8
Windows x86-64 release archive SHA-256: 8aca331c3d49ec4465ee8f3f7e3afb92e06d36e32fdec422c3252aaa813a7d2a
Source archive SHA-256: 628cfa920fb5cf9f0c61b2c91a036b713fc08c7858fc53f1cc87e0921d74ffa1
Extracted Linux executable SHA-256: 0d38d86de5ab6bbc1adae531331d64585b5a09ce3604a5f090c27f71b6a64b23
Extracted Windows executable SHA-256: 6e812b38484d0c764291779fadee83ffbe2eceaccb4e3a21f8a043a02654a01e

LICENSE is copied from the matching upstream source archive. The bundled CLI
reports version 3.2.0 and Apache License 2.0. It is run with armor, app-header,
and external compression disabled so patch members are bare VCDIFF streams.

The [v3.2.0 release workflow](https://github.com/jmacd/xdelta/blob/v3.2.0/.github/workflows/release.yml)
builds the distributed CLI with `XD3_LZMA_FETCH=ON` and default armor support.
Its [CMake pins](https://github.com/jmacd/xdelta/blob/v3.2.0/xdelta3/CMakeLists.txt)
statically link [XZ Utils liblzma v5.8.3](https://github.com/tukaani-project/xz/tree/v5.8.3)
and [BLAKE3 1.8.5](https://github.com/BLAKE3-team/BLAKE3/tree/1.8.5).
XZ's [upstream COPYING](https://github.com/tukaani-project/xz/blob/v5.8.3/COPYING)
identifies liblzma as 0BSD; its [0BSD text](../../docs/third-party/xz-liblzma-0BSD.txt)
is retained. BLAKE3 offers CC0-1.0 or Apache-2.0 alternatives; MC records
the [CC0 text](../../docs/third-party/blake3-CC0.txt). Disabling armor when
invoking xdelta3 does not remove statically linked BLAKE3 from the executable.
