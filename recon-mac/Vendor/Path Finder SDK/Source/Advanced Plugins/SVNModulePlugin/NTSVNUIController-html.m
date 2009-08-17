//
//  NTSVNUIController-html.m
//  SVNModulePlugin
//
//  Created by Steve Gehrman on 12/27/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NTSVNUIController-html.h"
#import "NTSVNUIController-Private.h"

@implementation NTSVNUIController (html)

- (NSString*)repositoryHTML;
{
	NSString* body = [NSString stringWithFormat:@"<div id=\"repository\"><h1>%@:</h1>"
		"<span id=\"path\">%@</span>"
		"</div>",
		[[self host] localize:@"Repository" table:@"modulePlugins"],
		[[self directory] path]];
	
	return body;
}

- (NSString*)navBarHTML;
{
	NSString* body = @"<div id=\"commands\">"
	"<ul>"
	"<li><a href=\"mshp://status\">%@</a>"
	"<li><a href=\"mshp://update\">%@</a>"
	"<li><a href=\"mshp://commit\">%@</a>"
	"<li><a href=\"mshp://diff\">%@</a>"
	"<li><a href=\"mshp://other\">%@</a>"
	"<li><a href=\"mshp://raw\">%@</a>"
	"<li><a href=\"mshp://terminal\">%@</a>"
	"</ul>"
	"</div>";
	
	body = [NSString stringWithFormat:body, 
		[[self host] localize:@"status" table:@"modulePlugins"],
		[[self host] localize:@"update" table:@"modulePlugins"],
		[[self host] localize:@"commit" table:@"modulePlugins"],
		[[self host] localize:@"diff" table:@"modulePlugins"],
		[[self host] localize:@"other" table:@"modulePlugins"],
		[[self host] localize:@"raw" table:@"modulePlugins"],
		[[self host] localize:@"terminal" table:@"modulePlugins"]
		];
	
	return body;
}

- (NSString*)footerHTML;
{
	NSString* body = @"<br><br>"
	"<p align=\"left\">"
	
	"</p>";
	
	return body;
}

@end
