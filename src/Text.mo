import Prim "mo:⛔";

import Array "Array";
import Char "Char";
import Compare "Compare";
import Iter "Iter";
import Stack "Stack";

module {
    public func contains(t : Text, c : Text) : Bool {
        let chars = Array.fromIterator(t.chars());
        let ts = t.size(); 
        let check = Array.fromIterator(c.chars());
        let cs = check.size();
        if (ts < cs) return false;

        for (i in Iter.range(0, ts - cs + 1)) {
            var j = 0;
            label lj while (j < cs) {
                if (chars[i + j] != check[j]) break lj;
                j += 1;
            };
            if (j == cs) return true;
        };
        false;
    };

    public func startsWith(t : Text, c : Text) : Bool {
        let ts = t.size(); 
        let check = Array.fromIterator(c.chars());
        let cs = check.size();
        if (cs == 0) return true;
        if (ts < cs) return false;
        var i = 0;
        for (char in t.chars()) {
            if (char != check[i]) return false;
            i += 1;
            if (cs <= i) return true;
        };
        true;
    };

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
