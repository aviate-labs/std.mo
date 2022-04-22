import Array "Array";
import vArray "var/Array";

module {
    // TODO: replace with bit-shifting.
    // (n & (1 << pos)) != 0
    public func bit(n : Nat, p : Nat) : Bool {
        let bs = bits(n);
        bs[bs.size() - p - 1];
    };

    public func bits(n : Nat) : [Bool] {
        let bits = vArray.init<Bool>(bitSize(n), false);
        let s = bitSize(n);
        var m = n;
        var i = 0;
        while (0 < m) {
            bits[i] := m % 2 == 1;
            m /= 2;
            i += 1;
        };
        Array.fromVar(bits);
    };

    public func bitSize(n : Nat) : Nat {
        1 + logX(n, 2);
    };

    public func logX(n : Nat, x : Nat) : Nat {
        if (n < x) return 0;
        1 + logX(n / x, x);
    };
};
