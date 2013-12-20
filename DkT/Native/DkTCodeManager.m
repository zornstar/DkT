//
//  DkTCodeManager.m
//  DkT
//
//  Created by Matthew Zorn on 7/15/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTCodeManager.h"

NSString* const DkTCodeSearchDisplayKey = @"search_code";
NSString* const DkTCodeBluebookKey = @"bluebook_code";
NSString* const DkTCodePACERSearchKey = @"pacer_search_code";
NSString* const DkTCodePACERDisplayKey = @"pacer_display_code";
NSString* const DkTCodeTypeKey = @"type";

@interface DkTCodeManager ()

@property (nonatomic, strong) NSArray *codes;

@end

@implementation DkTCodeManager

+(id)sharedManager
{
    static dispatch_once_t pred;
    static DkTCodeManager *sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[DkTCodeManager alloc] init];
        
    });
    return sharedInstance;
}

+(NSArray *) valuesForKey:(NSString *)key types:(DkTCodeType)type
{
    
    DkTCodeManager *mgr = [DkTCodeManager sharedManager];
    NSArray *results = [NSArray array];
    
    if(type != DkTCodeTypeNone)
    {
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"(type.intValue & %i != NO)", type];
        results = [[mgr.codes filteredArrayUsingPredicate:pred] valueForKey:key];
    }
    return results;
}

+(NSArray *) valuesForKey:(NSString *)key type:(DkTCodeType)type
{
    
    DkTCodeManager *mgr = [DkTCodeManager sharedManager];
    NSArray *results = [NSArray array];
    
    if(type != DkTCodeTypeNone)
    {
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"(type.intValue == %i)", type];
        results = [[mgr.codes filteredArrayUsingPredicate:pred] valueForKey:key];
    }
    return results;
}


