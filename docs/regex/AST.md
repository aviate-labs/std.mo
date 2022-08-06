# regex/AST

## Type `AST`
`type AST = {#Empty : Span; #Flags : SetFlags; #Literal : Literal; #Dot : Span; #Assertion : Assertion; #Class : Class; #Repetition : Repetition; #Group : Group; #Alternation : Alternation; #Concat : Concat}`


## Value `AST`
`let AST`


## Type `Error`
`type Error = { kind : ErrorKind; pattern : Text; span : Span }`


## Value `Error`
`let Error`


## Type `ErrorKind`
`type ErrorKind = {#GroupNameEmpty; #GroupNameInvalid; #GroupNameDuplicate; #GroupNameUnexpectedEOF; #GroupUnclosed; #GroupUnopened; #EscapeUnexpectedEOF; #UnsupportedBackReference; #GroupsEmpty; #FlagUnrecognized; #FlagDanglingNegation; #FlagRepeatedNegation : { original : Span }; #FlagUnexpectedEOF; #FlagDuplicate : { original : Span }; #RepetitionMissing; #RepetitionCountUnclosed; #RepetitionCountInvalid; #UnsupportedLookAround; #EscapeHexInvalidDigit; #EscapeHexInvalid; #DecimalEmpty}`


## Value `ErrorKind`
`let ErrorKind`


## Type `Position`
`type Position = { offset : Nat; line : Nat; column : Nat }`


## Value `Position`
`let Position`


## Type `Span`
`type Span = { start : Position; end : Position }`


## Value `Span`
`let Span`


## Type `Comment`
`type Comment = { span : Span; comment : Text }`


## Type `Alternation`
`type Alternation = { span : Span; asts : [AST] }`


## Value `Alternation`
`let Alternation`


## Type `AlternationVar`
`type AlternationVar = { var span : Span; asts : Stack.Stack<AST> }`


## Value `AlternationVar`
`let AlternationVar`


## Type `Concat`
`type Concat = { span : Span; asts : [AST] }`


## Value `Concat`
`let Concat`


## Type `ConcatVar`
`type ConcatVar = { var span : Span; asts : Stack.Stack<AST> }`


## Value `ConcatVar`
`let ConcatVar`


## Type `Literal`
`type Literal = { span : Span; kind : LiteralKind; c : Char }`


## Value `Literal`
`let Literal`


## Type `LiteralKind`
`type LiteralKind = {#Verbatim; #Punctuation; #Octal; #HexFixed : HexLiteralKind; #HexBrace : HexLiteralKind; #Special : SpecialLiteralKind}`


## Value `LiteralKind`
`let LiteralKind`


## Type `HexLiteralKind`
`type HexLiteralKind = {#X; #UnicodeShort; #UnicodeLong}`


## Value `HexLiteralKind`
`let HexLiteralKind`


## Type `SpecialLiteralKind`
`type SpecialLiteralKind = {#Bell; #FormFeed; #Tab; #LineFeed; #CarriageReturn; #VerticalTab; #Space}`


## Value `SpecialLiteralKind`
`let SpecialLiteralKind`


## Type `Class`
`type Class = {#Unicode : ClassUnicode; #Perl : ClassPerl; #Bracketed : ClassBracketed}`


## Value `Class`
`let Class`


## Type `ClassType`
`type ClassType<T> = { span : Span; kind : T; negated : Bool }`


## Value `ClassType`
`let ClassType`


## Type `ClassUnicode`
`type ClassUnicode = ClassType<ClassUnicodeKind>`


## Value `ClassUnicode`
`let ClassUnicode`


## Type `ClassUnicodeKind`
`type ClassUnicodeKind = {#OneLetter : Char; #Named : Text; #NamedValue : { op : ClassUnicodeOpKind; name : Text; value : Text }}`


## Value `ClassUnicodeKind`
`let ClassUnicodeKind`


## Type `ClassUnicodeOpKind`
`type ClassUnicodeOpKind = {#Equal; #Colon; #NotEqual}`


## Value `ClassUnicodeOpKind`
`let ClassUnicodeOpKind`


## Type `ClassAscii`
`type ClassAscii = ClassType<ClassAsciiKind>`


## Value `ClassAscii`
`let ClassAscii`


## Type `ClassAsciiKind`
`type ClassAsciiKind = {#Alnum; #Alpha; #Ascii; #Blank; #Cntrl; #Digit; #Graph; #Lower; #Print; #Punct; #Space; #Upper; #Word; #Xdigit}`


