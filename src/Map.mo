import Array "var/Array";
import Compare "Compare";
import Iterator "Iterator";

module {
    public let INITIAL_CAPACITY = 16;

    public type Map<K, V> = {
        keyType     : KeyType<K>;
        var count   : Nat;
        var buckets : [var ?Entry<K, V>];
    };

    /// Creates an empty Map
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
                let (new, ov) = setEntry<K, V>(map.keyType, bucket, k, null);
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
        findEntry<K, V>(map.keyType, map.buckets[p], k);
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
                    key      = k;
                    value    = v;
                    var next = null;
                };
                map.count += 1;
                null;
            };
            case (? bucket) {
                let (new, ov) = setEntry<K, V>(map.keyType, bucket, k, ?v);
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
                        ?(bucket.key, bucket.value);
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
            let new = Array.init<?Entry<K, V>>(size, null);
            // NOTE: this can be VERY expensive!
            for (k in map.buckets.keys()) {
                var bucket = map.buckets[k];
                label l loop {
                    switch (bucket) {
                        case (null) break l;
                        case (? e) {
                            let p : Nat = map.keyType.hash(e.key, size);
                            new[p] := ?{ 
                                key      = e.key; 
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

    public type Entry<K, V> = {
        key       : K;
        value     : V;
        var next  : ?Entry<K, V>;
    };

    private func findEntry<K, V>(keyType : KeyType<K>, bucket : ?Entry<K, V>, k : K) : ?V {
        var current : ?Entry<K, V> = bucket;
        loop {
            switch (current) {
                case (null) return null;
                case (? bucket) {
                    if (keyType.eq(bucket.key, k)) {
                        return ?bucket.value;
                    };
                    current := bucket.next;
                };
            };
        };
    };

    /// Sets the entry to the given value, returns the new root and overwritten value.
    private func setEntry<K, V>(keyType : KeyType<K>, bucket : Entry<K, V>, k : K, v : ?V) : (?Entry<K, V>, ?V) {
        if (keyType.eq(bucket.key, k)) {
            return switch (v) {
                case (null) (bucket.next, ?bucket.value);
                case (? v) (?{
                    key      = k;
                    value    = v;
                    var next = bucket.next;
                }, ?bucket.value);
            };
        };
        // The last entry that was checked for the given key-value pair.
        var last : Entry<K, V> = bucket;
        loop {
            switch (last.next) {
                case (null) {
                    // No next value, if v is not null, we can append.
                    switch (v) {
                        case (null) {};
                        case (? v) {
                            last.next := ?{
                                key      = k;
                                value    = v;
                                var next = null;
                            };
                        };
                    };
                    return (?bucket, null)
                };
                case (? next) {
                    if (keyType.eq(next.key, k)) {
                        switch (v) {
                            case (null) {
                                // Remove entry.
                                last.next := next.next;
                            };
                            case (? v) {
                                // Overwrite entry.
                                last.next := ?{
                                    key      = k;
                                    value    = v;
                                    var next = next.next;
                                };
                            };
                        };
                        return (?bucket, ?next.value);
                    };
                    last := next;
                };
            };
        };
    };

    public type KeyType<K> = {
        hash : (key : K, mod : Nat) -> Nat;
        eq   : Compare.Eq<K>;
    };
};