import Prim "mo:⛔";

import Char "Char";
import Compare "Compare";
import Result "Result";

module Nat {
    public func parseNat(t : Text) : Result.Result<Nat, Text> {
        var n = 0;
        label l for (c in t.chars()) {
            if (c == '_') continue l;
            if (c < '0' or '9' < c) return #err("invalid character: " # Char.toText(c));
            n *= 10;
            n += Char.toNat(c) - 48; // ZERO = 48 = Char.toNat('0')
        };
        #ok(n);
    };

    public module Nat8 = {
        public let toNat : (n : Nat8) -> Nat = Prim.nat8ToNat;
    };

    public module Nat32 = {
        public let fromNat : (n : Nat) -> Nat32 = Prim.intToNat32Wrap;
    };
};
