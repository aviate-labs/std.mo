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
};
