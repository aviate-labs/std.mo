# tree/Radix

## Function `new`
`func new<T>() : Tree<T>`


## Function `fromArray`
`func fromArray<T>(vals : [(Text, T)]) : Tree<T>`


## Type `Tree`
`type Tree<T> = { var root : Node<T>; var size : Nat }`


## Value `Tree`
`let Tree`


## Function `insert`
`func insert<T>(tree : Tree<T>, key : [Char], value : T) : ?T`


## Function `delete`
`func delete<T>(tree : Tree<T>, key : [Char]) : ?T`


## Function `get`
`func get<T>(tree : Tree<T>, key : [Char]) : ?T`


## Type `Node`
`type Node<T> = { var prefix : [Char]; var leaf : ?LeafNode<T>; var edges : Edges<T> }`


## Value `Node`
`let Node`


## Type `LeafNode`
`type LeafNode<T> = { key : [Char]; var value : T }`


## Value `LeafNode`
`let LeafNode`


## Type `EdgeNode`
`type EdgeNode<T> = { key : Char; var node : Node<T> }`


## Value `EdgeNode`
`let EdgeNode`


## Type `Edges`
`type Edges<T> = [EdgeNode<T>]`


## Value `Edges`
`let Edges`


## Function `size`
`func size<T>(t : Tree<T>) : Nat`


## Function `toArray`
`func toArray<T>(tree : Tree<T>) : [([Char], T)]`


## Function `walk`
`func walk<T>(node : Node<T>, f : (key : [Char], value : T) -> Bool)`

