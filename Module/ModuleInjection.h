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
-(void) registModule:(Class) cls interfaces:(NSArray<Protocol*>*) interfaces loadOnStart:(BOOL)load;
-(void) boot;
@end
