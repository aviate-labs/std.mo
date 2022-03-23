import { describe; it; itp; Suite } = "mo:testing/Suite";

import Prim "mo:⛔";

import AST "../../src/regex/AST";
import Parser "../../src/regex/Parser";

let suite = Suite();

func span(s : Nat, e : Nat) : AST.Span {
    let start = AST.Position.new(s, 1, s + 1);
    let end   = AST.Position.new(e, 1, e + 1);
    AST.Span.new(start, end);
};

func checkFlags(r : Parser.Result<AST.Flags>, s : AST.Span, items : [AST.FlagsItem]) : Bool {
    switch (r) {
        case (#err(_)) false;
        case (#ok(flags)) {
            if (flags.span.start.offset != s.start.offset or flags.span.end.offset != s.end.offset) return false;
            if (flags.items.size() != items.size()) return false;
            var k = 0;
            for (i in items.vals()) {
                if (flags.items[k].kind != items[k].kind) return false;
                if (AST.Span.cf(flags.items[k].span, items[k].span) != 0) return false;
                k += 1;
            };
            true;
        };
    };
};

func checkFlagsErr(r : Parser.Result<AST.Flags>, s : AST.Span, kind : AST.ErrorKind) : Bool {
    switch (r) {
        case (#ok(_)) false;
        case (#err(e)) {
            if (AST.Span.cf(e.span, s) != 0) return false;
            AST.ErrorKind.cf(e.kind, kind) == 0;
        };
    };
};

suite.run([
    describe("Parser", [
        describe("Flags", [
            it("i:", func () : Bool {
                let p = Parser.Parser("i:");
                checkFlags(p.parseFlags(), span(0, 1), [
                    { span = span(0, 1); kind = #Flag(#CaseInsensitive) },
                ]);
            }),
            it("i)", func () : Bool {
                let p = Parser.Parser("i)");
                checkFlags(p.parseFlags(), span(0, 1), [
                    { span = span(0, 1); kind = #Flag(#CaseInsensitive) },
                ]);
            }),
            it("isU:", func () : Bool {
                let p = Parser.Parser("isU:");
                checkFlags(p.parseFlags(), span(0, 3), [
                    { span = span(0, 1); kind = #Flag(#CaseInsensitive) },
                    { span = span(1, 2); kind = #Flag(#DotMatchesNewLine) },
                    { span = span(2, 3); kind = #Flag(#SwapGreed) },
                ]);
            }),
            it("-isU:", func () : Bool {
                let p = Parser.Parser("-isU:");
                checkFlags(p.parseFlags(), span(0, 4), [
                    { span = span(0, 1); kind = #Negation },
                    { span = span(1, 2); kind = #Flag(#CaseInsensitive) },
                    { span = span(2, 3); kind = #Flag(#DotMatchesNewLine) },
                    { span = span(3, 4); kind = #Flag(#SwapGreed) },
                ]);
            }),
            it("i-sU:", func () : Bool {
                let p = Parser.Parser("i-sU:");
                checkFlags(p.parseFlags(), span(0, 4), [
                    { span = span(0, 1); kind = #Flag(#CaseInsensitive) },
                    { span = span(1, 2); kind = #Negation },
                    { span = span(2, 3); kind = #Flag(#DotMatchesNewLine) },
                    { span = span(3, 4); kind = #Flag(#SwapGreed) },
                ]);
            }),

            it("isU", func () : Bool {
                let p = Parser.Parser("isU");
                checkFlagsErr(
                    p.parseFlags(),
                    span(3, 3),
                    #FlagUnexpectedEOF
                );
            }),
            it("isUi:", func () : Bool {
                let p = Parser.Parser("isUi:");
                checkFlagsErr(
                    p.parseFlags(),
                    span(3, 4),
                    #FlagDuplicate({ original = span(0, 1) })
                );
            }),
            it("i-sU-i:", func () : Bool {
                let p = Parser.Parser("i-sU-i:");
                checkFlagsErr(
                    p.parseFlags(),
                    span(4, 5),
                    #FlagRepeatedNegation({ original = span(1, 2) })
                );
            }),
            it("-)", func () : Bool {
                let p = Parser.Parser("-)");
                checkFlagsErr(p.parseFlags(), span(0, 1), #FlagDanglingNegation);
            }),
        ])
    ])
]);
