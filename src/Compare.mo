import Prim "mo:⛔";

module {
    /// `==`: tests for `x` and `y` values to be equal.
    public type Eq<T> = (x : T, y : T) -> Bool;

    public type PartialEq<T> = {
        /// `==`.
        eq : Eq<T>;
    };

    /// `!=`: tests for `x` and `y` values not to be equal.
    public func ne<T> (x : T, y : T, eq : Eq<T>) : Bool {
        not eq(x, y);
    };

    /// The result of a comparison between two values.
    public type Ordering = {
        #less;
        #equal;
        #greater;
    };

    public module Ordering = {
        /// Returns `true` if the ordering is the `#equal` variant.
        public let eq = func (x : Ordering) : Bool { x == #equal };

        /// Returns `true` if the ordering is not the `#equal` variant.
        public let ne = func (x : Ordering) : Bool { x != #equal };

        /// Returns `true` if the ordering is the `#less` variant.
        public let lt = func (x : Ordering) : Bool { x == #less };

        /// Returns `true` if the ordering is the `#greater` variant.
        public let gt = func (x : Ordering) : Bool { x == #greater };

        /// Returns `true` if the ordering is either the `#less` or `#equal` variant.
        public let le = func (x : Ordering) : Bool { x != #greater };

        /// Returns `true` if the ordering is either the `#greater` or `#equal` variant.
        public let ge = func (x : Ordering) : Bool { x != #less };

        /// Reverses the ordering.
        /// * `#less` becomes `$greater`.
        /// * `#greater` becomes `#less`.
        /// * `#equal` becomes `#equal`.
        public let reverse = func (x : Ordering) : Ordering = switch (x) {
            case (#less)    #greater;
            case (#equal)   #equal;
            case (#greater) #less;
        };

        /// Chains two orderings.
        public let then = func (x : Ordering, y : Ordering) : Ordering = switch (x) {
            case (#equal) y;
            case (_)      x;
        };

        /// Chains the ordering with the given function.
        public let thenF = func (x : Ordering, f : () -> Ordering) : Ordering = switch (x) {
            case (#equal) f();
            case (_)      x;
        };
    };

    public type Ord<T> = (x : T, y : T) -> Ordering;

    public type PartialOrd<T> = {
        // `>`, `<`, `<=` and `>=`.
        cmp : Ord<T>;
    } and PartialEq<T>;

    /// `<`: tests less than (for `x` and `y`).
    public func lt<T> (x : T, y : T, cmp : Ord<T>) : Bool = Ordering.lt(cmp(x, y));

    /// `>`: tests greater than (for `x` and `y`).
    public func gt<T>(x : T, y : T, cmp : Ord<T>) : Bool = Ordering.gt(cmp(x, y));

    /// `<=`: tests less than or equal (for `x` and `y`).
    public func le<T> (x : T, y : T, cmp : Ord<T>) : Bool = Ordering.le(cmp(x, y));

    /// `>=`: tests greater than or equal (for `x` and `y`).
    public func ge<T>(x : T, y : T, cmp : Ord<T>) : Bool = Ordering.ge(cmp(x, y));

    /// Returns the maximum of two values with respect to the specified comparison function.
    public func max<T>(x : T, y : T, cmp : Ord<T>) : T = switch (cmp(x, y)) {
        case (#greater) x;
        case (_)        y;
    };

    /// Returns the maximum of two values with respect to the specified comparison function.
    public func maxByKey<T, K>(x : T, y : T, f : T -> K, cmp : Ord<K>) : T {
        max(x, y, func (x : T, y : T) : Ordering { cmp(f(x), f(y)) });
    };

    /// Returns the minimum of two values with respect to the specified comparison function.
    public func min<T>(x : T, y : T, cmp : Ord<T>) : T = switch (cmp(x, y)) {
        case (#greater) y;
        case (_)        x;
    };

    /// Returns the minimum of two values with respect to the specified comparison function.
    public func minByKey<T, K>(x : T, y : T, f : T -> K, cmp : Ord<K>) : T {
        min(x, y, func (x : T, y : T) : Ordering { cmp(f(x), f(y)) });
    };

    /*
     * PRIMITIVES
     */

    public let Bool : PartialOrd<Bool> = {
        eq  = func (x : Bool, y : Bool) : Bool = x == y;
        cmp = func (x : Bool, y : Bool) : Ordering = switch (x, y) {
            case (false, true) #less;
            case (true, false) #greater;
            case (_) #equal;
        };
    };

    public let Nat : PartialOrd<Nat> = {
        eq  = func (x : Nat, y : Nat) : Bool = x == y;
        cmp = func (x : Nat, y : Nat) : Ordering {
            if (x < y) return #less;
            if (y < x) return #greater;
            #equal;
        };
    };

    public let Nat8 : PartialOrd<Nat8> = {
        eq  = func (x : Nat8, y : Nat8) : Bool = x == y;
        cmp = func (x : Nat8, y : Nat8) : Ordering {
            if (x < y) return #less;
            if (y < x) return #greater;
            #equal;
        };
    };

    public let Nat16 : PartialOrd<Nat16> = {
        eq  = func (x : Nat16, y : Nat16) : Bool = x == y;
        cmp = func (x : Nat16, y : Nat16) : Ordering {
            if (x < y) return #less;
            if (y < x) return #greater;
            #equal;
        };
    };

    public let Nat32 : PartialOrd<Nat32> = {
        eq  = func (x : Nat32, y : Nat32) : Bool = x == y;
        cmp = func (x : Nat32, y : Nat32) : Ordering {
            if (x < y) return #less;
            if (y < x) return #greater;
            #equal;
        };
    };

    public let Nat64 : PartialOrd<Nat64> = {
        eq  = func (x : Nat64, y : Nat64) : Bool = x == y;
        cmp = func (x : Nat64, y : Nat64) : Ordering {
            if (x < y) return #less;
            if (y < x) return #greater;
            #equal;
        };
    };

    public let Int : PartialOrd<Int> = {
        eq  = func (x : Int, y : Int) : Bool = x == y;
        cmp = func (x : Int, y : Int) : Ordering {
            if (x < y) return #less;
            if (y < x) return #greater;
            #equal;
        };
    };

    public let Int8 : PartialOrd<Int8> = {
        eq  = func (x : Int8, y : Int8) : Bool = x == y;
        cmp = func (x : Int8, y : Int8) : Ordering {
            if (x < y) return #less;
            if (y < x) return #greater;
            #equal;
        };
    };

    public let Int16 : PartialOrd<Int16> = {
        eq  = func (x : Int16, y : Int16) : Bool = x == y;
        cmp = func (x : Int16, y : Int16) : Ordering {
            if (x < y) return #less;
            if (y < x) return #greater;
            #equal;
        };
    };

    public let Int32 : PartialOrd<Int32> = {
        eq  = func (x : Int32, y : Int32) : Bool = x == y;
        cmp = func (x : Int32, y : Int32) : Ordering {
            if (x < y) return #less;
            if (y < x) return #greater;
            #equal;
        };
    };

    public let Int64 : PartialOrd<Int64> = {
        eq  = func (x : Int64, y : Int64) : Bool = x == y;
        cmp = func (x : Int64, y : Int64) : Ordering {
            if (x < y) return #less;
            if (y < x) return #greater;
            #equal;
        };
    };

    public let Float : PartialOrd<Float> = {
        eq  = func (x : Float, y : Float) : Bool = x == y;
        cmp = func (x : Float, y : Float) : Ordering {
            if (x < y) return #less;
            if (y < x) return #greater;
            #equal;
        };
    };

    public let Char : PartialOrd<Char> = {
        eq  = func (x : Char, y : Char) : Bool = x == y;
        cmp = func (x : Char, y : Char) : Ordering {
            if (x < y) return #less;
            if (y < x) return #greater;
            #equal;
        };
    };

    public let Text : PartialOrd<Text> = {
        eq  = func (x : Text, y : Text) : Bool = x == y;
        cmp = func (x : Text, y : Text) : Ordering {
            let diff = x.size() : Int - y.size();
            switch (diff) {
                case (0) {};
                case (_) {
                    if (diff < 0) return #less;
                    return #greater;
                };
            };

            let xs = x.chars();
            let ys = y.chars();
            loop {
                switch (xs.next(), ys.next()) {
                    case (? x, ? y ) {
                        let o = Char.cmp(x, y);
                        if (Ordering.ne(o)) return o;
                    };
                    case (null, ? _)  return #less;    // unreachable
                    case (? _, null)  return #greater; // unreachable
                    case (null, null) return #equal;
                };
            };
        };
    };

    public let Blob : PartialOrd<Blob> = {
        eq  = func (x : Blob, y : Blob) : Bool = x == y;
        cmp = func (x : Blob, y : Blob) : Ordering {
            if (x < y) return #less;
            if (y < x) return #greater;
            #equal;
        };
    };

    public let Principal : PartialOrd<Principal> = {
        eq  = func (x : Principal, y : Principal) : Bool = x == y;
        cmp = func (x : Principal, y : Principal) : Ordering {
            if (x < y) return #less;
            if (y < x) return #greater;
            #equal;
        };
    };
};
