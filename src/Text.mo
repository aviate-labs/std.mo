import Prim "mo:⛔";

import Buffer "Buffer";

module {
    public func fromArray(chars : [Char]) : Text {
        var t = "";
        for (c in chars.vals()) t #= Prim.charToText(c);
        t;
    };

    public func toArray(t : Text) : [Char] {
        let b = Buffer.init<Char>(8);
        for (c in t.chars()) Buffer.add(b, c);
        Buffer.toArray(b);
    };
};