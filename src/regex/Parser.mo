import Prim "mo:⛔";

import AST "AST";
import Array "../Array";
import Char "../Char";
import Compare "../Compare";
import { Nat32 = HNat32 } = "../encoding/Hex";
import { Nat32 = ONat32 } = "../encoding/Octal";
import Iter "../Iter";
import { parseNat; Nat32 } = "../Nat";
import Result "../Result";
import Stack "../Stack";
import Text "../Text";

module {
    public type Result<T> = Result.Result<T, AST.Error>;

    public type Either<A, B> = {
        #left  : A;
        #right : B;
    };

    private type Primitive = {
        #Literal   : AST.Literal;
        #Assertion : AST.Assertion;
        #Dot       : AST.Span;
        #Perl      : AST.ClassPerl;
        #Unicode   : AST.ClassUnicode;
    };

    private module Primitive = {
        public func toAST(p : Primitive) : AST.AST {
            switch (p) {
                case (#Literal(l))   #Literal(l);
                case (#Assertion(a)) #Assertion(a);
                case (#Dot(d))       #Dot(d);
                case (#Perl(c))      #Class(#Perl(c));
                case (#Unicode(c))   #Class(#Unicode(c));
            };
        };
    };

    private type GroupState = {
        #Group       : GroupStateGroup;
        #Alternation : AST.AlternationVar;
    };

    private type GroupStateGroup = {
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
        var octal    = false;

        public func toggleOctal(toggle : Bool) { octal := toggle };

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

        public func parsePrimitive() : Result<Primitive> {
            switch (char()) {
                case '\\' parseEscape();
                case '.' {
                    let d = #Dot(spanChar());
                    ignore bump();
                    #ok(d);
                };
                case '^' {
                    let a = #Assertion({
                        span = spanChar();
                        kind = #StartLine;
                    });
                    ignore bump();
                    #ok(a);
                };
                case '$' {
                    let a = #Assertion({
                        span = spanChar();
                        kind = #EndLine;
                    });
                    ignore bump();
                    #ok(a);
                };
                case (c) {
                    let p = #Literal({
                        span = spanChar();
                        kind = #Verbatim;
                        c;
                    });
                    ignore bump();
                    #ok(p);
                };
            };
        };

        public func parseEscape() : Result<Primitive> {
            assert(char() == '\\');
            let start = pos();
            if (not bump()) return #err(err(#EscapeUnexpectedEOF, { start; end = pos() }));
            let c = char();
            if ('0' <= c and c <= '7') {
                if (not octal) return #err(err(#UnsupportedBackReference, { start; end = spanChar().end }));
                return switch (parseOctal()) {
                    case (#err(e)) #err(e);
                    case (#ok(lit)) #ok(#Literal({
                        span = { start; end = lit.span.end };
                        kind = lit.kind;
                        c = lit.c;
                    }));
                };
            };
            if (c == '8' or c == '9') {
                if (not octal) return #err(err(#UnsupportedBackReference, { start; end = spanChar().end }));
            };
            if (c == 'x' or c == 'u' or c == 'U') return switch (parseHex()) {
                case (#err(e))  #err(e);
                case (#ok(lit)) #ok(#Literal(lit));
            };
            // TODO: octal, unicode, etc...
            return #err(err(#UnsupportedBackReference, { start; end = spanChar().end }));
        };

        public func parseOctal() : Result<AST.Literal> {
            let c = char();
            assert('0' <= c and c <= '7');
            let start = pos();
            var tmp = Char.toText(c);
            label l loop {
                if (not bump()) break l;
                let c = char();
                let { offset } = pos();
                if (c < '0' or '7' < c or 2 < (offset - start.offset : Nat)) break l;
                tmp #= Char.toText(c);
            };
            let end = pos();
            switch (ONat32.oct(tmp)) {
                case (#err(_)) #err(err(#EscapeHexInvalid, { start; end }));
                case (#ok(n)) #ok({
                    span = { start; end };
                    kind = #Octal;
                    c = Char.fromNat32(n);
                });
            };
        };

        private func isHex(c : Char) : Bool = ('0' <= c and c <= '9') or ('a' <= c and c <= 'f') or ('A' <= c and c <= 'F');

        public func parseHex() : Result<AST.Literal> {
            let c = char();
            assert(c == 'x' or c == 'u' or c == 'U');
            let kind = switch (c) {
                case ('x') #X;
                case ('u') #UnicodeShort;
                case (_)   #UnicodeLong;
            };
            if (not bumpBumpSpace()) return #err(err(#EscapeUnexpectedEOF, span()));
            if (char() == '{') return parseHexBrace(kind);
            parseHexDigit(kind);
        };

        public func parseHexBrace(kind : AST.HexLiteralKind) : Result<AST.Literal> {
            // TODO
            #err(err(#EscapeUnexpectedEOF, span()));
        };

        public func parseHexDigit(kind : AST.HexLiteralKind) : Result<AST.Literal> {
            let start = pos();
            var tmp = "";
            for (i in Iter.range(0, AST.HexLiteralKind.digits(kind) - 1)) {
                if (0 < i and not bumpBumpSpace()) return #err(err(#EscapeUnexpectedEOF, span()));
                let c = char();
                if (not isHex(c)) return #err(err(#EscapeHexInvalidDigit, spanChar()));
                tmp #= Char.toText(c);
            };
            ignore bumpBumpSpace();
            let end = pos();
            switch (HNat32.hex(tmp)) {
                case (#err(_)) #err(err(#EscapeHexInvalid, { start; end }));
                case (#ok(n)) #ok({
                    span = { start; end };
                    kind = #HexFixed(kind);
                    c = Char.fromNat32(n);
                });
            };
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
            for (i in Iter.range(start.offset, end.offset - 1)) {
                name #= Char.toText(pattern[i]);
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
                        concat;
                        group = AST.Group.mut(group);
                    }));
                    #ok(AST.ConcatVar.new(span()));
                };
            };
        };

        public func popGroup(concat : AST.ConcatVar) : Result<AST.ConcatVar> {
            assert(char() == ')');
            let ({ group; concat = prior }, alt) : (GroupStateGroup, ?AST.AlternationVar) = switch (Stack.pop(groups)) {
                case (null) return #err(err(#GroupUnopened, spanChar()));
                case (? #Alternation(alt)) switch (Stack.pop(groups)) {
                    case (? #Group(g)) (g, ?alt);
                    case (_) return #err(err(#GroupUnopened, spanChar()));
                };
                case (? #Group(g)) (g, null);
            };
            concat.span := AST.Span.withEnd(concat.span, pos());
            ignore bump();
            group.span := AST.Span.withEnd(group.span, pos());
            switch (alt) {
                case (? alt) {
                    alt.span := AST.Span.withEnd(alt.span, group.span.end);
                    Stack.push(alt.asts, AST.Concat.toAST(AST.ConcatVar.mut(concat)));
                    group.ast := AST.Alternation.toAST(AST.AlternationVar.mut(alt));
                };
                case (null) {
                    group.ast := AST.Concat.toAST(AST.ConcatVar.mut(concat));
                };
            };
            Stack.push(prior.asts, #Group(AST.GroupVar.mut(group)));
            #ok(prior);
        };

        public func popGroupEnd(concat : AST.ConcatVar) : Result<AST.AST> {
            concat.span := AST.Span.withEnd(concat.span, pos());
            let ast = switch (Stack.pop(groups)) {
                case (null) #ok(AST.Concat.toAST(AST.ConcatVar.mut(concat)));
                case (? #Alternation(alt)) {
                    alt.span := AST.Span.withEnd(alt.span, pos());
                    Stack.push(alt.asts, AST.Concat.toAST(AST.ConcatVar.mut(concat)));
                    #ok(#Alternation(AST.AlternationVar.mut(alt)));
                };
                case (? #Group(g)) return #err(err(#GroupUnclosed, g.group.span));
            };
            switch (Stack.pop(groups)) {
                case (null) ast;
                case (? #Alternation(_)) { assert(false); loop {} }; // unreachable!
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
                        if (Compare.Ordering.eq(AST.FlagsItemKind.cmp(i.kind, item.kind))) return #err(err(#FlagRepeatedNegation({
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
                        if (Compare.Ordering.eq(AST.FlagsItemKind.cmp(i.kind, item.kind))) return #err(err(#FlagDuplicate({
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

        public func pushAlternation(concat : AST.ConcatVar) : Result<AST.ConcatVar> {
            assert(char() == '|');
            concat.span := AST.Span.withEnd(concat.span, pos());
            pushOrAddAlternation(AST.ConcatVar.mut(concat));
            ignore bump();
            #ok(AST.ConcatVar.new(span()));
        };

        public func pushOrAddAlternation(concat : AST.Concat) {
            let ast = AST.Concat.toAST(concat);
            switch (Stack.last(groups)) {
                case (? #Alternation(alts)) {
                    Stack.push(alts.asts, ast);
                };
                case (_) {
                    let alt = AST.AlternationVar.new(AST.Span.withEnd(concat.span, pos()));
                    Stack.push(alt.asts, ast);
                    Stack.push(groups, #Alternation(alt));
                };
            };
        };

        public func parseRepetition(
            concat : AST.ConcatVar,
            kind   : AST.RepetitionKind
        ) : Result<()> {
            let c = char();
            assert(c == '?' or c == '*' or c == '+');
            let start = pos();
            let ast = switch (Stack.pop(concat.asts)) {
                case (null) return #err(err(#RepetitionMissing, span()));
                case (? ast) { ast };
            };
            switch (ast) {
                case (#Empty(_)) return #err(err(#RepetitionMissing, span()));
                case (#Flags(_)) return #err(err(#RepetitionMissing, span()));
                case (_) {}
            };
            var greedy = if (bump() and char() == '?') {
                ignore bump();
                false;
            } else { true };
            Stack.push(concat.asts, #Repetition({
                span =  AST.Span.withEnd(AST.AST.span(ast), pos());
                op   = {
                    span = {
                        start;
                        end = pos();
                    };
                    kind;
                };
                greedy;
                ast;
            }));
            #ok();
        };

        public func parseRange(
            concat : AST.ConcatVar,
        ) : Result<()> {
            assert(char() == '{');
            let start = pos();
            let ast = switch (Stack.pop(concat.asts)) {
                case (null) return #err(err(#RepetitionMissing, span()));
                case (? ast) { ast };
            };
            switch (ast) {
                case (#Empty(_)) return #err(err(#RepetitionMissing, span()));
                case (#Flags(_)) return #err(err(#RepetitionMissing, span()));
                case (_) {}
            };
            if (not bumpBumpSpace()) return #err(err(#RepetitionCountUnclosed, {
                start;
                end = pos();
            }));
            let cStart = switch (parseDecimal()) {
                case (#ok(n))  n;
                case (#err(e)) return #err(e);
            };
            var range : AST.RepetitionRange = #Exactly(cStart);
            if (isEOF()) return #err(err(#RepetitionCountUnclosed, {
                start;
                end = pos();
            }));
            if (char() == ',') {
                if (not bumpBumpSpace()) return #err(err(#RepetitionCountUnclosed, {
                    start;
                    end = pos();
                }));
                if (char() == '}') {
                    range := #AtLeast(cStart);
                } else {
                    let cEnd = switch (parseDecimal()) {
                        case (#ok(n))  n;
                        case (#err(e)) return #err(e);
                    };
                    range := #Bounded(cStart, cEnd);
                };
            };
            if (isEOF() or char() != '}') return #err(err(#RepetitionCountUnclosed, {
                start;
                end = pos();
            }));
            var greedy = true;
            if (bumpBumpSpace() and char() == '?') {
                greedy := false;
                ignore bump();
            };

            let op = {
                start;
                end = pos();
            };
            if (not AST.RepetitionRange.isValid(range)) return #err(err(#RepetitionCountInvalid, op));
            Stack.push(concat.asts, #Repetition({
                span = AST.Span.withEnd(AST.AST.span(ast), pos());
                op   = {
                    span = op;
                    kind = #Range(range);
                };
                greedy;
                ast;
            }));
            #ok();
        };

        private func parseDecimal() : Result<Nat32> {
            while (not isEOF() and Prim.charIsWhitespace(char())) {
                ignore bump()
            };
            let start = pos();
            let t = Stack.init<Char>(2);
            while (not isEOF() and Char.isDigit(char())) {
                Stack.push(t, char());
                ignore bumpBumpSpace();
            };
            let span = {
                start;
                end = pos();
            };
            while (not isEOF() and Prim.charIsWhitespace(char())) {
                ignore bump()
            };
            if (t.size == 0) return #err(err(#DecimalEmpty, span));
            let digits = Text.fromChars(Stack.toArray(t));
            #ok(Nat32.fromNat(switch (parseNat(digits)) {
                case (#ok(n)) n;
                case (#err(_)) {
                    assert(false); // unreachable;
                    0;
                };
            }));
        };

        public func parse() : Result<AST.AST> {
            var concat = AST.ConcatVar.new(span());
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
                    case ('|') switch (pushAlternation(concat)) {
                        case (#err(e)) return #err(e);
                        case (#ok(c)) { concat := c };
                    };
                    case ('?') switch (parseRepetition(concat, #ZeroOrOne)) {
                        case (#err(e)) return #err(e);
                        case (#ok(_)) {};
                    };
                    case ('*') switch (parseRepetition(concat, #ZeroOrMore)) {
                        case (#err(e)) return #err(e);
                        case (#ok(_)) {};
                    };
                    case ('+') switch (parseRepetition(concat, #OneOrMore)) {
                        case (#err(e)) return #err(e);
                        case (#ok(_)) {};
                    };
                    case ('{') switch (parseRange(concat)) {
                        case (#err(e)) return #err(e);
                        case (#ok(_)) {};
                    };
                    case (c) switch (parsePrimitive()) {
                        case (#err(e)) return #err(e);
                        case (#ok(p)) {
                            Stack.push(concat.asts, Primitive.toAST(p));
                        };
                    };
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
                                comment #= Char.toText(c);
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

        public func bumpBumpSpace() : Bool {
            if (not bump()) return false;
            bumpSpace();
            not isEOF();
        };

        public func peek() : ?Char {
            if (pattern.size() <= offset + 1) return null;
            ?charAt(offset + 1);
        };
    };
};