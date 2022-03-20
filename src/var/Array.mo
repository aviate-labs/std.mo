import { Array_init = init } = "mo:⛔";

import Compare "../Compare";
import Iterator "../Iterator";

module {
    /// Sorts the elements of an array in place.
    public func sort<T>(xs : [var T], cf : Compare.Cf<T>) {
        // In-place quicksort w/ the Hoare partition scheme.

        let size = xs.size();
        if (size < 2) return;
        
        func partition(xs : [var T], lo : Nat, hi : Nat) : Nat {
            let pivot = xs[(hi + lo) / 2];
            var i = lo;
            var j = hi;
            loop {
                while (cf(xs[i], pivot) < 0) i += 1;
                while (cf(xs[j], pivot) > 0) j -= 1;
                if (j <= i) return j;
                let x = xs[i]; // swap
                xs[i] := xs[j];
                xs[j] := x;
            };
        };

        func sort(xs : [var T], lo : Nat, hi : Nat) {
            if (hi <= lo) return;
            let p = partition(xs, lo, hi);
            sort(xs, lo, p);
            sort(xs, p + 1, hi);
        };
        
        sort(xs, 0, xs.size() - 1);
    };
};