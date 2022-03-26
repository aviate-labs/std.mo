import Prim "mo:⛔";

import Compare "../Compare";
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
            // TODO!
            return 0;
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
    };

    public type ErrorKind = {
        #GroupNameEmpty;
        #GroupNameInvalid;
        #GroupNameDuplicate;
        #GroupNameUnexpectedEOF;
        #GroupUnclosed;
        #GroupUnopened;

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

        #UnsupportedLookAround;

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

    public type Concat = {
        span : Span;
        asts : [AST];
    };

    public module Concat = {
        public func mut(c : Concat) : ConcatVar = {
            var span = c.span;
            var asts = Stack.init<AST>(16);
        };
    };

    public type ConcatVar = {
        var span : Span;
        var asts : Stack.Stack<AST>;
    };

    public module ConcatVar = {
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

    public type LiteralKind = {
        #Verbatim;
        #Punctuation;
        #Octal;
        #HexFixed : HexLiteralKind;
        #HexBrace : HexLiteralKind;
        #Special  : SpecialLiteralKind;
    };

    public type HexLiteralKind = {
        #X;
        #UnicodeShort;
        #UnicodeLong;
    };

    public type SpecialLiteralKind = {
        #Bell; #FormFeed; #Tab; #LineFeed; #CarriageReturn; #VerticalTab; #Space;
    };

    public type Class = {
        #Unicode   : ClassUnicode;
        #Perl      : ClassPerl;
        #Bracketed : ClassBracketed;
    };

    public type ClassType<T> = {
        span : Span;
        kind : T;
        negated : Bool;
    };

    public type ClassUnicode = ClassType<ClassUnicodeKind>;

    public type ClassUnicodeKind = {
        #OneLetter  : Char;
        #Named      : Text;
        #NamedValue : {
            op : ClassUnicodeOpKind;
            name : Text;
            value : Text;
        };
    };

    public type ClassUnicodeOpKind = {
        #Equal; #Colon; #NotEqual;
    };

    public type ClassAscii = ClassType<ClassAsciiKind>;

    public type ClassAsciiKind = {
        #Alnum; #Alpha; #Ascii; #Blank; #Cntrl; #Digit; #Graph; #Lower;
        #Print; #Punct; #Space; #Upper; #Word; #Xdigit;
    };

    public type ClassPerl = ClassType<ClassPerlKind>;

    public type ClassPerlKind = {
        #Digit; #Space; #Word;
    };

    public type ClassBracketed = ClassType<ClassSet>;

    public type ClassSet = {
        #Item     : ClassSetItem;
        #BinaryOp : ClassSetBinaryOp;
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

    public type ClassSetRange = {
        span  : Span;
        start : Literal;
        end   : Literal;
    };

    public type ClassSetUnion = {
        span  : Span;
        items : [ClassSetItem];
    };

    public type ClassSetBinaryOp = {
        span : Span;
        kind : ClassSetBinaryOpKind;
        lhs  : ClassSet;
        rhs  : ClassSet;
    };

    public type ClassSetBinaryOpKind = {
        #Intersection; #Difference; #SymmetricDifference;
    };

    public type Assertion = {
        span : Span;
        kind : AssertionKind;
    };

    public type AssertionKind = {
        #StartLine; #EndLine; #StartText; #EndText; #WordBoundary; #NotWordBoundary;
    };

    public type Repetition = {
        span   : Span;
        op     : RepetitionOp;
        greedy : Bool;
        ast    : AST;
    };

    public type RepetitionOp = {
        span : Span;
        kind : RepetitionKind;
    };

    public type RepetitionKind = {
        #ZeroOrOne; #ZeroOrMore; #OneOrMore;
        #Range : RepetitionRange;
    };

    public type RepetitionRange = {
        #Exactly : Nat32;
        #AtLeast : Nat32;
        #Bounded : (Nat32, Nat32);
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
                case (#CaptureIndex(x), #CaptureIndex(y)) { Prim.nat32ToNat(x) - Prim.nat32ToNat(y) };
                case (#CaptureName(x), #CaptureName(y)) {
                    // TODO: lexical cf?
                    if (x == y) return 0;
                    -1;
                };
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
                case (0) switch (x.kind == y.kind) {
                    case (true)  { 0 };
                    case (false) { -1 };
                };
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
                case (#Flag(x), #Flag(y)) {
                    if (x == y) return 0;
                    -1;
                };
                case (_) {
                    if (x == y) return 0;
                    -1;
                };
            }
        };
    };

    public type Flag = {
        #CaseInsensitive; #MultiLine; #DotMatchesNewLine;
        #SwapGreed; #Unicode; #IgnoreWhitespace;
    };
};
