//
//  EnumCaseParameterClauseSyntax.swift
//  SimplifiedEnumMacro
//
//  Created by ido on 29/09/2024.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public extension EnumCaseParameterClauseSyntax {
    var hasValidParantheses: Bool {
        return
            leftParen.tokenKind == .leftParen &&
            rightParen.tokenKind == .rightParen
    }

    var associatedTypeIds: [IdentifierTypeSyntax] {
        guard hasValidParantheses else {
            return []
        }

        // Worst case: return the string text
        return parameters.compactMap { caseSyntex in
            caseSyntex.type.as(IdentifierTypeSyntax.self)
        } as [IdentifierTypeSyntax]
    }
}
