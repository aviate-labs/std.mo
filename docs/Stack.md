# Stack

## Type `Stack`
`type Stack<T> = { var capacity : Nat; var size : Nat; var xs : [var T] }`

An extendable mutable stack.
- __capacity__ : The capacity of the stack, is used to initialize if xs.size() == 0.
- __size__ : The current occupied size.
- __xs__ : The managed backbone array of the stack.

## Function `init`
`func init<T>(capacity : Nat) : Stack<T>`

Initializes a new stack with the given capacity.

## Function `make`
`func make<T>(xs : [T]) : Stack<T>`

Makes a new stack based on the given array.

## Function `empty`
`func empty<T>() : Stack<T>`

Creates an empty stack with capacity 0.

## Function `get`
`func get<T>(b : Stack<T>, index : Nat) : ?T`


## Function `push`
`func push<T>(b : Stack<T>, x : T)`

Adds the given value 'x' to the stack.

## Function `pop`
`func pop<T>(b : Stack<T>) : ?T`

Removes the last value from the stack and returns it.

## Function `last`
`func last<T>(b : Stack<T>) : ?T`

Returns the last value from the stack without removing it.

## Function `toArray`
`func toArray<T>(b : Stack<T>) : [T]`

Extracts an array from the stack.

## Function `values`
`func values<T>(b : Stack<T>) : Iterator.Iterator<T>`


## Value `Autofill`
`let Autofill`

