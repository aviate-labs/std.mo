import { abs; Array_tabulate; Array_init } = "mo:⛔";

import Stack "Stack";
import Compare "Compare";
import Iterator "Iterator";
import v "var/Array";

module {
    public func init<T>(capacity : Nat, default : T) : [T] {
        fromVar(v.init<T>(capacity, default));
    };

    /// Returns the array element at the given index. Negative integers count back from the last element.
    public func at<T>(xs : [T], n : Int) : T {
        xs[negIndex(xs.size(), n)];
    };

    /// Returns a new array that is the first array joined with the second.
    public func concat<T>(xs : [T], ys : [T]) : [T] {
        switch(xs.size(), ys.size()) {
            case (0, 0) { []; };
            case (0, _) { ys; };
            case (_, 0) { xs; };
            case (xss, yss) {
                Array_tabulate<T>(xss + yss, func (i : Nat) : T {
                    if (i < xss) { xs[i] } else { ys[i - xss] };
                });
            };
        };
    };

    /// Returns a new array iterator object that contains the (key, value) pairs for each index in the array.
    public func entries<T>(xs : [T]) : Iterator.Iterator<(Nat, T)> {
        let size = xs.size();
        if (size == 0) return object {
            public func next() : ?(Nat, T) { null };
        };
        object {
            var i = 0;
            public func next() : ?(Nat, T) {
                if (i == size) return null;
                let v = ?(i, xs[i]);
                i += 1;
                v;
            };
        };
    };

    /// Returns true if every element in the array satisfies the testing function.
    public func every<T>(xs : [T], f : (x : T) -> Bool) : Bool {
        for (x in xs.vals()) if (not f(x)) return false;
        return true;
    };

    /// Returns a new array containing all elements that satisfy the filtering function.
    public func filter<T>(xs : [T], f : (x : T) -> Bool) : [T] {
        let ys : Stack.Stack<T> = Stack.init(xs.size());
        for (x in xs.vals()) if (f(x)) Stack.push(ys, x);
        Stack.toArray(ys);
    };

    /// Returns the first element in the array that satisfies the testing function, returns 'null' if none are found.
    public func find<T>(xs : [T], f : (x : T) -> Bool) : ?T {
        for (x in xs.vals()) if (f(x)) return ?x;
        return null;
    };

    /// Returns the index of the first element in the array that satisfies the testing function, returns 'null' if none are found.
    public func findIndex<T>(xs : [T], f : (x : T) -> Bool) : ?Nat {
        for (i in xs.keys()) if (f(xs[i])) return ?i;
        return null;
    };

    /// Calls the function for each element in the calling array.
    public func forEach<T>(xs : [T], f : (x : T) -> ()) {
        for (x in xs.vals()) f(x);
    };

    /// Returns whether the array contains the given value.
    public func includes<T>(xs : [T], y : T, eq : Compare.Eq<T>) : Bool {
        for (x in xs.vals()) {
            if (eq(x, y)) return true;
        };
        false;
    };

    /// Returns the first index at which a given element can be found in the array.
    public func indexOf<T>(xs : [T], y : T, eq : Compare.Eq<T>) : ?Nat {
        for ((i, x) in entries(xs)) {
            if (eq(x, y)) return ?i;
        };
        null;
    };

    /// Joins all elements of the array into a string.
    public func join<T>(xs : [T], toText : (x : T) -> Text, seperator : Text) : Text {
        var t = "";
        for ((k, x) in entries(xs)) {
            if (k != 0) t #= seperator;
            t #= toText(x);
        };
        t;
    };

    /// Returns the last index at which a given element can be found in the array.
    public func lastIndexOf<T>(xs : [T], y : T, eq : Compare.Eq<T>) : ?Nat {
        var v : ?Nat = null;
        for ((i, x) in entries(xs)) {
            if (eq(x, y)) v := ?i;
        };
        v;
    };

    /// Returns a new array containing the results of invoking the given function on every element in the array.
    public func map<T, M>(xs : [T], f : (x : T) -> M) : [M] {
        let ys  = Stack.init<M>(xs.size());
        let push = func (x : T) { Stack.push<M>(ys, f(x)) };
        forEach(xs, push);
        Stack.toArray(ys);
    };

    /// Executes a user-supplied "reducer" callback function on each element of the array (from left to right), to reduce
    /// it to a single value.
    public func reduce<T, R>(xs : [T], f : (p : R, x : T) -> R, initial : R) : R {
        var i = initial;
        for (x in xs.vals()) {
            i := f(i, x);
        };
        i;
    };

    /// Executes a user-supplied "reducer" callback function on each element of the array (from right to left), to reduce 
    /// it to a single value.
    public func reduceRight<T, R>(xs : [T], f : (p : R, x : T) -> R, initial : R) : R {
        let size = xs.size();
        var i = initial;
        for (k in xs.keys()) {
            i := f(i, xs[size - 1 - k]);
        };
        i;
    };

    /// Returns a new array in the reverse order of the elements of the given array.
    public func reverse<T>(xs : [T]) : [T] {
        let size = xs.size();
        if (size <= 1) return xs;
        Array_tabulate<T>(xs.size(), func (i : Nat) : T {
            xs[size - 1 - i];
        });
    };

    /// Extracts a section of the given array and returns a new array.
    public func slice<T>(xs : [T], start : Int, end : ?Int) : [T] {
        let size = xs.size();
        let s = negIndex(size, start);
        if (size <= s) return [];
        let e = negIndex(size, switch (end) {
            case (?i) { i };
            case (_) { size };
        });
        if (e < s)  return [];
        if (e == s) return [xs[e]];
        Array_tabulate<T>(e - s, func (i : Nat) : T {
            xs[s + i];
        });
    };

    /// Returns true if at least one element in the given array satisfies the provided testing function.
    public func some<T>(xs : [T], f : (x : T) -> Bool) : Bool {
        for (x in xs.vals()) {
            if (f(x)) return true;
        };
        false;
    };

    /// Returns a new sorted array based on the elements of the given array.
    public func sort<T>(xs : [T], cf : Compare.Cf<T>) : [T] {
        let ys = toVar<T>(xs);
        v.sort(ys, cf);
        fromVar(ys);
    };

    /// Returns a new array iterator object that contains the values for each index in the array.
    public func values<T>(xs : [T]) : Iterator.Iterator<T> = xs.vals();

    /// Converts an immutable array to a variable array.
    public func toVar<T>(xs : [T]) : [var T] {
        let size = xs.size();
        if (size == 0) return [var];
        let ys = Array_init<T>(size, xs[0]);
        for (i in ys.keys()) ys[i] := xs[i];
        ys;
    };

    /// Converts a variable array to an immutable array.
    public func fromVar<T>(xs : [var T]) : [T] {
        Array_tabulate<T>(xs.size(), func (i : Nat) { xs[i] });
    };

    public func fromIterator<T>(i : Iterator.Iterator<T>) : [T] {
        let b = Stack.init<T>(16);
        for (v in i) Stack.push(b, v);
        Stack.toArray(b);
    };

    private func negIndex(size : Nat, n : Int) : Nat {
        let m = abs(n);
        switch (n < 0) {
            case true {
                if (size < m) return 0;
                size - m;
            };
            case false {
                if (size < m) return size;
                m;
            };
        };
    };
};
