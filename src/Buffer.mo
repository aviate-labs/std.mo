import { Array_init; Array_tabulate } = "mo:⛔";

module Buffer {
    /// An extendable mutable buffer.
    /// - __capacity__ : The capacity of the buffer, is used to initialize if xs.size() == 0.
    /// - __size__ : The current occupied size.
    /// - __xs__ : The managed backbone array of the buffer.
    public type Buffer<T> = {
        var capacity : Nat;
        var size     : Nat;
        var xs       : [var T];
    };

    /// Initializes a new buffer with the given capacity.
    public func init<T>(capacity : Nat) : Buffer<T> {
        return {
            var capacity = capacity;
            var size     = 0;
            var xs       = [var];
        };
    };

    /// Makes a new buffer based on the given array.
    public func make<T>(xs : [T]) : Buffer<T> {
        let size = xs.size();
        {
            var capacity = size;
            var size;
            var xs       = _make(xs);
        };
    };

    private func _make<T>(xs : [T]) : [var T] {
        let size = xs.size();
        if (size == 0) return [var];
        let ys = Array_init<T>(size, xs[0]);
        for (i in ys.keys()) ys[i] := xs[i];
        ys;
    };

    /// Creates an empty buffer with capacity 0.
    public func empty<T>() : Buffer<T> {
        make([]);
    };

    /// Adds the given value 'x' to the buffer.
    public func add<T>(b : Buffer<T>, x : T) {
        if (b.size == b.xs.size()) {
            let size = if (b.size == 0) {
                if (0 < b.capacity) { b.capacity } else { 1 };
            } else { 2 * b.xs.size() };
            let ys = Array_init<T>(size, x);

            var i = 0;
            label l loop {
                if (b.size <= i) break l;
                ys[i] := b.xs[i];
                i += 1;
            };
            b.xs       := ys;
            b.capacity := size;
        };

        b.xs[b.size] := x;
        b.size       += 1;
    };

    /// Extracts an array from the buffer.
    public func toArray<T>(b : Buffer<T>) : [T] {
        Array_tabulate<T>(b.size, func(i : Nat) : T { b.xs[i] });
    };
};
