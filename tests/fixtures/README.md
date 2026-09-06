# Version 1 state fixture

`state-v1.db` was created by the NativeAOT `OperationStore` at commit `0a003310badf7ceb8e5541b922adfff49c6ab0d9`, through its `Begin` and `Advance` methods. The store closed normally before the database was copied.

It contains one completed synthetic runtime check at revision 1. `state-v1.json` records its identity, SQLite version, producer, and SHA-256 hash. It contains no game files, paths, credentials, or user settings. Tests copy it into an owned directory before migration; they never modify this input fixture.
