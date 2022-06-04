import { describe; it; Suite } = "mo:testing/Suite";

import Prim "mo:⛔";

import Sort "../src/Sort";

let suite = Suite();

suite.run([
    describe("Sort", [
        it("insert", func () : Bool {
            var a : [Nat] = [];
            a := Sort.insert<Nat>(a, 1, func (x : Nat, y : Nat) : Int { x - y });
            if (a != [1]) return false;
            a := Sort.insert<Nat>(a, 5, func (x : Nat, y : Nat) : Int { x - y });
            if (a != [1, 5]) return false;
            a := Sort.insert<Nat>(a, 1, func (x : Nat, y : Nat) : Int { x - y });
            if (a != [1, 1, 5]) return false;
            a := Sort.insert<Nat>(a, 2, func (x : Nat, y : Nat) : Int { x - y });
            if (a != [1, 1, 2, 5]) return false;
            a := Sort.insert<Nat>(a, 9, func (x : Nat, y : Nat) : Int { x - y });
            a == [1, 1, 2, 5, 9]
        }),
    ])
]);
