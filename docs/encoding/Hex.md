# encoding/Hex

## Type `Hex`
`type Hex = Text`


## Type `HexChar`
`type HexChar = Char`


## Value `HexChar`
`let HexChar`


## Type `HexChars`
`type HexChars = (Char, Char)`


## Value `HexChars`
`let HexChars`


## Type `HexByte`
`type HexByte = Nat8`


## Value `HexByte`
`let HexByte`


## Function `fromNat8`
`func fromNat8(n : Nat8) : Hex`


## Function `fromArray`
`func fromArray(ns : [Nat8]) : Hex`


## Function `toArray`
`func toArray(h : Hex) : Result.Result<[Nat8], Char>`


## Type `PartialHex`
`type PartialHex<T> = { hex : (h : Hex) -> Result.Result<T, Char> }`


## Value `Nat32`
`let Nat32 : PartialHex<Nat32>`

