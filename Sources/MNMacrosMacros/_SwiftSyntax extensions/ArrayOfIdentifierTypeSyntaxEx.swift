//
//  ArrayOfIdentifierTypeSyntaxEx.swift
//  SimplifiedEnumMacro
//
//  Created by ido on 29/09/2024.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public extension Sequence where Element == IdentifierTypeSyntax {
    var names: [String] {
        return map { identifierTypeSyntax in
            identifierTypeSyntax.name.text
        }
    }

    var namesDescription: String {
        let descs = names
        switch descs.count {
        case 0:
            return SimplifiedEnum.NO_ASSOCIATED_TYPES_STR // "[NO ASSOCIATED TYPES]"
        case 1:
            return descs.first!.description
        default:
            return descs.description
        }
    }
}