## Value `ClassAsciiKind`
`let ClassAsciiKind`


## Type `ClassPerl`
`type ClassPerl = ClassType<ClassPerlKind>`


## Value `ClassPerl`
`let ClassPerl`


## Type `ClassPerlKind`
`type ClassPerlKind = {#Digit; #Space; #Word}`


## Value `ClassPerlKind`
`let ClassPerlKind`


## Type `ClassBracketed`
`type ClassBracketed = ClassType<ClassSet>`


## Value `ClassBracketed`
`let ClassBracketed`


## Type `ClassSet`
`type ClassSet = {#Item : ClassSetItem; #BinaryOp : ClassSetBinaryOp}`


## Value `ClassSet`
`let ClassSet`


## Type `ClassSetItem`
`type ClassSetItem = {#Empty : Span; #Literal : Literal; #Range : ClassSetRange; #Ascii : ClassAscii; #Unicode : ClassUnicode; #Perl : ClassPerl; #Bracketed : ClassBracketed; #Union : ClassSetUnion}`


## Value `ClassSetItem`
`let ClassSetItem`


## Type `ClassSetRange`
`type ClassSetRange = { span : Span; start : Literal; end : Literal }`


## Value `ClassSetRange`
`let ClassSetRange`


## Type `ClassSetUnion`
`type ClassSetUnion = { span : Span; items : [ClassSetItem] }`


## Value `ClassSetUnion`
`let ClassSetUnion`


## Type `ClassSetBinaryOp`
`type ClassSetBinaryOp = { span : Span; kind : ClassSetBinaryOpKind; lhs : ClassSet; rhs : ClassSet }`


## Value `ClassSetBinaryOp`
`let ClassSetBinaryOp`


## Type `ClassSetBinaryOpKind`
`type ClassSetBinaryOpKind = {#Intersection; #Difference; #SymmetricDifference}`


## Value `ClassSetBinaryOpKind`
`let ClassSetBinaryOpKind`


## Type `Assertion`
`type Assertion = { span : Span; kind : AssertionKind }`


## Value `Assertion`
`let Assertion`


## Type `AssertionKind`
`type AssertionKind = {#StartLine; #EndLine; #StartText; #EndText; #WordBoundary; #NotWordBoundary}`


## Value `AssertionKind`
`let AssertionKind`


## Type `Repetition`
`type Repetition = { span : Span; op : RepetitionOp; greedy : Bool; ast : AST }`


## Value `Repetition`
`let Repetition`


## Type `RepetitionOp`
`type RepetitionOp = { span : Span; kind : RepetitionKind }`


## Value `RepetitionOp`
`let RepetitionOp`


## Type `RepetitionKind`
`type RepetitionKind = {#ZeroOrOne; #ZeroOrMore; #OneOrMore; #Range : RepetitionRange}`


## Value `RepetitionKind`
`let RepetitionKind`


## Type `RepetitionRange`
`type RepetitionRange = {#Exactly : Nat32; #AtLeast : Nat32; #Bounded : (Nat32, Nat32)}`


## Value `RepetitionRange`
`let RepetitionRange`


## Type `Group`
`type Group = { span : Span; kind : GroupKind; ast : AST }`


## Value `Group`
`let Group`


## Type `GroupVar`
`type GroupVar = { var span : Span; var kind : GroupKind; var ast : AST }`


## Value `GroupVar`
`let GroupVar`


## Type `GroupKind`
`type GroupKind = {#CaptureIndex : Nat32; #CaptureName : CaptureName; #NonCapturing : Flags}`


## Value `GroupKind`
`let GroupKind`


## Type `CaptureName`
`type CaptureName = { span : Span; name : Text; index : Nat32 }`


## Value `CaptureName`
`let CaptureName`


## Type `SetFlags`
`type SetFlags = { span : Span; flags : Flags }`


## Value `SetFlags`
`let SetFlags`


## Type `Flags`
`type Flags = { span : Span; items : [FlagsItem] }`


## Value `Flags`
`let Flags`


## Type `FlagsItem`
`type FlagsItem = { span : Span; kind : FlagsItemKind }`


## Value `FlagsItem`
`let FlagsItem`


## Type `FlagsItemKind`
`type FlagsItemKind = {#Negation; #Flag : Flag}`


## Value `FlagsItemKind`
`let FlagsItemKind`


## Type `Flag`
`type Flag = {#CaseInsensitive; #MultiLine; #DotMatchesNewLine; #SwapGreed; #Unicode; #IgnoreWhitespace}`


## Value `Flag`
`let Flag`

