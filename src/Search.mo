module {
    // Uses binary search to find and return the smallest index i in [0, n) at which f(i) is true.
    public func search(n : Nat, f : (i : Nat) -> Bool) : Nat {
        var i = 0;
        var j = n;
        while (i < j) {
            let h = (i + j) / 2;
            // i <= h < j
            if (not f(h)) {
                i := h + 1;
            } else {
                j := h;
            };
        };
        i;
    };
};
