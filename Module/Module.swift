//
//  Module.swift
//  Module
//
//  Created by 王航 on 2017/9/28.
//  Copyright © 2017年 mike. All rights reserved.
//

import Foundation
public enum ModuleInjectError: Error {
    case ModuleNotFound(msg:String)
    case CircleDependency(msg:String)
}
public protocol ModuleInject {
    func instance<T>() throws ->T
}
public protocol Module: NSObjectProtocol {
    static func interfaces()->[AnyObject]
    static func loadOnStart()->Bool
    init(inject:ModuleInject)
}

protocol ModuleLoader {
    func modules()->[AnyClass]
}

extension Array {
    public func appendBy(_ newElement: Element) -> Array<Element> {
        var ret = self
        ret.append(newElement)
        return ret
    }
}

class RootModule : NSObject, ModuleInject {
    let modules:[String:AnyClass]
    let interfaces:[String:String]
    var instances = [String:AnyObject]()
    private var circle = [String]()
    init(loader:ModuleLoader) {
        self.modules = Dictionary(uniqueKeysWithValues: loader.modules().map({ (m) -> (String,AnyClass) in
            return (String(describing:m),m)
        }))
        print("[module] modules:",self.modules)
        self.interfaces = self.modules.reduce([:], { (result, kv) -> [String:String] in
            let ins = (kv.value as? Module.Type)?.interfaces() ?? []
            let maps = ins.map({(p) -> (String,String) in
                return (String(describing: p),kv.key)
            })
            let dict = Dictionary(uniqueKeysWithValues: maps)
            return result.merging(dict, uniquingKeysWith: { (a, b) -> String in
                return a
            })
        })
        super.init()
        
        let ms = self.modules
        let loadOnStartModules = self.modules.keys.filter { (name) -> Bool in
            return (ms[name] as? Module.Type)?.loadOnStart() ?? false
        }
        loadOnStartModules.forEach {try? self.loadModule(name: $0)}
    }
    
    func instance<T>() throws ->T{
        let ints = self.interfaces
        let key = String(describing: T.self as AnyObject)
        print("[module] instance:",key)
        guard let objKey = ints[key] else {
            throw ModuleInjectError.ModuleNotFound(msg: key)
        }
        let vals = self.instances
        if let val = vals[objKey] as? T {
            return val
        }
        try self.loadModule(name:objKey)
        let vals2 = self.instances
        if let val = vals2[objKey] as? T {
            return val
        }
        throw ModuleInjectError.ModuleNotFound(msg: key)
    }
    func loadModule(name:String) throws{
        try syncRunOnMain {
            guard self.instances[name] == nil else {
                return
            }
            if let module = self.modules[name] as? Module.Type {
                let msg = self.circle.appendBy(name).joined(separator: " -> ")
                if self.circle.contains(name) {
                    throw ModuleInjectError.CircleDependency(msg: msg)
                }
                self.circle.append(name)
                let m = module.init(inject: self)
                self.instances[name] = m as AnyObject
                _ = self.circle.popLast()
                print("[module] module loaded:",name)
            }
        }
    }
    func syncRunOnMain(block:()throws ->Void) rethrows{
        if Thread.isMainThread {
            try block()
        }else{
            try DispatchQueue.main.sync(execute: block)
        }
    }
}

class Loader:NSObject,ModuleLoader {
    func modules() -> [AnyClass] {
        let expectedClassCount = objc_getClassList(nil, 0)
        let allClasses = UnsafeMutablePointer<AnyClass>.allocate(capacity: Int(expectedClassCount))
        let autoreleasingAllClasses = AutoreleasingUnsafeMutablePointer<AnyClass>(allClasses) // Huh? We should have gotten this for free.
        let actualClassCount:Int32 = objc_getClassList(autoreleasingAllClasses, expectedClassCount)
        var classes = [AnyClass]()
        for i in 0 ..< actualClassCount {
            if let cls = allClasses[Int(i)] as? Module.Type{
                if !classes.contains(where: {$0.isSubclass(of: cls as AnyClass)}){ // only load final class
                    classes = classes.filter({ !(cls as AnyClass).isSubclass(of: $0)})
                    classes.append(cls)
                }
            }
        }
        allClasses.deallocate(capacity: Int(expectedClassCount))
        return classes
    }
}
public let root:ModuleInject = RootModule(loader: Loader())
