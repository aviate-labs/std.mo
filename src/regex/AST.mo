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
        public func cmp(x : AST, y : AST) : Compare.Ordering {
            switch (x, y) {
                case (#Empty(x)      , #Empty(y))       Span.cmp(x, y);
                case (#Flags(x)      , #Flags(y))       SetFlags.cmp(x, y);
                case (#Literal(x)    , #Literal(y))     Literal.cmp(x, y);
                case (#Dot(x)        , #Dot(y))         Span.cmp(x, y);
                case (#Assertion(x)  , #Assertion(y))   Assertion.cmp(x, y);
                case (#Class(x)      , #Class(y))       Class.cmp(x, y);
                case (#Repetition(x) , #Repetition(y))  Repetition.cmp(x, y);
                case (#Group(x)      , #Group(y))       Group.cmp(x, y);
                case (#Alternation(x), #Alternation(y)) Alternation.cmp(x, y);
                case (#Concat(x)     , #Concat(y))      Concat.cmp(x, y);

                case (#Empty(_)      , _) #less;
                case (#Flags(_)      , _) #less;
                case (#Literal(_)    , _) #less;
                case (#Dot(_)        , _) #less;
                case (#Assertion(_)  , _) #less;
                case (#Class(_)      , _) #less;
                case (#Repetition(_) , _) #less;
                case (#Group(_)      , _) #less;
                case (#Alternation(_), _) #less;

                case (_, _) #greater;
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

        public let eq : Compare.Eq<Error> = func (x : Error, y : Error) : Bool {
            switch (ErrorKind.eq(x.kind, y.kind)) {
                case (true) Compare.Ordering.eq(Span.cmp(x.span, y.span));
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
                    if (ErrorKind.eq(e.kind, from)) return #err({
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
        #EscapeHexInvalid;

        #DecimalEmpty;
    };

    public module ErrorKind = {
        public let eq : Compare.Eq<ErrorKind> = func (x : ErrorKind, y : ErrorKind) : Bool {
            switch (x, y) {
                case (#FlagRepeatedNegation(x), #FlagRepeatedNegation(y)) Compare.Ordering.eq(Span.cmp(x.original, y.original));
                case (#FlagDuplicate(x)       , #FlagDuplicate(y))        Compare.Ordering.eq(Span.cmp(x.original, y.original));
                case (_) x == y;
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

        public let cmp : Compare.Ord<Position> = func (x : Position, y : Position) : Compare.Ordering = Compare.Nat.cmp(x.offset, y.offset);
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

        public let cmp : Compare.Ord<Span> = func (x : Span, y : Span) : Compare.Ordering {
            switch (Position.cmp(x.start, y.start)) {
                case (#equal) Position.cmp(x.end, y.end);
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
        public let cmp : Compare.Ord<Alternation> = func (x : Alternation, y : Alternation) : Compare.Ordering {
            switch (Span.cmp(x.span, y.span)) {
                case (#equal) {
                    let oS = Compare.Nat.cmp(x.asts.size(), y.asts.size());
                    if (Compare.Ordering.ne(oS)) return oS;

                    for (k in x.asts.keys()) {
                        switch (AST.cmp(x.asts[k], y.asts[k])) {
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
        public let cmp : Compare.Ord<Concat> = func (x : Concat, y : Concat) : Compare.Ordering {
            switch (Span.cmp(x.span, y.span)) {
                case (#equal) {
                    let oS = Compare.Nat.cmp(x.asts.size(), y.asts.size());
                    if (Compare.Ordering.ne(oS)) return oS;

                    for (k in x.asts.keys()) {
                        switch (AST.cmp(x.asts[k], y.asts[k])) {
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

        public let cmp : Compare.Ord<Literal> = func (x : Literal, y : Literal) : Compare.Ordering {
            switch (Span.cmp(x.span, y.span)) {
                case (#equal) switch (LiteralKind.cmp(x.kind, y.kind)) {
                    case (#equal) Compare.Char.cmp(x.c, y.c);
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
        public let cmp : Compare.Ord<LiteralKind> = func (x : LiteralKind, y : LiteralKind) : Compare.Ordering {
            switch (x, y) {
                case (#Verbatim   , #Verbatim)    #equal;
                case (#Punctuation, #Punctuation) #equal;
                case (#Octal      , #Octal)       #equal;
                case (#HexFixed(x), #HexFixed(y)) HexLiteralKind.cmp(x, y);
                case (#HexBrace(x), #HexBrace(y)) HexLiteralKind.cmp(x, y);
                case (#Special(x) , #Special(y))  SpecialLiteralKind.cmp(x, y);

                case (#Verbatim   , _) #less;
                case (#Punctuation, _) #less;
                case (#Octal      , _) #less;
                case (#HexFixed(x), _) #less;
                case (#HexBrace(x), _) #less;

                case (_, _) #greater;
            };
        };
    };

    public type HexLiteralKind = {
        #X;
        #UnicodeShort;
        #UnicodeLong;
    };
    
    public module HexLiteralKind = {
        public let cmp : Compare.Ord<HexLiteralKind> = func (x : HexLiteralKind, y : HexLiteralKind) : Compare.Ordering = switch (x, y) {
            case (#X           , #X)            #equal;
            case (#UnicodeShort, #UnicodeShort) #equal;
            case (#UnicodeLong , #UnicodeLong)  #equal;

            case (#X           , _) #less;
            case (#UnicodeShort, _) #less;

            case (_, _) #greater; 
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
        public let cmp : Compare.Ord<SpecialLiteralKind> = func (x : SpecialLiteralKind, y : SpecialLiteralKind) : Compare.Ordering = switch (x, y) {
            case (#Bell          , #Bell) #equal;
            case (#FormFeed      , #FormFeed) #equal;
            case (#Tab           , #Tab) #equal;
            case (#LineFeed      , #LineFeed) #equal;
            case (#CarriageReturn, #CarriageReturn) #equal;
            case (#VerticalTab   , #VerticalTab) #equal;
            case (#Space         , #Space) #equal;

            case (#Bell          , _) #less;
            case (#FormFeed      , _) #less;
            case (#Tab           , _) #less;
            case (#LineFeed      , _) #less;
            case (#CarriageReturn, _) #less;
            case (#VerticalTab   , _) #less;

            case (_, _) #greater;
        };
    };

    public type Class = {
        #Unicode   : ClassUnicode;
        #Perl      : ClassPerl;
        #Bracketed : ClassBracketed;
    };

    public module Class = {
        public let cmp : Compare.Ord<Class> = func (x : Class, y : Class) : Compare.Ordering {
            switch (x, y) {
                case (#Unicode(x)  , #Unicode(y))   ClassUnicode.cmp(x, y);
                case (#Perl(x)     , #Perl(y))      ClassPerl.cmp(x, y);
                case (#Bracketed(x), #Bracketed(y)) ClassBracketed.cmp(x, y);

                case (#Unicode(_), _) #less;
                case (#Perl(_)   , _) #less;

                case (_, _) #greater;
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
        public func cmp<T>(x : ClassType<T>, y : ClassType<T>, cf : Compare.Ord<T>) : Compare.Ordering {
            switch (Span.cmp(x.span, y.span)) {
                case (#equal) switch (cf(x.kind, y.kind)) {
                    case (#equal) Compare.Bool.cmp(x.negated, y.negated);
                    case (n) n;
                };
                case (n) n;
            };
        };
    };

    public type ClassUnicode = ClassType<ClassUnicodeKind>;

    public module ClassUnicode = {
        public let cmp : Compare.Ord<ClassUnicode> = func (x : ClassUnicode, y : ClassUnicode) : Compare.Ordering = ClassType.cmp(x, y, ClassUnicodeKind.cmp);
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
        public let cmp : Compare.Ord<ClassUnicodeKind> = func (x : ClassUnicodeKind, y : ClassUnicodeKind) : Compare.Ordering {
            switch (x, y) {
                case (#OneLetter(x), #OneLetter(y)) Compare.Char.cmp(x, y);
                case (#Named(x)    , #Named(y))     Compare.Text.cmp(x, y);
                case (#NamedValue(x), #NamedValue(y)) {
                    switch (ClassUnicodeOpKind.cmp(x.op, y.op)) {
                        case (#equal) switch (Compare.Text.cmp(x.name, y.name)) {
                            case (#equal) Compare.Text.cmp(x.value, y.value);
                            case (n) n;
                        };
                        case (n) n;
                    }
                };

                case (#OneLetter(_), _) #less;
                case (#Named(_)    , _) #less;

                case (_, _) #greater;
            }
        };
    };

    public type ClassUnicodeOpKind = {
        #Equal;
        #Colon;
        #NotEqual;
    };

    public module ClassUnicodeOpKind = {
        public let cmp : Compare.Ord<ClassUnicodeOpKind> = func (x : ClassUnicodeOpKind, y : ClassUnicodeOpKind) : Compare.Ordering = switch(x, y) {
            case (#Equal   , #Equal)    #equal;
            case (#Colon   , #Colon)    #equal;
            case (#NotEqual, #NotEqual) #equal;

            case (#Equal, _) #less;
            case (#Colon, _) #less;

            case (_, _) #greater
        };
    };

    public type ClassAscii = ClassType<ClassAsciiKind>;

    public module ClassAscii = {
        public let cmp : Compare.Ord<ClassAscii> = func (x : ClassAscii, y : ClassAscii) : Compare.Ordering = ClassType.cmp(x, y, ClassAsciiKind.cmp);
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
        public let cmp : Compare.Ord<ClassAsciiKind> = func (x : ClassAsciiKind, y : ClassAsciiKind) : Compare.Ordering = switch (x, y) {
            case (#Alnum , #Alnum)  #equal;
            case (#Alpha , #Alpha)  #equal;
            case (#Ascii , #Ascii)  #equal;
            case (#Blank , #Blank)  #equal;
            case (#Cntrl , #Cntrl)  #equal;
            case (#Digit , #Digit)  #equal;
            case (#Graph , #Graph)  #equal;
            case (#Lower , #Lower)  #equal;
            case (#Print , #Print)  #equal;
            case (#Punct , #Punct)  #equal;
            case (#Space , #Space)  #equal;
            case (#Upper , #Upper)  #equal;
            case (#Word  , #Word)   #equal;
            case (#Xdigit, #Xdigit) #equal;

            case (#Alnum , _) #less;
            case (#Alpha , _) #less;
            case (#Ascii , _) #less;
            case (#Blank , _) #less;
            case (#Cntrl , _) #less;
            case (#Digit , _) #less;
            case (#Graph , _) #less;
            case (#Lower , _) #less;
            case (#Print , _) #less;
            case (#Punct , _) #less;
            case (#Space , _) #less;
            case (#Upper , _) #less;
            case (#Word  , _) #less;

            case (_, _) #greater;
        };
    };

    public type ClassPerl = ClassType<ClassPerlKind>;

    public module ClassPerl = {
        public let cmp : Compare.Ord<ClassPerl> = func (x : ClassPerl, y : ClassPerl) : Compare.Ordering = ClassType.cmp(x, y, ClassPerlKind.cmp);
    };

    public type ClassPerlKind = {
        #Digit;
        #Space;
        #Word;
    };

    public module ClassPerlKind = {
        public let cmp : Compare.Ord<ClassPerlKind> = func (x : ClassPerlKind, y : ClassPerlKind) : Compare.Ordering = switch (x, y) {
            case (#Digit, #Digit) #equal;
            case (#Space, #Space) #equal;
            case (#Word , #Word)  #equal;

            case (#Digit, _) #less;
            case (#Space, _) #less;
            
            case (_, _) #greater;
        };
    };

    public type ClassBracketed = ClassType<ClassSet>;

    public module ClassBracketed = {
        public let cmp : Compare.Ord<ClassBracketed> = func (x : ClassBracketed, y : ClassBracketed) : Compare.Ordering = ClassType.cmp(x, y, ClassSet.cmp);
    };

    public type ClassSet = {
        #Item     : ClassSetItem;
        #BinaryOp : ClassSetBinaryOp;
    };

    public module ClassSet = {
        public let cmp : Compare.Ord<ClassSet> = func (x : ClassSet, y : ClassSet) : Compare.Ordering {
            switch (x, y) {
                case (#Item(x)    , #Item(y))     ClassSetItem.cmp(x, y);
                case (#BinaryOp(x), #BinaryOp(y)) ClassSetBinaryOp.cmp(x, y);

                case (#Item(_), _) #less;

                case (_, _) #greater;
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
        public let cmp : Compare.Ord<ClassSetItem> = func (x : ClassSetItem, y : ClassSetItem) : Compare.Ordering {
            switch (x, y) {
                case (#Empty(x)    , #Empty(y))     Span.cmp(x, y);
                case (#Literal(x)  , #Literal(y))   Literal.cmp(x, y);
                case (#Range(x)    , #Range(y))     ClassSetRange.cmp(x, y);
                case (#Ascii(x)    , #Ascii(y))     ClassAscii.cmp(x, y);
                case (#Unicode(x)  , #Unicode(y))   ClassUnicode.cmp(x, y);
                case (#Perl(x)     , #Perl(y))      ClassPerl.cmp(x, y);
                case (#Bracketed(x), #Bracketed(y)) ClassBracketed.cmp(x, y);
                case (#Union(x)    , #Union(y))     ClassSetUnion.cmp(x, y);

                case (#Empty(x)    , _) #less;
                case (#Literal(x)  , _) #less;
                case (#Range(x)    , _) #less;
                case (#Ascii(x)    , _) #less;
                case (#Unicode(x)  , _) #less;
                case (#Perl(x)     , _) #less;
                case (#Bracketed(x), _) #less;

                case (_, _) #greater;
            };
        };
    };

    public type ClassSetRange = {
        span  : Span;
        start : Literal;
        end   : Literal;
    };

    public module ClassSetRange = {
        public let cmp : Compare.Ord<ClassSetRange> = func (x : ClassSetRange, y : ClassSetRange) : Compare.Ordering {
            switch (Span.cmp(x.span, y.span)) {
                case (#equal) switch (Literal.cmp(x.start, y.start)) {
                    case (#equal) Literal.cmp(x.end, y.end);
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
        public let cmp : Compare.Ord<ClassSetUnion> = func (x : ClassSetUnion, y : ClassSetUnion) : Compare.Ordering {
            switch (Span.cmp(x.span, y.span)) {
                case (#equal) {
                    let oS = Compare.Nat.cmp(x.items.size(), y.items.size());
                    if (Compare.Ordering.ne(oS)) return oS;
                    for (k in x.items.keys()) {
                        switch (ClassSetItem.cmp(x.items[k], y.items[k])) {
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
        public let cmp : Compare.Ord<ClassSetBinaryOp> = func (x : ClassSetBinaryOp, y : ClassSetBinaryOp) : Compare.Ordering {
            switch (Span.cmp(x.span, y.span)) {
                case (#equal) switch (ClassSetBinaryOpKind.cmp(x.kind, y.kind)) {
                    case (#equal) switch (ClassSet.cmp(x.lhs, y.lhs)) {
                        case (#equal) ClassSet.cmp(x.rhs, y.rhs);
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
        public let cmp : Compare.Ord<ClassSetBinaryOpKind> = func (x : ClassSetBinaryOpKind, y : ClassSetBinaryOpKind) : Compare.Ordering = switch (x, y) {
            case (#Intersection       , #Intersection)        #equal;
            case (#Difference         , #Difference)          #equal;
            case (#SymmetricDifference, #SymmetricDifference) #equal;

            case (#Intersection, _) #less;
            case (#Difference  , _) #less;
            
            case (_, _) #greater;
        };
    };

    public type Assertion = {
        span : Span;
        kind : AssertionKind;
    };

    public module Assertion = {
        public let cmp : Compare.Ord<Assertion> = func (x : Assertion, y : Assertion) : Compare.Ordering {
            switch (Span.cmp(x.span, y.span)) {
                case (#equal) AssertionKind.cmp(x.kind, y.kind);
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
        public let cmp : Compare.Ord<AssertionKind> = func (x : AssertionKind, y : AssertionKind) : Compare.Ordering = switch (x, y) {
            case (#StartLine      , #StartLine)       #equal;
            case (#EndLine        , #EndLine)         #equal;
            case (#StartText      , #StartText)       #equal;
            case (#EndText        , #EndText)         #equal;
            case (#WordBoundary   , #WordBoundary)    #equal;
            case (#NotWordBoundary, #NotWordBoundary) #equal;

            case (#StartLine      , _) #less;
            case (#EndLine        , _) #less;
            case (#StartText      , _) #less;
            case (#EndText        , _) #less;
            case (#WordBoundary   , _) #less;

            case (_, _) #greater;
        };
    };

    public type Repetition = {
        span   : Span;
        op     : RepetitionOp;
        greedy : Bool;
        ast    : AST;
    };

    public module Repetition = {
        public let cmp : Compare.Ord<Repetition> = func (x : Repetition, y : Repetition) : Compare.Ordering {
            switch (Span.cmp(x.span, y.span)) {
                case (#equal) switch (RepetitionOp.cmp(x.op, y.op)) {
                    case (#equal) {
                        let o = Compare.Bool.cmp(x.greedy, y.greedy);
                        if (Compare.Ordering.ne(o)) return o;
                        AST.cmp(x.ast, y.ast);
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
        public let cmp : Compare.Ord<RepetitionOp> = func (x : RepetitionOp, y : RepetitionOp) : Compare.Ordering {
            switch (Span.cmp(x.span, y.span)) {
                case (#equal) RepetitionKind.cmp(x.kind, y.kind);
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
        public let cmp : Compare.Ord<RepetitionKind> = func (x : RepetitionKind, y : RepetitionKind) : Compare.Ordering {
            switch (x, y) {
                case (#Range(x)  , #Range(y))   RepetitionRange.cmp(x, y);
                case (#ZeroOrOne , #ZeroOrOne)  #equal;
                case (#ZeroOrMore, #ZeroOrMore) #equal;
                case (#OneOrMore , #OneOrMore)  #equal;

                case (#Range(_)  , _) #less;
                case (#ZeroOrOne , _) #less;
                case (#ZeroOrMore, _) #less;

                case (_, _) #greater;
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

        public let cmp : Compare.Ord<RepetitionRange> = func (x : RepetitionRange, y : RepetitionRange) : Compare.Ordering {
            switch (x, y) {
                case (#Exactly(x), #Exactly(y)) Compare.Nat32.cmp(x, y);
                case (#AtLeast(x), #AtLeast(y)) Compare.Nat32.cmp(x, y);
                case (#Bounded(x), #Bounded(y)) {
                    switch (Compare.Nat32.cmp(x.0, y.0)) {
                        case (#equal) Compare.Nat32.cmp(x.1, y.1);
                        case (n) n;
                    };
                };

                case (#Exactly(_), _) #less;
                case (#AtLeast(_), _) #less;

                case (_, _) #greater; 
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

        public let cmp : Compare.Ord<Group> = func (x : Group, y : Group) : Compare.Ordering {
            switch (Span.cmp(x.span, y.span)) {
                case (#equal) switch (GroupKind.cmp(x.kind, y.kind)) {
                    case (#equal) AST.cmp(x.ast, y.ast);
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
        public let cmp : Compare.Ord<GroupKind> = func (x : GroupKind, y : GroupKind) : Compare.Ordering {
            switch (x, y) {
                case (#CaptureIndex(x), #CaptureIndex(y)) Compare.Nat32.cmp(x, y);
                case (#CaptureName(x) , #CaptureName(y))  CaptureName.cmp(x, y);
                case (#NonCapturing(x), #NonCapturing(y)) Flags.cmp(x, y);

                case (#CaptureIndex(_), _) #less;
                case (#CaptureName(_) , _) #less;

                case (_, _) #greater;
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

        public let cmp : Compare.Ord<CaptureName> = func (x : CaptureName, y : CaptureName) : Compare.Ordering {
            switch (Span.cmp(x.span, y.span)) {
                case (#equal) {
                    let o = Compare.Text.cmp(x.name, y.name);
                    if (Compare.Ordering.ne(o)) return o;
                    Compare.Nat32.cmp(x.index, y.index);
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

        public let cmp : Compare.Ord<SetFlags> = func (x : SetFlags, y : SetFlags) : Compare.Ordering {
            switch (Span.cmp(x.span, y.span)) {
                case (#equal) Flags.cmp(x.flags, y.flags);
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

        public let cmp : Compare.Ord<Flags> = func (x : Flags, y : Flags) : Compare.Ordering {
            switch (Span.cmp(x.span, y.span)) {
                case (#equal) {
                    let oS = Compare.Nat.cmp(x.items.size(), y.items.size());
                    if (Compare.Ordering.ne(oS)) return oS;

                    for (k in x.items.keys()) {
                        switch (FlagsItem.cmp(x.items[k], y.items[k])) {
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

        public let cmp : Compare.Ord<FlagsItem> = func (x : FlagsItem, y : FlagsItem) : Compare.Ordering {
            switch (Span.cmp(x.span, y.span)) {
                case (#equal) FlagsItemKind.cmp(x.kind, y.kind);
                case (n) n;
            };
        };
    };

    public type FlagsItemKind = {
        #Negation;
        #Flag : Flag;
    };

    public module FlagsItemKind = {
        public let cmp : Compare.Ord<FlagsItemKind> = func (x : FlagsItemKind, y : FlagsItemKind) : Compare.Ordering {
            switch (x, y) {
                case (#Flag(x) , #Flag(y))  Flag.cmp(x, y);
                case (#Negation, #Negation) #equal;

                case (#Flag(_), _) #less;

                case (_, _) #greater;
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
        public let cmp : Compare.Ord<Flag> = func (x : Flag, y : Flag) : Compare.Ordering = switch (x, y) {
            case (#CaseInsensitive  , #CaseInsensitive)   #equal;
            case (#MultiLine        , #MultiLine)         #equal;
            case (#DotMatchesNewLine, #DotMatchesNewLine) #equal;
            case (#SwapGreed        , #SwapGreed)         #equal;
            case (#Unicode          , #Unicode)           #equal;
            case (#IgnoreWhitespace , #IgnoreWhitespace)  #equal;

            case (#CaseInsensitive  , _) #less;
            case (#MultiLine        , _) #less;
            case (#DotMatchesNewLine, _) #less;
            case (#SwapGreed        , _) #less;
            case (#Unicode          , _) #less;

            case (_, _) #greater;
        };
    };
};
