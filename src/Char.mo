import Prim "mo:⛔";
import Compare "Compare";

module Char {
    public let toText : (c : Char) -> Text = Prim.charToText;

    public let toNat32 : (c : Char) -> Nat32 = Prim.charToNat32; 

    public func toNat(c : Char) : Nat {
        Prim.nat32ToNat(toNat32(c));
    };

    public func toNat8(c : Char) : Nat8 {
        Prim.intToNat8Wrap(toNat(c));
    };

    public func isDigit(c : Char) : Bool = '0' <= c and c <= '9';

    public func cf(x : Char, y : Char) : Compare.Order {
        if (x < y) return #less;
        if (y < x) return #greater;
        #equal;
    };
};