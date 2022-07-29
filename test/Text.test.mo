import { describe; it; Suite } = "mo:testing/Suite";

import Prim "mo:⛔";

import Compare "mo:std/Compare";
import Text "mo:std/Text";

let suite = Suite();

suite.run([
    describe("Text", [
        describe("cf", [
            it("a < b", func () : Bool {
                Compare.lt("a", "b", Text.cf);
            }),
            it("aa > b", func () : Bool {
                Compare.gt("aa", "b", Text.cf);
            }),
            it("abc > aba", func () : Bool {
                Compare.gt("abc", "aba", Text.cf);
            }),
            it("caa > aaa", func () : Bool {
                Compare.gt("caa", "aaa", Text.cf);
            }),
        ])
    ])
]);
