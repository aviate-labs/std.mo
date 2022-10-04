import Compare "mo:std/Compare";
import {
    ne; lt; gt;
    Nat; Ordering
} = "mo:std/Compare";

do { // EXAMPLE: Eq
    type UserType = {
        #admin;
        #default;
    };

    type User = {
        id  : Nat;
        typ : UserType;
    };

    let User : Compare.PartialEq<User> = {
        eq = func (self: User, other : User) : Bool {
            self.id == other.id;
        };
    };

    let u0 : User = { id = 0; typ = #admin };
    let u1 : User = { id = 0; typ = #default };
    let u2 : User = { id = 9; typ = #default };

    assert(User.eq(u0, u1));

    assert(not User.eq(u1, u2)); // OR
    assert(ne(u1, u2, User.eq));
};

do { // EXAMPLE: Ordering
    assert(lt(1, 2, Nat.cmp));
    assert(Nat.eq(1, 1));
    assert(gt(2, 1, Nat.cmp));

    assert(Ordering.lt(#less));
    assert(Ordering.le(#less));
};

do { // EXAMPLE: Ordering.then
    let x = (1, 2, 7);
    let y = (1, 5, 3);
    let r = Ordering.then(
        Nat.cmp(x.0, y.0),
        Ordering.then(
            Nat.cmp(x.1, y.1),
            Nat.cmp(x.2, y.2)
        )
    );
    assert(Ordering.lt(r));
};

do { // EXAMPLE: Ordering.thenF
    let x = (1, 2, 7);
    let y = (1, 5, 3);
    let r = Ordering.thenF(
        Nat.cmp(x.0, y.0),
        func () : Compare.Ordering {
            Ordering.thenF(
                Nat.cmp(x.1, y.1),
                func () : Compare.Ordering {
                    // ❌ never executed.
                    Nat.cmp(x.2, y.2);
                }
            );
        }
    );
    assert(Ordering.lt(r));
};
