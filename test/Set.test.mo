import { describe; it; Suite } = "mo:testing/SuiteState";

import Prim "mo:⛔";

import Map "../src/Map";
import Set "../src/Set";
import Iterator "../src/Iterator";

type State = {
    set : Set.Set<Nat>;
};

let keyType : Map.KeyType<Nat> = {
    hash = func (k : Nat, mod : Nat) : Nat { k % mod };
    eq   = func (x : Nat, y : Nat) : Bool { x == y };
};

let suite = Suite<State>({
    set = Set.empty<Nat>(keyType);
});

suite.run([
    describe("Set", [
        it("size 0", func (s : State) : Bool {
            Set.size(s.set) == 0;
        }),
        it("delete 1", func (s : State) : Bool {
            not Set.delete(s.set, 1);
        }),
        it("add 1", func (s : State) : Bool {
            Set.add(s.set, 1);
            Set.size(s.set) == 1;
        }),
        it("has 1", func (s : State) : Bool {
            Set.has(s.set, 1);
        }),
        it("delete 1", func (s : State) : Bool {
            Set.delete(s.set, 1);
        }),
        it("size 0", func (s : State) : Bool {
            Set.size(s.set) == 0;
        }),
        it("rescale", func (s : State) : Bool {
            for (k in Iterator.range(0, 99)) {
                Set.add(s.set, k);
            };
            var i = 0;
            for (v in Set.values(s.set)) {
                if (v != i) return false;
                i += 1;
            };
            if (Set.size(s.set) != 100) return false;
            // 16 -> 32 -> 64 -> 128
            s.set.buckets.size() == 128;
        })
    ])
]);
