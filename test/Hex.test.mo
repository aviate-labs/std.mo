import { describe; it; Suite } = "mo:testing/Suite";

import Prim "mo:⛔";

import Hex "mo:std/encoding/Hex";

let suite = Suite();

suite.run([
    describe("Hex", [
        describe("fromArray", [
            it("0x00ff", func () : Bool {
                Hex.fromArray([0x00, 0xff]) == "00ff";
            }),
            it("0xff00", func () : Bool {
                Hex.fromArray([0xff, 0x00]) == "ff00"
            })
        ]),
        describe("toArray", [
            it("0x0123", func () : Bool {
                switch (Hex.toArray("123")) {
                    case (#ok(hb)) hb == [0x01, 0x23];
                    case (#err(_)) false;
                };
            }),
        ])
    ]),
    describe("HexByte", [
        describe("fromChar", [
            it("1", func () : Bool {
                switch (Hex.HexByte.fromChar('1')) {
                    case (#ok(hb)) hb == 0x01;
                    case (#err(_)) false;
                };
            }),
            it("B", func () : Bool {
                switch (Hex.HexByte.fromChar('B')) {
                    case (#ok(hb)) hb == 0x0B;
                    case (#err(_)) false;
                };
            }),
            it("b", func () : Bool {
                switch (Hex.HexByte.fromChar('b')) {
                    case (#ok(hb)) hb == 0x0b;
                    case (#err(_)) false;
                };
            }),
            it("x", func () : Bool {
                switch (Hex.HexByte.fromChar('x')) {
                    case (#ok(hb)) false;
                    case (#err(c)) c == 'x';
                };
            })
        ])
    ]),
    describe("Nat32", [
        describe("hex", [
            it("0x0f0f00ff", func () : Bool {
                Hex.Nat32.hex("0f0f00ff") == #ok(0x0f0f00ff);
            }),
            it("0x00ff", func () : Bool {
                Hex.Nat32.hex("00ff") == #ok(0x00ff);
            }),
            it("0x01", func () : Bool {
                Hex.Nat32.hex("01") == #ok(0x0001);
            })
        ]),
    ]),
]);
