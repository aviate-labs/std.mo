import Array "var/Array";
import Compare "Compare";
import Iterator "Iterator";
import List "List";

module {
    public let INITIAL_CAPACITY = 16;

    public type Map<K, V> = {
        keyType     : KeyType<K>;
        var count   : Nat;
        var buckets : [var List.KeyValue<K, V>];
    };

    /// Creates an empty Map object.
    public func empty<K, V>(keyType : KeyType<K>) : Map<K, V> = {
        keyType;
        var count   = 0;
        var buckets = [var];
    };

    /// Returns the size of the Map object.
    public func size<K, V>(map : Map<K, V>) : Nat = map.count;

    /// Removes all key-value pairs from the Map object.
    public func clear<K, V>(map : Map<K, V>) {
        map.count := 0;
        for (k in map.buckets.keys()) {
            map.buckets[k] := null;
        };
    };

    /// Returns the deleted element if it existed in the Map object and has been removed, or null if the element does not exist.
    public func delete<K, V>(map : Map<K, V>, k : K) : ?V {
        let size = map.buckets.size();
        if (size == 0 or map.count == 0) return null;
        let p = map.keyType.hash(k, size);
        switch (map.buckets[p]) {
            case (null) null;
            case (? bucket) {
                let (new, ov) = List.KeyValue.set(?bucket, k, null, map.keyType.eq);
                map.buckets[p] := new;
                switch (ov) {
                    case (null) {};
                    case (? _) { map.count -= 1 };
                };
                ov;
            };
        };
    };

    /// Returns the value associated to the key, or null if there is none.
    public func get<K, V>(map : Map<K, V>, k : K) : ?V {
        let size = map.buckets.size();
        if (size == 0 or map.count == 0) return null;
        let p = map.keyType.hash(k, size);
        List.KeyValue.find<K, V>(map.buckets[p], k, map.keyType.eq);
    };

    // Returns a boolean asserting whether a value has been associated to the key in the Map object or not.
    public func has<K, V>(map : Map<K, V>, k : K) : Bool {
        switch (get(map, k)) {
            case (null) false;
            case (? _)  true;
        };
    };

    /// Sets the value for the key in the Map object. Returns the overwritten value.
    public func set<K, V>(map : Map<K, V>, k : K, v : V) : ?V {
        let size = rescale<K, V>(map);
        let p = map.keyType.hash(k, size);
        switch (map.buckets[p]) {
            case (null) {
                map.buckets[p] := ?{
                    value    = (k, v);
                    var next = null;
                };
                map.count += 1;
                null;
            };
            case (? bucket) {
                let (new, ov) = List.KeyValue.set<K, V>(?bucket, k, ?v, map.keyType.eq);
                map.buckets[p] := new;
                switch (ov) {
                    case (null) { map.count += 1 };
                    case (? _) {};
                };
                ov;
            };
        };
    };

    /// Returns a new Iterator object that contains the keys for each element in the Map object.
    public func keys<K, V>(map : Map<K, V>) : Iterator.Iterator<K> {
        Iterator.map(entries(map), func ((k, _) : (K, V)) : K { k });
    };

    /// Returns a new Iterator object that contains the values for each element in the Map object.
    public func values<K, V>(map : Map<K, V>) : Iterator.Iterator<V> {
        Iterator.map(entries(map), func ((_, v) : (K, V)) : V { v });
    };

    /// Returns a new Iterator object that contains an tuple of (key, value) for each element in the Map object.
    public func entries<K, V>(map : Map<K, V>) : Iterator.Iterator<(K, V)> {
        if (map.buckets.size() == 0 or map.count == 0) {
            return object {
                public func next() : ?(K, V) { null };
            };
        };
        object {
            var current = map.buckets[0];
            var index   = 1;
            public func next() : ?(K, V) {
                switch (current) {
                    case (null) {
                        if (map.buckets.size() <= index) return null;
                        current := map.buckets[index];
                        index += 1;
                        next();
                    };
                    case (? bucket) {
                        current := bucket.next;
                        ?bucket.value;
                    };
                };
            };
        };
    };

    // Will only rescale the buckets if needed.
    private func rescale<K, V>(map : Map<K, V>) : Nat {
        let _size = map.buckets.size();
        if (_size <= map.count) {
            let size = switch (map.count) {
                case (0) INITIAL_CAPACITY;
                case (_) _size * 2;
            };
            let new = Array.init<List.KeyValue<K, V>>(size, null);
            // NOTE: this can be VERY expensive!
            for (k in map.buckets.keys()) {
                var bucket = map.buckets[k];
                label l loop {
                    switch (bucket) {
                        case (null) break l;
                        case (? e) {
                            let (k, v) = e.value;
                            let p : Nat = map.keyType.hash(k, size);
                            new[p] := ?{ 
                                value    = e.value;
                                var next = new[p];
                            };
                            bucket := e.next;
                        };
                    };
                };
            };
            map.buckets := new;
            return size;
        };
        _size;
    };

    public type KeyType<K> = {
        hash : (key : K, mod : Nat) -> Nat;
        eq   : Compare.Eq<K>;
    };
};