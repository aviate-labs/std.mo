# Compare

## Type `Eq`
`type Eq<T> = (x : T, y : T) -> Bool`

`==`: tests for `x` and `y` values to be equal.

## Type `PartialEq`
`type PartialEq<T> = { eq : Eq<T> }`


## Function `ne`
`func ne<T>(x : T, y : T, eq : Eq<T>) : Bool`

`!=`: tests for `x` and `y` values not to be equal.

## Type `Ordering`
`type Ordering = {#less; #equal; #greater}`

The result of a comparison between two values.

## Value `Ordering`
`let Ordering`


## Type `Ord`
`type Ord<T> = (x : T, y : T) -> Ordering`


## Type `PartialOrd`
`type PartialOrd<T> = { cmp : Ord<T> } and PartialEq<T>`


## Function `lt`
`func lt<T>(x : T, y : T, cmp : Ord<T>) : Bool`

`<`: tests less than (for `x` and `y`).

## Function `gt`
`func gt<T>(x : T, y : T, cmp : Ord<T>) : Bool`

`>`: tests greater than (for `x` and `y`).

## Function `le`
`func le<T>(x : T, y : T, cmp : Ord<T>) : Bool`

`<=`: tests less than or equal (for `x` and `y`).

## Function `ge`
`func ge<T>(x : T, y : T, cmp : Ord<T>) : Bool`

`>=`: tests greater than or equal (for `x` and `y`).

## Function `max`
`func max<T>(x : T, y : T, cmp : Ord<T>) : T`

Returns the maximum of two values with respect to the specified comparison function.

## Function `maxByKey`
`func maxByKey<T, K>(x : T, y : T, f : T -> K, cmp : Ord<K>) : T`

Returns the maximum of two values with respect to the specified comparison function.

## Function `min`
`func min<T>(x : T, y : T, cmp : Ord<T>) : T`

Returns the minimum of two values with respect to the specified comparison function.

## Function `minByKey`
`func minByKey<T, K>(x : T, y : T, f : T -> K, cmp : Ord<K>) : T`

Returns the minimum of two values with respect to the specified comparison function.

## Value `Bool`
`let Bool : PartialOrd<Bool>`


## Value `Nat`
`let Nat : PartialOrd<Nat>`


## Value `Nat8`
`let Nat8 : PartialOrd<Nat8>`


## Value `Nat16`
`let Nat16 : PartialOrd<Nat16>`


## Value `Nat32`
`let Nat32 : PartialOrd<Nat32>`


## Value `Nat64`
`let Nat64 : PartialOrd<Nat64>`


## Value `Int`
`let Int : PartialOrd<Int>`


## Value `Int8`
`let Int8 : PartialOrd<Int8>`


## Value `Int16`
`let Int16 : PartialOrd<Int16>`


## Value `Int32`
`let Int32 : PartialOrd<Int32>`


## Value `Int64`
`let Int64 : PartialOrd<Int64>`


## Value `Float`
`let Float : PartialOrd<Float>`


## Value `Char`
`let Char : PartialOrd<Char>`


## Value `Text`
`let Text : PartialOrd<Text>`


## Value `Blob`
`let Blob : PartialOrd<Blob>`


## Value `Principal`
`let Principal : PartialOrd<Principal>`

