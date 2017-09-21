//
//  ModuleInjection.h
//  Module
//
//  Created by mike on 2017/9/21.
//  Copyright © 2017年 mike. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Module.h>

@interface ModuleInjection : NSObject <ModuleInjection>
-(void) registModule:(NSString*) name class:(Class) cls interfaces:(NSArray<Protocol*>*) interfaces;
@end
