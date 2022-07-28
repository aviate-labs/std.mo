module {
    public type Order = {
        #less;
        #equal;
        #notEqual;
        #greater;
    };

    public module Order = {
        public func lt(o : Order) : Bool = switch (o) {
            case (#less) true;
            case (_)     false;
        };

        public func eq(o : Order) : Bool = switch (o) {
            case (#equal) true;
            case (_)      false;
        };

        public func neq(o : Order) : Bool = switch (o) {
            case (#less)     true;
            case (#notEqual) true;
            case (#greater)  true;
            case (#equal)    false;
        };

        public func gt(o : Order) : Bool = switch (o) {
            case (#greater) true;
            case (_)        false;
        };
    };

    public type Cf<T> = (x : T, y : T) -> Order;

    public func lt<T>(x : T, y : T, cf : Cf<T>) : Bool = Order.lt(cf(x, y));

    public func eq<T>(x : T, y : T, cf : Cf<T>) : Bool = Order.eq(cf(x, y));

    public func neq<T>(x : T, y : T, cf : Cf<T>) : Bool = Order.neq(cf(x, y));

    public func gt<T>(x : T, y : T, cf : Cf<T>) : Bool = Order.gt(cf(x, y));

    public type Eq<T> = (x : T, y : T) -> Bool;
};