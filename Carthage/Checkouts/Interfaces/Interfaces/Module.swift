//
//  Module.swift
//  Interfaces
//
//  Created by 王航 on 2017/10/21.
//  Copyright © 2017年 mike. All rights reserved.
//

import Foundation

public enum ModuleInjectError: Error {
    case ModuleNotFound(msg:String)
    case CircleDependency(msg:String)
}

@objc public protocol ModuleInject:AnyObject {
    @objc func instance(interface:AnyObject) throws ->AnyObject
}

public class ModuleInjectT {
    let inject:ModuleInject
    public init(_ inject:ModuleInject) {
        self.inject = inject
    }
    public func instance<T>() throws ->T{
        if let val = try inject.instance(interface:T.self as AnyObject) as? T {
            return val
        }
        throw ModuleInjectError.ModuleNotFound(msg: String(describing: T.self as AnyObject))
    }
}

@objc public protocol Module:AnyObject {
    @objc static func interfaces()->[AnyObject]
    @objc static func loadOnStart()->Bool
    @objc init(inject:ModuleInject)
}
