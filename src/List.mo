import Compare "Compare";

module {
    public type List<T> = ?{
        value    : T;
        var next : List<T>;
    };

    public func push<T>(ls : List<T>, value : T) : List<T> = ?{
        value;
        var next = ls;
    };

    public func pop<T>(ls : List<T>) : (?T, List<T>) {
        switch (ls) {
            case (null) (null, null);
            case (? ls) (?ls.value, ls.next);
        };
    };

    public func size<T>(ls : List<T>) : Nat {
        func _size(ls : List<T>, n : Nat) : Nat {
            switch (ls) {
                case (null) n;
                case (? ls) _size(ls.next, n + 1);
            };
        };
        _size(ls, 0);
    };

    public func find<T>(ls : List<T>, v : T, eq : Compare.Eq<T>) : ?T {
        switch (ls) {
            case (null) null;
            case (? ls) {
                if (eq(v, ls.value)) return ?ls.value;
                find(ls.next, v, eq);
            };
        };
    };

    public type KeyValue<K, V> = List<(K, V)>;

    public module KeyValue = {
        // @scope
        private type List<K, V> = KeyValue<K, V>;

        public func find<K, V>(ls : List<K, V>, key : K, eq : Compare.Eq<K>) : ?V {
            switch (ls) {
                case (null) null;
                case (? ls) {
                    let (k, v) = ls.value;
                    if (eq(key, k)) return ?v;
                    find(ls.next, key, eq);
                };
            };
        };

        public func set<K, V>(ls : List<K, V>, key : K, val : ?V, eq : Compare.Eq<K>) : (List<K, V>, ?V) {
            var last = switch (ls) {
                case (null) return (null, null);
                case (? ls) ls;
            };
            let (k, v) = last.value;
            if (eq(key, k)) {
                return switch (val) {
                    case (null) (last.next, ?v);
                    case (? val) (?{
                        value    = (k, val);
                        var next = last.next;
                    }, ?v);
                };
            };
            loop {
                switch (last.next) {
                    case (null) {
                        // No next value, if v is not null, we can append.
                        switch (val) {
                            case (null) {};
                            case (? val) {
                                last.next := ?{
                                    value    = (key, val);
                                    var next = null;
                                };
                            };
                        };
                        return (ls, null)
                    };
                    case (? next) {
                        let (k, v) = next.value;
                        if (eq(key, k)) {
                            switch (val) {
                                case (null) {
                                    // Remove pair.
                                    last.next := next.next;
                                };
                                case (? val) {
                                    // Overwrite entry.
                                    last.next := ?{
                                        value    = (key, val);
                                        var next = next.next;
                                    };
                                };
                            };
                            return (ls, ?v);
                        };
                        last := next;
                    };
                };
            };
        };
    };
};
