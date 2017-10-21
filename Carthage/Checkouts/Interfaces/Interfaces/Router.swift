//
//  Router.swift
//  Interfaces
//
//  Created by 王航 on 2017/10/21.
//  Copyright © 2017年 mike. All rights reserved.
//

import UIKit

@objc public protocol Router: AnyObject {
    func push(path:String)
    func replace(path:String)
    func pop()
    
    func addRouter(path:String,comptent:@escaping (String,[String:String])->UIViewController?)
    func addDefaultRouter(comptent:@escaping (String,[String:String])->UIViewController?)
    func addSubRouter(path:String, comptent:@escaping (String,[String:String])->Void) -> Router
}
