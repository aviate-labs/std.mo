import { describe; it; Suite } = "mo:testing/Suite";

import Prim "mo:⛔";

import AST "../../src/regex/AST";
import Parser "../../src/regex/Parser";

let suite = Suite();

func span(s : Nat, e : Nat) : AST.Span {
    let start = AST.Position.new(s, 1, s + 1);
    let end   = AST.Position.new(e, 1, e + 1);
    AST.Span.new(start, end);
};

func checkFlags(r : Parser.Result<AST.Flags>, expected : AST.Flags) : Bool {
    switch (r) {
        case (#err(_)) false;
        case (#ok(flags)) AST.Flags.cf(flags, expected) == 0;
    };
};

func checkFlagsErr(r : Parser.Result<AST.Flags>, err : AST.Error) : Bool {
    switch (r) {
        case (#ok(_))  false;
        case (#err(e)) AST.Error.cf(e, err) == 0;
    };
};

func checkSetFlags(r : Parser.Result<Parser.Either<AST.SetFlags, AST.Group>>, flags : AST.SetFlags) : Bool {
    switch (r) {
        case (#err(_)) false;
        case (#ok(e)) {
            switch (e) {
                case (#right(_)) false;
                case (#left(sf)) AST.SetFlags.cf(sf, flags) == 0;
            };
        };
    };
};

func checkCaptureName(r : Parser.Result<AST.CaptureName>, cn : AST.CaptureName) : Bool {
    switch (r) {
        case (#err(_)) false;
        case (#ok(n))  AST.CaptureName.cf(n, cn) == 0;
    };
};

func checkCaptureNameErr(r : Parser.Result<AST.CaptureName>, err : AST.Error) : Bool {
    switch (r) {
        case (#ok(_))  false;
        case (#err(e)) AST.Error.cf(e, err) == 0;
    };
};

func checkGroup(r : Parser.Result<Parser.Either<AST.SetFlags, AST.Group>>, group : AST.Group) : Bool {
    switch (r) {
        case (#err(_)) false;
        case (#ok(e)) {
            switch (e) {
                case (#left(_))  false;
                case (#right(g)) {
                    AST.Group.cf(g, group) == 0;
                }
            };
        };
    };
};

func checkAST(r : Parser.Result<AST.AST>, ast : AST.AST) : Bool {
    switch (r) {
        case (#err(_)) false;
        case (#ok(e))  AST.AST.cf(e, ast) == 0;
    };
};

func checkASTErr(r : Parser.Result<AST.AST>, err : AST.Error) : Bool {
    switch (r) {
        case (#ok(_))  false;
        case (#err(e)) AST.Error.cf(e, err) == 0;
    };
};

suite.run([
    describe("Parser", [
        describe("Flags", [
            it("i)", func () : Bool {
                let p = Parser.Parser("i)");
                checkFlags(p.parseFlags(), AST.Flags.new(span(0, 1), [
                    { span = span(0, 1); kind = #Flag(#CaseInsensitive) },
                ]));
            }),
            it("isU:", func () : Bool {
                let p = Parser.Parser("isU:");
                checkFlags(p.parseFlags(), AST.Flags.new(span(0, 3), [
                    { span = span(0, 1); kind = #Flag(#CaseInsensitive) },
                    { span = span(1, 2); kind = #Flag(#DotMatchesNewLine) },
                    { span = span(2, 3); kind = #Flag(#SwapGreed) },
                ]));
            }),
            it("-isU:", func () : Bool {
                let p = Parser.Parser("-isU:");
                checkFlags(p.parseFlags(), AST.Flags.new(span(0, 4), [
                    { span = span(0, 1); kind = #Negation },
                    { span = span(1, 2); kind = #Flag(#CaseInsensitive) },
                    { span = span(2, 3); kind = #Flag(#DotMatchesNewLine) },
                    { span = span(3, 4); kind = #Flag(#SwapGreed) },
                ]));
            }),
            it("i-sU:", func () : Bool {
                let p = Parser.Parser("i-sU:");
                checkFlags(p.parseFlags(), AST.Flags.new(span(0, 4), [
                    { span = span(0, 1); kind = #Flag(#CaseInsensitive) },
                    { span = span(1, 2); kind = #Negation },
                    { span = span(2, 3); kind = #Flag(#DotMatchesNewLine) },
                    { span = span(3, 4); kind = #Flag(#SwapGreed) },
                ]));
            }),

            it("isU", func () : Bool {
                let p = Parser.Parser("isU");
                checkFlagsErr(
                    p.parseFlags(),
                    AST.Error.new(#FlagUnexpectedEOF, span(3, 3))
                );
            }),
            it("isUi:", func () : Bool {
                let p = Parser.Parser("isUi:");
                checkFlagsErr(
                    p.parseFlags(),
                    AST.Error.new(#FlagDuplicate({ original = span(0, 1) }), span(3, 4))
                );
            }),
            it("i-sU-i:", func () : Bool {
                let p = Parser.Parser("i-sU-i:");
                checkFlagsErr(
                    p.parseFlags(),
                    AST.Error.new(#FlagRepeatedNegation({ original = span(1, 2) }), span(4, 5))
                );
            }),
            it("-)", func () : Bool {
                let p = Parser.Parser("-)");
                checkFlagsErr(p.parseFlags(), AST.Error.new(#FlagDanglingNegation, span(0, 1)));
            })
        ]),
        describe("CaptureName", [
            it("abc>", func () : Bool {
                let p = Parser.Parser("abc>");
                checkCaptureName(
                    p.parseCaptureName(1),
                    AST.CaptureName.new(span(0, 3), "abc", 1)
                );
            }),
            it("a_1", func () : Bool {
                let p = Parser.Parser("a_1>");
                checkCaptureName(
                    p.parseCaptureName(1),
                    AST.CaptureName.new(span(0, 3), "a_1", 1)
                );
            }),
            it("a.1>", func () : Bool {
                let p = Parser.Parser("a.1>");
                checkCaptureName(
                    p.parseCaptureName(1),
                    AST.CaptureName.new(span(0, 3), "a.1", 1)
                );
            }),
            it("a[1]>", func () : Bool {
                let p = Parser.Parser("a[1]>");
                checkCaptureName(
                    p.parseCaptureName(1),
                    AST.CaptureName.new(span(0, 4), "a[1]", 1)
                );
            }),

            it("", func () : Bool {
                let p = Parser.Parser("");
                checkCaptureNameErr(p.parseCaptureName(1), AST.Error.new(#GroupNameUnexpectedEOF, span(0, 0)));
            }),
            it(">", func () : Bool {
                let p = Parser.Parser(">");
                checkCaptureNameErr(p.parseCaptureName(1), AST.Error.new(#GroupNameEmpty, span(0, 0)));
            }),
            it("0a>", func () : Bool {
                let p = Parser.Parser("0a>");
                checkCaptureNameErr(p.parseCaptureName(1), AST.Error.new(#GroupNameInvalid, span(0, 1)));
            }),
            it("a>a>", func () : Bool {
                let p = Parser.Parser("a>a>");
                ignore p.parseCaptureName(1);
                checkCaptureNameErr(p.parseCaptureName(1), AST.Error.new(#GroupNameDuplicate, span(2, 3)));
            })
        ]),
        describe("Group", [
            it("(?iU)", func () : Bool {
                let p = Parser.Parser("(?i-U)");
                checkSetFlags(
                    p.parseGroup(),
                    AST.SetFlags.new(
                        span(0, 6),
                        AST.Flags.new(
                            span(2, 5),
                            [
                                AST.FlagsItem.new(
                                    span(2, 3),
                                    #Flag(#CaseInsensitive)
                                ),
                                AST.FlagsItem.new(
                                    span(3, 4),
                                    #Negation
                                ),
                                AST.FlagsItem.new(
                                    span(4, 5),
                                    #Flag(#SwapGreed)
                                )
                            ]
                        )
                    )
                )
            }),
            it("(a)", func () : Bool {
                let p = Parser.Parser("(a)");
                checkAST(
                    p.parse(),
                    #Group(AST.Group.new(
                        span(0, 3),
                        #CaptureIndex(1),
                        #Literal(AST.Literal.new(1, 'a'))
                    ))
                );
            }),
            it("(())", func () : Bool {
                let p = Parser.Parser("(())");
                checkAST(
                    p.parse(),
                    #Group(AST.Group.new(
                        span(0, 4),
                        #CaptureIndex(1),
                        #Group(AST.Group.new(
                            span(1, 3),
                            #CaptureIndex(2),
                            #Empty(span(2, 2))
                        ))
                    ))
                );
            }),
            it("(?:a)", func () : Bool {
                let p = Parser.Parser("(?:a)");
                checkAST(
                    p.parse(),
                    #Group(AST.Group.new(
                        span(0, 5),
                        #NonCapturing(AST.Flags.new(span(2, 2), [])),
                        #Literal(AST.Literal.new(3, 'a'))
                    ))
                );
            }),
            it("(?i-U:a)", func () : Bool {
                let p = Parser.Parser("(?i-U:a)");
                checkAST(
                    p.parse(),
                    #Group(AST.Group.new(
                        span(0, 8),
                        #NonCapturing(AST.Flags.new(span(2, 5), [
                            AST.FlagsItem.new(span(2, 3), #Flag(#CaseInsensitive)),
                            AST.FlagsItem.new(span(3, 4), #Negation),
                            AST.FlagsItem.new(span(4, 5), #Flag(#SwapGreed)),
                        ])),
                        #Literal(AST.Literal.new(6, 'a'))
                    ))
                );
            }),

            it("(?", func () : Bool {
                let p = Parser.Parser("(?");
                checkASTErr(
                    p.parse(),
                    AST.Error.new(#GroupUnclosed, span(0, 1))
                )
            }),
            it("(?P", func () : Bool {
                let p = Parser.Parser("(?P");
                checkASTErr(
                    p.parse(),
                    AST.Error.new(#FlagUnrecognized, span(2, 3))
                )
            }),
            it("a)", func () : Bool {
                let p = Parser.Parser("a)");
                checkASTErr(
                    p.parse(),
                    AST.Error.new(#GroupUnopened, span(1, 2))
                )
            })
        ])
    ]),
]);
