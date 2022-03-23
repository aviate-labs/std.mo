# Iterator

## Type `Iterator`
`type Iterator<T> = { next : () -> ?T }`

The "iterator" protocol defines a standard way to produce a sequence of 
values (either finite or infinite).

An object is an iterator when it implements a next() method.
- returns the value 'null' if the iterator has completed its sequence.

## Function `map`
`func map<A, B>(i : Iterator<A>, f : A -> B) : Iterator<B>`


## Function `range`
`func range(start : Nat, end : Nat) : Iterator<Nat>`

