import { describe; it; Suite } = "mo:testing/Suite";

import Prim "mo:⛔";

import Nat "mo:std/Nat";
import Sort "mo:std/Sort";

let suite = Suite();

suite.run([
    describe("Sort", [
        it("insert", func () : Bool {
            var a : [Nat] = [];
            a := Sort.insert<Nat>(a, 1, Nat.cf);
            if (a != [1]) return false;
            a := Sort.insert<Nat>(a, 5, Nat.cf);
            if (a != [1, 5]) return false;
            a := Sort.insert<Nat>(a, 1, Nat.cf);
            if (a != [1, 1, 5]) return false;
            a := Sort.insert<Nat>(a, 2, Nat.cf);
            if (a != [1, 1, 2, 5]) return false;
            a := Sort.insert<Nat>(a, 9, Nat.cf);
            a == [1, 1, 2, 5, 9]
        }),
    ])
]);
