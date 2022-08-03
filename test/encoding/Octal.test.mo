import { describe; it; Suite } = "mo:testing/Suite";

import Prim "mo:⛔";

import Octal "mo:std/encoding/Octal";

let suite = Suite();

suite.run([
    describe("Octal", [
        describe("fromArray", [
            it("0o0777", func () : Bool {
                Octal.fromArray([0x07, 0x77]) == "0777";
            }),
            it("0o7777", func () : Bool {
                Octal.fromArray([0x77, 0x77]) == "7777"
            })
        ]),
        describe("toArray", [
            it("0o0123", func () : Bool {
                switch (Octal.toArray("123")) {
                    case (#ok(hb)) hb == [0x01, 0x23];
                    case (#err(_)) false;
                };
            }),
        ])
    ]),
    describe("HexByte", [
        describe("fromChar", [
            it("1", func () : Bool {
                switch (Octal.OctalByte.fromChar('1')) {
                    case (#ok(hb)) hb == 0x01;
                    case (#err(_)) false;
                };
            }),
            it("x", func () : Bool {
                switch (Octal.OctalByte.fromChar('8')) {
                    case (#ok(hb)) false;
                    case (#err(c)) c == '8';
                };
            })
        ])
    ]),
    describe("Nat32", [
        describe("octal", [
            it("o777", func () : Bool {
                Octal.Nat32.oct("777") == #ok(0x1ff);
            })
        ]),
    ])
]);
