module {
    public type Array  = [Value];
    
    public type Object = [(Text, Value)];

    public type Value = {
        #Any       : Any;
        #Array     : Array;
        #Blob      : Blob;
        #Bool      : Bool;
        #Char      : Char;
        #Error     : Error;
        #Float     : Float;
        #Int       : Int;
        #Int16     : Int16;
        #Int32     : Int32;
        #Int64     : Int64;
        #Int8      : Int8;
        #Nat       : Nat;
        #Nat16     : Nat16;
        #Nat32     : Nat32;
        #Nat64     : Nat64;
        #Nat8      : Nat8;
        #None;
        #Null      : Null;
        #Principal : Principal;
        #Text      : Text;
        #Object    : Object;
    };

    public func typeOf(v : Value) : Text {
        switch (v) {
            case (#Any(_))       return "any";
            case (#Array(_))     return "array";
            case (#Blob(_))      return "blob";
            case (#Bool(_))      return "bool";
            case (#Char(_))      return "char";
            case (#Error(_))     return "error";
            case (#Float(_))     return "float";
            case (#Int(_))       return "int";
            case (#Int16(_))     return "int16";
            case (#Int32(_))     return "int32";
            case (#Int64(_))     return "int64";
            case (#Int8(_))      return "int8";
            case (#Nat(_))       return "int";
            case (#Nat16(_))     return "nat16";
            case (#Nat32(_))     return "nat32";
            case (#Nat64(_))     return "nat64";
            case (#Nat8(_))      return "nat8";
            case (#None)         return "none";
            case (#Null(_))      return "null";
            case (#Principal(_)) return "principal";
            case (#Text(_))      return "text";
            case (#Object(_))    return "object";
        };
    };
};
