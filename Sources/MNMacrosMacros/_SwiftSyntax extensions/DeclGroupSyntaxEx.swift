//
//  DeclGroupSyntaxEx.swift
//  SimplifiedEnumMacro
//
//  Created by ido on 29/09/2024.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public extension DeclGroupSyntax {
    private func internal_RecourseChildren(where test: DeclGroupTest, stopOnFirst: Bool, viewMode: SyntaxTreeViewMode, depth: Int) throws -> [any SyntaxProtocol] {
        guard depth < DeclGroupSyntaxErrors.declGroupSyntaxMaxRecursion else {
            throw DeclGroupSyntaxErrors.DeclGroupSyntaxRecursionTooDeep
        }

        var result: [any SyntaxProtocol] = []
        if test(self, depth) {
            result.append(self)

            // Return if needed
            if stopOnFirst { return result }
        }

        for child in children(viewMode: viewMode) {
            if let child = child as? DeclGroupSyntax {
                try result.append(contentsOf:
                    child.internal_RecourseChildren(where: test, stopOnFirst: stopOnFirst, viewMode: viewMode, depth: depth + 1)
                )
            }

            // Return if needed
            if stopOnFirst, result.count > 0 { return result }
        }

        return result
    }

    func allRecoursedChildren(where test: DeclGroupTest, viewMode: SyntaxTreeViewMode = .all) throws -> [any SyntaxProtocol] {
        return try internal_RecourseChildren(where: test, stopOnFirst: false, viewMode: viewMode, depth: 0)
    }

    func firstRecoursedChild(where test: DeclGroupTest, viewMode: SyntaxTreeViewMode = .all) throws -> (any SyntaxProtocol)? {
        return try internal_RecourseChildren(where: test, stopOnFirst: true, viewMode: viewMode, depth: 0).first
    }
}
