module {
    private type Iterator<T> =  { next : () -> ?T };

    public func map<A, B>(i : Iterator<A>, f : A -> B) : Iterator<B> = object {
        public func next() : ?B {
            switch (i.next()) {
                case (null)   null;
                case (? next) ?f(next);
            };
        };
    };

    public func range(start : Nat, end : Nat) : Iterator<Nat> = object {
        var i = start;
        public func next() : ?Nat {
            if (end < i) return null;
            let j = i;
            i += 1;
            ?j;
        };
    };
};
