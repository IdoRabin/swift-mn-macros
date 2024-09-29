//
//  SyntaxProtocolEx.swift
//  SimplifiedEnumMacro
//
//  Created by ido on 29/09/2024.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public extension SyntaxProtocol {
    private func internal_recursiveParents(where test: SyntaxProtocolTest, stopOnFirst: Bool, depth: Int) throws -> [any SyntaxProtocol] {
        guard depth < DeclGroupSyntaxErrors.declGroupSyntaxMaxRecursion else {
            throw DeclGroupSyntaxErrors.DeclGroupSyntaxRecursionTooDeep
        }

        var result: [any SyntaxProtocol] = []
        if test(self, depth) {
            result.append(self)
            if stopOnFirst { return result }
        }

        if let prnt = parent {
            try result.append(contentsOf:
                prnt.internal_recursiveParents(where: test, stopOnFirst: stopOnFirst, depth: depth + 1)
            )
        }

        return result
    }

    func recursiveParents(where test: SyntaxProtocolTest) throws -> [any SyntaxProtocol] {
        return try internal_recursiveParents(where: test, stopOnFirst: false, depth: 0)
    }

    /// Get the nearest parent where the test passes (nearest to self node)
    /// - Parameter test: test for the parent to tast in order to be included in the result
    /// - Returns: the nearest (nearest to self, going up the tree) parent which passes the test, or nil if not found
    func firstRecursiveParent(where test: SyntaxProtocolTest) throws -> (any SyntaxProtocol)? {
        return try internal_recursiveParents(where: test, stopOnFirst: false, depth: 0).first
    }

    /// Get the top most parent where the test passes
    /// NOTE: Convenience method, this is exactly the same as calling `topMostRecursiveParent(where test:...)`
    /// - Parameter test: test for the parent to tast in order to be included in the result
    /// - Returns: the topmost (nearest to root) parent which passes the test, or nil if not found
    func lastRecursiveParent(where test: DeclGroupTest) throws -> (any SyntaxProtocol)? {
        return try topMostRecursiveParent(where: test)
    }

    /// Get the top most parent where the test passes
    /// - Parameter test: test for the parent to tast in order to be included in the result
    /// - Returns: the topmost (nearest to root) parent which passes the test, or nil if not found
    func topMostRecursiveParent(where test: DeclGroupTest) throws -> (any SyntaxProtocol)? {
        return try internal_recursiveParents(where: test, stopOnFirst: false, depth: 0).last
    }
}
