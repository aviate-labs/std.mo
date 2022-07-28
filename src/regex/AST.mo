import Prim "mo:⛔";

import Char "../Char";
import Compare "../Compare";
import Nat "../Nat";
import Result "../Result";
import Stack "../Stack";
import Text "../Text";

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
        public let cf : Compare.Cf<AST> = func (x : AST, y : AST) : Compare.Order {
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
                case (_) #notEqual; 
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

        public let cf : Compare.Cf<Error> = func (x : Error, y : Error) : Compare.Order {
            switch (ErrorKind.cf(x.kind, y.kind)) {
                case (#equal) Span.cf(x.span, y.span);
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
                    if (Compare.eq(e.kind, from, ErrorKind.cf)) return #err({
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

        #EscapeHexInvalidDigit;

        #DecimalEmpty;

        #TODO
    };

    public module ErrorKind = {
        public let cf : Compare.Cf<ErrorKind> = func (x : ErrorKind, y : ErrorKind) : Compare.Order {
            switch (x, y) {
                case (#FlagRepeatedNegation(x), #FlagRepeatedNegation(y)) Span.cf(x.original, y.original);
                case (#FlagDuplicate(x)       , #FlagDuplicate(y))        Span.cf(x.original, y.original);
                case (_) {
                    if (x == y) return #equal;
                    #notEqual;
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

        public let cf : Compare.Cf<Position> = func (x : Position, y : Position) : Compare.Order = Nat.cf(x.offset, y.offset);
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

        public let cf : Compare.Cf<Span> = func (x : Span, y : Span) : Compare.Order {
            switch (Position.cf(x.start, y.start)) {
                case (#equal) Position.cf(x.end, y.end);
                case (n) n;
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
        public let cf : Compare.Cf<Alternation> = func (x : Alternation, y : Alternation) : Compare.Order {
            switch (Span.cf(x.span, y.span)) {
                case (#equal) {
                    let oS = Nat.cf(x.asts.size(), y.asts.size());
                    if (Compare.Order.neq(oS)) return oS;

                    for (k in x.asts.keys()) {
                        switch (AST.cf(x.asts[k], y.asts[k])) {
                            case (#equal) {};
                            case (n) return n;
                        };
                    };
                    #equal;
                };
                case (n) n;
            };
        };

        public func toAST(c : Alternation) : AST {
            switch (c.asts.size()) {
                case (0) #Empty(c.span);
                case (1) c.asts[0];
                case (_) #Alternation(c);
            };
        };
    };

    public type AlternationVar = {
        var span : Span;
        asts     : Stack.Stack<AST>;
    };

    public module AlternationVar = {
        public func new(span : Span) : AlternationVar = {
            var span = span;
            asts = Stack.init<AST>(16);
        };

        public func mut(a : AlternationVar) : Alternation = {
            span = a.span;
            asts = Stack.toArray(a.asts);
        };
    };

    public type Concat = {
        span : Span;
        asts : [AST];
    };

    public module Concat = {
        public let cf : Compare.Cf<Concat> = func (x : Concat, y : Concat) : Compare.Order {
            switch (Span.cf(x.span, y.span)) {
                case (#equal) {
                    let oS = Nat.cf(x.asts.size(), y.asts.size());
                    if (Compare.Order.neq(oS)) return oS;

                    for (k in x.asts.keys()) {
                        switch (AST.cf(x.asts[k], y.asts[k])) {
                            case (#equal) {};
                            case (n) return n;
                        };
                    };
                    #equal;
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

        public let cf : Compare.Cf<Literal> = func (x : Literal, y : Literal) : Compare.Order {
            switch (Span.cf(x.span, y.span)) {
                case (#equal) switch (LiteralKind.cf(x.kind, y.kind)) {
                    case (#equal) Char.cf(x.c, y.c);
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
        public let cf : Compare.Cf<LiteralKind> = func (x : LiteralKind, y : LiteralKind) : Compare.Order {
            switch (x, y) {
                case (#HexFixed(x), #HexFixed(y)) HexLiteralKind.cf(x, y);
                case (#HexBrace(x), #HexBrace(y)) HexLiteralKind.cf(x, y);
                case (#Special(x) , #Special(y))  SpecialLiteralKind.cf(x, y);
                case (_) {
                    if (x == y) return #equal;
                    #notEqual;
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
        public let cf : Compare.Cf<HexLiteralKind> = func (x : HexLiteralKind, y : HexLiteralKind) : Compare.Order {
            if (x == y) return #equal;
            #notEqual;
        };

        public func digits(kind : HexLiteralKind) : Nat = switch (kind) {
            case (#X)            2;
            case (#UnicodeShort) 4;
            case (#UnicodeLong)  8;
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
        public let cf : Compare.Cf<SpecialLiteralKind> = func (x : SpecialLiteralKind, y : SpecialLiteralKind) : Compare.Order {
            if (x == y) return #equal;
            #notEqual;
        };
    };

    public type Class = {
        #Unicode   : ClassUnicode;
        #Perl      : ClassPerl;
        #Bracketed : ClassBracketed;
    };

    public module Class = {
        public let cf : Compare.Cf<Class> = func (x : Class, y : Class) : Compare.Order {
            switch (x, y) {
                case (#Unicode(x)  , #Unicode(y))   ClassUnicode.cf(x, y);
                case (#Perl(x)     , #Perl(y))      ClassPerl.cf(x, y);
                case (#Bracketed(x), #Bracketed(y)) ClassBracketed.cf(x, y);
                case (_) #notEqual;
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

    public module ClassType = {
        public func cf<T>(x : ClassType<T>, y : ClassType<T>, cf : Compare.Cf<T>) : Compare.Order {
            switch (Span.cf(x.span, y.span)) {
                case (#equal) switch (cf(x.kind, y.kind)) {
                    case (#equal) {
                        if (x.negated == y.negated) return #equal;
                        #notEqual;
                    };
                    case (n) n;
                };
                case (n) n;
            };
        };
    };

    public type ClassUnicode = ClassType<ClassUnicodeKind>;

    public module ClassUnicode = {
        public let cf : Compare.Cf<ClassUnicode> = func (x : ClassUnicode, y : ClassUnicode) : Compare.Order = ClassType.cf(x, y, ClassUnicodeKind.cf);
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
        public let cf : Compare.Cf<ClassUnicodeKind> = func (x : ClassUnicodeKind, y : ClassUnicodeKind) : Compare.Order {
            switch (x, y) {
                case (#OneLetter(x), #OneLetter(y)) Char.cf(x, y);
                case (#Named(x)    , #Named(y))     Text.cf(x, y);
                case (#NamedValue(x), #NamedValue(y)) {
                    switch (ClassUnicodeOpKind.cf(x.op, y.op)) {
                        case (#equal) switch (Text.cf(x.name, y.name)) {
                            case (#equal) Text.cf(x.value, y.value);
                            case (n) n;
                        };
                        case (n) n;
                    }
                };
                case (_) #notEqual;
            }
        };
    };

    public type ClassUnicodeOpKind = {
        #Equal;
        #Colon;
        #NotEqual;
    };

    public module ClassUnicodeOpKind = {
        public let cf : Compare.Cf<ClassUnicodeOpKind> = func (x : ClassUnicodeOpKind, y : ClassUnicodeOpKind) : Compare.Order {
            if (x == y) return #equal;
            #notEqual;
        };
    };

    public type ClassAscii = ClassType<ClassAsciiKind>;

    public module ClassAscii = {
        public let cf : Compare.Cf<ClassAscii> = func (x : ClassAscii, y : ClassAscii) : Compare.Order = ClassType.cf(x, y, ClassAsciiKind.cf);
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
        public let cf : Compare.Cf<ClassAsciiKind> = func (x : ClassAsciiKind, y : ClassAsciiKind) : Compare.Order {
            if (x == y) return #equal;
            return #notEqual;
        };
    };

    public type ClassPerl = ClassType<ClassPerlKind>;

    public module ClassPerl = {
        public let cf : Compare.Cf<ClassPerl> = func (x : ClassPerl, y : ClassPerl) : Compare.Order = ClassType.cf(x, y, ClassPerlKind.cf);
    };

    public type ClassPerlKind = {
        #Digit;
        #Space;
        #Word;
    };

    public module ClassPerlKind = {
        public let cf : Compare.Cf<ClassPerlKind> = func (x : ClassPerlKind, y : ClassPerlKind) : Compare.Order {
            if (x == y) return #equal;
            #notEqual;
        };
    };

    public type ClassBracketed = ClassType<ClassSet>;

    public module ClassBracketed = {
        public let cf : Compare.Cf<ClassBracketed> = func (x : ClassBracketed, y : ClassBracketed) : Compare.Order = ClassType.cf(x, y, ClassSet.cf);
    };

    public type ClassSet = {
        #Item     : ClassSetItem;
        #BinaryOp : ClassSetBinaryOp;
    };

    public module ClassSet = {
        public let cf : Compare.Cf<ClassSet> = func (x : ClassSet, y : ClassSet) : Compare.Order {
            switch (x, y) {
                case (#Item(x)    , #Item(y))     ClassSetItem.cf(x, y);
                case (#BinaryOp(x), #BinaryOp(y)) ClassSetBinaryOp.cf(x, y);
                case (_) #notEqual;
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
        public let cf : Compare.Cf<ClassSetItem> = func (x : ClassSetItem, y : ClassSetItem) : Compare.Order {
            switch (x, y) {
                case (#Empty(x)    , #Empty(y))     Span.cf(x, y);
                case (#Literal(x)  , #Literal(y))   Literal.cf(x, y);
                case (#Range(x)    , #Range(y))     ClassSetRange.cf(x, y);
                case (#Ascii(x)    , #Ascii(y))     ClassAscii.cf(x, y);
                case (#Unicode(x)  , #Unicode(y))   ClassUnicode.cf(x, y);
                case (#Perl(x)     , #Perl(y))      ClassPerl.cf(x, y);
                case (#Bracketed(x), #Bracketed(y)) ClassBracketed.cf(x, y);
                case (#Union(x)    , #Union(y))     ClassSetUnion.cf(x, y);
                case (_) #notEqual;
            };
        };
    };

    public type ClassSetRange = {
        span  : Span;
        start : Literal;
        end   : Literal;
    };

    public module ClassSetRange = {
        public let cf : Compare.Cf<ClassSetRange> = func (x : ClassSetRange, y : ClassSetRange) : Compare.Order {
            switch (Span.cf(x.span, y.span)) {
                case (#equal) switch (Literal.cf(x.start, y.start)) {
                    case (#equal) Literal.cf(x.end, y.end);
                    case (n) n;
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
        public let cf : Compare.Cf<ClassSetUnion> = func (x : ClassSetUnion, y : ClassSetUnion) : Compare.Order {
            switch (Span.cf(x.span, y.span)) {
                case (#equal) {
                    let oS = Nat.cf(x.items.size(), y.items.size());
                    if (Compare.Order.neq(oS)) return oS;
                    for (k in x.items.keys()) {
                        switch (ClassSetItem.cf(x.items[k], y.items[k])) {
                            case (#equal) {};
                            case (n) return n;
                        };
                    };
                    #equal;
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
        public let cf : Compare.Cf<ClassSetBinaryOp> = func (x : ClassSetBinaryOp, y : ClassSetBinaryOp) : Compare.Order {
            switch (Span.cf(x.span, y.span)) {
                case (#equal) switch (ClassSetBinaryOpKind.cf(x.kind, y.kind)) {
                    case (#equal) switch (ClassSet.cf(x.lhs, y.lhs)) {
                        case (#equal) ClassSet.cf(x.rhs, y.rhs);
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
        public let cf : Compare.Cf<ClassSetBinaryOpKind> = func (x : ClassSetBinaryOpKind, y : ClassSetBinaryOpKind) : Compare.Order {
            if (x == y) return #equal;
            #notEqual;
        };
    };

    public type Assertion = {
        span : Span;
        kind : AssertionKind;
    };

    public module Assertion = {
        public let cf : Compare.Cf<Assertion> = func (x : Assertion, y : Assertion) : Compare.Order {
            switch (Span.cf(x.span, y.span)) {
                case (#equal) AssertionKind.cf(x.kind, y.kind);
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
        public let cf : Compare.Cf<AssertionKind> = func (x : AssertionKind, y : AssertionKind) : Compare.Order {
            if (x == y) return #equal;
            #notEqual;
        };
    };

    public type Repetition = {
        span   : Span;
        op     : RepetitionOp;
        greedy : Bool;
        ast    : AST;
    };

    public module Repetition = {
        public let cf : Compare.Cf<Repetition> = func (x : Repetition, y : Repetition) : Compare.Order {
            switch (Span.cf(x.span, y.span)) {
                case (#equal) switch (RepetitionOp.cf(x.op, y.op)) {
                    case (#equal) {
                        if (x.greedy != y.greedy) return #notEqual;
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
        public let cf : Compare.Cf<RepetitionOp> = func (x : RepetitionOp, y : RepetitionOp) : Compare.Order {
            switch (Span.cf(x.span, y.span)) {
                case (#equal) RepetitionKind.cf(x.kind, y.kind);
                case (n) n;
            };
        };
    };

    public type RepetitionKind = {
        #ZeroOrOne;
        #ZeroOrMore;
        #OneOrMore;
        #Range : RepetitionRange;
    };

    public module RepetitionKind = {
        public let cf : Compare.Cf<RepetitionKind> = func (x : RepetitionKind, y : RepetitionKind) : Compare.Order {
            switch (x, y) {
                case (#Range(x)  , #Range(y))   RepetitionRange.cf(x, y);
                case (#ZeroOrOne , #ZeroOrOne)  #equal;
                case (#ZeroOrMore, #ZeroOrMore) #equal;
                case (#OneOrMore , #OneOrMore)  #equal;
                case (_) #notEqual;
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

        public let cf : Compare.Cf<RepetitionRange> = func (x : RepetitionRange, y : RepetitionRange) : Compare.Order {
            switch (x, y) {
                case (#Exactly(x), #Exactly(y)) Nat.Nat32.cf(x, y);
                case (#AtLeast(x), #AtLeast(y)) Nat.Nat32.cf(x, y);
                case (#Bounded(x), #Bounded(y)) {
                    switch (Nat.Nat32.cf(x.0, y.0)) {
                        case (#equal) Nat.Nat32.cf(x.1, y.1);
                        case (n) n;
                    };
                };
                case (_) #notEqual;
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

        public let cf : Compare.Cf<Group> = func (x : Group, y : Group) : Compare.Order {
            switch (Span.cf(x.span, y.span)) {
                case (#equal) switch (GroupKind.cf(x.kind, y.kind)) {
                    case (#equal) AST.cf(x.ast, y.ast);
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
        public let cf : Compare.Cf<GroupKind> = func (x : GroupKind, y : GroupKind) : Compare.Order {
            switch (x, y) {
                case (#CaptureIndex(x), #CaptureIndex(y)) Nat.Nat32.cf(x, y);
                case (#CaptureName(x) , #CaptureName(y))  CaptureName.cf(x, y);
                case (#NonCapturing(x), #NonCapturing(y)) Flags.cf(x, y);
                case (_) #notEqual;
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

        public let cf : Compare.Cf<CaptureName> = func (x : CaptureName, y : CaptureName) : Compare.Order {
            switch (Span.cf(x.span, y.span)) {
                case (#equal) {
                    let o = Text.cf(x.name, y.name);
                    if (Compare.Order.neq(o)) return o;
                    Nat.Nat32.cf(x.index, y.index);
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

        public let cf : Compare.Cf<SetFlags> = func (x : SetFlags, y : SetFlags) : Compare.Order {
            switch (Span.cf(x.span, y.span)) {
                case (#equal) Flags.cf(x.flags, y.flags);
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

        public let cf : Compare.Cf<Flags> = func (x : Flags, y : Flags) : Compare.Order {
            switch (Span.cf(x.span, y.span)) {
                case (#equal) {
                    let oS = Nat.cf(x.items.size(), y.items.size());
                    if (Compare.Order.neq(oS)) return oS;

                    for (k in x.items.keys()) {
                        switch (FlagsItem.cf(x.items[k], y.items[k])) {
                            case (#equal) {};
                            case (n) return n;
                        };
                    };
                    #equal;
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

        public let cf : Compare.Cf<FlagsItem> = func (x : FlagsItem, y : FlagsItem) : Compare.Order {
            switch (Span.cf(x.span, y.span)) {
                case (#equal) FlagsItemKind.cf(x.kind, y.kind);
                case (n) n;
            };
        };
    };

    public type FlagsItemKind = {
        #Negation;
        #Flag : Flag;
    };

    public module FlagsItemKind = {
        public let cf : Compare.Cf<FlagsItemKind> = func (x : FlagsItemKind, y : FlagsItemKind) : Compare.Order {
            switch (x, y) {
                case (#Flag(x) , #Flag(y))  Flag.cf(x, y);
                case (#Negation, #Negation) #equal;
                case (_) #notEqual;
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
        public let cf : Compare.Cf<Flag> = func (x : Flag, y : Flag) : Compare.Order {
            if (x == y) return #equal;
            #notEqual;
        };
    };
};
