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
    var nameStrings: [String] {
        return map { identifierTypeSyntax in
            identifierTypeSyntax.name.text
        }
    }

    var namesDescription: String {
        let descs = self.nameStrings
        var result = ""
        switch descs.count {
        case 0:
            result = SimplifiedEnum.NO_ASSOCIATED_TYPES_STR // "[NO ASSOCIATED TYPES]"
        case 1:
            result = descs.first!
        default:
            result = descs.joined(separator: "_")
        }
        return result
    }
}
