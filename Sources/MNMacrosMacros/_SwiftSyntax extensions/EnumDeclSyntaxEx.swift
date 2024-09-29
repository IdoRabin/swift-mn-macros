//
//  EnumDeclSyntaxEx.swift
//  SimplifiedEnumMacro
//
//  Created by ido on 29/09/2024.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public extension EnumDeclSyntax {
    func allEnumCaseDeclerations(viewMode _: SyntaxTreeViewMode = .all) -> [EnumCaseElementSyntax] {
        var result: [EnumCaseElementSyntax] = []
        for child in memberBlock.members {
            if // let child = child.as(MemberBlockItemSyntax.self),
               let enumCase = child.decl.as(EnumCaseDeclSyntax.self)?.enumCaseElementSyntax()
            {
                result.append(enumCase)
            }
        }
        return result
    }
}
