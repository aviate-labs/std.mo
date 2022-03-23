# Map

## Value `INITIAL_CAPACITY`
`let INITIAL_CAPACITY`


## Type `Map`
`type Map<K, V> = { keyType : KeyType<K>; var count : Nat; var buckets : [var ?Entry<K, V>] }`


## Function `empty`
`func empty<K, V>(keyType : KeyType<K>) : Map<K, V>`

Creates an empty Map object.

## Function `size`
`func size<K, V>(map : Map<K, V>) : Nat`

Returns the size of the Map object.

## Function `clear`
`func clear<K, V>(map : Map<K, V>)`

Removes all key-value pairs from the Map object.

## Function `delete`
`func delete<K, V>(map : Map<K, V>, k : K) : ?V`

Returns the deleted element if it existed in the Map object and has been removed, or null if the element does not exist.

## Function `get`
`func get<K, V>(map : Map<K, V>, k : K) : ?V`

Returns the value associated to the key, or null if there is none.

## Function `has`
`func has<K, V>(map : Map<K, V>, k : K) : Bool`


## Function `set`
`func set<K, V>(map : Map<K, V>, k : K, v : V) : ?V`

Sets the value for the key in the Map object. Returns the overwritten value.

## Function `keys`
`func keys<K, V>(map : Map<K, V>) : Iterator.Iterator<K>`

Returns a new Iterator object that contains the keys for each element in the Map object.

## Function `values`
`func values<K, V>(map : Map<K, V>) : Iterator.Iterator<V>`

Returns a new Iterator object that contains the values for each element in the Map object.

## Function `entries`
`func entries<K, V>(map : Map<K, V>) : Iterator.Iterator<(K, V)>`

Returns a new Iterator object that contains an tuple of (key, value) for each element in the Map object.

## Type `Entry`
`type Entry<K, V> = { key : K; value : V; var next : ?Entry<K, V> }`


## Type `KeyType`
`type KeyType<K> = { hash : (key : K, mod : Nat) -> Nat; eq : Compare.Eq<K> }`

