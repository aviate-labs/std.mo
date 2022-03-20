module Iterator {
    /// The "iterator" protocol defines a standard way to produce a sequence of 
    /// values (either finite or infinite).
    ///
    /// An object is an iterator when it implements a next() method.
    /// - returns the value 'null' if the iterator has completed its sequence.
    public type Iterator<T> = {
        next : () -> ?T;
    };

    public class range(start : Nat, end : Nat) : Iterator<Nat> {
        var i = start;

        public func next() : ?Nat {
            if (end < i) return null;
            let j = i;
            i += 1;
            ?j;
        };
    };
};
