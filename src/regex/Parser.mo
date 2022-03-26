import Prim "mo:⛔";

import AST "AST";
import Array "../Array";
import Stack "../Stack";
import Iterator "../Iterator";
import Result "../Result";

module {
    public type Result<T> = Result.Result<T, AST.Error>;

    public type Either<A, B> = {
        #left  : A;
        #right : B;
    };

    public type GroupState = {
        #Group : {
            concat : AST.Concat;
            group  : AST.Group;   
        };
        #Alternation : AST.Alternation;
    };

    private type GroupStateVar = {
        concat : AST.ConcatVar;
        group  : AST.GroupVar;
    };

    public class Parser(_pattern : Text) {
        let pattern : [Char] = Array.fromIterator(_pattern.chars());
        var offset   = 0;
        var line     = 1;
        var column   = 1;
        let comments = Stack.init<AST.Comment>(16);
        let names    = Stack.init<AST.CaptureName>(16);
        let groups   = Stack.init<GroupState>(16);
        var index    = 1 : Nat32;

        public func err(kind : AST.ErrorKind, span : AST.Span) : AST.Error = {
            kind;
            pattern = _pattern;
            span;
        };

        public func nextCaptureIndex() : Nat32 {
            let i = index;
            index += 1;
            i;
        };

        public func isCaptureChar(c : Char, first : Bool) : Bool {
            c == '_'
            or (not first and (('0' <= c and c <= '9') or c == '.' or c == '[' or c == ']'))
            or ('A' <= c and c <= 'Z')
            or ('a' <= c and c <= 'z');
        };

        // @pre first character after '<'.
        public func parseCaptureName(index : Nat32) : Result<AST.CaptureName> {
            if (isEOF()) return #err(err(#GroupNameUnexpectedEOF, span()));
            let start = pos();
            label l loop {
                let c = char();
                if (c == '>') break l;
                if (not isCaptureChar(c, pos().offset == start.offset)) {
                    return #err(err(#GroupNameInvalid, spanChar()));
                };
                if (not bump()) break l;
            };
            let end = pos();
            if (isEOF()) return #err(err(#GroupNameUnexpectedEOF, span()));
            assert(char() == '>');
            ignore bump();
            if (start.offset == end.offset) return #err(err(#GroupNameEmpty, { start; end }));
            var name = "";
            for (i in Iterator.range(start.offset, end.offset - 1)) {
                name #= Prim.charToText(pattern[i]);
            };
            let captureName : AST.CaptureName = {
                span = { start; end };
                name;
                index;
            };
            for (v in Stack.values(names)) {
                if (v.name == captureName.name) return #err(err(
                    #GroupNameDuplicate,
                    captureName.span
                ));
            };
            Stack.push(names, captureName);
            #ok(captureName);
        };

        public func pushGroup(concat : AST.ConcatVar) : Result<AST.ConcatVar> {
            assert(char() == '(');
            switch (parseGroup()) {
                case (#err(e)) #err(e);
                case (#ok(#left(sf))) {
                    // TODO: set flags?
                    Stack.push(concat.asts, #Flags(sf));
                    #ok(concat);
                };
                case (#ok(#right(group))) {
                    // TODO: set group flags?
                    Stack.push(groups, #Group({
                        concat = AST.ConcatVar.mut(concat); 
                        group;
                    }));
                    #ok({
                        var span = span();
                        var asts = Stack.init<AST.AST>(16);
                    });
                };
            };
        };

        public func popGroup(concat : AST.ConcatVar) : Result<AST.ConcatVar> {
            assert(char() == ')');
            let { group; concat = prior } : GroupStateVar = switch (Stack.pop(groups)) {
                case (null) return #err(err(#GroupUnclosed, spanChar()));
                case (? #Alternation(_)) return #err(err(#TODO, span()));
                case (? #Group(g)) {{
                    group  = AST.Group.mut(g.group);
                    concat = AST.Concat.mut(g.concat);
                }};
            };
            concat.span := AST.Span.withEnd(concat.span, pos());
            ignore bump();
            group.span := AST.Span.withEnd(group.span, pos());
            group.ast  := #Concat(AST.ConcatVar.mut(concat));
            Stack.push(prior.asts, #Group(AST.GroupVar.mut(group)));
            #ok(prior);
        };

        public func popGroupEnd(concat : AST.ConcatVar) : Result<AST.AST> {
            concat.span := AST.Span.withEnd(concat.span, pos());
            let ast = switch (Stack.pop(groups)) {
                case (null) #ok(#Concat(AST.ConcatVar.mut(concat)));
                case (? #Alternation(_)) return #err(err(#TODO, span()));
                case (? #Group(g)) return #err(err(#GroupUnclosed, g.group.span));
            };
            switch (Stack.pop(groups)) {
                case (null) ast;
                case (? #Alternation(_)) return #err(err(#TODO, span()));
                case (? #Group(g)) return #err(err(#GroupUnclosed, g.group.span));
            };
        };

        public func parseGroup() : Result<Either<AST.SetFlags, AST.Group>> {
            assert(char() == '(');
            let openSpan = spanChar();
            ignore bump();
            bumpSpace();
            if (isLookAroundPrefix()) return #err(err(
                #UnsupportedLookAround, {
                    start = openSpan.start;
                    end   = span().end;
                },
            ));
            let innerSpan = span();
            if (bumpIf("?P<")) {
                let i = nextCaptureIndex();
                let n = switch (parseCaptureName(i)) {
                    case (#ok(n))  n;
                    case (#err(e)) return #err(e);
                };
                #ok(#right({
                    span = openSpan;
                    kind = #CaptureName(n);
                    ast  = #Empty(span());
                }));
            } else if (bumpIf("?")) {
                if (isEOF()) return #err(err(#GroupUnclosed, openSpan));
                let flags = switch (parseFlags()) {
                    case (#ok(flags)) flags;
                    case (#err(e)) return #err(e);
                };
                let endChar = char();
                ignore bump();
                switch (endChar) {
                    case (')') {
                        if (flags.items.size() == 0) {
                            return #err(err(#RepetitionMissing, innerSpan));
                        };
                        #ok(#left({
                            span = AST.Span.withEnd(openSpan, pos());
                            flags;
                        }))
                    };
                    case (_) {
                        assert(endChar == ':');
                        #ok(#right({
                            span = openSpan;
                            kind = #NonCapturing(flags);
                            ast  = #Empty(span());
                        }));
                    };
                };
            } else {
                let i = nextCaptureIndex();
                #ok(#right({
                    span = openSpan;
                    kind = #CaptureIndex(i);
                    ast  = #Empty(span());
                }));
            }
        };

        public func parseFlags() : Result<AST.Flags> {
            let start = span();
            let items = Stack.init<AST.FlagsItem>(16);
            var negated : ?AST.Span = null;
            label l loop {
                let c = char();
                if (c == ':' or c == ')') break l;
                if (c == '-') {
                    let span = spanChar();
                    negated := ?span;
                    let item : AST.FlagsItem = {
                        span; 
                        kind = #Negation;
                    };
                    for (i in Stack.values(items)) {
                        if (AST.FlagsItemKind.cf(i.kind, item.kind) == 0) return #err(err(#FlagRepeatedNegation({
                            original = i.span;
                        }), spanChar())); 
                    };
                    Stack.push(items, item);
                } else {
                    negated := null;
                    let item : AST.FlagsItem = {
                        span = spanChar();
                        kind = #Flag(switch (parseFlag()) {
                            case (#ok(flag)) flag;
                            case (#err(e)) return #err(e);
                        });
                    };
                    for (i in Stack.values(items)) {
                        if (AST.FlagsItemKind.cf(i.kind, item.kind) == 0) return #err(err(#FlagDuplicate({
                            original = i.span;
                        }), spanChar())); 
                    };
                    Stack.push(items, item);
                };
                if (not bump()) return #err(err(#FlagUnexpectedEOF, span()));
            };
            switch (negated) {
                case (null) {};
                case (? span) return #err(err(#FlagDanglingNegation, span));
            };
            #ok({
                span  = { start = start.start; end = pos() };
                items = Stack.toArray(items);
            });
        };

        public func parseFlag() : Result<AST.Flag> {
            switch (char()) {
                case ('i') #ok(#CaseInsensitive);
                case ('m') #ok(#MultiLine);
                case ('s') #ok(#DotMatchesNewLine);
                case ('U') #ok(#SwapGreed);
                case ('u') #ok(#Unicode);
                case ('x') #ok(#IgnoreWhitespace);
                case (_) #err(err(#FlagUnrecognized, spanChar()))
            };
        };

        public func parse() : Result<AST.AST> {
            var concat : AST.ConcatVar = {
                var span = span();
                var asts = Stack.init<AST.AST>(16);
            };
            label l loop {
                bumpSpace();
                if (isEOF()) break l;
                switch (char()) {
                    case ('(') switch (pushGroup(concat)) {
                        case (#err(e)) return #err(e);
                        case (#ok(c)) { concat := c };
                    };
                    case (')') switch (popGroup(concat)) {
                        case (#err(e)) return #err(e);
                        case (#ok(c)) { concat := c };
                    };
                    case (_) return #err(AST.Error.new(#TODO, span()));
                };
            };
            let ast = switch (popGroupEnd(concat)) {
                case (#err(e))  return #err(e);
                case (#ok(ast)) { ast };
            };
            #ok(ast);
        };

        public func span() : AST.Span {
            let p = pos();
            { start = p; end = p };
        };

        public func spanChar() : AST.Span {
            let c = char();
            let end : AST.Position = {
                offset = offset + 1;
                line   = if (c == '\n') { line + 1 } else { line };
                column = if (c == '\n') { 1 } else { column + 1 };
            };
            { start = pos(); end };
        };

        public func pos() : AST.Position = { offset; line; column };

        public func char() : Char { charAt(offset) };

        public func charAt(i : Nat) : Char { pattern[i] };

        public func isEOF() : Bool { offset == pattern.size() };

        public func bump() : Bool {
            if (isEOF()) return false;
            if (char() == '\n') {
                line += 1;
                column := 1;
            } else {
                column += 1;
            };
            offset += 1;
            not isEOF();
        };

        public func bumpIf(prefix : Text) : Bool {
            if (pattern.size() <= offset + prefix.size()) return false;
            var i = 0; var nl = 0;
            for (c in prefix.chars()) {
                if (c != charAt(offset + i)) return false;
                if (c == '\n') nl += 1;
                i += 1;
            };
            line += nl;
            offset += prefix.size();
            true;
        };

        public func isLookAroundPrefix() : Bool {
            bumpIf("?=") or bumpIf("?!") or bumpIf("?<=") or bumpIf("?<!");
        };

        public func bumpSpace() {
            while (not isEOF()) {
                let c = char();
                if (Prim.charIsWhitespace(c)) {
                    ignore bump();
                } else {
                    switch (c) {
                        // Comments...
                        case ('#') {
                            let start = pos();
                            var comment = "";
                            ignore bump();
                            label l loop {
                                if (isEOF()) break l;
                                let c = char();
                                ignore bump();
                                if (c == '\n') break l;
                                comment #= Prim.charToText(c);
                            };
                            Stack.push(comments, {
                                span = {
                                    start;
                                    end = pos();
                                };
                                comment;
                            });
                        };
                        case (_) return;
                    };
                }
            };
        };

        public func peek() : ?Char {
            if (pattern.size() <= offset + 1) return null;
            ?charAt(offset + 1);
        };
    };
};