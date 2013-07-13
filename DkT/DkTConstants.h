//
//  DkTConstants.h
//  DkTp
//
//  Created by Matthew Zorn on 5/21/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#ifndef DkT_DkTConstants_h
#define DkT_DkTConstants_h

#define kAppName @"FedDocket"
#define kAppID @""
#define kActiveColor [UIColor colorWithRed:104./255 green:135./255 blue:152./255 alpha:1]
#define kActiveColorLight [UIColor colorWithRed:200./255 green:221./255 blue:230./255 alpha:1]

#define kDarkTextColor [UIColor colorWithRed:38./255 green:38./255. blue:38./255 alpha:1]
#define kTextColor [UIColor colorWithRed:235./255 green:235./255 blue:235./255 alpha:1]
#define kLightTextColor [UIColor colorWithRed:245./255 green:245./255 blue:245./255 alpha:1]

#define kInactiveColor [UIColor colorWithRed:235./255 green:235./255 blue:235./255 alpha:1]
#define kInactiveColorDark [UIColor colorWithRed:200./255 green:211./255 blue:211./255 alpha:1]

#define kDateTextColor [UIColor redColor]

#define kMainFont @"STHeitiSC-Medium"
#define kLightFont @"STHeitiSC-Light"
#define kContrastFont @"Cutive-Regular"
#define kStatusFont @"Montserrat-Regular"
#define kHelpFont [UIFont systemFontOfSize:10]
#define kBoldHelpFont [UIFont boldSystemFontOfSize:10]


#define kTabBarImage [UIImage imageNamed:@"tabBarImage"]
#define kTabBarHeight .12
#define kBookmarkPath 
#define kBodyColor

#define kSearchImage [UIImage imageNamed:@"search"]
#define kBookmarkImage [UIImage imageNamed:@"bookmark"]
#define kDocumentsImage [UIImage imageNamed:@"documents"]
#define kDocketImage [UIImage imageNamed:@"docket"]
#define kSearchSmallImage [UIImage imageNamed:@"searchSmall"]
#define kTabImage [UIImage imageNamed:@"home"]
#define kSettingsImage [UIImage imageNamed:@"settings"]
#define kQuestionsImage [UIImage imageNamed:@"question"]
#define kInfoImage [UIImage imageNamed:@"card"]
#define kShareIcon [UIImage imageNamed:@"share"]
#define kLoginButtonImage [UIImage imageNamed:@"key"]
#define kSessionButtonImage [UIImage imageNamed:@"session"]
#define kFolderImage [UIImage imageNamed:@"folder"]
#define kDocumentIcon [UIImage imageNamed:@"document"]
#define kClipboardImage [UIImage imageNamed:@"clipboard"]
#define kSavedDocuments [UIImage imageNamed:@"save"]
#define kSubscribeImage [UIImage imageNamed:@"subscribe"]
#define kSearchButtonImage [UIImage imageNamed:@"searchButtonImage"]
#define kUpdateImage [UIImage imageNamed:@"update"]

#define kAppStoreURL @"http://itunes.apple.com/"

#define kCaseNoKey @"case_no"
#define kDCRegionKey @"dc_region"
#define kDateFiledStartKey @"date_filed_start"
#define kDateFiledEndKey @"date_filed_end"
#define kDateTermStartKey @"date_term_start"
#define kDateTermEndKey @"date_term_end"
#define kPartyKey @"party"
#define kCourtTypeKey @"court_type"

#define kStatusBarHeight 20.0

#define kToolbarIconSize CGSizeMake(30,30)

#define kBaseFolder @"Federal Dockets"
#define kDocketsFolder @"Federal Dockets"

#define kDownloadStringsNotFoundSet [NSSet new]
typedef enum {PACERCourtTypeNone, PACERCourtTypeAppellate, PACERCourtTypeBankruptcy, PACERCourtTypeCivil, PACERCourtTypeCriminal, PACERCourtTypeMDL} PACERCourtType;
typedef enum {PACERRegionTypeNone, PACERRegionTypeAppellate, PACERRegionTypeBankruptcy, PACERRegionTypeState, PACERRegionTypeDistrict, PACERCourtTypeState} PACERRegionType;

#endif
