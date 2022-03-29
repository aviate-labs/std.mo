import Prim "mo:⛔";

import Char "../Char";
import Compare "../Compare";
import Result "../Result";
import Stack "../Stack";

module {
    public type AST = {
         /// An empty regex that matches everything.
        #Empty : Span;
        /// A set of flags, e.g., `(?is)`.
        #Flags : SetFlags;
        /// A single character literal, which includes escape sequences.
        #Literal : Literal;
        /// The "any character" class.
        #Dot : Span;
        /// A single zero-width assertion.
        #Assertion : Assertion;
        /// A single character class.
        #Class : Class;
        /// A repetition operator applied to an arbitrary regular expression.
        #Repetition : Repetition;
        /// A grouped regular expression.
        #Group : Group;
        /// An alternation of regular expressions.
        #Alternation : Alternation;
        /// A concatenation of regular expressions.
        #Concat : Concat;
    };

    public module AST = {
        public let cf : Compare.Cf<AST> = func (x : AST, y : AST) : Int {
            switch (x, y) {
                case (#Empty(x)      , #Empty(y))       Span.cf(x, y);
                case (#Flags(x)      , #Flags(y))       SetFlags.cf(x, y);
                case (#Literal(x)    , #Literal(y))     Literal.cf(x, y);
                case (#Dot(x)        , #Dot(y))         Span.cf(x, y);
                case (#Assertion(x)  , #Assertion(y))   Assertion.cf(x, y);
                case (#Class(x)      , #Class(y))       Class.cf(x, y);
                case (#Repetition(x) , #Repetition(y))  Repetition.cf(x, y);
                case (#Group(x)      , #Group(y))       Group.cf(x, y);
                case (#Alternation(x), #Alternation(y)) Alternation.cf(x, y);
                case (#Concat(x)     , #Concat(y))      Concat.cf(x, y);
                case (_) -1; 
            };
        };

        public func span(ast : AST) : Span {
            switch (ast) {
                case (#Empty(span))    span;
                case (#Flags(e))       e.span;
                case (#Literal(e))     e.span;
                case (#Dot(span))      span;
                case (#Assertion(e))   e.span;
                case (#Class(e))       Class.span(e);
                case (#Repetition(e))  e.span;
                case (#Group(e))       e.span;
                case (#Alternation(e)) e.span;
                case (#Concat(e))      e.span;
            };
        };
    };

    public type Error = {
        kind    : ErrorKind;
        pattern : Text;
        span    : Span;
    };

    // NOTE: ignores the pattern!
    public module Error = {
        public func new(kind : ErrorKind, span : Span) : Error = { kind; pattern = ""; span };

        public let cf : Compare.Cf<Error> = func (x : Error, y : Error) : Int {
            switch (ErrorKind.cf(x.kind, y.kind)) {
                case (0) Span.cf(x.span, y.span);
                case (n) n;
            };
        };

        public func transform<T>(
            r    : Result.Result<T, Error>,
            from : ErrorKind,
            to   : ErrorKind
        ) : Result.Result<T, Error> {
            switch (r) {
                case (#err(e)) {
                    if (ErrorKind.cf(e.kind, from) == 0) return #err({
                        kind    = to;
                        pattern = e.pattern;
                        span    = e.span;
                    });
                };
                case (_) {};
            };
            r;
        };
    };

    public type ErrorKind = {
        #GroupNameEmpty;
        #GroupNameInvalid;
        #GroupNameDuplicate;
        #GroupNameUnexpectedEOF;
        #GroupUnclosed;
        #GroupUnopened;

        #EscapeUnexpectedEOF;
        #UnsupportedBackReference;

        #GroupsEmpty;

        #FlagUnrecognized;
        #FlagDanglingNegation;
        #FlagRepeatedNegation : {
            original : Span;
        };
        #FlagUnexpectedEOF;
        #FlagDuplicate : {
            original : Span;
        };

        #RepetitionMissing;
        #RepetitionCountUnclosed;
        #RepetitionCountInvalid;

        #UnsupportedLookAround;

        #DecimalEmpty;

        #TODO
    };

    public module ErrorKind = {
        public let cf : Compare.Cf<ErrorKind> = func (x : ErrorKind, y : ErrorKind) : Int {
            switch (x, y) {
                case (#FlagRepeatedNegation(x), #FlagRepeatedNegation(y)) {
                    Span.cf(x.original, y.original);
                };
                case (#FlagDuplicate(x), #FlagDuplicate(y)) {
                    Span.cf(x.original, y.original);
                };
                case (_) {
                    if (x == y) return 0;
                    -1;
                };
            };
        };
    };

    public type Position = {
        offset : Nat;
        line   : Nat;
        column : Nat;
    };

    public module Position = {
        public func new(offset : Nat, line : Nat, column : Nat) : Position = { offset; line; column };

        public let cf : Compare.Cf<Position> = func (x : Position, y : Position) : Int { x.offset - y.offset };
    };

    public type Span = {
        start : Position;
        end   : Position;
    };

    public module Span = {
        public func new(start : Position, end : Position) : Span = { start; end };

        public func snew(p : Position) : Span = { start = p; end = p };

        public func withStart(s : Span, p : Position) : Span = { start = p; end = s.end };

        public func withEnd(s : Span, p : Position) : Span = { start = s.start; end = p };

        public func isOneLine(s : Span) : Bool { s.start.line == s.end.line };

        public func isEmpty(s : Span) : Bool { s.start.offset == s.end.offset };

        public let cf : Compare.Cf<Span> = func (x : Span, y : Span) : Int {
            switch (Position.cf(x.start, y.start)) {
                case (0) Position.cf(x.end, y.end);
                case (n) { n };
            };
        };
    };

    public type Comment = {
        span    : Span;
        comment : Text;
    };

    public type Alternation = {
        span : Span;
        asts : [AST];
    };

    public module Alternation = {
        public let cf : Compare.Cf<Alternation> = func (x : Alternation, y : Alternation) : Int {
            switch (Span.cf(x.span, y.span)) {
                case (0) {
                    let xS = x.asts.size();
                    let yS = y.asts.size();
                    if (xS != yS) return xS - yS;
                    for (k in x.asts.keys()) {
                        switch (AST.cf(x.asts[k], y.asts[k])) {
                            case (0) {};
                            case (n) return n;
                        };
                    };
                    0;
                };
                case (n) n;
            };
        };
    };

    public type Concat = {
        span : Span;
        asts : [AST];
    };

    public module Concat = {
        public let cf : Compare.Cf<Concat> = func (x : Concat, y : Concat) : Int {
            switch (Span.cf(x.span, y.span)) {
                case (0) {
                    let xS = x.asts.size();
                    let yS = y.asts.size();
                    if (xS != yS) return xS - yS;
                    for (k in x.asts.keys()) {
                        switch (AST.cf(x.asts[k], y.asts[k])) {
                            case (0) {};
                            case (n) return n;
                        };
                    };
                    0;
                };
                case (n) n;
            };
        };

        public func mut(c : Concat) : ConcatVar = {
            var span = c.span;
            asts     = Stack.init<AST>(16);
        };

        public func toAST(c : Concat) : AST {
            switch (c.asts.size()) {
                case (0) #Empty(c.span);
                case (1) c.asts[0];
                case (_) #Concat(c);
            };
        };
    };

    public type ConcatVar = {
        var span : Span;
        asts     : Stack.Stack<AST>;
    };

    public module ConcatVar = {
        public func new(span : Span) : ConcatVar = {
            var span = span;
            asts = Stack.init<AST>(16);
        };

        public func mut(c : ConcatVar) : Concat = {
            span = c.span;
            asts = Stack.toArray(c.asts);
        };
    };

    public type Literal = {
        span : Span;
        kind : LiteralKind;
        c    : Char;
    };

    public module Literal = {
        public func new(n : Nat, c : Char) : Literal = {
            span = {
                start = Position.new(n, 0, n + 1);
                end   = Position.new(n + 1, 0, n + 2);
            };
            kind = #Verbatim;
            c;
        };

        public let cf : Compare.Cf<Literal> = func (x : Literal, y : Literal) : Int {
            switch (Span.cf(x.span, y.span)) {
                case (0) switch (LiteralKind.cf(x.kind, y.kind)) {
                    case (0) Char.toNat(x.c) - Char.toNat(y.c);
                    case (n) n;
                };
                case (n) n;
            };
        };
    };

    public type LiteralKind = {
        #Verbatim;
        #Punctuation;
        #Octal;
        #HexFixed : HexLiteralKind;
        #HexBrace : HexLiteralKind;
        #Special  : SpecialLiteralKind;
    };

    public module LiteralKind = {
        public let cf : Compare.Cf<LiteralKind> = func (x : LiteralKind, y : LiteralKind) : Int {
            switch (x, y) {
                case (#HexFixed(x), #HexFixed(y)) HexLiteralKind.cf(x, y);
                case (#HexBrace(x), #HexBrace(y)) HexLiteralKind.cf(x, y);
                case (#Special(x) , #Special(y))  SpecialLiteralKind.cf(x, y);
                case (_) {
                    if (x == y) return 0;
                    -1;
                };
            };
        };
    };

    public type HexLiteralKind = {
        #X;
        #UnicodeShort;
        #UnicodeLong;
    };
    
    public module HexLiteralKind = {
        public let cf : Compare.Cf<HexLiteralKind> = func (x : HexLiteralKind, y : HexLiteralKind) : Int {
            if (x == y) return 0;
            return -1;
        };
    };

    public type SpecialLiteralKind = {
        #Bell;
        #FormFeed;
        #Tab;
        #LineFeed;
        #CarriageReturn;
        #VerticalTab;
        #Space;
    };

    public module SpecialLiteralKind = {
        public let cf : Compare.Cf<SpecialLiteralKind> = func (x : SpecialLiteralKind, y : SpecialLiteralKind) : Int {
            if (x == y) return 0;
            return -1;
        };
    };

    public type Class = {
        #Unicode   : ClassUnicode;
        #Perl      : ClassPerl;
        #Bracketed : ClassBracketed;
    };

    public module Class = {
        public let cf : Compare.Cf<Class> = func (x : Class, y : Class) : Int {
            switch (x, y) {
                case (#Unicode(x)  , #Unicode(y))   ClassUnicode.cf(x, y);
                case (#Perl(x)     , #Perl(y))      ClassPerl.cf(x, y);
                case (#Bracketed(x), #Bracketed(y)) ClassBracketed.cf(x, y);
                case (_) -1;
            };
        };

        public func span(c : Class) : Span {
            switch (c) {
                case (#Unicode(e))   e.span;
                case (#Perl(e))      e.span;
                case (#Bracketed(e)) e.span;
            };
        };
    };

    public type ClassType<T> = {
        span : Span;
        kind : T;
        negated : Bool;
    };

    public type ClassUnicode = ClassType<ClassUnicodeKind>;

    public module ClassUnicode = {
        public let cf : Compare.Cf<ClassUnicode> = func (x : ClassUnicode, y : ClassUnicode) : Int {
            switch (Span.cf(x.span, y.span)) {
                case (0) switch (ClassUnicodeKind.cf(x.kind, y.kind)) {
                    case (0) {
                        if (x.negated == y.negated) return 0;
                        -1;
                    };
                    case (n) n;
                };
                case (n) n;
            };
        };
    };

    public type ClassUnicodeKind = {
        #OneLetter  : Char;
        #Named      : Text;
        #NamedValue : {
            op : ClassUnicodeOpKind;
            name : Text;
            value : Text;
        };
    };

    public module ClassUnicodeKind = {
        public let cf : Compare.Cf<ClassUnicodeKind> = func (x : ClassUnicodeKind, y : ClassUnicodeKind) : Int {
            switch (x, y) {
                case (#OneLetter(x), #OneLetter(y)) Char.toNat(x) - Char.toNat(y);
                case (#Named(x)    , #Named(y)) {
                    // TODO: lexical cmp.
                    if (x == y) return 0;
                    -1;
                };
                case (#NamedValue(x), #NamedValue(y)) {
                    switch (ClassUnicodeOpKind.cf(x.op, y.op)) {
                        case (0) {
                            if (x.name != y.name)   return -1;
                            if (x.value != x.value) return -1;
                            0;
                        };
                        case (n) n;
                    }
                };
                case (_) -1;
            }
        };
    };

    public type ClassUnicodeOpKind = {
        #Equal;
        #Colon;
        #NotEqual;
    };

    public module ClassUnicodeOpKind = {
        public let cf : Compare.Cf<ClassUnicodeOpKind> = func (x : ClassUnicodeOpKind, y : ClassUnicodeOpKind) : Int {
            if (x == y) return 0;
            return -1;
        };
    };

    public type ClassAscii = ClassType<ClassAsciiKind>;

    public module ClassAscii = {
        public let cf : Compare.Cf<ClassAscii> = func (x : ClassAscii, y : ClassAscii) : Int {
            switch (Span.cf(x.span, y.span)) {
                case (0) switch (ClassAsciiKind.cf(x.kind, y.kind)) {
                    case (0) {
                        if (x.negated == y.negated) return 0;
                        -1;
                    };
                    case (n) n;
                };
                case (n) n;
            };
        };
    };

    public type ClassAsciiKind = {
        #Alnum;
        #Alpha;
        #Ascii;
        #Blank;
        #Cntrl;
        #Digit;
        #Graph;
        #Lower;
        #Print;
        #Punct;
        #Space;
        #Upper;
        #Word;
        #Xdigit;
    };

    public module ClassAsciiKind = {
        public let cf : Compare.Cf<ClassAsciiKind> = func (x : ClassAsciiKind, y : ClassAsciiKind) : Int {
            if (x == y) return 0;
            return -1;
        };
    };

    public type ClassPerl = ClassType<ClassPerlKind>;

    public module ClassPerl = {
        public let cf : Compare.Cf<ClassPerl> = func (x : ClassPerl, y : ClassPerl) : Int {
            switch (Span.cf(x.span, y.span)) {
                case (0) switch (ClassPerlKind.cf(x.kind, y.kind)) {
                    case (0) {
                        if (x.negated == y.negated) return 0;
                        -1;
                    };
                    case (n) n;
                };
                case (n) n;
            };
        };
    };

    public type ClassPerlKind = {
        #Digit;
        #Space;
        #Word;
    };

    public module ClassPerlKind = {
        public let cf : Compare.Cf<ClassPerlKind> = func (x : ClassPerlKind, y : ClassPerlKind) : Int {
            if (x == y) return 0;
            return -1;
        };
    };

    public type ClassBracketed = ClassType<ClassSet>;

    public module ClassBracketed = {
        public let cf : Compare.Cf<ClassBracketed> = func (x : ClassBracketed, y : ClassBracketed) : Int {
            switch (Span.cf(x.span, y.span)) {
                case (0) switch (ClassSet.cf(x.kind, y.kind)) {
                    case (0) {
                        if (x.negated == y.negated) return 0;
                        -1;
                    };
                    case (n) n;
                };
                case (n) n;
            };
        };
    };

    public type ClassSet = {
        #Item     : ClassSetItem;
        #BinaryOp : ClassSetBinaryOp;
    };

    public module ClassSet = {
        public let cf : Compare.Cf<ClassSet> = func (x : ClassSet, y : ClassSet) : Int {
            switch (x, y) {
                case (#Item(x)    , #Item(y))     ClassSetItem.cf(x, y);
                case (#BinaryOp(x), #BinaryOp(y)) ClassSetBinaryOp.cf(x, y);
                case (_) -1;
            };
        };
    };

    public type ClassSetItem = {
        #Empty     : Span;
        #Literal   : Literal;
        #Range     : ClassSetRange;
        #Ascii     : ClassAscii;
        #Unicode   : ClassUnicode;
        #Perl      : ClassPerl;
        #Bracketed : ClassBracketed;
        #Union     : ClassSetUnion;
    };

    public module ClassSetItem = {
        public let cf : Compare.Cf<ClassSetItem> = func (x : ClassSetItem, y : ClassSetItem) : Int {
            switch (x, y) {
                case (#Empty(x)    , #Empty(y))     Span.cf(x, y);
                case (#Literal(x)  , #Literal(y))   Literal.cf(x, y);
                case (#Range(x)    , #Range(y))     ClassSetRange.cf(x, y);
                case (#Ascii(x)    , #Ascii(y))     ClassAscii.cf(x, y);
                case (#Unicode(x)  , #Unicode(y))   ClassUnicode.cf(x, y);
                case (#Perl(x)     , #Perl(y))      ClassPerl.cf(x, y);
                case (#Bracketed(x), #Bracketed(y)) ClassBracketed.cf(x, y);
                case (#Union(x)    , #Union(y))     ClassSetUnion.cf(x, y);
                case (_) -1;
            };
        };
    };

    public type ClassSetRange = {
        span  : Span;
        start : Literal;
        end   : Literal;
    };

    public module ClassSetRange = {
        public let cf : Compare.Cf<ClassSetRange> = func (x : ClassSetRange, y : ClassSetRange) : Int {
            switch (Span.cf(x.span, y.span)) {
                case (0) {
                    // TODO: lexical cmp.
                    if (x.start != y.start) return -1;
                    if (x.end != y.end)     return -1;
                    0;
                };
                case (n) n;
            };
        };
    };

    public type ClassSetUnion = {
        span  : Span;
        items : [ClassSetItem];
    };

    public module ClassSetUnion = {
        public let cf : Compare.Cf<ClassSetUnion> = func (x : ClassSetUnion, y : ClassSetUnion) : Int {
            switch (Span.cf(x.span, y.span)) {
                case (0) {
                    let xS = x.items.size();
                    let yS = y.items.size();
                    if (xS != yS) return xS - yS;
                    for (k in x.items.keys()) {
                        switch (ClassSetItem.cf(x.items[k], y.items[k])) {
                            case (0) {};
                            case (n) return n;
                        };
                    };
                    0;
                };
                case (n) n;
            };
        };
    };

    public type ClassSetBinaryOp = {
        span : Span;
        kind : ClassSetBinaryOpKind;
        lhs  : ClassSet;
        rhs  : ClassSet;
    };

    public module ClassSetBinaryOp = {
        public let cf : Compare.Cf<ClassSetBinaryOp> = func (x : ClassSetBinaryOp, y : ClassSetBinaryOp) : Int {
            switch (Span.cf(x.span, y.span)) {
                case (0) switch (ClassSetBinaryOpKind.cf(x.kind, y.kind)) {
                    case (0) switch (ClassSet.cf(x.lhs, y.lhs)) {
                        case (0) ClassSet.cf(x.rhs, y.rhs);
                        case (n) n;
                    };
                    case (n) n;
                };
                case (n) n;
            };
        };
    };

    public type ClassSetBinaryOpKind = {
        #Intersection;
        #Difference;
        #SymmetricDifference;
    };

    public module ClassSetBinaryOpKind = {
        public let cf : Compare.Cf<ClassSetBinaryOpKind> = func (x : ClassSetBinaryOpKind, y : ClassSetBinaryOpKind) : Int {
            if (x == y) return 0;
            -1;
        };
    };

    public type Assertion = {
        span : Span;
        kind : AssertionKind;
    };

    public module Assertion = {
        public let cf : Compare.Cf<Assertion> = func (x : Assertion, y : Assertion) : Int {
            switch (Span.cf(x.span, y.span)) {
                case (0) AssertionKind.cf(x.kind, y.kind);
                case (n) n;
            };
        };
    };

    public type AssertionKind = {
        #StartLine;
        #EndLine;
        #StartText;
        #EndText;
        #WordBoundary;
        #NotWordBoundary;
    };

    public module AssertionKind = {
        public let cf : Compare.Cf<AssertionKind> = func (x : AssertionKind, y : AssertionKind) : Int {
            if (x == y) return 0;
            -1;
        };
    };

    public type Repetition = {
        span   : Span;
        op     : RepetitionOp;
        greedy : Bool;
        ast    : AST;
    };

    public module Repetition = {
        public let cf : Compare.Cf<Repetition> = func (x : Repetition, y : Repetition) : Int {
            switch (Span.cf(x.span, y.span)) {
                case (0) switch (RepetitionOp.cf(x.op, y.op)) {
                    case (0) {
                        if (x.greedy != y.greedy) return -1;
                        AST.cf(x.ast, y.ast);
                    };
                    case (n) n;
                };
                case (n) n;
            };
        };
    };

    public type RepetitionOp = {
        span : Span;
        kind : RepetitionKind;
    };

    public module RepetitionOp = {
        public let cf : Compare.Cf<RepetitionOp> = func (x : RepetitionOp, y : RepetitionOp) : Int {
            switch (Span.cf(x.span, y.span)) {
                case (0) RepetitionKind.cf(x.kind, y.kind);
                case (n) n;
            };
        };
    };

    public type RepetitionKind = {
        #ZeroOrOne; #ZeroOrMore; #OneOrMore;
        #Range : RepetitionRange;
    };

    public module RepetitionKind = {
        public let cf : Compare.Cf<RepetitionKind> = func (x : RepetitionKind, y : RepetitionKind) : Int {
            switch (x, y) {
                case (#Range(x)  , #Range(y))   RepetitionRange.cf(x, y);
                case (#ZeroOrOne , #ZeroOrOne)  0;
                case (#ZeroOrMore, #ZeroOrMore) 0;
                case (#OneOrMore , #OneOrMore)  0;
                case (_) -1;
            };
        };
    };

    public type RepetitionRange = {
        #Exactly : Nat32;
        #AtLeast : Nat32;
        #Bounded : (Nat32, Nat32);
    };

    public module RepetitionRange = {
        public func isValid(r : RepetitionRange) : Bool {
            switch (r) {
                case (#Bounded(m, n)) n >= m;
                case (_)              true;
            };
        };

        public let cf : Compare.Cf<RepetitionRange> = func (x : RepetitionRange, y : RepetitionRange) : Int {
            switch (x, y) {
                case (#Exactly(x), #Exactly(y)) Prim.nat32ToNat(x) - Prim.nat32ToNat(y);
                case (#AtLeast(x), #AtLeast(y)) Prim.nat32ToNat(x) - Prim.nat32ToNat(y);
                case (#Bounded(x), #Bounded(y)) {
                    let n : Int = Prim.nat32ToNat(x.0) - Prim.nat32ToNat(y.0);
                    switch (n) {
                        case (0) Prim.nat32ToNat(x.1) - Prim.nat32ToNat(y.1);
                        case (n) n;
                    };
                };
                case (_) -1;
            };
        };
    };

    public type Group = {
        span : Span;
        kind : GroupKind;
        ast  : AST;
    };

    public module Group = {
        public func new(span : Span, kind : GroupKind, ast : AST) : Group = { span; kind; ast };

        public let cf : Compare.Cf<Group> = func (x : Group, y : Group) : Int {
            switch (Span.cf(x.span, y.span)) {
                case (0) switch (GroupKind.cf(x.kind, y.kind)) {
                    case (0) AST.cf(x.ast, y.ast);
                    case (n) n;
                };
                case (n) n;
            }
        };

        public func mut(g : Group) : GroupVar = {
            var span = g.span;
            var kind = g.kind;
            var ast  = g.ast;
        };
    };

    public type GroupVar = {
        var span : Span;
        var kind : GroupKind;
        var ast  : AST;
    };

    public module GroupVar = {
        public func mut(g : GroupVar) : Group = {
            span = g.span;
            kind = g.kind;
            ast  = g.ast;
        };
    };

    public type GroupKind = {
        #CaptureIndex : Nat32;
        #CaptureName  : CaptureName;
        #NonCapturing : Flags;
    };

    public module GroupKind = {
        public let cf : Compare.Cf<GroupKind> = func (x : GroupKind, y : GroupKind) : Int {
            switch (x, y) {
                case (#CaptureIndex(x), #CaptureIndex(y)) Prim.nat32ToNat(x) - Prim.nat32ToNat(y);
                case (#CaptureName(x) , #CaptureName(y))  CaptureName.cf(x, y);
                case (#NonCapturing(x), #NonCapturing(y)) Flags.cf(x, y);
                case (_) { -1 };
            };
        };
    };

    public type CaptureName = {
        span  : Span;
        name  : Text;
        index : Nat32;
    };

    public module CaptureName = {
        public func new(span : Span, name : Text, index : Nat32) : CaptureName = { span; name; index };

        public let cf : Compare.Cf<CaptureName> = func (x : CaptureName, y : CaptureName) : Int {
            switch (Span.cf(x.span, y.span)) {
                case (0) {
                    // TODO: lexical cmp.
                    if (x.name != y.name) return -1;
                    Prim.nat32ToNat(x.index) - Prim.nat32ToNat(y.index);
                };
                case (n) n;
            };
        };
    };

    public type SetFlags = {
        span  : Span;
        flags : Flags;
    };

    public module SetFlags = {
        public func new(span : Span, flags : Flags) : SetFlags = { span; flags };

        public let cf : Compare.Cf<SetFlags> = func (x : SetFlags, y : SetFlags) : Int {
            switch (Span.cf(x.span, y.span)) {
                case (0) Flags.cf(x.flags, y.flags);
                case (n) n;
            };
        };
    };

    public type Flags = {
        span  : Span;
        items : [FlagsItem];
    };

    public module Flags = {
        public func new(span : Span, items : [FlagsItem]) : Flags = { span; items };

        public let cf : Compare.Cf<Flags> = func (x : Flags, y : Flags) : Int {
            switch (Span.cf(x.span, y.span)) {
                case (0) {
                    let xS = x.items.size();
                    let yS = y.items.size();
                    if (xS != yS) return xS - yS;
                    for (k in x.items.keys()) {
                        switch (FlagsItem.cf(x.items[k], y.items[k])) {
                            case (0) {};
                            case (n) return n;
                        };
                    };
                    0;
                };
                case (n) n;
            };
        };
    };

    public type FlagsItem = {
        span : Span;
        kind : FlagsItemKind;
    };

    public module FlagsItem = {
        public func new(span : Span, kind : FlagsItemKind) : FlagsItem = { span; kind };

        public let cf : Compare.Cf<FlagsItem> = func (x : FlagsItem, y : FlagsItem) : Int {
            switch (Span.cf(x.span, y.span)) {
                case (0) FlagsItemKind.cf(x.kind, y.kind);
                case (n) n;
            };
        };
    };

    public type FlagsItemKind = {
        #Negation;
        #Flag : Flag;
    };

    public module FlagsItemKind = {
        public let cf : Compare.Cf<FlagsItemKind> = func (x : FlagsItemKind, y : FlagsItemKind) : Int {
            switch (x, y) {
                case (#Flag(x) , #Flag(y))  Flag.cf(x, y);
                case (#Negation, #Negation) 0;
                case (_) -1;
            }
        };
    };

    public type Flag = {
        #CaseInsensitive;
        #MultiLine;
        #DotMatchesNewLine;
        #SwapGreed;
        #Unicode;
        #IgnoreWhitespace;
    };

    public module Flag = {
        public let cf : Compare.Cf<Flag> = func (x : Flag, y : Flag) : Int {
            if (x == y) return 0;
            -1;
        };
    };
};
