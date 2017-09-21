//
//  Module.h
//  Module
//
//  Created by mike on 2017/9/20.
//  Copyright © 2017年 mike. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for Module.
FOUNDATION_EXPORT double ModuleVersionNumber;

//! Project version string for Module.
FOUNDATION_EXPORT const unsigned char ModuleVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <Module/PublicHeader.h>

#define ModuleLoader(M) \
__attribute__((constructor)) \
static void M##_ModuleLoader(){ \
    Class cls = [M class]; \
    NSArray * list = [[[NSThread mainThread] threadDictionary] objectForKey:@"_module_registes"]; \
    list = list ? list : @[]; \
    list = [list arrayByAddingObject:cls]; \
    [[[NSThread mainThread] threadDictionary] setObject:list forKey:@"_module_registes"]; \
}

@protocol ModuleInjection <NSObject>
-(id) instanceForInterface:(Protocol*) interface;
@end

@protocol Module <NSObject>
+(NSArray*) Interfaces;
+(BOOL) loadWhenStart;
-(id) initWithInjection:(id) injection;
@end

@class Module;
