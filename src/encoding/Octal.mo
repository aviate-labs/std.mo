import Prim "mo:⛔";

import Char "../Char";
import { Nat8 } = "../Nat";
import Result "../Result";

module {
    public type Octal = Text;

    public type OctalChar = Char;

    public module OctalChar = {
        private let octal : [Char] = [
            '0', '1', '2', '3',
            '4', '5', '6', '7',
        ];

        public func fromOctalByte(o : OctalByte) : OctalChar = octal[Nat8.toNat(o)];
    };

    public type OctalChars = (Char, Char);

    public module OctalChars = {
        public func fromOctalBytes((b0, b1) : OctalBytes) : OctalChars = (
            OctalChar.fromOctalByte(b0),
            OctalChar.fromOctalByte(b1)
        );
    };

    // [0:8[
    public type OctalByte = Nat8;

    public module OctalByte = {
        public func fromChar(c : Char) : Result.Result<OctalByte, Char> {
            if ('0' <= c and c <= '7') return #ok(Char.toNat8(c) - 0x30); // 0
            #err(c);
        };
    };

    // 0[0:8[ 0[0:8[
    private type DoubleOctalByte = Nat8;

    private type OctalBytes = (OctalByte, OctalByte);

    private module OctalBytes = {
        // [0, 511] (0777)
        public func fromDoubleOctalByte(n : DoubleOctalByte) : OctalBytes = (
            n >> 4 & 0x7,
            n & 0x7
        );
    };

    // Converts `Nat8` (byte) to its corresponding octal format.
    public func fromNat8(n : Nat8) : Octal {
        let (c0, c1) = OctalChars.fromOctalBytes(OctalBytes.fromDoubleOctalByte(n));
        Char.toText(c0) # Char.toText(c1);
    };

    // Converts `[Nat8]` (bytes) to its corresponding hexadecimal format.
    public func fromArray(ns : [Nat8]) : Octal {
        var hex = "";
        var i = 0;
        while (i < ns.size()) {
            hex #= fromNat8(ns[i]);
            i += 1;
        };
        hex;
    };

    // NOTE: does not use a packed representation, there is a redundancy of two bits in each `Nat8`.
    public func toArray(h : Octal) : Result.Result<[Nat8], Char> {
        var i = 0;
        let ns = Prim.Array_init<Nat8>(h.size() / 2 + (h.size() % 2), 0);
        let cs = h.chars();
                label l loop {
            let x0 : OctalByte = if (i == 0 and h.size() % 2 == 1) { 0 } else switch (cs.next()) {
                case (? c) switch (OctalByte.fromChar(c)) {
                    case (#err(c)) return #err(c);
                    case (#ok(x)) x;
                };
                case (null) break l;
            };
            let x1 : OctalByte = switch (cs.next()) {
                case (? c) switch (OctalByte.fromChar(c)) {
                    case (#err(c)) return #err(c);
                    case (#ok(x)) x;
                };
                case (null) return #err(OctalChar.fromOctalByte(x0));
            };
            ns[i] := x0 * 16 + x1;
            i += 1;
        };
        #ok(Prim.Array_tabulate<Nat8>(ns.size(), func (i : Nat) : Nat8 { ns[i] }));
    };

    /*
     * PRIMITIVES
     */

    public type PartialOctal<T> = {
        oct : (o : Octal) -> Result.Result<T, Char>;
    };

    private func nat8to32(n : Nat8) : Nat32 = Prim.natToNat32(Prim.nat8ToNat(n));

    public let Nat32 : PartialOctal<Nat32> = {
        oct = func (o : Octal) : Result.Result<Nat32, Char> {
            let hb : [Nat8] = switch (toArray(o)) {
                case (#ok(hs)) hs;
                case (#err(c)) return #err(c);
            };
            
            if (hb.size() > 3)  return #err(OctalChar.fromOctalByte(hb[3]));
            if (hb.size() == 0) return #ok(0);
            var i = 1;
            let (b0, b1) = OctalBytes.fromDoubleOctalByte(hb[hb.size() - 1]);
            var n32 : Nat32 = nat8to32(b0 << 3 | b1);
            while (i < hb.size()) {
                i += 1;
                let (b0, b1) = OctalBytes.fromDoubleOctalByte(hb[hb.size() - i]);
                n32 |= nat8to32(b0 << 3 | b1) << (6 * Prim.natToNat32(i - 1));
            };
            #ok(n32);
        };
    };
};
