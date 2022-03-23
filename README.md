# An (Experimental) Motoko Library

[DOCS](./docs)

```motoko
import Array "mo:std/Array";

let cf = func (x : Nat, y : Nat) : Int { x - y };
assert(Array.sort([4, 2, 5, 1, 3], cf) == [1, 2, 3, 4, 5]);
```

## Table of Contents

- [Array](./docs/Array.md)
- [Map](./docs/Map.md)
- [Set](./docs/Set.md)
