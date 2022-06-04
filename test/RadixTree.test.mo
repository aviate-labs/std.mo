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
        it("delete \"ab\"", func (s : State) : Bool {
            let v = Radix.delete<Nat>(s.tree, Text.toArray("ab"));
            if (v != ?12) return false;
            Radix.toArray(s.tree) == [
                (['_'], 0),
            ];
        }),
    ])
]);
