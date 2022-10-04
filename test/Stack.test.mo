import { describe; it; Suite } = "mo:testing/Suite";

import Prim "mo:⛔";

import Stack "mo:std/Stack";

let suite = Suite();

suite.run([
    describe("Stack", [
        it("size", func () : Bool {
            let s = Stack.init<Nat>(5);
            for (v in [0, 1, 3, 5, 10].vals()) Stack.push(s, v);
            s.size == 5;
        })
    ]),
    describe("Autofill", [
        it("get", func () : Bool {
            let s = Stack.Autofill.init<Nat>(5, [0, 1, 3, 5, 10].vals());
            if (s.size != 0) return false;
            if (Stack.Autofill.get(s, 0) != ?0) return false;
            if (s.size != 1) return false;
            if (Stack.Autofill.get(s, 4) != ?10) return false;
            if (s.size != 5) return false;
            if (Stack.Autofill.get(s, 2) != ?3) return false;
            Stack.Autofill.get(s, 5) == null;
        })
    ])
]);
