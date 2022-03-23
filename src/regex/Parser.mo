import Prim "mo:⛔";

import AST "AST";
import Array "../Array";
import Buffer "../Buffer";
import Iterator "../Iterator";
import Result "../Result";

module {
    public type Result<T> = Result.Result<T, AST.Error>;

    public type Either<A, B> = {
        #Left  : A;
        #Right : B;
    };

    public class Parser(_pattern : Text) {
        let pattern : [Char] = Array.fromIterator(_pattern.chars());
        var offset   = 0;
        var line     = 0;
        var column   = 0;
        let comments = Buffer.init<AST.Comment>(16);
        let groups   = Buffer.init<AST.Concat>(16);
        var index    = 0 : Nat32;

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
            var name = "";
            for (i in Iterator.range(start.offset, end.offset)) {
                name #= Prim.charToText(pattern[i]);
            };
            if (name == "") return #err(err(#GroupNameEmpty, { start; end = start }));
            #ok({
                span = { start; end };
                name;
                index;
            });
        };

        public func pushGroup(concat : AST.Concat) {
            assert(char() == '(');
            // TODO
        };

        public func parseGroup() : Result<Either<AST.SetFlags, AST.Group>> {
            let openChar = spanChar();
            ignore bump();
            bumpSpace();
            if (isLookAroundPrefix()) return #err(err(
                #UnsupportedLookAround, {
                    start = openChar.start;
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
                #ok(#Right({
                    span = openChar;
                    kind = #CaptureName(n);
                    ast  = #Empty(span());
                }));
            } else if (bumpIf("?")) {
                if (isEOF()) return #err(err(#GroupUnclosed, openChar));
                let flags = switch (parseFlags()) {
                    case (#ok(flags)) flags;
                    case (#err(e)) return #err(e);
                };
                let end = char();
                ignore bump();
                switch (end) {
                    case (')') {
                        if (flags.items.size() == 0) {
                            return #err(err(#RepetitionMissing, innerSpan));
                        };
                        #ok(#Left({
                            span = {
                                start = openChar.start;
                                end   = pos();
                            };
                            flags;
                        }))
                    };
                    case (_) {
                        assert(end == ':');
                        #ok(#Right({
                            span = openChar;
                            kind = #NonCapturing(flags);
                            ast  = #Empty(span());
                        }));
                    };
                };
            } else {
                let i = nextCaptureIndex();
                #ok(#Right({
                    span = openChar;
                    kind = #CaptureIndex(i);
                    ast  = #Empty(span());
                }));
            }
        };

        public func parseFlags() : Result<AST.Flags> {
            let start = span();
            let items = Buffer.init<AST.FlagsItem>(16);
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
                    for (i in Buffer.values(items)) {
                        if (AST.FlagsItemKind.cf(i.kind, item.kind) == 0) return #err(err(#FlagRepeatedNegation({
                            original = i.span;
                        }), spanChar())); 
                    };
                    Buffer.add(items, item);
                } else {
                    negated := null;
                    let item : AST.FlagsItem = {
                        span = spanChar();
                        kind = #Flag(switch (parseFlag()) {
                            case (#ok(flag)) flag;
                            case (#err(e)) return #err(e);
                        });
                    };
                    for (i in Buffer.values(items)) {
                        if (AST.FlagsItemKind.cf(i.kind, item.kind) == 0) return #err(err(#FlagDuplicate({
                            original = i.span;
                        }), spanChar())); 
                    };
                    Buffer.add(items, item);
                };
                if (not bump()) return #err(err(#FlagUnexpectedEOF, span()));
            };
            switch (negated) {
                case (null) {};
                case (? span) return #err(err(#FlagDanglingNegation, span));
            };
            #ok({
                span  = { start = start.start; end = pos() };
                items = Buffer.toArray(items);
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

        public func parse() : [AST.AST] {
            var concat : AST.Concat = {
                span = span();
                asts = [];
            };
            label l loop {
                bumpSpace();
                if (isEOF()) break l;
                switch (char()) {
                    case ('(') pushGroup(concat);
                    case (_) {};
                };
            };
            [];
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
                            Buffer.add(comments, {
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