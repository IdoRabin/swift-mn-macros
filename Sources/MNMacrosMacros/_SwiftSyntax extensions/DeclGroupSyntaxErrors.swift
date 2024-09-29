//
//  DeclGroupSyntaxErrors.swift
//  SimplifiedEnumMacro
//
//  Created by ido on 29/09/2024.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

enum DeclGroupSyntaxErrors : Error, CustomStringConvertible {
    case DeclGroupSyntaxRecursionTooDeep
    
    var description : String {
        switch self {
        case .DeclGroupSyntaxRecursionTooDeep:
            return "DeclGroupSyntax recursion was too deep. (max \(Self.declGroupSyntaxMaxRecursion)"
        }
    }
    
    static var declGroupSyntaxMaxRecursion : Int {
        return 64
    }
}

public typealias DeclGroupTest = (_ item:any SyntaxProtocol, _ depth:Int)->Bool
public typealias SyntaxProtocolTest = (_ item:any SyntaxProtocol, _ depth:Int)->Bool
