import { describe; it; Suite } = "mo:testing/Suite";

import Prim "mo:⛔";

import Iterator "../src/Iterator";
import Nat "../src/Nat";

let suite = Suite();

suite.run([
    describe("Array", [
        it("bit", func () : Bool {
            let n = 123456789;
            let a = [1, 1, 1, 0, 1, 0, 1, 1, 0, 1, 1, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 0, 1, 0, 1, 0, 1];
            for (i in Iterator.range(0, a.size() - 1)) {
                let b = Nat.bit(n, i);
                if (b != (a[i] != 0)) return false;
            };
            true;
        })
    ])
]);
