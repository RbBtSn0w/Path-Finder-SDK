//
//  NTLaunchServiceHacks.m
//  CocoatechFile
//
//  Created by Steve Gehrman on Sun Mar 23 2003.
//  Copyright (c) 2003 CocoaTech. All rights reserved.
//

#import "NTLaunchServiceHacks.h"
#import "NTFSRefObject.h"

// undocumented function call
extern OSStatus _LSSetWeakBindingForType(OSType        inType,			// kLSUnknownType if no type binding performed
                         OSType        inCreator,		// always kLSUnknownCreator
                         CFStringRef   inExtension,	// or NULL if no extension binding is done
                         LSRolesMask   inRole,			// role for the binding
                         FSRef *       inAppRefOrNil);	// bound app or NULL to clear the binding

// undocumented function call
extern OSStatus _LSGetStrongBindingForRef(const FSRef *  inItemRef,
                          FSRef *        outAppRef);

// undocumented function call
extern OSStatus _LSSetStrongBindingForRef(const FSRef *  inItemRef,
                          FSRef *        inAppRefOrNil);	// NULL to clear the strong binding

@implementation NTLaunchServiceHacks

+ (OSStatus)LSSetWeakBindingForType:(OSType)inType			// kLSUnknownType if no type binding performed
                            creator:(OSType)inCreator		// always kLSUnknownCreator
                          extension:(NSString*)inExtension	// or NULL if no extension binding is done
                               role:(LSRolesMask)inRole			// role for the binding
                        application:(FSRef *)inAppRefOrNil;	// bound app or NULL to clear the binding
{
    // undocumented function call
    return _LSSetWeakBindingForType(inType,			// kLSUnknownType if no type binding performed
                                    inCreator,		// always kLSUnknownCreator
                                    (CFStringRef)inExtension,	// or NULL if no extension binding is done
                                    inRole,			// role for the binding
                                    inAppRefOrNil);	// bound app or NULL to clear the binding
}

+ (OSStatus)LSGetStrongBindingForRef:(const FSRef *)inItemRef
                           outAppRef:(FSRef *)outAppRef;
{
    // undocumented function call
    return _LSGetStrongBindingForRef(inItemRef, outAppRef);
}

+ (OSStatus)LSSetStrongBindingForRef:(const FSRef *)inItemRef
                         application:(FSRef *)inAppRefOrNil;	// NULL to clear the strong binding
{
    // undocumented function call
    return _LSSetStrongBindingForRef(inItemRef, inAppRefOrNil);	// NULL to clear the strong binding
}

@end

