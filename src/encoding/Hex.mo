import Prim "mo:⛔";

import Char "../Char";
import { Nat8 } = "../Nat";
import Result "../Result";

module {
    private let base : Nat8 = 16;

    public type Hex = Text;

    public type HexChar = Char;

    public module HexChar = {
        private let hex : [Char] = [
            '0', '1', '2', '3',
            '4', '5', '6', '7',
            '8', '9', 'a', 'b',
            'c', 'd', 'e', 'f'
        ];

        public func fromHexByte(h : HexByte) : HexChar = hex[Nat8.toNat(h)];
    };

    public type HexChars = (Char, Char);

    public module HexChars = {
        public func fromHexBytes((b0, b1) : HexBytes) : HexChars = (
            HexChar.fromHexByte(b0),
            HexChar.fromHexByte(b1)
        );
    };

    // [0:16[
    public type HexByte = Nat8;

    public module HexByte = {
        public func fromChar(c : Char) : Result.Result<HexByte, Char> {
            if ('0' <= c and c <= '9') return #ok(Char.toNat8(c) - 0x30); // 0
            if ('A' <= c and c <= 'F') return #ok(Char.toNat8(c) - 0x37); // A + 10
            if ('a' <= c and c <= 'f') return #ok(Char.toNat8(c) - 0x57); // a + 10
            #err(c);
        };
    };

    // [0:16[ [0:16[
    private type DoubleHexByte = Nat8;

    private type HexBytes = (HexByte, HexByte);

    private module HexBytes = {
        public func fromDoubleHexByte(n : DoubleHexByte) : HexBytes = (
            n >> 4,
            n & 0xF
        );
    };

    // Converts `Nat8` (byte) to its corresponding hexadecimal format.
    public func fromNat8(n : Nat8) : Hex {
        let (c0, c1) = HexChars.fromHexBytes(HexBytes.fromDoubleHexByte(n));
        Char.toText(c0) # Char.toText(c1);
    };

    // Converts `[Nat8]` (bytes) to its corresponding hexadecimal format.
    public func fromArray(ns : [Nat8]) : Hex {
        var hex = "";
        var i = 0;
        while (i < ns.size()) {
            hex #= fromNat8(ns[i]);
            i += 1;
        };
        hex;
    };

    public func toArray(h : Hex) : Result.Result<[Nat8], Char> {
        var i = 0;
        let ns = Prim.Array_init<Nat8>(h.size() / 2 + (h.size() % 2), 0);
        let cs = h.chars();
        label l loop {
            let x0 : HexByte = if (i == 0 and h.size() % 2 == 1) { 0 } else switch (cs.next()) {
                case (? c) switch (HexByte.fromChar(c)) {
                    case (#err(c)) return #err(c);
                    case (#ok(x)) x;
                };
                case (null) break l;
            };
            let x1 : HexByte = switch (cs.next()) {
                case (? c) switch (HexByte.fromChar(c)) {
                    case (#err(c)) return #err(c);
                    case (#ok(x)) x;
                };
                case (null) return #err(HexChar.fromHexByte(x0));
            };
            ns[i] := x0 * base + x1;
            i += 1;
        };
        #ok(Prim.Array_tabulate<Nat8>(ns.size(), func (i : Nat) : Nat8 { ns[i] }));
    };

    /*
     * PRIMITIVES
     */

    public type PartialHex<T> = {
        hex : (h : Hex) -> Result.Result<T, Char>;
    };

    private func nat8to32(n : Nat8) : Nat32 = Prim.natToNat32(Prim.nat8ToNat(n));

    public let Nat32 : PartialHex<Nat32> = {
        hex = func (h : Hex) : Result.Result<Nat32, Char> {
            let hb : [Nat8] = switch (toArray(h)) {
                case (#ok(hs)) hs;
                case (#err(c)) return #err(c);
            };
            
            if (hb.size() > 4)  return #err(HexChar.fromHexByte(hb[4]));
            if (hb.size() == 0) return #ok(0);
            var i = 1;
            var n32 : Nat32 = nat8to32(hb[hb.size() - 1]);
            while (i < hb.size()) {
                i += 1;
                n32 |= nat8to32(hb[hb.size() - i]) << (8 * Prim.natToNat32(i - 1));
            };
            #ok(n32);
        };
    };
};
