import Prim "mo:⛔";
import Compare "Compare";

module Char {
    public let toText : (c : Char) -> Text = Prim.charToText;

    public let toNat32 : (c : Char) -> Nat32 = Prim.charToNat32;

    public let fromNat32 : (n : Nat32) -> Char = Prim.nat32ToChar;

    public func toNat(c : Char) : Nat {
        Prim.nat32ToNat(toNat32(c));
    };

    public func toNat8(c : Char) : Nat8 {
        Prim.intToNat8Wrap(toNat(c));
    };

    public func isDigit(c : Char) : Bool = '0' <= c and c <= '9';
};
