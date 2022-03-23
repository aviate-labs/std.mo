# Set

## Type `Set`
`type Set<V> = Map.Map<V, ()>`


## Function `empty`
`func empty<V>(keyType : Map.KeyType<V>) : Set<V>`

Creates an empty Set object.

## Function `size`
`func size<V>(set : Set<V>) : Nat`

Returns the size of the Set object.

## Function `add`
`func add<V>(set : Set<V>, v : V)`


## Function `clear`
`func clear<V>(set : Set<V>)`

Removes all elements from the Set object.

## Function `delete`
`func delete<V>(set : Set<V>, v : V) : Bool`

Removes the element associated to the value and returns a boolean asserting whether an element was successfully removed or not.

## Function `has`
`func has<V>(set : Set<V>, v : V) : Bool`

Returns a boolean asserting whether an element is present with the given value in the Set object or not.

## Function `values`
`func values<V>(set : Set<V>) : Iterator.Iterator<V>`

Returns a new Iterator object that contains the values for each element in the Map object.
