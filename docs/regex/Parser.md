# regex/Parser

## Type `Result`
`type Result<T> = Result.Result<T, AST.Error>`


## Type `Either`
`type Either<A, B> = {#left : A; #right : B}`


## `class Parser`


### Function `err`
`func err(kind : AST.ErrorKind, span : AST.Span) : AST.Error`



### Function `nextCaptureIndex`
`func nextCaptureIndex() : Nat32`



### Function `isCaptureChar`
`func isCaptureChar(c : Char, first : Bool) : Bool`



### Function `parsePrimitive`
`func parsePrimitive() : Result<Primitive>`



### Function `parseEscape`
`func parseEscape() : Result<Primitive>`



### Function `parseHex`
`func parseHex() : Result<AST.Literal>`



### Function `parseHexBrace`
`func parseHexBrace(kind : AST.HexLiteralKind) : Result<AST.Literal>`



### Function `parseHexDigit`
`func parseHexDigit(kind : AST.HexLiteralKind) : Result<AST.Literal>`



### Function `parseCaptureName`
`func parseCaptureName(index : Nat32) : Result<AST.CaptureName>`



### Function `pushGroup`
`func pushGroup(concat : AST.ConcatVar) : Result<AST.ConcatVar>`



### Function `popGroup`
`func popGroup(concat : AST.ConcatVar) : Result<AST.ConcatVar>`



### Function `popGroupEnd`
`func popGroupEnd(concat : AST.ConcatVar) : Result<AST.AST>`



### Function `parseGroup`
`func parseGroup() : Result<Either<AST.SetFlags, AST.Group>>`



### Function `parseFlags`
`func parseFlags() : Result<AST.Flags>`



### Function `parseFlag`
`func parseFlag() : Result<AST.Flag>`



### Function `pushAlternation`
`func pushAlternation(concat : AST.ConcatVar) : Result<AST.ConcatVar>`



### Function `pushOrAddAlternation`
`func pushOrAddAlternation(concat : AST.Concat)`



### Function `parseRepetition`
`func parseRepetition(concat : AST.ConcatVar, kind : AST.RepetitionKind) : Result<()>`



### Function `parseRange`
`func parseRange(concat : AST.ConcatVar) : Result<()>`



### Function `parse`
`func parse() : Result<AST.AST>`



### Function `span`
`func span() : AST.Span`



### Function `spanChar`
`func spanChar() : AST.Span`



### Function `pos`
`func pos() : AST.Position`



### Function `char`
`func char() : Char`



### Function `charAt`
`func charAt(i : Nat) : Char`



### Function `isEOF`
`func isEOF() : Bool`



### Function `bump`
`func bump() : Bool`



### Function `bumpIf`
`func bumpIf(prefix : Text) : Bool`



### Function `isLookAroundPrefix`
`func isLookAroundPrefix() : Bool`



### Function `bumpSpace`
`func bumpSpace()`



### Function `bumpBumpSpace`
`func bumpBumpSpace() : Bool`



### Function `peek`
`func peek() : ?Char`

