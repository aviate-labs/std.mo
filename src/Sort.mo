import { Array_tabulate } = "mo:⛔";

import Compare "Compare";

module {
    // NOTE: inefficient (rebuilding the whole array).
    public func insert<T>(xs : [T], x : T, cf : Compare.Cf<T>) : [T] {
        let s = xs.size();
        var inserted = false;
        Array_tabulate<T>(s + 1, func (i : Nat) : T {
            if (not inserted) {
                if (i == s) return x;
                if (0 < cf(xs[i], x)) {
                    inserted := true;
                    return x;
                };
                return xs[i];
            };
            xs[i - 1];
        });
    };
};