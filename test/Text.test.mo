import { describe; it; Suite } = "mo:testing/Suite";

import Prim "mo:⛔";

import { lt; gt; Text } = "mo:std/Compare";

let suite = Suite();

suite.run([
    describe("Text", [
        describe("cf", [
            it("a < b", func () : Bool {
                lt("a", "b", Text.cmp);
            }),
            it("aa > b", func () : Bool {
                gt("aa", "b", Text.cmp);
            }),
            it("abc > aba", func () : Bool {
                gt("abc", "aba", Text.cmp);
            }),
            it("caa > aaa", func () : Bool {
                gt("caa", "aaa", Text.cmp);
            }),
        ])
    ])
]);
