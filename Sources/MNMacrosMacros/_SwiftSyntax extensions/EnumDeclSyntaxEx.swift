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
    
    /// Checks if the enum conforms to a given protocol.
        /// - Parameter protocolName: The name of the protocol to check.
        /// - Returns: A Boolean value indicating whether the enum conforms to the given protocol.
        func conformsToProtocol(_ protocolName: String) -> Bool {
            // Check if the enum has an inheritance clause
            guard let inheritanceClause = self.inheritanceClause else {
                return false // No inheritance clause means no conformance
            }

            // Loop through the inherited types and check if the protocol is listed
            for inheritedType in inheritanceClause.inheritedTypes {
                if let inheritedProtocol = inheritedType.type.as(IdentifierTypeSyntax.self)?.name.text {
                    if inheritedProtocol == protocolName {
                        return true // Protocol found
                    }
                }
            }

            return false // Protocol not found
        }
}
