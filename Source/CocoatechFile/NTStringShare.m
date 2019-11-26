//
//  NTStringShare.m
//  CocoatechFile
//
//  Created by Steve Gehrman on Sat Dec 06 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "NTStringShare.h"
/*

Kind strings and file extensions aren't that varied.  Rather than every object owning their own copy of the string "txt", or "Text Document", this class allows them to share the same instance

*/

@interface NTStringShare ()
@property (nonatomic, retain) NSLock *kindLock;
@property (nonatomic, retain) NSLock *extensionLock;
@property (nonatomic, retain) NSMutableSet *kindStrings;
@property (nonatomic, retain) NSMutableSet *extensionStrings;
@property (nonatomic, retain) NSString *packageKindString;
@property (nonatomic, retain) NSString *volumeKindString;
@property (nonatomic, retain) NSString *folderKindString;
@property (nonatomic, retain) NSString *symbolicLinkKindString;
@property (nonatomic, retain) NSString *documentKindString;
@end

@interface NTStringShare (Private)
- (NSMutableSet*)defaultKindStrings;
- (NSMutableSet*)defaultExtensions;
@end

@implementation NTStringShare

NTSINGLETON_INITIALIZE;
NTSINGLETONOBJECT_STORAGE;

@synthesize kindLock;
@synthesize extensionLock;
@synthesize kindStrings;
@synthesize extensionStrings;
@synthesize packageKindString;
@synthesize volumeKindString;
@synthesize folderKindString;
@synthesize symbolicLinkKindString;
@synthesize documentKindString;

- (id)init;
{
    self = [super init];
	
	self.packageKindString = [NTLocalizedString localize:@"Package" table:@"CocoaTechFoundation"];
	self.volumeKindString = [NTLocalizedString localize:@"Volume" table:@"CocoaTechFoundation"];
	self.folderKindString = [NTLocalizedString localize:@"Folder" table:@"CocoaTechFoundation"];
	self.symbolicLinkKindString = [NTLocalizedString localize:@"Symbolic Link" table:@"CocoaTechFoundation"];
	self.documentKindString = [NTLocalizedString localize:@"Document" table:@"CocoaTechFoundation"];
	
	[self setKindLock:[[[NSLock alloc] init] autorelease]];
    [self setExtensionLock:[[[NSLock alloc] init] autorelease]];

	[self setKindStrings:[self defaultKindStrings]];
    [self setExtensionStrings:[self defaultExtensions]];
	
    return self;
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{
    self.kindLock = nil;
    self.extensionLock = nil;
    self.kindStrings = nil;
    self.extensionStrings = nil;
    self.packageKindString = nil;
    self.volumeKindString = nil;
    self.folderKindString = nil;
    self.symbolicLinkKindString = nil;
    self.documentKindString = nil;
	
    [super dealloc];
}

- (NSString*)sharedKindString:(NSString*)kindString;
{
    if (kindString && [kindString length])
    {
        if ([self.kindLock tryLock])
        {
            NSString* result = [self.kindStrings member:kindString];
            if (!result)
            {
                [self.kindStrings addObject:kindString];
                
                result = kindString;
            }
            
            [self.kindLock unlock];
            
            return result;
        }
    }
    
    return kindString;
}

- (NSString*)sharedExtensionString:(NSString*)extensionString;
{
    if (extensionString && [extensionString length])
    {    
        if ([self.extensionLock tryLock])
        {
            NSString* result = [self.extensionStrings member:extensionString];
            if (!result)
            {
                [self.extensionStrings addObject:extensionString];
                
                result = extensionString;
            }
            
            [self.extensionLock unlock];
            
            return result;
        }
    }
    
    return extensionString;
}

@end

@implementation NTStringShare (Private)

- (NSMutableSet*)defaultExtensions;
{
    return [[[NSMutableSet alloc] initWithObjects:
        @"txt",
        @"text",
        @"doc",
        @"rtf",
        @"rtfd",
        
        @"html",
        @"htm",
        @"php",
        @"cgi",
        
        @"c",
        @"m",
        @"h",
        @"cp",
        @"cpp",
        @"cc",
        @"mm",
        @"sh",
        @"in",
        @"xml",
        @"rb",
        @"pl",
        @"plx",
        @"xsl",
        @"pm",
        @"css",
        @"spec",
        @"lsm",
        @"csh",
        @"r",
        @"java",
        @"plist",
        @"info",
        
        @"mov",
        @"fcp",
        @"swf",
        @"mpeg",
        @"mpg",
        @"mp3",
        @"mp4",
        @"avi",
        @"snd",
        @"wav",
        @"au",
        @"aif",
        @"aiff",
        
        @"ai",
        @"eps",
        @"tif",
        @"tiff",
        @"gif",
        @"jpg",
        @"jpeg",
        @"pdf",
        @"icns",
        @"ico",
        
        @"dmg",
        @"img",
        @"smi",
        @"toast",
        
        @"ape",

        @"tgz",
        @"zip",
        @"gz",
        @"sit",
        @"sitx",
        @"pkg",
        
        @"webloc",
        @"help",
        @"obj",
        @"localized",
        @"url",
        @"applescript",
        @"plugin",
        @"cfg",
        @"dic",
        @"dat",
        @"js",
        @"jar",
        @"class",
        @"png",
        @"scriptSuite",
        @"scriptTerminology",
        @"app",
        @"rpm",
        @"lproj",

        @"acb",
        @"aco",
        @"grd",
        @"irs",
        @"pat",
        @"abr",
        @"atn",
        @"scpt",
        @"menu",
        @"dtd",
        @"sql",
        @"ini",
        @"pbproj",
        @"asf",
        @"mpkg",
        @"psd",
        @"zvt",
        @"tpl",
        @"asl",
        @"act",
        @"iros",
        @"ent",

        nil] autorelease];
}

- (NSMutableSet*)defaultKindStrings;
{
    return [[[NSMutableSet alloc] initWithObjects:
        
        [self packageKindString],
        [self volumeKindString],
        [self folderKindString],
        [self symbolicLinkKindString],
        [self documentKindString],        
        
        nil] autorelease];
}

@end


