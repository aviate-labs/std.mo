import Prim "mo:⛔";

import Array "../Array";
import Char "../Char";
import Compare "../Compare";
import Stack "../Stack";
import Search "../Search";
import Sort "../Sort";
import Text "../Text";

module {
    public func new<T>() : Tree<T> = {
        var root = {
            var prefix = [];
            var leaf   = null;
            var edges  = [];
        };
        var size = 0;
    };

    public func fromArray<T>(vals : [(Text, T)]) : Tree<T> = new();

    public type Tree<T> = {
        var root : Node<T>;
        var size : Nat;
    };

    public module Tree = {
        public func toText<T>(tree : Tree<T>, toText : (t : T) -> Text) : Text {
            // TODO: replace debug_show
            "[size:"  # debug_show(tree.size) # "] " # Node.toText(tree.root, toText);
        };
    };

    public func insert<T>(tree : Tree<T>, key : [Char], value : T) : ?T {
        return _insert(tree, tree.root, 0, key, value);
    };

    private func _insert<T>(tree : Tree<T>, current : Node<T>, index : Nat, key : [Char], value : T) : ?T {
        if (index == key.size()) {
            let old = Node.addLeaf(current, key, value);
            switch (old) {
                case (null) tree.size += 1;
                case (? _) {}
            };
            return old;
        };
        let k = key[index];
        switch (Node.getEdge(current, k)) {
            case (_, ? edge) return _insert(tree, edge, index + 1, key, value);
            case (_) {};
        };
        switch (current.leaf) {
            case (? leaf) {
                if (key.size() < leaf.key.size()) {
                    let oldPrefix = current.prefix;
                    current.prefix := key;
                    current.leaf := ?{
                        key;
                        var value = value;
                    };
                    Node.addEdge<T>(current, {
                        key = k;
                        var node = {
                            var edges  = [];
                            var leaf   = ?leaf;
                            var prefix = Array.slice(oldPrefix, index, null);
                        };
                    });
                    tree.size += 1;
                    return null;
                };
            };
            case (null) { /* ignore */};
        };
        Node.addEdge<T>(current, {
            key = k; 
            var node = {
                var edges  = [];
                var leaf   = ?{
                    key;
                    var value = value;
                };
                var prefix = Array.slice(key, index, null);
            };
        });
        tree.size += 1;
        null;
    };

    public func delete<T>(tree : Tree<T>, key : [Char]) : ?T {
        let current = tree.root;
        if (key.size() == 0) return switch (current.leaf) {
            case (? leaf) {
                let old = leaf.value;
                current.leaf := null;
                tree.size -= 1;
                ?old;
            };
            case (null) null;
        };
        switch (Node.getEdge(current, key[0])) {
            case (i, ? edge) _delete(tree, current, i, edge, 1, key);
            case (_) null;
        };
    };

    private func _delete<T>(tree : Tree<T>, parent : Node<T>, edgeIndex : Nat, current : Node<T>, index : Nat, key : [Char]) : ?T {
        if (index == key.size()) {
            return switch (current.leaf) {
                case (? leaf) {
                    let old = leaf.value;
                    if (current.edges.size() == 0) {
                        let s = parent.edges.size();
                        if (s == 1) {
                            parent.edges := [];
                        } else {
                            parent.edges := Prim.Array_tabulate<EdgeNode<T>>(
                                s - 1,
                                func (i : Nat) : EdgeNode<T> {
                                    if (i < edgeIndex) return parent.edges[i];
                                    return parent.edges[i + 1];
                                }
                            );
                        };
                    } else {
                        current.leaf := null;
                    };
                    tree.size -= 1;
                    ?old;
                };
                case (null) null;
            };
        };
        switch (Node.getEdge(current, key[index])) {
            case (i, ? edge) _delete(tree, current, i, edge, index + 1, key);
            case (_) null;
        };
    };

    public func get<T>(tree : Tree<T>, key : [Char]) : ?T {
        _get(tree.root, 0, key);
    };

    private func _get<T>(current : Node<T>, index : Nat, key : [Char]) : ?T {
        switch (current.leaf) {
            case (? leaf) {
                if (index == key.size() or leaf.key == key) return ?leaf.value;
            };
            case (null) {};
        };
        switch (Node.getEdge(current, key[index])) {
            case (_, ? edge) _get(edge, index + 1, key);
            case (_) null;
        };
    };

    public type Node<T> = {
        var prefix : [Char];
        var leaf   : ?LeafNode<T>;
        var edges  : Edges<T>;
    };

    public module Node = {
        public func new<T>() : Node<T> = {
            var prefix  = [];
            var leaf    = null;
            var edges   = [];
        };

        public func equal<T>(x : Node<T>, y : Node<T>) : Bool { x.prefix == y.prefix };

        public func newLeafNode<T>(leaf : LeafNode<T>) : Node<T> = {
            var prefix  = [];
            var leaf    = ?leaf;
            var edges   = [];
        };

        public func toText<T>(node : Node<T>, toText : (t : T) -> Text) : Text {
            var t = switch (node.prefix.size()) {
                case (0) "";
                case (_) "("  # Text.fromArray(node.prefix) # ") ";
            };
            switch (node.leaf) {
                case (? leaf) {
                    t #= LeafNode.toText(leaf, toText);
                };
                case (_) {};
            };
            if (node.prefix.size() != 0 and node.edges.size() != 0) t #= " ";
            t # Edges.toText(node.edges, toText);
        };

        public func isLeaf<T>(node : Node<T>) : Bool = switch (node.leaf) {
            case (? _) true;
            case (  _) false;
        };

        /// Returns the node with the given key from the given node's edges.
        public func getEdge<T>(node : Node<T>, key : Char) : (index : Nat, edge : ?Node<T>) {
            let n = node.edges.size();
            let i = Search.search(n, func (i : Nat) : Bool {
                node.edges[i].key >= key
            });
            if (i < n and node.edges[i].key == key) {
                return (i, ?node.edges[i].node);
            };
            return (0, null);
        };

        /// Adds the given edge to the given node's edges.
        public func addEdge<T>(node : Node<T>, edge : EdgeNode<T>) {
            node.edges := Sort.insert(
                node.edges, edge,
                func(x : EdgeNode<T>, y : EdgeNode<T>) : Compare.Order {
                    Char.cf(x.key, y.key);
                }
            );
        };

        public func addLeaf<T>(node : Node<T>, key : [Char], value : T) : ?T {
            switch (node.leaf) {
                case (? leaf) {
                    // Replace the old leaf value.
                    if (leaf.key == key) {
                        let old = leaf.value;
                        leaf.value := value;
                        return ?old;
                    };
                    let old : LeafNode<T> = {
                        key = leaf.key;
                        var value = leaf.value;
                    };
                    node.prefix := key;
                    node.leaf := ?{
                        key;
                        var value = value;
                    };
                    Node.addEdge<T>(node, {
                        key = old.key[0];
                        var node = {
                            var edges  = [];
                            var leaf   = ?old;
                            var prefix = old.key;
                        };
                    });
                    null;
                };
                case (null) {
                    // No leaf present.
                    node.leaf := ?{
                        key;
                        var value = value;
                    };
                    null;
                };
            };
        };
    };

    public type LeafNode<T> = {
        key       : [Char];
        var value : T;
    };

    public module LeafNode = {
        public func toText<T>(leaf : LeafNode<T>, toText : (t : T) -> Text) : Text {
            Text.fromArray(leaf.key) # ":" # toText(leaf.value);
        };
    };

    public type EdgeNode<T> = {
        key      : Char;
        var node : Node<T>;
    };

    public module EdgeNode = {
        public func toText<T>(edge : EdgeNode<T>, toText : (t : T) -> Text) : Text {
            Prim.charToText(edge.key) # " " # Node.toText(edge.node, toText);
        };
    };

    public type Edges<T> = [EdgeNode<T>];

    public module Edges = {
        public func toText<T>(edges : Edges<T>, toText : (t : T) -> Text) : Text {
            if (edges.size() == 0) return "";
            var t = "[";
            var i = 0;
            for (edge in edges.vals()) {
                if (i != 0) t #= ", ";
                t #= EdgeNode.toText(edge, toText);
                i += 1;
            };
            t # "]";
        };
    };

    public func size<T>(t : Tree<T>) : Nat = t.size;

    public func toArray<T>(tree : Tree<T>) : [([Char], T)] {
        let b = Stack.init<([Char], T)>(tree.size);
        walk(tree.root, func (key : [Char], value : T) : Bool {
            Stack.push(b, (key, value));
            false;
        });
        Stack.toArray(b);
    };

    public func walk<T>(node : Node<T>, f : (key : [Char], value : T) -> Bool) {
        ignore _walk(node, f);
    };

    private func _walk<T>(node : Node<T>, f : (key : [Char], value : T) -> Bool) : Bool {
        switch (node.leaf) {
            case (? leaf) {
                if (f(leaf.key, leaf.value)) return true;
            };
            case (_) {};
        };
        for (e in node.edges.vals()) {
            if (_walk(e.node, f)) return true;
        };
        return false;
    };
};
