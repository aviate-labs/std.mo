import Compare "../Compare";

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

    public type Error = {
        kind    : ErrorKind;
        pattern : Text;
        span    : Span;
    };

    public type ErrorKind = {
        #GroupNameEmpty;
        #GroupNameInvalid;
        #GroupNameUnexpectedEOF;
        #GroupUnclosed;

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

    public type GroupKind = {
        #CaptureIndex : Nat32;
        #CaptureName  : CaptureName;
        #NonCapturing : Flags;
    };

    public type CaptureName = {
        span  : Span;
        name  : Text;
        index : Nat32;
    };

    public type SetFlags = {
        span  : Span;
        flags : Flags;
    };

    public type Flags = {
        span  : Span;
        items : [FlagsItem];
    };

    public type FlagsItem = {
        span : Span;
        kind : FlagsItemKind;
    };

    public module FlagsItem = {
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
