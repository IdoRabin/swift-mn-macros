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

class EnumSyntaxCaseUtil {
    static func cleanName(_ name:String, `default` defaultStr:String)->String {
        var result = name
        guard !result.isEmpty else {
            return defaultStr
        }
        
        let prefixes = ["case ", "any "]
        for aprefix in prefixes {
            result = String(result.trimmingPrefix(aprefix))
        }
        let seperators = ["(", "<"]
        for asep in seperators {
            result = String(result.split(separator: asep).first ?? String.SubSequence(defaultStr))
        }
        return result.replacingOccurrences(of: " ", with: "_")
    }
}

public extension EnumCaseParameterClauseSyntax {
    
    var parentEnum : EnumDeclSyntax? {
        do {
            let parentEnum = try self.firstRecursiveParent { item, depth in
                item.is(EnumDeclSyntax.self)
            }
            if parentEnum?.kind == SyntaxKind.enumDecl, let parentEnum = parentEnum?.as(EnumDeclSyntax.self) {
                return parentEnum
            }
        } catch let error {
            print("Error EnumCaseParameterClauseSyntax.parentEnum not found with error: \(error.localizedDescription)")
        }
        
        
        return nil
    }
    
    var parentEnumCase : EnumCaseDeclSyntax? {
        do {
            let parentCase = try self.firstRecursiveParent { item, depth in
                item.is(EnumCaseDeclSyntax.self)
            }
            if parentCase?.kind == SyntaxKind.enumCaseDecl, let parentCase = parentCase?.as(EnumCaseDeclSyntax.self) {
                return parentCase
            }
        } catch let error {
            print("Error EnumCaseParameterClauseSyntax.parentCase not found with error: \(error.localizedDescription)")
        }
        
        
        return nil
    }
    
    var parentEnumCaseName : String? {
        guard let acase = self.parentEnumCase else {
            return "Unknown_case"
        }
        // acase.trimmedDescription is expected to return: "case custom((any CustomStringConvertible, any Comparable)->Bool)"
        return EnumSyntaxCaseUtil.cleanName(acase.trimmedDescription, default: "Unknown_case")
    }
    
    var hasValidParantheses: Bool {
        return
            leftParen.tokenKind == .leftParen &&
            rightParen.tokenKind == .rightParen
    }

    private func getAnonymousFuncParams(anonFunc:FunctionTypeSyntax)->[String] {
        let result : [String] = anonFunc.parameters.enumerated().compactMap { param in
            let index = param.offset.magnitude
            let name = "p\(index)" + (param.element.firstName?.text ?? EnumSyntaxCaseUtil.cleanName(param.element.type.trimmedDescription, default: "Unknown_param"))
            if !name.isEmpty {
                return name
            }
            return nil
        }
        return result
    }
    
    private func createAnonymousFuncAlias(anonFunc:FunctionTypeSyntax, index:Int)->TypeAliasDeclSyntax {
        let name = "Anonymous_Func_\(index)"
        return DeclSyntax(stringLiteral: "typealias \(name) = \(anonFunc.trimmedDescription)").as(TypeAliasDeclSyntax.self)!
    }
    
    var associatedTypeIds: [IdentifierTypeSyntax] {
        guard hasValidParantheses else {
            return []
        }

        // print("Checking associatedTypeIds for: [\(self.trimmedDescription)]")
        // Worst case: return the string text
        // Search for associated types that are Namd Types or typeAliased (named) functions
        let identifiers = parameters.compactMap { caseSyntex in
            caseSyntex.type.as(IdentifierTypeSyntax.self)
        } as [IdentifierTypeSyntax]
        
        return identifiers
    }
    
    var associatedFuncs : [IdentifierTypeSyntax] {
        var result : [IdentifierTypeSyntax] = []
        guard hasValidParantheses else {
            return result
        }
        
        // Check for assoc type of anonymous function:
        let funcs = parameters.compactMap { caseSyntex in
            caseSyntex.type.as(FunctionTypeSyntax.self)
        } as [FunctionTypeSyntax]
        
        //
        if !funcs.isEmpty {
            var idx = 0
            for funcSyntx in funcs {
                let newAlias : TypeAliasDeclSyntax = self.createAnonymousFuncAlias(anonFunc: funcSyntx, index: idx)
                // print("New alias: \(String(describing: newAlias.firstToken(viewMode: .all))) \(newAlias.debugDescription)")
                
                if let id = newAlias.name.text.isEmpty ? nil : newAlias.name {
                    // print("    anonymous func alias id: \(id.kind) \(id.tokenKind) \(id.text)")
                    let idType = IdentifierTypeSyntax(name:id)
                    result.append(idType)
                    idx += 1
                }
            }
        }
        
        return result
    }
}
