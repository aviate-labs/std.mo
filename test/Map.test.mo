import { describe; it; Suite } = "mo:testing/SuiteState";

import Prim "mo:⛔";

import Map "../src/Map";
import Iterator "../src/Iterator";

type State = {
    map : Map.Map<Nat, Text>;
};

let keyType : Map.KeyType<Nat> = {
    hash = func (k : Nat, mod : Nat) : Nat { k % mod };
    eq   = func (x : Nat, y : Nat) : Bool { x == y };
};

let suite = Suite<State>({
    map = Map.empty<Nat, Text>(keyType);
});

suite.run([
    describe("Map", [
        it("size 0", func (s : State) : Bool {
            Map.size(s.map) == 0;
        }),
        it("delete 1", func (s : State) : Bool {
            let v = Map.delete(s.map, 1);
            v == null;
        }),
        it("add {1:\"a\"}", func (s : State) : Bool {
            let v = Map.set(s.map, 1, "a");
            if (Map.size(s.map) != 1) return false;
            v == null;
        }),
        it("get 1 (a)", func (s : State) : Bool {
            Map.get(s.map, 1) == ?"a";
        }),
        it("set 1 to \"b\"", func (s : State) : Bool {
            let v = Map.set(s.map, 1, "b");
            if (Map.size(s.map) != 1) return false;
            v == ?"a";
        }),
        it("get 1 (b)", func (s : State) : Bool {
            Map.get(s.map, 1) == ?"b";
        }),
        it("delete 1", func (s : State) : Bool {
            Map.delete(s.map, 1) == ?"b";
        }),
        it("size 0", func (s : State) : Bool {
            Map.size(s.map) == 0;
        }),
        it("rescale", func (s : State) : Bool {
            for (k in Iterator.range(0, 99)) {
                let v = Map.set(s.map, k, debug_show(k));
                if (v != null) return false;
            };
            for ((k, v) in Map.entries(s.map)) {
                if (v != debug_show(k)) return false;
            };
            if (Map.size(s.map) != 100) return false;
            // 16 -> 32 -> 64 -> 128
            s.map.buckets.size() == 128;
        })
    ])
]);
