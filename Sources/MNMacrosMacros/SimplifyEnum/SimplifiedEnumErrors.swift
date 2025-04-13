//
//  SimplifiedEnumErrors.swift
//  SimplifiedEnumMacro
//
//  Created by ido on 29/09/2024.
//
import SwiftSyntax
import SwiftDiagnostics

public enum SimplifiedEnumErrors : CustomStringConvertible, Error, Codable, Hashable {
    fileprivate static let ERROR_DOMAIN = "MNMacros.SimplifiedEnum"
    
    case canOnlyImplementOnEnum
    case canOnlyImplementOnAssocValuedEnum
    case alreadyHasSimplifiedImplementedInEnum
    case hasMultipleAssocValueTypesInCase(String) // TODO: Check why multiple associated values for one case (i.e associated "tuple") was decided to be non-Simplable?
    case caseHasNoClearCaseName(String)
    case failedCreatingSimplifiedEnum(String)
    
    // Needed for fixit and Diagnostic
    
    public var description: String {
        switch self {
        case .canOnlyImplementOnEnum:
            return "SimplifiedEnum macro can only be applied to an Enum. (NOTE: the enum decleration must have has at least one case with an associated value.)"
        case .canOnlyImplementOnAssocValuedEnum:
            return "SimplifiedEnum macro can only be applied to an Enum decleration that has at least one case with an associated value."
        case .alreadyHasSimplifiedImplementedInEnum:
            return "SimplifiedEnum macro cannot be implemented: the Enum \"Simplified\" was already declared."
        case .hasMultipleAssocValueTypesInCase(let name):
            return "SimplifiedEnum macro cannot be implemented: the Enum \"Simplified\" has multiple associated type parameters in decleration of case \(name)."
        case .caseHasNoClearCaseName(let text):
            return "SimplifiedEnum macro cannot be implemented: the Enum \"Simplified\" has no clear case name for associated types: \(text)."
        case .failedCreatingSimplifiedEnum(let name):
            return "SimplifiedEnum macro failed creating a simplified sub-enum for: \(name)"
        }
    }
    
    fileprivate var diagnosticMessage : String {
        return self.description
    }
    
    public var fixItMessageStr : String {
        switch self {
        case .canOnlyImplementOnEnum:
            return "change this to an Enum with at least one associated value."
        case .canOnlyImplementOnAssocValuedEnum:
            return "add to at least one case an associatd value"
        case .alreadyHasSimplifiedImplementedInEnum:
            return "Remove or rename Enum \"Simplified\" to something else."
        case .hasMultipleAssocValueTypesInCase(let name):
            // TODO: Why is this an error?
            return "Change the case \(name)'s associated types to be a single-value type (non-tuple, non-comma delimited type)."
        case .caseHasNoClearCaseName(let text):
            return "give a clear case name to \(text)."
        case .failedCreatingSimplifiedEnum(let name):
            return "failed creating a Simplified Enum for: \(name)."
        }
    }
    
    public var asFixitMessage : FixItMessage {
        return SimplifiedEnumFixItMessage(err: self)
    }
}

// Remove or rename Enum

extension SimplifiedEnumErrors : DiagnosticMessage {
    public var message: String {
        return self.diagnosticMessage
    }
    
    public var diagnosticID: SwiftDiagnostics.MessageID {
        return MessageID(domain: SimplifiedEnumErrors.ERROR_DOMAIN + ".diagID", id: "\(self)")
    }
    
    public var severity: SwiftDiagnostics.DiagnosticSeverity {
        return .error
    }
}

struct SimplifiedEnumFixItMessage : FixItMessage  {
    private var error : SimplifiedEnumErrors
    
    init(err: SimplifiedEnumErrors) {
        self.error = err
    }
    
    var fixItID: SwiftDiagnostics.MessageID {
        return MessageID(domain: SimplifiedEnumErrors.ERROR_DOMAIN + ".fixitID", id: "\(error)")
    }
    
    var message: String {
        return error.fixItMessageStr
    }
}

public extension SimplifiedEnumErrors /*FixIt*/ {
    
