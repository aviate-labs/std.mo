import { describe; it; itp; Suite } = "mo:testing/SuiteState";

import Prim "mo:⛔";

import Radix "../src/Tree/Radix";
import Text "../src/Text";

type State = {
    tree : Radix.Tree<Nat>;
};

let suite = Suite<State>({
    tree = Radix.new<Nat>();
});

suite.run([
    describe("Radix Tree", [
        it("insert empty text", func (s : State) : Bool {
            let v = Radix.insert<Nat>(s.tree, Text.toArray(""), 0);
            if (v != null) return false;
            Radix.toArray(s.tree) == [
                ([], 0)
            ];
        }),
        it("insert \"a\" = 0", func (s : State) : Bool {
            let v = Radix.insert<Nat>(s.tree, Text.toArray("a"), 0);
            if (v != null) return false;
            Radix.toArray(s.tree) == [
                ([], 0),
                (['a'], 0),
            ];
        }),
        it("insert \"a\" = 1", func (s : State) : Bool {
            let v = Radix.insert<Nat>(s.tree, Text.toArray("a"), 1);
            if (v != ?0) return false;
            Radix.toArray(s.tree) == [
                ([], 0),
                (['a'], 1),
            ];
        }),
        it("insert \"ab\" = 12", func (s : State) : Bool {
            let v = Radix.insert<Nat>(s.tree, Text.toArray("ab"), 12);
            if (v != null) return false;
            Radix.toArray(s.tree) == [
                ([], 0),
                (['a'], 1),
                (['a', 'b'], 12),
            ];
        }),
        it("get \"ab\"", func (s : State) : Bool {
            let v = Radix.get<Nat>(s.tree, Text.toArray("ab"));
            v == ?12;
        }),
        it("insert \"b\" = 2", func (s : State) : Bool {
            let v = Radix.insert<Nat>(s.tree, Text.toArray("b"), 2);
            if (v != null) return false;
            Radix.toArray(s.tree) == [
                ([], 0),
                (['a'], 1),
                (['a', 'b'], 12),
                (['b'], 2),
            ];
        }),
        it("insert \"_\" = 0", func (s : State) : Bool {
            let v = Radix.insert<Nat>(s.tree, Text.toArray("_"), 0);
            if (v != null) return false;
            Radix.toArray(s.tree) == [
                ([], 0),
                (['_'], 0),
                (['a'], 1),
                (['a', 'b'], 12),
                (['b'], 2),
            ];
        }),
        it("delete \"\"", func (s : State) : Bool {
            let v = Radix.delete<Nat>(s.tree, Text.toArray(""));
            if (v != ?0) return false;
            Radix.toArray(s.tree) == [
                (['_'], 0),
                (['a'], 1),
                (['a', 'b'], 12),
                (['b'], 2),
            ];
        }),
        it("delete \"a\"", func (s : State) : Bool {
            let v = Radix.delete<Nat>(s.tree, Text.toArray("a"));
            if (v != ?1) return false;
            Radix.toArray(s.tree) == [
                (['_'], 0),
                (['a', 'b'], 12),
                (['b'], 2)
            ];
        }),
        it("delete \"b\"", func (s : State) : Bool {
            let v = Radix.delete<Nat>(s.tree, Text.toArray("b"));
            if (v != ?2) return false;
            Radix.toArray(s.tree) == [
                (['_'], 0),
                (['a', 'b'], 12),
            ];
        }),
        it("insert \"a..f\" = 99", func (s : State) : Bool {
            let v = Radix.insert<Nat>(s.tree, Text.toArray("abcdef"), 99);
            if (v != null) return false;
            Radix.toArray(s.tree) == [
                (['_'], 0),
                (['a', 'b'], 12),
                (['a', 'b', 'c', 'd', 'e', 'f'], 99),
            ];
        }),
        it("to text", func (s : State) : Bool {
            let toText = func (n : Nat) : Text { debug_show(n) };
            Radix.Tree.toText(s.tree, toText) == "[size:3] [_ (_) _:0, a (a)  [b (b) ab:12 [c (cdef) abcdef:99]]]";
        }),
        it("insert \"abc\" = 99", func (s : State) : Bool {
            let v = Radix.insert<Nat>(s.tree, Text.toArray("abc"), 123);
            if (v != null) return false;
            Radix.toArray(s.tree) == [
                (['_'], 0),
                (['a', 'b'], 12),
                (['a', 'b', 'c'], 123),
                (['a', 'b', 'c', 'd', 'e', 'f'], 99),
            ];
        }),
        it("delete \"ab\"", func (s : State) : Bool {
            let v = Radix.delete<Nat>(s.tree, Text.toArray("ab"));
            if (v != ?12) return false;
            Radix.toArray(s.tree) == [
                (['_'], 0),
                (['a', 'b', 'c'], 123),
                (['a', 'b', 'c', 'd', 'e', 'f'], 99),
            ];
        }),
        it("get long key", func (_ : State) : Bool {
            let t = Radix.new<Nat>();
            ignore Radix.insert<Nat>(t, Text.toArray("abcdef"), 0);
            ignore Radix.insert<Nat>(t, Text.toArray("abc"), 1);
            ignore Radix.insert<Nat>(t, Text.toArray("abcdefghijklmnopqrstuvwxyz"), 2);
            if (Radix.get<Nat>(t, Text.toArray("abcdef")) != ?0) return false;
            if (Radix.get<Nat>(t, Text.toArray("abc")) != ?1) return false;
            Radix.get<Nat>(t, Text.toArray("abcdefghijklmnopqrstuvwxyz")) == ?2;
        })
    ])
]);
