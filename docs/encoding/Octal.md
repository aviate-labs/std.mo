# encoding/Octal

## Type `Octal`
`type Octal = Text`


## Type `OctalChar`
`type OctalChar = Char`


## Value `OctalChar`
`let OctalChar`


## Type `OctalChars`
`type OctalChars = (Char, Char)`


## Value `OctalChars`
`let OctalChars`


## Type `OctalByte`
`type OctalByte = Nat8`


## Value `OctalByte`
`let OctalByte`


## Function `fromNat8`
`func fromNat8(n : Nat8) : Octal`


## Function `fromArray`
`func fromArray(ns : [Nat8]) : Octal`


## Function `toArray`
`func toArray(h : Octal) : Result.Result<[Nat8], Char>`


## Type `PartialOctal`
`type PartialOctal<T> = { oct : (o : Octal) -> Result.Result<T, Char> }`


## Value `Nat32`
`let Nat32 : PartialOctal<Nat32>`

