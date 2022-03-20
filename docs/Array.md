# Array

## Function `at`
`func at<T>(xs : [T], n : Int) : T`

Returns the array element at the given index. Negative integers count back from the last element.

## Function `concat`
`func concat<T>(xs : [T], ys : [T]) : [T]`

Returns a new array that is the first array joined with the second.

## Function `entries`
`func entries<T>(xs : [T]) : Iterator.Iterator<(Nat, T)>`

Returns a new array iterator object that contains the (key, value) pairs for each index in the array.

## Function `every`
`func every<T>(xs : [T], f : (x : T) -> Bool) : Bool`

Returns true if every element in the array satisfies the testing function.

## Function `filter`
`func filter<T>(xs : [T], f : (x : T) -> Bool) : [T]`

Returns a new array containing all elements that satisfy the filtering function.

## Function `find`
`func find<T>(xs : [T], f : (x : T) -> Bool) : ?T`

Returns the first element in the array that satisfies the testing function, returns 'null' if none are found.

## Function `findIndex`
`func findIndex<T>(xs : [T], f : (x : T) -> Bool) : ?Nat`

Returns the index of the first element in the array that satisfies the testing function, returns 'null' if none are found.

## Function `forEach`
`func forEach<T>(xs : [T], f : (x : T) -> ())`

Calls the function for each element in the calling array.

## Function `includes`
`func includes<T>(xs : [T], y : T, eq : Compare.Eq<T>) : Bool`

Returns whether the array contains the given value.

## Function `indexOf`
`func indexOf<T>(xs : [T], y : T, eq : Compare.Eq<T>) : ?Nat`

Returns the first index at which a given element can be found in the array.

## Function `join`
`func join<T>(xs : [T], toText : (x : T) -> Text, seperator : Text) : Text`

Joins all elements of the array into a string.

## Function `lastIndexOf`
`func lastIndexOf<T>(xs : [T], y : T, eq : Compare.Eq<T>) : ?Nat`

Returns the last index at which a given element can be found in the array.

## Function `map`
`func map<T, M>(xs : [T], f : (x : T) -> M) : [M]`

Returns a new array containing the results of invoking the given function on every element in the array.

## Function `reduce`
`func reduce<T, R>(xs : [T], f : (p : R, x : T) -> R, initial : R) : R`

Executes a user-supplied "reducer" callback function on each element of the array (from left to right), to reduce
it to a single value.

## Function `reduceRight`
`func reduceRight<T, R>(xs : [T], f : (p : R, x : T) -> R, initial : R) : R`

Executes a user-supplied "reducer" callback function on each element of the array (from right to left), to reduce 
it to a single value.

## Function `reverse`
`func reverse<T>(xs : [T]) : [T]`

Returns a new array in the reverse order of the elements of the given array.

## Function `slice`
`func slice<T>(xs : [T], start : Int, end : ?Int) : [T]`

Extracts a section of the given array and returns a new array.

## Function `some`
`func some<T>(xs : [T], f : (x : T) -> Bool) : Bool`

Returns true if at least one element in the given array satisfies the provided testing function.

## Function `sort`
`func sort<T>(xs : [T], cf : Compare.Cf<T>) : [T]`

Returns a new sorted array based on the elements of the given array.

## Function `values`
`func values<T>(xs : [T]) : Iterator.Iterator<T>`

Returns a new array iterator object that contains the values for each index in the array.

## Function `toVar`
`func toVar<T>(xs : [T]) : [var T]`

Converts an immutable array to a variable array.

## Function `fromVar`
`func fromVar<T>(xs : [var T]) : [T]`

Converts a variable array to an immutable array.
