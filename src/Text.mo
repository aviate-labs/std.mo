import Prim "mo:⛔";

import Stack "Stack";
import Char "Char";
import Compare "Compare";

module {
    public func fromArray(chars : [Char]) : Text {
        var t = "";
        for (c in chars.vals()) t #= Prim.charToText(c);
        t;
    };

    public func toArray(t : Text) : [Char] {
        let b = Stack.init<Char>(8);
        for (c in t.chars()) Stack.push(b, c);
        Stack.toArray(b);
    };

    public func fromChars(chars : [Char]) : Text {
        var t = "";
        for (c in chars.vals()) {
            t #= Char.toText(c);
        };
        t;
    };

    public func cf(x : Text, y : Text) : Compare.Order {
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
                    let o = Char.cf(x, y);
                    if (Compare.Order.neq(o)) return o;
                };
                case (null, ? _)  return #less;    // unreachable
                case (? _, null)  return #greater; // unreachable
                case (null, null) return #equal;
            };
        };
    };
};
