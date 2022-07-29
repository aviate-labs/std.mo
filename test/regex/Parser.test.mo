import { describe; it; Suite } = "mo:testing/Suite";

import Prim "mo:⛔";

import AST "mo:std/regex/AST";
import Compare "mo:std/Compare";
import Parser "mo:std/regex/Parser";

let suite = Suite();

module Check = {
    public func flags(r : Parser.Result<AST.Flags>, expected : AST.Flags) : Bool {
        switch (r) {
            case (#err(_)) false;
            case (#ok(flags)) Compare.eq(flags, expected, AST.Flags.cf);
        };
    };

    public func flagsErr(r : Parser.Result<AST.Flags>, err : AST.Error) : Bool {
        switch (r) {
            case (#ok(_))  false;
            case (#err(e)) Compare.eq(e, err, AST.Error.cf);
        };
    };

    public func setFlags(r : Parser.Result<Parser.Either<AST.SetFlags, AST.Group>>, flags : AST.SetFlags) : Bool {
        switch (r) {
            case (#err(_)) false;
            case (#ok(e)) {
                switch (e) {
                    case (#right(_)) false;
                    case (#left(sf)) Compare.eq(sf, flags, AST.SetFlags.cf);
                };
            };
        };
    };

    public func captureName(r : Parser.Result<AST.CaptureName>, cn : AST.CaptureName) : Bool {
        switch (r) {
            case (#err(_)) false;
            case (#ok(n))  Compare.eq(n, cn, AST.CaptureName.cf);
        };
    };

    public func captureNameErr(r : Parser.Result<AST.CaptureName>, err : AST.Error) : Bool {
        switch (r) {
            case (#ok(_))  false;
            case (#err(e)) Compare.eq(e, err, AST.Error.cf);
        };
    };

    public func group(r : Parser.Result<Parser.Either<AST.SetFlags, AST.Group>>, group : AST.Group) : Bool {
        switch (r) {
            case (#err(_)) false;
            case (#ok(e)) {
                switch (e) {
                    case (#left(_))  false;
                    case (#right(g)) Compare.eq(g, group, AST.Group.cf);
                };
            };
        };
    };

    public func ast(r : Parser.Result<AST.AST>, ast : AST.AST) : Bool {
        switch (r) {
            case (#err(e)) {
                Prim.debugPrint(debug_show("ERR", e));
                false;
            };
            case (#ok(e)) switch (AST.AST.cf(e, ast)) {
                case (#equal) true;
                case (_) {
                    Prim.debugPrint(debug_show("A", e));
                    Prim.debugPrint(debug_show("E", ast));
                    false;
                };
            };
        };
    };

    public func astErr(r : Parser.Result<AST.AST>, err : AST.Error) : Bool {
        switch (r) {
            case (#ok(_))  false;
            case (#err(e)) Compare.eq(e, err, AST.Error.cf);
        };
    };
};

func span(s : Nat, e : Nat) : AST.Span {
    let start = AST.Position.new(s, 1, s + 1);
    let end   = AST.Position.new(e, 1, e + 1);
    AST.Span.new(start, end);
};

suite.run([
    describe("Parser", [
        describe("Flags", [
            it("i)", func () : Bool {
                let p = Parser.Parser("i)");
                Check.flags(p.parseFlags(), AST.Flags.new(span(0, 1), [
                    { span = span(0, 1); kind = #Flag(#CaseInsensitive) },
                ]));
            }),
            it("isU:", func () : Bool {
                let p = Parser.Parser("isU:");
                Check.flags(p.parseFlags(), AST.Flags.new(span(0, 3), [
                    { span = span(0, 1); kind = #Flag(#CaseInsensitive) },
                    { span = span(1, 2); kind = #Flag(#DotMatchesNewLine) },
                    { span = span(2, 3); kind = #Flag(#SwapGreed) },
                ]));
            }),
            it("-isU:", func () : Bool {
                let p = Parser.Parser("-isU:");
                Check.flags(p.parseFlags(), AST.Flags.new(span(0, 4), [
                    { span = span(0, 1); kind = #Negation },
                    { span = span(1, 2); kind = #Flag(#CaseInsensitive) },
                    { span = span(2, 3); kind = #Flag(#DotMatchesNewLine) },
                    { span = span(3, 4); kind = #Flag(#SwapGreed) },
                ]));
            }),
            it("i-sU:", func () : Bool {
                let p = Parser.Parser("i-sU:");
                Check.flags(p.parseFlags(), AST.Flags.new(span(0, 4), [
                    { span = span(0, 1); kind = #Flag(#CaseInsensitive) },
                    { span = span(1, 2); kind = #Negation },
                    { span = span(2, 3); kind = #Flag(#DotMatchesNewLine) },
                    { span = span(3, 4); kind = #Flag(#SwapGreed) },
                ]));
            }),

            it("isU", func () : Bool {
                let p = Parser.Parser("isU");
                Check.flagsErr(
                    p.parseFlags(),
                    AST.Error.new(#FlagUnexpectedEOF, span(3, 3))
                );
            }),
            it("isUi:", func () : Bool {
                let p = Parser.Parser("isUi:");
                Check.flagsErr(
                    p.parseFlags(),
                    AST.Error.new(#FlagDuplicate({ original = span(0, 1) }), span(3, 4))
                );
            }),
            it("i-sU-i:", func () : Bool {
                let p = Parser.Parser("i-sU-i:");
                Check.flagsErr(
                    p.parseFlags(),
                    AST.Error.new(#FlagRepeatedNegation({ original = span(1, 2) }), span(4, 5))
                );
            }),
            it("-)", func () : Bool {
                let p = Parser.Parser("-)");
                Check.flagsErr(p.parseFlags(), AST.Error.new(#FlagDanglingNegation, span(0, 1)));
            })
        ]),
        describe("CaptureName", [
            it("abc>", func () : Bool {
                let p = Parser.Parser("abc>");
                Check.captureName(
                    p.parseCaptureName(1),
                    AST.CaptureName.new(span(0, 3), "abc", 1)
                );
            }),
            it("a_1", func () : Bool {
                let p = Parser.Parser("a_1>");
                Check.captureName(
                    p.parseCaptureName(1),
                    AST.CaptureName.new(span(0, 3), "a_1", 1)
                );
            }),
            it("a.1>", func () : Bool {
                let p = Parser.Parser("a.1>");
                Check.captureName(
                    p.parseCaptureName(1),
                    AST.CaptureName.new(span(0, 3), "a.1", 1)
                );
            }),
            it("a[1]>", func () : Bool {
                let p = Parser.Parser("a[1]>");
                Check.captureName(
                    p.parseCaptureName(1),
                    AST.CaptureName.new(span(0, 4), "a[1]", 1)
                );
            }),

            it("", func () : Bool {
                let p = Parser.Parser("");
                Check.captureNameErr(p.parseCaptureName(1), AST.Error.new(#GroupNameUnexpectedEOF, span(0, 0)));
            }),
            it(">", func () : Bool {
                let p = Parser.Parser(">");
                Check.captureNameErr(p.parseCaptureName(1), AST.Error.new(#GroupNameEmpty, span(0, 0)));
            }),
            it("0a>", func () : Bool {
                let p = Parser.Parser("0a>");
                Check.captureNameErr(p.parseCaptureName(1), AST.Error.new(#GroupNameInvalid, span(0, 1)));
            }),
            it("a>a>", func () : Bool {
                let p = Parser.Parser("a>a>");
                ignore p.parseCaptureName(1);
                Check.captureNameErr(p.parseCaptureName(1), AST.Error.new(#GroupNameDuplicate, span(2, 3)));
            })
        ]),
        describe("Group", [
            it("(?iU)", func () : Bool {
                let p = Parser.Parser("(?i-U)");
                Check.setFlags(
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
                Check.ast(
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
                Check.ast(
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
                Check.ast(
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
                Check.ast(
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
                Check.astErr(
                    p.parse(),
                    AST.Error.new(#RepetitionMissing, span(1, 1))
                )
            }),
            it("(?P", func () : Bool {
                let p = Parser.Parser("(?P");
                Check.astErr(
                    p.parse(),
                    AST.Error.new(#FlagUnrecognized, span(2, 3))
                )
            }),
            it("a)", func () : Bool {
                let p = Parser.Parser("a)");
                Check.astErr(
                    p.parse(),
                    AST.Error.new(#GroupUnopened, span(1, 2))
                )
            })
        ]),
        describe("Repetition", [
            it("a*", func () : Bool {
                let p = Parser.Parser("a*");
                Check.ast(
                    p.parse(),
                    #Repetition({
                        span   = span(0, 2);
                        op     = {
                            span = span(1, 2);
                            kind = #ZeroOrMore;   
                        };
                        greedy = true;
                        ast    = #Literal(AST.Literal.new(0, 'a')) 
                    })
                )
            }),
            it("a+", func () : Bool {
                let p = Parser.Parser("a+");
                Check.ast(
                    p.parse(),
                    #Repetition({
                        span   = span(0, 2);
                        op     = {
                            span = span(1, 2);
                            kind = #OneOrMore;   
                        };
                        greedy = true;
                        ast    = #Literal(AST.Literal.new(0, 'a')) 
                    })
                )
            }),
            it("a?", func () : Bool {
                let p = Parser.Parser("a?");
                Check.ast(
                    p.parse(),
                    #Repetition({
                        span   = span(0, 2);
                        op     = {
                            span = span(1, 2);
                            kind = #ZeroOrOne;   
                        };
                        greedy = true;
                        ast    = #Literal(AST.Literal.new(0, 'a')) 
                    })
                )
            }),
            it("a??", func () : Bool {
                let p = Parser.Parser("a??");
                Check.ast(
                    p.parse(),
                    #Repetition({
                        span   = span(0, 3);
                        op     = {
                            span = span(1, 3);
                            kind = #ZeroOrOne;   
                        };
                        greedy = false;
                        ast    = #Literal(AST.Literal.new(0, 'a')) 
                    })
                )
            }),
            it("a?b", func () : Bool {
                let p = Parser.Parser("a?b");
                Check.ast(
                    p.parse(),
                    #Concat({
                        span = span(0, 3);
                        asts = [
                            #Repetition({
                                span   = span(0, 2);
                                op     = {
                                    span = span(1, 2);
                                    kind = #ZeroOrOne;   
                                };
                                greedy = true;
                                ast    = #Literal(AST.Literal.new(0, 'a')) 
                            }),
                            #Literal(AST.Literal.new(2, 'b'))
                        ];
                    })
                )
            }),
            it("ab?", func () : Bool {
                let p = Parser.Parser("ab?");
                Check.ast(
                    p.parse(),
                    #Concat({
                        span = span(0, 3);
                        asts = [
                            #Literal(AST.Literal.new(0, 'a')),
                            #Repetition({
                                span   = span(1, 3);
                                op     = {
                                    span = span(2, 3);
                                    kind = #ZeroOrOne;   
                                };
                                greedy = true;
                                ast    = #Literal(AST.Literal.new(1, 'b'))
                            })
                        ];
                    })
                )
            }),
            it("(ab)?", func () : Bool {
                let p = Parser.Parser("(ab)?");
                Check.ast(
                    p.parse(),
                    #Repetition({
                        span = span(0, 5);
                        op   = {
                            span = span(4, 5);
                            kind = #ZeroOrOne;
                        };
                        greedy = true;
                        ast    = #Group(AST.Group.new(span(0, 4), #CaptureIndex(1), #Concat({
                            span = span(1, 3);
                            asts = [
                                #Literal(AST.Literal.new(1, 'a')),
                                #Literal(AST.Literal.new(2, 'b'))
                            ];
                        })));
                    })
                )
            }),

            it("*", func () : Bool {
                let p = Parser.Parser("*");
                Check.astErr(p.parse(), AST.Error.new(#RepetitionMissing, span(0, 0)));
            }),
            it("(?i)*", func () : Bool {
                let p = Parser.Parser("(?i)*");
                Check.astErr(p.parse(), AST.Error.new(#RepetitionMissing, span(4, 4)));
            }),
            it("(?:?)", func () : Bool {
                let p = Parser.Parser("(?:?)");
                Check.astErr(p.parse(), AST.Error.new(#RepetitionMissing, span(3, 3)));
            }),
        ]),
        describe("Range", [
            it("a{ 5 }", func () : Bool {
                let p = Parser.Parser("a{5}");
                Check.ast(
                    p.parse(),
                    #Repetition({
                        span   = span(0, 4);
                        op     = {
                            span = span(1, 4);
                            kind = #Range(#Exactly(5));   
                        };
                        greedy = true;
                        ast    = #Literal(AST.Literal.new(0, 'a')) 
                    })
                )
            }),
            it("a{ 5 , }", func () : Bool {
                let p = Parser.Parser("a{5,}");
                Check.ast(
                    p.parse(),
                    #Repetition({
                        span   = span(0, 5);
                        op     = {
                            span = span(1, 5);
                            kind = #Range(#AtLeast(5));   
                        };
                        greedy = true;
                        ast    = #Literal(AST.Literal.new(0, 'a')) 
                    })
                )
            }),
            it("a{ 5 , 9 }", func () : Bool {
                let p = Parser.Parser("a{5,9}");
                Check.ast(
                    p.parse(),
                    #Repetition({
                        span   = span(0, 6);
                        op     = {
                            span = span(1, 6);
                            kind = #Range(#Bounded(5, 9));   
                        };
                        greedy = true;
                        ast    = #Literal(AST.Literal.new(0, 'a')) 
                    })
                )
            }),
            it("a{5} ?", func () : Bool {
                let p = Parser.Parser("a{5}?");
                Check.ast(
                    p.parse(),
                    #Repetition({
                        span   = span(0, 5);
                        op     = {
                            span = span(1, 5);
                            kind = #Range(#Exactly(5));   
                        };
                        greedy = false;
                        ast    = #Literal(AST.Literal.new(0, 'a')) 
                    })
                )
            }),
            it("ab{5}c", func () : Bool {
                let p = Parser.Parser("ab{5}c");
                Check.ast(
                    p.parse(),
                    #Concat({
                        span = span(0, 6);
                        asts = [
                            #Literal(AST.Literal.new(0, 'a')),
                            #Repetition({
                                span   = span(1, 5);
                                op     = {
                                    span = span(2, 5);
                                    kind = #Range(#Exactly(5));   
                                };
                                greedy = true;
                                ast    = #Literal(AST.Literal.new(1, 'b')) 
                            }),
                            #Literal(AST.Literal.new(5, 'c'))
                        ];
                    })
                )
            }),

            it("(?i){0}", func () : Bool {
                let p = Parser.Parser("(?i){0}");
                Check.astErr(p.parse(), AST.Error.new(#RepetitionMissing, span(4, 4)));
            }),
            it("a{}", func () : Bool {
                let p = Parser.Parser("a{}");
                Check.astErr(p.parse(), AST.Error.new(#DecimalEmpty, span(2, 2)));
            }),
            it("a{", func () : Bool {
                let p = Parser.Parser("a{");
                Check.astErr(p.parse(), AST.Error.new(#RepetitionCountUnclosed, span(1, 2)));
            }),
        ]),
        describe("Alternation", [
            it("a|b|c", func () : Bool {
                let p = Parser.Parser("a|b|c");
                Check.ast(
                    p.parse(),
                    #Alternation({
                        span = span(0, 5);
                        asts = [
                            #Literal(AST.Literal.new(0, 'a')),
                            #Literal(AST.Literal.new(2, 'b')),
                            #Literal(AST.Literal.new(4, 'c'))
                        ];
                    })
                );
            }),
            it("||", func () : Bool {
                let p = Parser.Parser("||");
                Check.ast(
                    p.parse(),
                    #Alternation({
                        span = span(0, 2);
                        asts = [
                            #Empty(span(0, 0)),
                            #Empty(span(1, 1)),
                            #Empty(span(2, 2))
                        ];
                    })
                );
            }),
        ])
    ]),
]);
