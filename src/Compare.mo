module {
    public type Cf<T> = (x : T, y : T) -> Int;
    public type Eq<T> = (x : T, y : T) -> Bool;

    public func toEq<T>(compare : Cf<T>) : Eq<T> = func (x : T, y : T) : Bool {
        compare(x, y) == 0;
    };
};