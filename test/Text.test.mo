import { describe; it; Suite } = "mo:testing/Suite";

import Prim "mo:⛔";

import { contains; startsWith } = "mo:std/Text";
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
        ]),
        describe("contains", [
            it("b in abc", func () : Bool {
                if (not contains("abc", "")) return false;
                contains("abc", "b");
            }),
            it("abc in abc", func () : Bool {
                contains("abc", "abc");
            })
        ]),
        describe("startsWith", [
            it("abc sw a", func () : Bool {
                if (not startsWith("abc", "")) return false;
                startsWith("abc", "a");
            }),
            it("abc sw abc", func () : Bool {
                if (startsWith("abc", "abcd")) return false;
                startsWith("abc", "abc");
            }),
        ])
    ])
]);
