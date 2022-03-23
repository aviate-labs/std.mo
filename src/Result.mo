module {
    public type Result<O, E> = {
        #ok  : O;
        #err : E;
    };
};