+(NSString *)translateCode:(NSString *)code inputFormat:(NSString *)input outputFormat:(NSString *)output
{
    NSArray *codes = [[DkTCodeManager sharedManager] codes];
    
    NSArray *array = [codes filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(%K == %@)", input, code]];

    if(array.count > 0)
    {
        NSDictionary *dictionary = [array objectAtIndex:0];
        return [dictionary objectForKey:output];
    }
    
    return @"";
}

+(NSString *)translateCode:(NSString *)code inputFormat:(NSString *)input outputFormat:(NSString *)output type:(DkTCodeType)type
{
    NSArray *codes = [[DkTCodeManager sharedManager] codes];
    
    NSArray *array = [codes filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(%K == %@) AND (type.intValue & %i != NO)", input, code, type]];
    
    if(array.count > 0)
    {
        NSDictionary *dictionary = [array objectAtIndex:0];
        return [dictionary objectForKey:output];
    }
    
    return @"";
    
    
}

-(id) init
{
    if(self = [super init])
    {
        _codes = [self makeCodes];
    }
    
    return self;
}

-(NSArray *) codes
{
    if(_codes == nil)
    {
        _codes = [self makeCodes];
    }
    
    return _codes;
}

-(void) destroyCodes
{
    _codes = nil;
}

#define DkTCodeMake(_str1, _str2, _str3, _str4, _type) @{DkTCodeSearchDisplayKey:_str1, DkTCodeBluebookKey:_str2, DkTCodePACERSearchKey:_str3, DkTCodePACERDisplayKey:_str4, DkTCodeTypeKey:[NSNumber numberWithInt:_type]}

-(NSArray *) makeCodes
{
    return @[ DkTCodeMake(@"First Circuit", @"1st Cir.", @"01",@"01cae", (DkTCodeTypeAppellateCourt | DkTCodeTypeRegion )),
              DkTCodeMake(@"Second Circuit", @"2d Cir.", @"02",@"02cae", (DkTCodeTypeAppellateCourt | DkTCodeTypeRegion)),
              DkTCodeMake(@"Third Circuit", @"3d Cir.", @"03",@"03cae", (DkTCodeTypeAppellateCourt | DkTCodeTypeRegion)),
              DkTCodeMake(@"Fourth Circuit", @"4th Cir.", @"04",@"04cae", (DkTCodeTypeAppellateCourt | DkTCodeTypeRegion)),
              DkTCodeMake(@"Fifth Circuit", @"5th Cir.", @"05",@"05cae", (DkTCodeTypeAppellateCourt) | DkTCodeTypeRegion),
              DkTCodeMake(@"Sixth Circuit", @"6th Cir.", @"06",@"06cae", (DkTCodeTypeAppellateCourt | DkTCodeTypeRegion)),
              DkTCodeMake(@"Seventh Circuit", @"7th Cir.", @"07",@"07cae",(DkTCodeTypeAppellateCourt | DkTCodeTypeRegion)),
              DkTCodeMake(@"Eighth Circuit", @"8th Cir.", @"08",@"08cae", (DkTCodeTypeAppellateCourt | DkTCodeTypeRegion)),
              DkTCodeMake(@"Ninth Circuit", @"9th Cir.", @"09",@"09cae",(DkTCodeTypeAppellateCourt | DkTCodeTypeRegion)),
              DkTCodeMake(@"Tenth Circuit", @"10th Cir.", @"10",@"10cae", (DkTCodeTypeAppellateCourt | DkTCodeTypeRegion)),
              DkTCodeMake(@"Eleventh Circuit", @"11th Cir.", @"11",@"11cae", (DkTCodeTypeAppellateCourt | DkTCodeTypeRegion)),
              DkTCodeMake(@"D.C. Circuit", @"D.C. Cir.", @"dc",@"cadc", DkTCodeTypeAppellateCourt),
              DkTCodeMake(@"Federal Circuit", @"Fed. Cir.", @"CAFC",@"cafc", DkTCodeTypeAppellateCourt),
              DkTCodeMake(@"First Circuit", @"B.A.P. 1st Cir.", @"01",@"01bap", DkTCodeTypeBankruptcyAppellateCourt),
              DkTCodeMake(@"Second Circuit", @"B.A.P. 2d Cir.", @"02",@"02bap", DkTCodeTypeBankruptcyAppellateCourt),
              DkTCodeMake(@"Third Circuit", @"B.A.P. 3d Cir.", @"03",@"03bap", DkTCodeTypeBankruptcyAppellateCourt),
              DkTCodeMake(@"Fourth Circuit", @"B.A.P. 4th Cir.", @"04",@"04bap", DkTCodeTypeBankruptcyAppellateCourt),
              DkTCodeMake(@"Fifth Circuit", @"B.A.P. 5th Cir.", @"05",@"05bap", DkTCodeTypeBankruptcyAppellateCourt),
              DkTCodeMake(@"Sixth Circuit", @"B.A.P. 6th Cir.", @"06",@"06bap", DkTCodeTypeBankruptcyAppellateCourt),
              DkTCodeMake(@"Seventh Circuit", @"B.A.P. 7th Cir.", @"07",@"07bap",DkTCodeTypeBankruptcyAppellateCourt),
              DkTCodeMake(@"Eighth Circuit", @"B.A.P. 8th Cir.", @"08",@"08bap", DkTCodeTypeBankruptcyAppellateCourt),
              DkTCodeMake(@"Ninth Circuit", @"B.A.P. 9th Cir.", @"09",@"09bap",DkTCodeTypeBankruptcyAppellateCourt),
              DkTCodeMake(@"Tenth Circuit", @"B.A.P. 10th Cir.", @"10",@"10bap", DkTCodeTypeBankruptcyAppellateCourt),
              DkTCodeMake(@"Eleventh Circuit", @"B.A.P. 11th Cir.", @"11",@"11bap", DkTCodeTypeBankruptcyAppellateCourt),
              DkTCodeMake(@"Alabama", @"Ala.", @"AL", @"al", DkTCodeTypeRegion),
              DkTCodeMake(@"Alaska", @"Alaska", @"AK", @"al", DkTCodeTypeRegion),
              DkTCodeMake(@"Arizona", @"Ariz.", @"AZ", @"az", DkTCodeTypeRegion),
              DkTCodeMake(@"Arkansas", @"Ark.", @"AR", @"ar", DkTCodeTypeRegion),
              DkTCodeMake(@"California", @"Cal.", @"CA", @"ca", DkTCodeTypeRegion),
              DkTCodeMake(@"Colorado", @"Col.", @"CO", @"co", DkTCodeTypeRegion),
              DkTCodeMake(@"Connecticut", @"Conn.", @"CT", @"ct",DkTCodeTypeRegion),
              DkTCodeMake(@"District of Columbia", @"DC", @"dc", @"dc",DkTCodeTypeRegion),
              DkTCodeMake(@"Delaware", @"Del.", @"DE", @"de", DkTCodeTypeRegion),
              DkTCodeMake(@"Florida", @"Fla.", @"FL", @"fl", DkTCodeTypeRegion),
              DkTCodeMake(@"Georgia", @"Ga.", @"GA", @"ga", DkTCodeTypeRegion),
              DkTCodeMake(@"Guam", @"Guam", @"GU", @"gu",DkTCodeTypeRegion),
              DkTCodeMake(@"Hawaii", @"Haw.", @"HI", @"hi", DkTCodeTypeRegion),
              DkTCodeMake(@"Idaho", @"Idaho", @"ID", @"id", DkTCodeTypeRegion),
              DkTCodeMake(@"Illinois", @"Ill.", @"IL", @"il", DkTCodeTypeRegion),
              DkTCodeMake(@"Indiana", @"Ind.", @"IN", @"in", DkTCodeTypeRegion),
              DkTCodeMake(@"Iowa", @"Iowa", @"IA", @"ia", DkTCodeTypeRegion),
              DkTCodeMake(@"Kansas", @"Kan.", @"KS", @"ks", DkTCodeTypeRegion),
              DkTCodeMake(@"Kentucky", @"Ky.", @"KY", @"ky", DkTCodeTypeRegion),
              DkTCodeMake(@"Louisiana", @"La.", @"LA", @"la", DkTCodeTypeRegion),
              DkTCodeMake(@"Maine", @"Me.", @"ME", @"me", DkTCodeTypeRegion),
              DkTCodeMake(@"Maryland", @"Md.", @"MD", @"md", DkTCodeTypeRegion),
              DkTCodeMake(@"Massachussetts", @"Mass.", @"MA", @"ma", DkTCodeTypeRegion),
              DkTCodeMake(@"Michigan", @"Mich.", @"MI", @"mi", DkTCodeTypeRegion),
              DkTCodeMake(@"Minnesota", @"Minn.", @"MN", @"mn", DkTCodeTypeRegion),
              DkTCodeMake(@"Mississippi", @"Miss.", @"MS", @"ms", DkTCodeTypeRegion),
              DkTCodeMake(@"Missouri", @"Mo.", @"MO", @"mo", DkTCodeTypeRegion),
              DkTCodeMake(@"Montana", @"Mont.", @"MT", @"mt", DkTCodeTypeRegion),
              DkTCodeMake(@"Nebraska", @"Neb.", @"NE", @"ne", DkTCodeTypeRegion),
              DkTCodeMake(@"Nevada", @"Nev.", @"NV", @"nv", DkTCodeTypeRegion),
              DkTCodeMake(@"New Hampshire", @"N.H.", @"NH", @"nh", DkTCodeTypeRegion),
              DkTCodeMake(@"New Jersey", @"N.J.", @"NJ", @"nj", DkTCodeTypeRegion),
              DkTCodeMake(@"New Mexico", @"N.M.", @"NM", @"nm", DkTCodeTypeRegion),
              DkTCodeMake(@"New York", @"N.Y.", @"NY", @"ny", DkTCodeTypeRegion),
              DkTCodeMake(@"North Carolina", @"N.C.", @"NC", @"nc", DkTCodeTypeRegion),
              DkTCodeMake(@"North Dakota", @"N.D.", @"ND", @"nd", DkTCodeTypeRegion),
              DkTCodeMake(@"Ohio", @"Ohio", @"OH", @"oh", DkTCodeTypeRegion),
              DkTCodeMake(@"Oklahoma", @"Okla.", @"OK", @"ok", DkTCodeTypeRegion),
              DkTCodeMake(@"Oregon", @"Or.", @"OR", @"or", DkTCodeTypeRegion),
              DkTCodeMake(@"Pennsylvania", @"Pa.", @"PA", @"pa", DkTCodeTypeRegion),
              DkTCodeMake(@"Puerto Rico", @"P.R.", @"PR", @"pr", DkTCodeTypeRegion),
              DkTCodeMake(@"Rhode Island", @"R.I.", @"RI",@"ri", DkTCodeTypeRegion),
              DkTCodeMake(@"South Carolina", @"S.C.", @"SC", @"sc", DkTCodeTypeRegion),
              DkTCodeMake(@"South Dakota", @"S.D.", @"SD",@"sd", DkTCodeTypeRegion),
              DkTCodeMake(@"Tennessee", @"Tenn.", @"TN",@"tn", DkTCodeTypeRegion),
              DkTCodeMake(@"Texas", @"Tex.", @"TX", @"tx", DkTCodeTypeRegion),
              DkTCodeMake(@"Utah", @"Utah", @"UT",@"ut",DkTCodeTypeRegion),
              DkTCodeMake(@"Vermont", @"Vt.", @"VT", @"vt",DkTCodeTypeRegion),
              DkTCodeMake(@"Virgin Islands", @"V.I.", @"VI", @"vi", DkTCodeTypeRegion),
              DkTCodeMake(@"Virginia", @"Va.", @"VA", @"va", DkTCodeTypeRegion),
              DkTCodeMake(@"Washington", @"Wash.", @"WA", @"wa", DkTCodeTypeRegion),
              DkTCodeMake(@"West Virginia", @"W. Va.", @"WV", @"wv", DkTCodeTypeRegion),
              DkTCodeMake(@"Wisconsin", @"Wis.", @"WI", @"wi", DkTCodeTypeRegion),
              DkTCodeMake(@"Wyoming", @"Wyo.", @"WY", @"wy", DkTCodeTypeRegion),
              
              
              //BANKRUPTCY APPELLATE
              
              //B.A.P. 1st Cir.
              //BANKRUPTCY COURTS
              
              //Alabama
              DkTCodeMake(@"Alabama Middle", @"Bankr. M.D. Ala.", @"alm", @"almbke", DkTCodeTypeBankruptcyCourt),
              DkTCodeMake(@"Alabama Northern", @"Bankr. N.D. Ala.", @"aln", @"alnbke", DkTCodeTypeBankruptcyCourt),
              DkTCodeMake(@"Alabama Southern", @"Bankr. S.D. Ala.", @"als", @"alsbke", DkTCodeTypeBankruptcyCourt),
              
              //Alaska
              DkTCodeMake(@"Alaska", @"Bankr. D. Alaska", @"ak", @"akbke", DkTCodeTypeBankruptcyCourt),
             
              //Arizona
              DkTCodeMake(@"Arizona", @"Bankr. D. Ariz.", @"az", @"azbke", DkTCodeTypeBankruptcyCourt),
              
              //Arkansas
              DkTCodeMake(@"Arkansas Eastern", @"Bankr. E.D. Ark.", @"are", @"arebke", DkTCodeTypeBankruptcyCourt),
              DkTCodeMake(@"Arkansas Western", @"Bankr. W.D. Ark.", @"arw", @"arwbke", DkTCodeTypeBankruptcyCourt),
              
              //California
              DkTCodeMake(@"California Central", @"Bankr. C.D. Cal.", @"cac", @"cacbke", DkTCodeTypeBankruptcyCourt),
              DkTCodeMake(@"California Eastern", @"Bankr. E.D. Cal.", @"cae", @"caebke", DkTCodeTypeBankruptcyCourt),
              DkTCodeMake(@"California Northern", @"Bankr. N.D. Cal.", @"can", @"canbke", DkTCodeTypeBankruptcyCourt),
              DkTCodeMake(@"California Southern", @"Bankr. S.D. Cal.", @"cas", @"casbke", DkTCodeTypeBankruptcyCourt),
              
              //Colorado
              DkTCodeMake(@"Colorado", @"Bankr. D. Col.", @"co", @"cobke", DkTCodeTypeBankruptcyCourt),
              
              //Connecticut
              DkTCodeMake(@"Connecticut", @"Bankr. D. Conn.", @"ct", @"ctbke", DkTCodeTypeBankruptcyCourt),
              
              //Delaware
              
              DkTCodeMake(@"Delaware", @"Bankr. D. Del.", @"de", @"debke", DkTCodeTypeBankruptcyCourt),
              
              //DC
              DkTCodeMake(@"District of Columbia", @"Bankr. D.D.C.", @"dc", @"dcbke", DkTCodeTypeBankruptcyCourt),
              
              //Florida
              DkTCodeMake(@"Florida Middle", @"Bankr. M.D. Fla.", @"flm", @"flmbke", DkTCodeTypeBankruptcyCourt),
              DkTCodeMake(@"Florida Northern", @"Bankr. N.D. Fla.", @"fln", @"flnbke", DkTCodeTypeBankruptcyCourt),
              DkTCodeMake(@"Florida Southern", @"Bankr. S.D. Fla.", @"fls", @"flsbke", DkTCodeTypeBankruptcyCourt),
              
              //Georgia
              DkTCodeMake(@"Georgia Middle", @"Bankr. M.D. Ga.", @"gam", @"gambke", DkTCodeTypeBankruptcyCourt),
              DkTCodeMake(@"Georgia Northern", @"Bankr. N.D. Ga.", @"gan", @"ganbke", DkTCodeTypeBankruptcyCourt),
              DkTCodeMake(@"Georgia Southern", @"Bankr. S.D. Ga.", @"gas", @"gasbke", DkTCodeTypeBankruptcyCourt),
              
              //Guam
              DkTCodeMake(@"Guam", @"Bankr. D. Guam.", @"gu", @"gubke",DkTCodeTypeBankruptcyCourt),
              
              //Hawaii
              DkTCodeMake(@"Hawaii", @"Bankr. D. Haw.", @"hi", @"hibke",DkTCodeTypeBankruptcyCourt),
              
              //Idaho
              DkTCodeMake(@"Idaho", @"Bankr. D. Idaho", @"id", @"idbke", DkTCodeTypeBankruptcyCourt),
              
              //Illinois
              DkTCodeMake(@"Illinois Central", @"Bankr. C.D. Ill.", @"ilc", @"ilcbke",DkTCodeTypeBankruptcyCourt),
              DkTCodeMake(@"Illinois Northern", @"Bankr. N.D. Ill.", @"iln", @"ilnbke",DkTCodeTypeBankruptcyCourt),
              DkTCodeMake(@"Illinois Southern", @"Bankr. S.D. Ill.", @"ils", @"ilsbke",DkTCodeTypeBankruptcyCourt),
              
              //Indiana
              DkTCodeMake(@"Indiana Northern", @"Bankr. N.D. Ind.", @"inn", @"innbke",DkTCodeTypeBankruptcyCourt),
              DkTCodeMake(@"Indiana Southern", @"Bankr. S.D. Ind.", @"ins", @"insbke",DkTCodeTypeBankruptcyCourt),
              
              //Iowa
              DkTCodeMake(@"Iowa Northern", @"Bankr. N.D. Iowa", @"ian", @"ianbke",DkTCodeTypeBankruptcyCourt),
              DkTCodeMake(@"Iowa Southern", @"Bankr. S.D. Iowa", @"ias", @"iasbke",DkTCodeTypeBankruptcyCourt),
              
              //Kentucky
              DkTCodeMake(@"Kentucky Eastern", @"Bankr. E.D. Ky.", @"kye", @"kyebke",DkTCodeTypeBankruptcyCourt),
              DkTCodeMake(@"Kentucky Western", @"Bankr. W.D. Ky.", @"kyw", @"kywbke",DkTCodeTypeBankruptcyCourt),
              
              //Louisiana
              DkTCodeMake(@"Louisiana Eastern", @"Bankr. E.D. La.", @"lae", @"laebke",DkTCodeTypeBankruptcyCourt),
              DkTCodeMake(@"Louisiana Middle", @"Bankr. M.D. La.", @"lam", @"lambke",DkTCodeTypeBankruptcyCourt),
              DkTCodeMake(@"Louisiana Western", @"Bankr. W.D. La.", @"law", @"lawbke",DkTCodeTypeBankruptcyCourt),
              
              //Maine
              DkTCodeMake(@"Maine", @"Bankr. D. Me.", @"me", @"mebke",DkTCodeTypeBankruptcyCourt),
              
              //Maryland
              DkTCodeMake(@"Maryland", @"Bankr. D. Md.", @"md", @"mdbke",DkTCodeTypeBankruptcyCourt),
              
              //Massachussetts
              DkTCodeMake(@"Massachussetts", @"Bankr. D. Mass.", @"ma", @"mabke", DkTCodeTypeBankruptcyCourt),
              
              //Minnesota
              DkTCodeMake(@"Minnesota", @"Bankr. D. Minn.", @"mn", @"mnbke", DkTCodeTypeBankruptcyCourt),
              
              //Michigan
              DkTCodeMake(@"Michigan Eastern", @"Bankr. E.D. Mich.", @"mie", @"miebke",DkTCodeTypeBankruptcyCourt),
              DkTCodeMake(@"Michigan Western", @"Bankr. W.D. Mich.", @"miw", @"miwbke",DkTCodeTypeBankruptcyCourt),
              
              //Mississippi
              DkTCodeMake(@"Mississippi Nothern", @"Bankr. N.D. Miss.", @"msn", @"msnbke",DkTCodeTypeBankruptcyCourt),
              DkTCodeMake(@"Mississippi Southern", @"Bankr. S.D. Miss.", @"mss", @"mssbke",DkTCodeTypeBankruptcyCourt),
              
              //Missouri
              DkTCodeMake(@"Missouri Eastern", @"Bankr. E.D. Mo.", @"moe", @"moebke",DkTCodeTypeBankruptcyCourt),
              DkTCodeMake(@"Missouri Western", @"Bankr. S.D. Mo.", @"mow", @"mowbke",DkTCodeTypeBankruptcyCourt),
              
              //Montana
              DkTCodeMake(@"Montana", @"Bankr. D. Mont.", @"mt", @"mtbke",DkTCodeTypeBankruptcyCourt),
              
              //Nebraska
              DkTCodeMake(@"Nebraska", @"Bankr. D. Neb.", @"nb", @"nbbke",DkTCodeTypeBankruptcyCourt),
              
              //Nevada
              DkTCodeMake(@"Nevada", @"Bankr. D. Nev.", @"nv", @"nvbke",DkTCodeTypeBankruptcyCourt),
              
              //New Hampshire
              DkTCodeMake(@"New Hampshire", @"Bankr. D.N.H.", @"nh", @"nhbke",DkTCodeTypeBankruptcyCourt),
              
              //New Jersey
              DkTCodeMake(@"New Jersey", @"Bankr. D.N.J.", @"nj", @"njbke",DkTCodeTypeBankruptcyCourt),
              
              //New Maxico
              DkTCodeMake(@"New Mexico", @"Bankr. D.N.M.", @"nm", @"nmbke",DkTCodeTypeBankruptcyCourt),
              
              //New York
              DkTCodeMake(@"New York Eastern", @"Bankr. E.D.N.Y.", @"nye", @"nyebke",DkTCodeTypeBankruptcyCourt),
              DkTCodeMake(@"New York Northern", @"Bankr. N.D.N.Y.", @"nyn", @"nynbke",DkTCodeTypeBankruptcyCourt),
              DkTCodeMake(@"New York Southern", @"Bankr. S.D.N.Y.", @"nys", @"nysbke",DkTCodeTypeBankruptcyCourt),
              DkTCodeMake(@"New York Western", @"Bankr. W.D.N.Y.", @"nyw", @"nywbke",DkTCodeTypeBankruptcyCourt),
            
              //Northern Mariana Islands
              
              DkTCodeMake(@"Northern Mariana Islands", @"Bankr. D.N. Mar. I.", @"nmi",@"nmidce",DkTCodeTypeBankruptcyCourt),
              
              //North Carolina
              DkTCodeMake(@"North Carolina Eastern", @"Bankr. E.D.N.C.", @"nce",@"ncebke",DkTCodeTypeBankruptcyCourt),
              DkTCodeMake(@"North Carolina Middle", @"Bankr. M.D.N.C.", @"ncm",@"ncmbke",DkTCodeTypeBankruptcyCourt),
              DkTCodeMake(@"North Carolina Western", @"Bankr. W.D.N.C.",@"ncw",@"ncwbke", DkTCodeTypeBankruptcyCourt),
              
              //Ohio
              DkTCodeMake(@"Ohio Northern", @"Bankr. N.D. Oh.", @"ohn",@"ohnbke",DkTCodeTypeBankruptcyCourt),
              DkTCodeMake(@"Ohio Southern", @"Bankr. S.D. Oh.", @"ohs",@"ohsbke",DkTCodeTypeBankruptcyCourt),
            
              //Oklahoma
              DkTCodeMake(@"Oklahoma", @"Bankr. D. Okla.", @"ok", @"okb", DkTCodeTypeBankruptcyCourt),
              
              //Oregon
              DkTCodeMake(@"Oregon", @"Bankr. D. Or.", @"or", @"orbke",DkTCodeTypeBankruptcyCourt),
              
              //Pennsylvania
              DkTCodeMake(@"Pennsylvania Eastern", @"Bankr. E.D. Pa.",@"pae",@"paebke",DkTCodeTypeBankruptcyCourt),
              DkTCodeMake(@"Pennsylvania Middle", @"Bankr. M.D. Pa.", @"pam",@"pambke",DkTCodeTypeBankruptcyCourt),
              DkTCodeMake(@"Pennsylvania Western", @"Bankr. W.D. Pa.", @"paw",@"pawbke",DkTCodeTypeBankruptcyCourt),
              
              //Puerto Rico
              DkTCodeMake(@"Puerto Rico", @"Bankr. D.P.R.", @"pr", @"prbke",DkTCodeTypeBankruptcyCourt),
              
              //Rhode Island
              DkTCodeMake(@"Rhode Island", @"Bankr. D.R.I.", @"ri",@"ribke", DkTCodeTypeBankruptcyCourt),
              
              //South Carolina
              DkTCodeMake(@"South Carolina", @"Bankr. D.S.C.", @"sc", @"scbke",DkTCodeTypeBankruptcyCourt),
              
              //South Dakota
              DkTCodeMake(@"South Dakota", @"Bankr. D.S.D.", @"sd", @"sdbke",DkTCodeTypeBankruptcyCourt),
              
              //Tennessee
              DkTCodeMake(@"Tennessee Eastern", @"Bankr. E.D. Tenn.", @"tne",@"tnebke", DkTCodeTypeBankruptcyCourt),
              DkTCodeMake(@"Tennessee Middle", @"Bankr. M.D. Tenn.", @"tnm",@"tnmbke",DkTCodeTypeBankruptcyCourt),
              DkTCodeMake(@"Tennessee Western", @"Bankr. W.D. Tenn.", @"tnw",@"tnwbke", DkTCodeTypeBankruptcyCourt),
              
              //Texas
               DkTCodeMake(@"Texas Eastern", @"Bankr. E.D. Tex.", @"txe",@"txebke",DkTCodeTypeBankruptcyCourt),
               DkTCodeMake(@"Texas Northern", @"Bankr. N.D. Tex.", @"txn",@"txnbke",DkTCodeTypeBankruptcyCourt),
               DkTCodeMake(@"Texas Southern", @"Bankr. S.D. Tex.", @"txs",@"txsbke",DkTCodeTypeBankruptcyCourt),
               DkTCodeMake(@"Texas Western", @"Bankr. W.D. Tex.", @"txw",@"txwbke",DkTCodeTypeBankruptcyCourt),
              
              //Utah
              
              DkTCodeMake(@"Utah", @"Bankr. D. Utah", @"ut", @"utbke",DkTCodeTypeBankruptcyCourt),
              
              //Vermont
              DkTCodeMake(@"Vermont", @"Bankr. D. Vt.", @"vt", @"vtbke", DkTCodeTypeBankruptcyCourt),
              
              //Virgin Islands
              DkTCodeMake(@"Virgin Islands", @"Bankr. D.V.I.", @"vi", @"vibke",DkTCodeTypeBankruptcyCourt),
              
              //Virginia
              DkTCodeMake(@"Virginia Eastern", @"Bankr. E.D. Va.", @"vae",@"vaebke",DkTCodeTypeBankruptcyCourt),
              DkTCodeMake(@"Virginia Western", @"Bankr. W.D. Va.", @"vaw",@"vawbke",DkTCodeTypeBankruptcyCourt),
              
              //Washington
              DkTCodeMake(@"Washington Eastern", @"Bankr. E.D. Wa.", @"wae",@"waebke",DkTCodeTypeBankruptcyCourt),
              DkTCodeMake(@"Washington Western", @"Bankr. W.D. Wa.", @"waw",@"wawbke",DkTCodeTypeBankruptcyCourt),
              
              //West Virginia
              DkTCodeMake(@"West Virginia Northern", @"Bankr. N.D.W. Va.",@"wvn",@"wvnbke", DkTCodeTypeBankruptcyCourt ),
              DkTCodeMake(@"West Virginia Southern", @"Bankr. S.D.W. Va.",@"wvs",@"wvsbke",DkTCodeTypeBankruptcyCourt),
              
              //Wisconsin
              DkTCodeMake(@"Washington Eastern", @"Bankr. E.D. Wis.", @"wie",@"wiebke",DkTCodeTypeBankruptcyCourt),
              DkTCodeMake(@"Washington Western", @"Bankr. W.D. Wis.", @"wiw",@"wiwbke",DkTCodeTypeBankruptcyCourt),
              
              //Wyoming
              DkTCodeMake(@"Wyoming", @"Bankr. D. Wyo.", @"wy", @"wybke", DkTCodeTypeBankruptcyCourt),
              
              // DISTRICT COURTS
              
              //Alaska
              DkTCodeMake(@"Alaska", @"D. Alaska", @"ak", @"akdce", DkTCodeTypeDistrictCourt),
            
              //Arizona
              DkTCodeMake(@"Arizona", @"D. Ariz.", @"az", @"azdce", DkTCodeTypeDistrictCourt),
              
              //Alabama
              DkTCodeMake(@"Alabama Middle", @"M.D. Ala.", @"alm", @"almdce",DkTCodeTypeDistrictCourt),
              DkTCodeMake(@"Alabama Northern", @"N.D. Ala.", @"aln", @"alndce",DkTCodeTypeDistrictCourt),
              DkTCodeMake(@"Alabama Southern", @"S.D. Ala.", @"als", @"alsdce", DkTCodeTypeDistrictCourt),
              
              //Arkansas
              DkTCodeMake(@"Arkansas Eastern", @"E.D. Ark.", @"ake", @"aredce", DkTCodeTypeDistrictCourt),
              DkTCodeMake(@"Arkansas Western", @"W.D. Ark.", @"arw", @"arwdce", DkTCodeTypeDistrictCourt),
              
              //California
              DkTCodeMake(@"California Central", @"C.D. Cal.", @"cac", @"cacdce", DkTCodeTypeDistrictCourt),
              DkTCodeMake(@"California Eastern", @"E.D. Cal.", @"cae", @"caedce", DkTCodeTypeDistrictCourt),
              DkTCodeMake(@"California Northern", @"N.D. Cal.", @"can", @"candce", DkTCodeTypeDistrictCourt),
              DkTCodeMake(@"California Southern", @"S.D. Cal.", @"cas", @"casdce", DkTCodeTypeDistrictCourt),
              
              //Colorado
              DkTCodeMake(@"Colorado", @"D. Col.", @"co", @"codce", DkTCodeTypeBankruptcyCourt),
              
              //Connecticut
              DkTCodeMake(@"Connecticut", @"D. Conn.", @"ct", @"ctdce", DkTCodeTypeBankruptcyCourt),
              
              //DC
              DkTCodeMake(@"District of Columbia", @"D.D.C.", @"dc", @"dcdce", DkTCodeTypeDistrictCourt),
              
              //Delaware
              DkTCodeMake(@"Delaware", @"D. Del.", @"de", @"dedce", DkTCodeTypeDistrictCourt),
              
              //Florida
              DkTCodeMake(@"Florida Middle", @"M.D. Fla.", @"flm", @"flmdce", DkTCodeTypeDistrictCourt),
              DkTCodeMake(@"Florida Northern", @"N.D. Fla.", @"fln", @"flndce", DkTCodeTypeDistrictCourt),
              DkTCodeMake(@"Florida Southern", @"S.D. Fla.", @"fls", @"flsdce", DkTCodeTypeDistrictCourt),
              
              //Georgia
              DkTCodeMake(@"Georgia Middle", @"M.D. Ga.", @"gam", @"gamdce", DkTCodeTypeDistrictCourt),
              DkTCodeMake(@"Georgia Northern", @"N.D. Ga.", @"gan", @"gandce", DkTCodeTypeDistrictCourt),
              DkTCodeMake(@"Georgia Southern", @"S.D. Ga.", @"gas", @"gasdce", DkTCodeTypeDistrictCourt),
              
              //Guam
              DkTCodeMake(@"Guam", @"D. Guam.", @"gu", @"gudce", DkTCodeTypeDistrictCourt),
              
              //Hawaii
              DkTCodeMake(@"Hawaii", @"D. Haw.", @"hi", @"hidce", DkTCodeTypeDistrictCourt),
              
              //Idaho
              DkTCodeMake(@"Idaho", @"D. Idaho", @"id", @"iddce", DkTCodeTypeDistrictCourt),
              
              //Illinois
              DkTCodeMake(@"Illinois Central", @"C.D. Ill.", @"ilc", @"ilcdce", DkTCodeTypeDistrictCourt),
              DkTCodeMake(@"Illinois Northern", @"N.D. Ill.", @"iln", @"ilndce", DkTCodeTypeDistrictCourt),
              DkTCodeMake(@"Illinois Southern", @"S.D. Ill.", @"ils", @"ilsdce", DkTCodeTypeDistrictCourt),
              
              //Indiana
              DkTCodeMake(@"Indiana Northern", @"N.D. Ind.", @"inn", @"inndce", DkTCodeTypeDistrictCourt),
              DkTCodeMake(@"Indiana Southern", @"S.D. Ind.", @"ins", @"insdce", DkTCodeTypeDistrictCourt),
              
              //Iowa
              DkTCodeMake(@"Iowa Northern", @"N.D. Iowa", @"ian", @"iandce", DkTCodeTypeDistrictCourt),
              DkTCodeMake(@"Iowa Southern", @"S.D. Iowa", @"ias", @"iasdce", DkTCodeTypeDistrictCourt),
              
              //Kentucky
              DkTCodeMake(@"Kentucky Eastern", @"E.D. Ky.", @"kye", @"kyedce", DkTCodeTypeDistrictCourt),
              DkTCodeMake(@"Kentucky Western", @"W.D. Ky.", @"kyw", @"kywdce", DkTCodeTypeDistrictCourt),
              
              //Louisiana
              DkTCodeMake(@"Louisiana Eastern", @"E.D. La.", @"lae", @"laedce", DkTCodeTypeDistrictCourt),
              DkTCodeMake(@"Louisiana Middle", @"M.D. La.", @"lam", @"lamdce", DkTCodeTypeDistrictCourt),
              DkTCodeMake(@"Louisiana Western", @"W.D. La.", @"law", @"lawdce", DkTCodeTypeDistrictCourt),
              
              //Maine
              DkTCodeMake(@"Maine", @"D. Me.", @"me", @"medce",DkTCodeTypeDistrictCourt),
              
              //Maryland
              DkTCodeMake(@"Maryland", @"D. Md.", @"md", @"mddce", DkTCodeTypeDistrictCourt),
              
              //Massachussetts
              DkTCodeMake(@"Massachussetts", @"D. Mass.", @"ma", @"ma", DkTCodeTypeDistrictCourt),
              
              //Michigan
              DkTCodeMake(@"Michigan Eastern", @"E.D. Mich.", @"mie", @"miedce", DkTCodeTypeDistrictCourt),
              DkTCodeMake(@"Michigan Western", @"W.D. Mich.", @"miw", @"miwdce", DkTCodeTypeDistrictCourt),
              
              //Mississippi
              DkTCodeMake(@"Mississippi Nothern", @"N.D. Miss.", @"msn", @"msndce", DkTCodeTypeDistrictCourt),
              DkTCodeMake(@"Mississippi Southern", @"S.D. Miss.", @"mss", @"mssdce", DkTCodeTypeDistrictCourt),
              
              //Missouri
              DkTCodeMake(@"Missouri Eastern", @"E.D. Mo.", @"moe", @"moedce", DkTCodeTypeDistrictCourt),
              DkTCodeMake(@"Missouri Western", @"S.D. Mo.", @"mow", @"mowdce", DkTCodeTypeDistrictCourt),
              
              //Minnesota
              DkTCodeMake(@"Minnesota", @"Bankr. D. Minn.", @"mn", @"mnbke", DkTCodeTypeDistrictCourt),
              
              //Montana
              DkTCodeMake(@"Montana", @"D. Mont.", @"mt", @"mtdce",DkTCodeTypeDistrictCourt),
              
              //Nebraska
              DkTCodeMake(@"Nebraska", @"D. Neb.", @"nb", @"nbdce",DkTCodeTypeDistrictCourt),
              
              //Nevada
              DkTCodeMake(@"Nevada", @"D. Nev.", @"nv", @"nvdce",DkTCodeTypeDistrictCourt),
              
              //New Hampshire
              DkTCodeMake(@"New Hampshire", @"D.N.H.", @"nh", @"nhdce",DkTCodeTypeDistrictCourt),
              
              //New Jersey
               DkTCodeMake(@"New Jersey", @"D.N.J.", @"nj", @"njdce", DkTCodeTypeDistrictCourt),
              
              //New Maxico
              DkTCodeMake(@"New Mexico", @"D.N.M.", @"nm", @"nmdce",DkTCodeTypeDistrictCourt),
              
              //New York
              DkTCodeMake(@"New York Eastern", @"E.D.N.Y.", @"nye", @"nyedce", DkTCodeTypeDistrictCourt),
              DkTCodeMake(@"New York Northern", @"N.D.N.Y.", @"nyn", @"nyndce", DkTCodeTypeDistrictCourt),
              DkTCodeMake(@"New York Southern", @"S.D.N.Y.", @"nys", @"nysdce", DkTCodeTypeDistrictCourt),
              DkTCodeMake(@"New York Western", @"W.D.N.Y.", @"nyw", @"nywdce",DkTCodeTypeDistrictCourt),
              
              //Northern Mariana Islands
              DkTCodeMake(@"Northern Mariana Islands", @"D.N. Mar. I.", @"nmi",@"nmidce",DkTCodeTypeDistrictCourt),
              
              //North Carolina
              DkTCodeMake(@"North Carolina Eastern", @"E.D.N.C.", @"nce",@"ncedce",DkTCodeTypeDistrictCourt),
              DkTCodeMake(@"North Carolina Middle", @"M.D.N.C.", @"ncm",@"ncmdce", DkTCodeTypeDistrictCourt),
              DkTCodeMake(@"North Carolina Western", @"W.D.N.C.",@"ncw",@"ncwdce", DkTCodeTypeDistrictCourt),
              
              //Ohio
              DkTCodeMake(@"Ohio Northern", @"N.D. Oh.", @"ohn",@"ohndce",DkTCodeTypeDistrictCourt),
              DkTCodeMake(@"Ohio Southern", @"S.D. Oh.", @"ohs",@"ohsdce",DkTCodeTypeDistrictCourt),
              
              //Oklahoma
              DkTCodeMake(@"Oklahoma", @"D. Okla.", @"ok", @"okdce", DkTCodeTypeDistrictCourt),
              
              //Oregon
              DkTCodeMake(@"Oregon", @"D. Or.", @"or", @"ordce", DkTCodeTypeDistrictCourt),
              
              //Pennsylvania
              DkTCodeMake(@"Pennsylvania Eastern", @"E.D. Pa.",@"pae",@"paedce",DkTCodeTypeDistrictCourt),
              DkTCodeMake(@"Pennsylvania Middle", @"M.D. Pa.", @"pam",@"pamdce",DkTCodeTypeDistrictCourt),
              DkTCodeMake(@"Pennsylvania Western", @"W.D. Pa.", @"paw",@"pawdce",DkTCodeTypeDistrictCourt),
              
              //Puerto Rico
              DkTCodeMake(@"Puerto Rico", @"D.P.R.", @"pr", @"prdce",DkTCodeTypeDistrictCourt),
              
              //Rhode Island
              DkTCodeMake(@"Rhode Island", @"D.R.I.", @"ri", @"ridce", DkTCodeTypeDistrictCourt),
              //South Carolina
              DkTCodeMake(@"South Carolina", @"D.S.C.", @"sc", @"scdce", DkTCodeTypeDistrictCourt),
              
              
              //South Dakota
              
              DkTCodeMake(@"South Dakota", @"D.S.D.", @"sd", @"sddce", DkTCodeTypeDistrictCourt),
              
              
              //Tennessee
              DkTCodeMake(@"Tennessee Eastern", @"E.D. Tenn.", @"tne",@"tnedce", DkTCodeTypeDistrictCourt),
              DkTCodeMake(@"Tennessee Middle", @"M.D. Tenn.", @"tnm",@"tnmdce",DkTCodeTypeDistrictCourt),
              DkTCodeMake(@"Tennessee Western", @"W.D. Tenn.", @"tnw",@"tnwdce",DkTCodeTypeDistrictCourt),
              
              //Texas
              DkTCodeMake(@"Texas Eastern", @"E.D. Tex.", @"txe",@"txedce",DkTCodeTypeDistrictCourt),
              DkTCodeMake(@"Texas Northern", @"N.D. Tex.", @"txn",@"txndce",DkTCodeTypeDistrictCourt),
              DkTCodeMake(@"Texas Southern", @"S.D. Tex.", @"txs",@"txsdce",DkTCodeTypeDistrictCourt),
              DkTCodeMake(@"Texas Western", @"W.D. Tex.", @"txw",@"txwdce",DkTCodeTypeDistrictCourt),
              
              //Utah
              
              DkTCodeMake(@"Utah", @"D. Utah", @"ut", @"utdce", DkTCodeTypeDistrictCourt),
              
              //Vermont
              
              DkTCodeMake(@"Vermont", @"D. Vt.", @"vt", @"vtdce", DkTCodeTypeDistrictCourt),
              
              //Virgin Islands
              DkTCodeMake(@"Virgin Islands", @"Bankr. D.V.I.", @"vi", @"vibke",DkTCodeTypeBankruptcyCourt),
              
              //Virginia
              DkTCodeMake(@"Virginia Eastern", @"E.D. Va.", @"vae",@"vaedce",DkTCodeTypeDistrictCourt),
              DkTCodeMake(@"Virginia Western", @"W.D. Va.", @"vaw",@"vawdce",DkTCodeTypeDistrictCourt),
              
              //Washington
              DkTCodeMake(@"Washington Eastern", @"E.D. Wa.", @"wae",@"waedce",DkTCodeTypeDistrictCourt),
              DkTCodeMake(@"Washington Western", @"W.D. Wa.", @"waw",@"wawdce",DkTCodeTypeDistrictCourt),
              
              //West Virginia
              DkTCodeMake(@"West Virginia Northern", @"N.D.W. Va.",@"wvn",@"wvndce", DkTCodeTypeDistrictCourt ),
              DkTCodeMake(@"West Virginia Southern", @"S.D.W. Va.",@"wvs",@"wvsdce", DkTCodeTypeDistrictCourt),
              
              //Wisconsin
              DkTCodeMake(@"Washington Eastern", @"E.D. Wis.", @"wie",@"wiedce",DkTCodeTypeBankruptcyCourt),
              DkTCodeMake(@"Washington Western", @"W.D. Wis.", @"wiw",@"wiwdce",DkTCodeTypeBankruptcyCourt),
              
              //Wyoming
              
              DkTCodeMake(@"Wyoming", @"D. Wyo.", @"wy", @"wydce", DkTCodeTypeDistrictCourt),
              
              
              //Court of Federal Claims
              DkTCodeMake(@"United States Federal Claims Court",@"Fed. Cl.",@"fct", @"cofce",  DkTCodeTypeDistrictCourt)
              
              ];
              
}


@end