    func asFixit(node oldDecl:Syntax)->(FixIt, AbsolutePosition)? {
        let oldNode : EnumDeclSyntax? = oldDecl.as(EnumDeclSyntax.self)
        var changes : [FixIt.Change] = []
        var newName = oldNode?.name.trimmedDescription ?? oldDecl.trimmedDescription
        var fixitPosition : AbsolutePosition = oldDecl.position
        
        // At least one change required:
        switch self {
        case .canOnlyImplementOnEnum:
            // Find the name in the decl:
            do {
                if let found = try oldDecl.firstDeclChildWithName(nil, excluding:[.macroDecl]) {
                    // print(">>> Found firstDeclChildWithName decl: \(found.name) kind: \(found.item.kind)")
                    newName = found.name
                }
            } catch let error {
                print("WARNNG! SimplifiedEnumErrors.asFixit.canOnlyImplementOnEnum failed firstDeclChildWithName with error: \(error)")
            }
            
            // Create change:
            let newNode = DeclSyntax(stringLiteral:"""
@SimplifiedEnum
enum \(newName) {
case one
case two
}
""")
            let change = FixIt.Change.replace(oldNode: oldDecl, newNode: Syntax(newNode))
            changes.append(change)
        case .canOnlyImplementOnAssocValuedEnum:
            let types = ["String", "Int", "Bool", "[String]", "[Int]", "[Bool]", "MyExampleType"]
            var atypeEnum = types.makeIterator()
            let enumCaseDecls = oldNode!.allEnumCaseDeclerations()
            fixitPosition = enumCaseDecls.first?.position ?? fixitPosition
            
            for enumCaseDecl in enumCaseDecls {
                if let atype = atypeEnum.next() ?? {atypeEnum = types.makeIterator(); return atypeEnum.next()}() {
                    let newNode = DeclSyntax(stringLiteral:"case \(enumCaseDecl.name.trimmedDescription)(\(atype))")
                    let change = FixIt.Change.replace(oldNode: Syntax(enumCaseDecl), newNode: Syntax(newNode))
                    changes.append(change)
                }
            }
            break
        case .alreadyHasSimplifiedImplementedInEnum:
            do {
                if let oldNode = oldNode, let foundItem = try oldNode.firstDeclChildWithName("Simplified", excluding: [.macroDecl]) {
                    var newSimplified = foundItem.item.as(EnumDeclSyntax.self)!
                    fixitPosition = foundItem.item.position
                    newSimplified.name = "old_Simplified"
                    let change = FixIt.Change.replace(oldNode: Syntax(foundItem.item), newNode: Syntax(newSimplified))
                    changes.append(change)
                } else {
                    throw SimplifiedEnumErrors.canOnlyImplementOnEnum
                }
            } catch let err {
                print("Error finding the Simplified sub-Enum for the Fixit. \(err)")
            }
            break
        case .hasMultipleAssocValueTypesInCase(let string):
            // detect multiple valued cases, add fixits
            break
        case .caseHasNoClearCaseName(let string):
            break // error only, no suggestion to fix
        case .failedCreatingSimplifiedEnum(let string):
            break // error only, no suggestion to fix
        }
        
        if changes.count > 0 {
            return (FixIt(message: SimplifiedEnumFixItMessage(err: self),
                         changes: changes),
                    fixitPosition)
        }
        return nil
    }
    
    func asDiagnostic(node:Syntax)->Diagnostic {
//        SwiftSyntax.Diagnostic:
//        ... public init(
        //          node: some SyntaxProtocol,
        //          position: AbsolutePosition? = nil,
        //          message: DiagnosticMessage,
        //          highlights: [Syntax]? = nil,
        //          notes: [Note] = [],
        //          fixIt: FixIt
        // } ...
        
        
        // TODO: Learn how to add a fixit at a position different than the root decl node, then imlement the following correctly:
        /*
        if let fixitItem = self.asFixit(node: node) {
            let fixit = fixitItem.0
            let position = fixitItem.1
            
            let change = fixit.changes.first
            if self == .alreadyHasSimplifiedImplementedInEnum {
                print("Change: \(change.debugDescription)")
            }
            return Diagnostic(node: node,
                              position: position,
                              message: self /* conforms to DiagnosticMessage */,
                              fixIt:fixit)
        }
         */
        
        // No fixit created
        return Diagnostic(node: node,
                          position: node.position,
                          message: self /* conforms to DiagnosticMessage */)
    }
}
