# Buffer

## Type `Buffer`
`type Buffer<T> = { var capacity : Nat; var size : Nat; var xs : [var T] }`

An extendable mutable buffer.
- __capacity__ : The capacity of the buffer, is used to initialize if xs.size() == 0.
- __size__ : The current occupied size.
- __xs__ : The managed backbone array of the buffer.

## Function `init`
`func init<T>(capacity : Nat) : Buffer<T>`

Initializes a new buffer with the given capacity.

## Function `make`
`func make<T>(xs : [T]) : Buffer<T>`

Makes a new buffer based on the given array.

## Function `empty`
`func empty<T>() : Buffer<T>`

Creates an empty buffer with capacity 0.

## Function `add`
`func add<T>(b : Buffer<T>, x : T)`

Adds the given value 'x' to the buffer.

## Function `toArray`
`func toArray<T>(b : Buffer<T>) : [T]`

Extracts an array from the buffer.
