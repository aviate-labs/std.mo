import Iterator "Iterator";
import Map "Map";

module {
    public type Set<V> = Map.Map<V, ()>;

    /// Creates an empty Set object.
    public func empty<V>(keyType : Map.KeyType<V>) : Set<V> = Map.empty(keyType);

    /// Returns the size of the Set object.
    public func size<V>(set : Set<V>) : Nat = set.count;

    // Adds the given value to the Set object.
    public func add<V>(set : Set<V>, v : V) = ignore Map.set<V, ()>(set, v, ());

    /// Removes all elements from the Set object.
    public func clear<V>(set : Set<V>) = Map.clear(set);

    /// Removes the element associated to the value and returns a boolean asserting whether an element was successfully removed or not.
    public func delete<V>(set : Set<V>, v : V) : Bool {
        switch (Map.delete(set, v)) {
            case (null) false;
            case (? _)  true;
        };
    };

    /// Returns a boolean asserting whether an element is present with the given value in the Set object or not.
    public func has<V>(set : Set<V>, v : V) : Bool = Map.has(set, v);

    /// Returns a new Iterator object that contains the values for each element in the Map object.
    public func values<V>(set : Set<V>) : Iterator.Iterator<V> {
        Iterator.map(Map.entries(set), func ((v, _) : (V, ())) : V { v });
    };
};