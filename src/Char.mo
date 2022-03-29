import Prim "mo:⛔";

module Char {
    public let toText : (c : Char) -> Text = Prim.charToText;

    public let toNat32 : (c : Char) -> Nat32 = Prim.charToNat32; 

    public func toNat(c : Char) : Nat {
        Prim.nat32ToNat(toNat32(c));
    };

    public func toNat8(c : Char) : Nat8 {
        Prim.intToNat8Wrap(toNat(c));
    };

    public func isDigit(c : Char) : Bool {
        let n = toNat32(c);
        toNat32('0') <= n and n <= toNat32('9');
    };
};