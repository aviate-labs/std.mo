import { describe; it; Suite } = "mo:testing/Suite";

import Prim "mo:⛔";

import Array "mo:std/Array";
import Nat "mo:std/Nat";

let suite = Suite();

suite.run([
    describe("Array", [
        it("size", func () : Bool {
            let array = [0, 1, 3, 5, 10];
            array.size() == 5;
        }),

        it("at", func () : Bool {
            let array = [0, 1, 3, 5, 10];
            if (Array.at(array, 2) != 3) return false;
            Array.at(array, -2) == 5;
        }),

        it("concat", func () : Bool {
            let array1 = [0, 1, 3];
            let array2 = [5, 10];
            Array.concat(array1, array2) == [0, 1, 3, 5, 10];
        }),

        it("entries", func () : Bool {
            let array = [0, 1, 2, 3, 4];
            for ((k, v) in Array.entries(array)) {
                if (k != v) return false;
            };
            true;
        }),

        it("every", func () : Bool {
            let array = [0, 1, 3, 5, 10];
            let isBelow40 = func (v : Nat) : Bool { v < 40 };
            Array.every(array, isBelow40);
        }),

        it("filter", func () : Bool {
            let array = [0, 1, 3, 5, 10];
            let even = func (v : Nat) : Bool { v % 2 == 0 };
            Array.filter(array, even) == [0, 10];
        }),

        it("find", func () : Bool {
            let array = [0, 1, 3, 5, 10];
            let div2and5 = func (v : Nat) : Bool { v != 0 and v % 2 == 0 and v % 5 == 0 };
            Array.find(array, div2and5) == ?10;
        }),

        it("findIndex", func () : Bool {
            let array = [0, 1, 3, 5, 10];
            let over5 = func (v : Nat) : Bool { v > 5 };
            Array.findIndex(array, over5) == ?4;
        }),

        it("includes", func () : Bool {
            let array = [0, 1, 3, 5, 10];
            not Array.includes<Nat>(array, 4, func (x : Nat, y : Nat) { x == y });
        }),

        it("indexOf", func () : Bool {
            let array = [0, 1, 3, 5, 10];
            Array.indexOf<Nat>(array, 5, func (x : Nat, y : Nat) { x == y }) == ?3;
        }),

        it("join", func () : Bool {
            let array : [Float] = [0, 1, 3, 5, 10];
            Array.join<Float>(array, Prim.floatToText, ", ") == "0, 1, 3, 5, 10";
        }),

        it("lastIndexOf", func () : Bool {
            let array = [0, 1, 0, 1, 2];
            Array.lastIndexOf<Nat>(array, 0, func (x : Nat, y : Nat) { x == y }) == ?2;
        }),

        it("map", func () : Bool {
            let array = [0, 1, 3, 5, 10];
            Array.map(array, func (x : Nat) : Nat { x + 1 }) == [1, 2, 4, 6, 11];
        }),

        it("reduce", func () : Bool {
            let array = [0, 1, 3, 10, 5];
            let max = func (a : Nat, b : Nat) : Nat {
                if (a > b) { a } else { b };
            };
            Array.reduce<Nat, Nat>(array, max, 0) == 10;
        }),

        it("reduceRight", func () : Bool {
            let array = [[0, 1], [2, 3], [4, 5]];
            let concat = func (a : [Nat], b : [Nat]) : [Nat] {
                Array.concat<Nat>(a, b);
            };
            Array.reduceRight<[Nat], [Nat]>(array, concat, []) == [4, 5, 2, 3, 0, 1];
        }),

        it("reverse", func () : Bool {
            let array = [0, 1, 3, 5, 10];
            Array.reverse(array) == [10, 5, 3, 1, 0];
        }),

        it("slice", func () : Bool {
            let array = [0, 1, 3, 5, 10];
            if (Array.slice(array, 2, null) != [3, 5, 10])  return false;
            if (Array.slice(array, 2, ?4) != [3, 5])        return false;
            if (Array.slice(array, 1, ?5) != [1, 3, 5, 10]) return false;
            if (Array.slice(array, -2, null) != [5, 10])    return false;
            if (Array.slice(array, 2, ?-1) != [3, 5])       return false;
            Array.slice(array, 0, null) == array;
        }),

        it("some", func () : Bool {
            let array = [0, 1, 3, 5, 10];
            let uneven = func (x : Nat) : Bool { x % 2 == 1 };
            Array.some(array, uneven);
        }),

        it("sort", func () : Bool {
            let array = [4, 2, 5, 1, 3];
            Array.sort(array, Nat.cf) == [1, 2, 3, 4, 5];
        })
    ])
]);
