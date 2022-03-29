import { describe; it; Suite } = "mo:testing/Suite";

import Prim "mo:⛔";

import Nat "../src/Nat";

let suite = Suite();

suite.run([
    describe("Nat", [
        describe("parseNat", [
            it("0", func () : Bool {
                switch (Nat.parseNat("0")) {
                    case (#err(_)) false;
                    case (#ok(n)) n == 0;
                };
            }),
            it("-1", func () : Bool {
                switch (Nat.parseNat("-1")) {
                    case (#err(e)) e == "invalid character: -";
                    case (#ok(_))  false;
                };
            }),
            it("1_000", func () : Bool {
                switch (Nat.parseNat("1_000")) {
                    case (#err(_)) false;
                    case (#ok(n)) n == 1_000;
                };
            }),
        ])
    ])
]);
