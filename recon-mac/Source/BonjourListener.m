
#import "BonjourListener.h"

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>


@interface BonjourListener ()

@property (readwrite, retain) NSNetServiceBrowser *primaryBrowser;
@property (readwrite, retain) NSNetServiceBrowser *secondaryBrowser;
@property (readwrite, retain) NSMutableArray *services;
@property (readwrite, retain) NSDictionary *bonjourDict;

@end

@implementation BonjourListener

@synthesize primaryBrowser;
@synthesize secondaryBrowser;
@synthesize services;
@synthesize bonjourDict;

-(id)init {
   if (self = [super init])
   {   
      NSLog(@"Bonjour!");
      self.services = [NSMutableArray new];
      self.primaryBrowser = [[NSNetServiceBrowser new] autorelease];
      self.primaryBrowser.delegate = self;
      self.secondaryBrowser = [[NSNetServiceBrowser new] autorelease];
      self.secondaryBrowser.delegate = self;
      [self setBonjourDict];
   }   
   
   return self;
}

-(void)dealloc {
   self.primaryBrowser = nil;
   self.secondaryBrowser = nil;
   [services release];   
   [super dealloc];
}

-(IBAction)search:(id)sender {
   NSLog(@"BonjourListener: search");
   [self.primaryBrowser stop];
   [self.secondaryBrowser stop];   
   [self.primaryBrowser searchForServicesOfType:@"_services._dns-sd._udp." inDomain:@""];   
}

#pragma mark Net Service Browser Delegate Methods
-(void)netServiceBrowser:(NSNetServiceBrowser *)aBrowser didFindService:(NSNetService *)aService moreComing:(BOOL)more {
   if (aBrowser == self.primaryBrowser)
   {      
      [services addObject:aService];

      if (more == NO)
      {
         NSNetService *s = [services objectAtIndex:0];
         NSString *name = [s name];
         NSString *type = [s type];
         NSArray *a = [type componentsSeparatedByString:@"."];
         NSString *newSearch = [NSString stringWithFormat:@"%@.%@", name, [a objectAtIndex:0]];
         
         [services removeObjectAtIndex:0];
         [self.secondaryBrowser searchForServicesOfType:newSearch inDomain:@""];            
      }
   }
   
   if (aBrowser == self.secondaryBrowser)
   {
      [aService retain];
      aService.delegate = self;
      [aService resolveWithTimeout:60];      
      
      [secondaryBrowser stop];
      
      if ([services count] > 0)
      {
         NSNetService *s = [services objectAtIndex:0];
         NSString *name = [s name];
         NSString *type = [s type];
         NSArray *a = [type componentsSeparatedByString:@"."];
         NSString *newSearch = [NSString stringWithFormat:@"%@.%@", name, [a objectAtIndex:0]];

         [services removeObjectAtIndex:0];
         [self.secondaryBrowser searchForServicesOfType:newSearch inDomain:@""];            
      }      
   }
}

-(void)netServiceBrowser:(NSNetServiceBrowser *)aBrowser didRemoveService:(NSNetService *)aService moreComing:(BOOL)more {
//   [servicesController removeObject:aService];
//   if ( aService == self.connectedService ) self.isConnected = NO;
}

-(void)netServiceDidResolveAddress:(NSNetService *)service {
//   NSLog(@"netServiceDidResolveAddress");
   
   NSMutableDictionary *newService = [[[NSMutableDictionary alloc] init] autorelease];

   // We have to unpack the IP Address
   uint8_t name[SOCK_MAXADDRLEN];   
   [[[service addresses] lastObject] getBytes:name];
   struct sockaddr_in *temp_addr = (struct sockaddr_in *)name;
   NSString *ipaddr = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr)->sin_addr)];
   
   [newService setObject:ipaddr forKey:@"IP_Address"];
   [newService setObject:[service domain] forKey:@"Domain"];
   [newService setObject:[service hostName] forKey:@"Hostname"];
   [newService setObject:[service name] forKey:@"Name"];
   [newService setObject:[service type] forKey:@"Type"];
   
   // Check if service is listed in our Pretty-Printed dictionary
   NSString *y = [[service type] stringByReplacingOccurrencesOfString:@"._tcp" withString:@""];
   y = [y stringByReplacingOccurrencesOfString:@"_" withString:@""];
   y = [y stringByReplacingOccurrencesOfString:@"." withString:@""];   
   
   if ([bonjourDict objectForKey:y])
      [newService setObject:[bonjourDict objectForKey:y] forKey:@"Long_Type"];
   else
      [newService setObject:[service type] forKey:@"Long_Type"];

   
   NSDictionary *txtdict = [NSNetService dictionaryFromTXTRecordData:[service TXTRecordData]];
      
   NSMutableDictionary *advService = [[[NSMutableDictionary alloc] init] autorelease];   
   
   for (id dictKey in [txtdict allKeys])
   {
      NSData *dictValue = [txtdict valueForKey:dictKey];
      NSString *aStr = [[NSString alloc] initWithData:dictValue encoding:NSASCIIStringEncoding]; 
      // To use Bindings, we have to replace spaces and '-' with underscores
      dictKey = [dictKey stringByReplacingOccurrencesOfString:@"-" withString:@"_"];
      dictKey = [dictKey stringByReplacingOccurrencesOfString:@" " withString:@"_"];
      [advService setObject:aStr forKey:dictKey];
   }
      
   [newService setObject:advService forKey:@"Protocol_Information"];
   
   NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];      
   [nc postNotificationName:@"BAFfoundBonjourServices" object:newService];  
}

-(void)netService:(NSNetService *)service didNotResolve:(NSDictionary *)errorDict {
   NSLog(@"Could not resolve: %@", errorDict);
}

- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)netServiceBrowser {
   NSLog(@"About to search!\n");
}

// Bonjour services lookup
//   Munged from http://www.dns-sd.org/ServiceTypes.html
- (void)setBonjourDict
{
   self.bonjourDict = [NSDictionary dictionaryWithObjectsAndKeys:
                  @"1Password Password Manager data sharing and synchronization protocol",@"1password",
                  @"Applied Biosystems Universal Instrument Framework",@"abi-instrument",
                  @"FTK2 Database Discovery Service",@"accessdata-f2d",
                  @"FTK2 Backend Processing Agent Service",@"accessdata-f2w",
                  @"Strix Systems 5S/AccessOne protocol",@"accessone",
                  @"MYOB AccountEdge",@"accountedge",
                  @"Adobe Acrobat",@"acrobatsrv",
                  @"ActionItems",@"actionitems",
                  @"Active Storage Proprietary Device Management Protocol",@"activeraid",
                  @"Encrypted transport of Active Storage Proprietary Device Management Protocol",@"activeraid-ssl",
                  @"Address-O-Matic",@"addressbook",
                  @"Adobe Version Cue",@"adobe-vc",
                  @"Automatic Disk Discovery",@"adisk",
                  @"ADPRO Security Device Setup",@"adpro-setup",
                  @"Apple Application Engineering Services",@"aecoretech",
                  @"Aeroflex instrumentation and software",@"aeroflex",
                  @"Apple File Sharing",@"afpovertcp",
                  @"AirPort Base Station",@"airport",
                  @"AirProjector",@"airprojector",
                  @"Animo License Manager",@"animolmd",
                  @"Animo Batch Server",@"animobserver",
                  @"Appelezvous",@"appelezvous",
                  @"Apple Audio Units",@"apple-ausend",
                  @"Apple MIDI",@"apple-midi",
                  @"Apple Password Server",@"apple-sasl",
                  @"Apple Remote Debug Services (OpenGL Profiler)",@"applerdbg",
                  @"Apple TV",@"appletv",
                  @"Apple TV discovery of iTunes",@"appletv-itunes",
                  @"Apple TV Pairing",@"appletv-pair",
                  @"AquaMon",@"aquamon",
                  @"Apple Software Restore",@"asr",
                  @"Asterisk Caller-ID Notification Service",@"astnotify",
                  @"Astralite",@"astralite",
                  @"address-o-sync",@"async",
                  @"Allen Vanguard Hardware Service",@"av",
                  @"Axis Video Cameras",@"axis-video",
                  @"Authentication Service",@"auth",
                  @"3M Unitek Digital Orthodontic System",@"b3d-convince",
                  @"BibDesk Sharing",@"bdsk",
                  @"BeatPack Synchronization Server for BeatMaker",@"beatpack",
                  @"Xgrid Technology Preview",@"beep",
                  @"BuildForge Agent",@"bfagent",
                  @"Big Bang Chess",@"bigbangchess",
                  @"Big Bang Mancala",@"bigbangmancala",
                  @"BitTorrent Zeroconf Peer Discovery Protocol",@"bittorrent",
                  @"Little Black Book Information Exchange Protocol",@"blackbook",
                  @"BlueVertise Network Protocol (BNP)",@"bluevertise",
                  @"Bookworm Client Discovery",@"bookworm",
                  @"Bootstrap Protocol Server",@"bootps",
                  @"Proprietary",@"boundaryscan",
                  @"Bag Of Unusual Strategy Games",@"bousg",
                  @"RFID Reader Basic Reader Interface",@"bri",
                  @"Backup Simplicity",@"bsqdea",
                  @"BusySync Calendar Synchronization Protocol",@"busycal",
                  @"CalTalk",@"caltalk",
                  @"Card Send Protocol",@"cardsend",
                  @"The Cheat",@"cheat",
                  @"Project Gridlock",@"chess",
                  @"Fluid Theme Server",@"chfts",
                  @"The CHILI Radiology System",@"chili",
                  @"Clipboard Sharing",@"clipboard",
                  @"Clique Link-Local Multicast Chat Room",@"clique",
                  @"Oracle CLS Cluster Topology Service",@"clscts",
                  @"Published Collection Object",@"collection",
                  @"Now Contact",@"contactserver",
                  @"Corroboree Server",@"corroboree",
                  @"NoteBook 2",@"cpnotebook2",
                  @"CVS PServer",@"cvspserver",
                  @"CodeWarrior HTI Xscale PowerTAP",@"cw-codetap",
                  @"CodeWarrior HTI DPI PowerTAP",@"cw-dpitap",
                  @"CodeWarrior HTI OnCE PowerTAP",@"cw-oncetap",
                  @"CodeWarrior HTI COP PowerTAP",@"cw-powertap",
                  @"CyTV",@"cytv",
                  @"Digital Audio Access Protocol (iTunes)",@"daap",
                  @"Digital Audio Control Protocol (iTunes)",@"dacp",
                  @"Device Info",@"device-info",
                  @"EyeHome",@"difi",
                  @"Distributed Compiler",@"distcc",
                  @"Ditrios SOA Framework Protocol",@"ditrios",
                  @"Dive Log Data Sharing and Synchronization Protocol",@"divelogsync",
                  @"Local Area Dynamic Time Synchronisation Protocol",@"dltimesync",
                  @"DNS Long-Lived Queries",@"dns-llq",
                  @"DNS Service Discovery",@"dns-sd",
                  @"DNS Dynamic Update Service",@"dns-update",
                  @"Domain Name Server",@"domain",
                  @"Vortimac Dossier Protocol",@"dossier",
                  @"Digital Photo Access Protocol (iPhoto)",@"dpap",
                  @"DropCopy",@"dropcopy",
                  @"Data Synchronization Protocol for Discovery Software products",@"dsl-sync",
                  @"Desktop Transporter Remote Desktop Protocol",@"dtrmtdesktop",
                  @"DVB Service Discovery",@"dvbservdsc",
                  @"Earphoria",@"earphoria",
                  @"ebXML Messaging",@"ebms",
                  @"Northrup Grumman/Mission Systems/ESL Data Flow Protocol",@"ecms",
                  @"ebXML Registry",@"ebreg",
                  @"Net Monitor Anti-Piracy Service",@"ecbyesfsgksc",
                  @"LaCie Ethernet Disk Configuration Protocol",@"edcp",
                  @"Interactive Room Software Infrastructure (Event Sharing)",@"eheap",
                  @"DataEnvoy",@"embrace",
                  @"Remote AppleEvents",@"eppc",
                  @"Extensis Server Protocol",@"esp",
                  @"Now Up-to-Date",@"eventserver",
                  @"Synchronization Protocol for Ilium Software's eWallet",@"ewalletsync",
                  @"Example Service Type",@"example",
                  @"Exbiblio Cascading Service Protocol",@"exb",
                  @"Remote Process Execution",@"exec",
                  @"Extensis Serial Number",@"extensissn",
                  @"EyeTV Sharing",@"eyetvsn",
                  @"FaceSpan",@"facespan",
                  @"Fairview Device Identification",@"fairview",
                  @"FAXstf",@"faxstfx",
                  @"NetNewsWire 2.0",@"feed-sharing",
                  @"Fish",@"fish",
                  @"Financial Information Exchange (FIX) Protocol",@"fix",
                  @"Fjork",@"fjork",
                  @"FilmLight Cluster Power Control Service",@"fl-purr",
                  @"FileMaker Pro",@"fmpro-internal",
                  @"FileMaker Server Administration Communication Service",@"fmserver-admin",
                  @"FontAgent Pro",@"fontagentnode",
                  @"FoxTrot Professional Search Discovery Service",@"foxtrot-start",
                  @"FreeHand MusicPad Pro Interface Protocol",@"freehand",
                  @"File Transfer",@"ftp",
                  @"Crocodile FTP Server",@"ftpcroco",
                  @"Fairview Certificate",@"fv-cert",
                  @"Fairview Key",@"fv-key",
                  @"Fairview Time/Date",@"fv-time",
                  @"Frog Navigation Systems",@"frog",
                  @"SnapMail",@"gbs-smp",
                  @"SnapTalk",@"gbs-stp",
                  @"G-Force Control via SoundSpectrum's SSMP TCP Protocol",@"gforce-ssmp",
                  @"GlassPad Data Exchange Protocol",@"glasspad",
                  @"GlassPadServer Data Exchange Protocol",@"glasspadserver",
                  @"OpenGL Driver Monitor",@"glrdrvmon",
                  @"Grid Plug and Play",@"gpnp",
                  @"Roxio ToastAnywhere(tm) Recorder Sharing",@"grillezvous",
                  @"Growl",@"growl",
                  @"Special service type for resolving by GUID (Globally Unique Identifier)",@"guid",
                  @"H.323 Real-time audio, video and data communication call setup protocol",@"h323",
                  @"MultiUser Helix Server",@"helix",
                  @"Home Media Control Protocol",@"hmcp",
                  @"World Wide Web HTML-over-HTTP",@"http",
                  @"HTTP over SSL/TLS",@"https",
                  @"iDo Technology Home Automation Protocol",@"homeauto",
                  @"Honeywell Video Systems",@"honeywell-vid",
                  @"Hotwayd",@"hotwayd",
                  @"Howdy messaging and notification protocol",@"howdy",
                  @"HP Remote Build System for Linux-based Systems",@"hpr-bldlnx",
                  @"HP Remote Build System for Microsoft Windows Systems",@"hpr-bldwin",
                  @"Identifies systems that house databases for the Remote Build System and Remote Test System",@"hpr-db",
                  @"HP Remote Repository for Build and Test Results",@"hpr-rep",
                  @"HP Remote System that houses compilers and tools for Linux-based Systems",@"hpr-toollnx",
                  @"HP Remote System that houses compilers and tools for Microsoft Windows Systems",@"hpr-toolwin",
                  @"HP Remote Test System for Linux-based Systems",@"hpr-tstlnx",
                  @"HP Remote Test System for Microsoft Windows Systems",@"hpr-tstwin",
                  @"Hobbyist Software Off Discovery",@"hs-off",
                  @"SubEthaEdit",@"hydra",
                  @"Inter Asterisk eXchange, ease-of-use NAT friendly open VoIP protocol",@"iax",
                  @"iBiz Server",@"ibiz",
                  @"Image Capture Networking",@"ica-networking",
                  @"Northrup Grumman/TASC/ICAN Protocol",@"ican",
                  @"iChalk",@"ichalkboard",
                  @"iChat 1.0",@"ichat",
                  @"iConquer",@"iconquer",
                  @"Generic Data Acquisition and Control Protocol",@"idata",
                  @"SplashID Synchronization Service",@"idsync",
                  @"Published iFolder",@"ifolder",
                  @"Idle Hands iHouse Protocol",@"ihouse",
                  @"Instant Interactive Drills",@"ii-drills",
                  @"Instant Interactive Konane",@"ii-konane",
                  @"iLynX",@"ilynx",
                  @"Internet Message Access Protocol",@"imap",
                  @"iMidi",@"imidi",
                  @"Inova Solutions OnTrack Display Protocol",@"inova-ontrack",
                  @"Intermec Device Configuration Web Services",@"idcws",
                  @"IP Broadcaster",@"ipbroadcaster",
                  @"IPP (Internet Printing Protocol)",@"ipp",
                  @"IP Speaker Control Protocol",@"ipspeaker",
                  @"Intego Remote Management Console",@"irmc",
                  @"Internet Small Computer Systems Interface (iSCSI)",@"iscsi",
                  @"iSparx",@"isparx",
                  @"iSpQ VideoChat",@"ispq-vc",
                  @"iShare",@"ishare",
                  @"iSticky",@"isticky",
                  @"iStorm",@"istorm",
                  @"iTunes Socket Remote Control",@"itsrc",
                  @"iWork Server",@"iwork",
                  @"Northrup Grumman/TASC/JCAN Protocol",@"jcan",
                  @"Jedit X",@"jeditx",
                  @"Jini Service Discovery",@"jini",
                  @"Proprietary",@"jtag",
                  @"Kerberos",@"kerberos",
                  @"Kerberos Administration",@"kerberos-adm",
                  @"Kabira Transaction Platform",@"ktp",
                  @"Lan2P Peer-to-Peer Network Protocol",@"lan2p",
                  @"Gawker",@"lapse",
                  @"LANrev Agent",@"lanrevagent",
                  @"LANrev Server",@"lanrevserver",
                  @"Lightweight Directory Access Protocol",@"ldap",
                  @"Lexicon Vocabulary Sharing",@"lexicon",
                  @"Liaison",@"liaison",
                  @"Delicious Library 2 Collection Data Sharing Protocol",@"library",
                  @"RFID reader Low Level Reader Protocol",@"llrp",
                  @"RFID reader Low Level Reader Protocol over SSL/TLS",@"llrp-secure",
                  @"Gobby",@"lobby",
                  @"Logic Pro Distributed Audio",@"logicnode",
                  @"Remote Login a la Telnet",@"login",
                  @"LonTalk over IP (ANSI 852)",@"lontalk",
                  @"Echelon LNS Remote Client",@"lonworks",
                  @"Linksys One Application Server API",@"lsys-appserver",
                  @"Linksys One Camera API",@"lsys-camera",
                  @"LinkSys EZ Configuration",@"lsys-ezcfg",
                  @"LinkSys Operations, Administration, Management, and Provisioning",@"lsys-oamp",
                  @"Lux Solis Data Transport Protocol",@"lux-dtp",
                  @"LXI",@"lxi",
                  @"iPod Lyrics Service",@"lyrics",
                  @"MacFOH",@"macfoh",
                  @"MacFOH admin services",@"macfoh-admin",
                  @"MacFOH audio stream",@"macfoh-audio",
                  @"MacFOH show control events",@"macfoh-events",
                  @"MacFOH realtime data",@"macfoh-data",
                  @"MacFOH database",@"macfoh-db",
                  @"MacFOH Remote",@"macfoh-remote",
                  @"Mac Minder",@"macminder",
                  @"Maestro Music Sharing Service",@"maestro",
                  @"Magic Dice Game Protocol",@"magicdice",
                  @"Mandos Password Server",@"mandos",
                  @"MediaBroker++ Consumer",@"mbconsumer",
                  @"MediaBroker++ Producer",@"mbproducer",
                  @"MediaBroker++ Server",@"mbserver",
                  @"MediaCentral",@"mcrcp",
                  @"Mes Amis",@"mesamis",
                  @"Mimer SQL Engine",@"mimer",
                  @"Mental Ray for Maya",@"mi-raysat",
                  @"modo LAN Services",@"modolansrv",
                  @"SplashMoney Synchronization Service",@"moneysync",
                  @"MoneyWorks Gold and MoneyWorks Datacentre network service",@"moneyworks",
                  @"Bonjour Mood Ring tutorial program",@"moodring",
                  @"Mother script server protocol",@"mother",
                  @"MP3 Sushi",@"mp3sushi",
                  @"IBM MQ Telemetry Transport Broker",@"mqtt",
                  @"Martian SlingShot",@"mslingshot",
                  @"MySync Protocol",@"mysync",
                  @"MenuTunes Sharing",@"mttp",
                  @"MatrixStore",@"mxs",
                  @"Network Clipboard Broadcasts",@"ncbroadcast",
                  @"Network Clipboard Direct Transfers",@"ncdirect",
                  @"Network Clipboard Sync Server",@"ncsyncserver",
                  @"NeoRiders Client Discovery Protocol",@"neoriders",
                  @"Apple Remote Desktop",@"net-assistant",
                  @"Vesa Net2Display",@"net2display",
                  @"NetRestore",@"netrestore",
                  @"Escale",@"newton-dock",
                  @"Network File System - Sun Microsystems",@"nfs",
                  @"DO over NSSocketPort",@"nssocketport",
                  @"American Dynamics Intellex Archive Management Service",@"ntlx-arch",
                  @"American Dynamics Intellex Enterprise Management Service",@"ntlx-ent",
                  @"American Dynamics Intellex Video Service",@"ntlx-video",
                  @"Network Time Protocol",@"ntp",
                  @"Tenasys",@"ntx",
                  @"Observations Framework",@"obf",
                  @"Means for clients to locate servers in an Objective (http://www.objective.com) instance.",@"objective",
                  @"Oce Common Exchange Protocol",@"oce",
                  @"OD4Contact",@"odabsharing",
                  @"Optical Disk Sharing",@"odisk",
                  @"OmniFocus setting configuration",@"ofocus-conf",
                  @"OmniFocus document synchronization",@"ofocus-sync",
                  @"One Laptop per Child activity",@"olpc-activity1",
                  @"OmniWeb",@"omni-bookmark",
                  @"OpenBase SQL",@"openbase",
                  @"Conferencing Protocol",@"opencu",
                  @"oprofile server protocol",@"oprofile",
                  @"Open Sound Control Interface Transfer",@"oscit",
                  @"ObjectVideo OV Ready Protocol",@"ovready",
                  @"OWFS (1-wire file system) web server",@"owhttpd",
                  @"OWFS (1-wire file system) server",@"owserver",
                  @"Remote Parental Controls",@"parentcontrol",
                  @"PasswordWallet Data Synchronization Protocol",@"passwordwallet",
                  @"Mac OS X Podcast Producer Server",@"pcast",
                  @"Peer-to-Peer Chat (Sample Java Bonjour application)",@"p2pchat",
                  @"PhoneValet Anywhere",@"parliant",
                  @"Printer Page Description Language Data Stream (vendor-specific)",@"pdl-datastream",
                  @"Horowitz Key Protocol (HKP)",@"pgpkey-hkp",
                  @"PGP Keyserver using HTTP/1.1",@"pgpkey-https",
                  @"PGP Keyserver using HTTPS",@"pgpkey-https",
                  @"PGP Keyserver using LDAP",@"pgpkey-ldap",
                  @"PGP Key submission using SMTP",@"pgpkey-mailto",
                  @"Photo Parata Event Photography Software",@"photoparata",
                  @"Pictua Intercommunication Protocol",@"pictua",
                  @"pieSync Computer to Computer Synchronization",@"piesync",
                  @"Pedestal Interface Unit by RPM-PSI",@"piu",
                  @"Parallel OperatiOn and Control Heuristic (Pooch)",@"poch",
                  @"Communication channel for \"Poke Eye\" Elgato EyeTV remote controller",@"pokeeye",
                  @"Post Office Protocol - Version 3",@"pop3",
                  @"PostgreSQL Server",@"postgresql",
                  @"PowerEasy ERP",@"powereasy-erp",
                  @"PowerEasy Point of Sale",@"powereasy-pos",
                  @"Piano Player Remote Control",@"pplayer-ctrl",
                  @"Peer-to-peer messaging / Link-Local Messaging",@"presence",
                  @"Retrieve a description of a device's print capabilities",@"print-caps",
                  @"Spooler (more commonly known as \"LPR printing\" or \"LPD printing\")",@"printer",
                  @"Profile for Mac medical practice management software",@"profilemac",
                  @"Prolog",@"prolog",
                  @"Physical Security Interoperability Alliance Protocol",@"psia",
                  @"PTNetPro Service",@"ptnetprosrv2",
                  @"Picture Transfer Protocol",@"ptp",
                  @"PTP Initiation Request Protocol",@"ptp-req",
                  @"QBox Appliance Locator",@"qbox",
                  @"QuickTime Transfer Protocol",@"qttp",
                  @"Quinn Game Server",@"quinn",
                  @"Rakket Client Protocol",@"rakket",
                  @"RadioTAG: Event tagging for radio services",@"radiotag",
                  @"RadioVIS: Visualisation for radio services",@"radiovis",
                  @"RadioEPG:ÊElectronic Programme Guide forÊradio services",@"radioepg",
                  @"Remote Audio Output Protocol (AirTunes)",@"raop",
                  @"RBR Instrument Communication",@"rbr",
                  @"PowerCard",@"rce",
                  @"Windows Remote Desktop Protocol",@"rdp",
                  @"RealPlayer Shared Favorites",@"realplayfavs",
                  @"Recipe Sharing Protocol",@"recipe",
                  @"LaCie Remote Burn",@"remoteburn",
                  @"ARTvps RenderDrive/PURE Renderer Protocol",@"renderpipe",
                  @"RendezvousPong",@"rendezvouspong",
                  @"Community Service",@"resacommunity",
                  @"RESOL VBus",@"resol-vbus",
                  @"Retrospect backup and restore service",@"retrospect",
                  @"Remote Frame Buffer (used by realvnc.com)",@"rfb",
                  @"Remote Frame Buffer Client (Used by VNC viewers in listen-mode)",@"rfbc",
                  @"RFID Reader Mach1(tm) Protocol",@"rfid",
                  @"Remote I/O USB Printer Protocol",@"riousbprint",
                  @"Roku Control Protocol",@"roku-rcp",
                  @"RemoteQuickLaunch",@"rql",
                  @"Remote System Management Protocol (Server Instance)",@"rsmp-server",
                  @"Rsync",@"rsync",
                  @"Real Time Streaming Protocol",@"rtsp",
                  @"RubyGems GemServer",@"rubygems",
                  @"Safari Menu",@"safarimenu",
                  @"Salling Clicker Sharing",@"sallingbridge",
                  @"Salling Clicker Service",@"sallingclicker",
                  @"Salutafugi Peer-To-Peer Java Message Service Implementation",@"salutafugijms",
                  @"Sandvox",@"sandvox",
                  @"Bonjour Scanning",@"scanner",
                  @"Schick",@"schick",
                  @"Scone",@"scone",
                  @"IEEE 488.2 (SCPI) Socket",@"scpi-raw",
                  @"IEEE 488.2 (SCPI) Telnet",@"scpi-telnet",
                  @"Speed Download",@"sdsharing",
                  @"SubEthaEdit 2",@"see",
                  @"seeCard",@"seeCard",
                  @"Senteo Assessment Software Protocol",@"senteo-http",
                  @"Sentillion Vault System",@"sentillion-vlc",
                  @"Sentillion Vault Systems Cluster",@"sentillion-vlt",
                  @"serendiPd Shared Patches for Pure Data",@"serendipd",
                  @"ServerEye AgentContainer Communication Protocol",@"servereye",
                  @"Mac OS X Server Admin",@"servermgr",
                  @"DNS Service Discovery",@"services",
                  @"Session File Sharing",@"sessionfs",
                  @"Secure File Transfer Protocol over SSH",@"sftp-ssh",
                  @"like exec, but automatic authentication is performed as for login server.",@"shell",
                  @"Swift Office Ships",@"shipsgm",
                  @"Swift Office Ships",@"shipsinvit",
                  @"SplashShopper Synchronization Service",@"shoppersync",
                  @"Nicecast",@"shoutcast",
                  @"Session Initiation Protocol, signalling protocol for VoIP",@"sip",
                  @"Session Initiation Protocol Uniform Resource Identifier",@"sipuri",
                  @"Sirona Xray Protocol",@"sironaxray",
                  @"Skype",@"skype",
                  @"Sleep Proxy Server",@"sleep-proxy",
                  @"SliMP3 Server Command-Line Interface",@"slimcli",
                  @"SliMP3 Server Web Interface",@"slimhttp",
                  @"Server Message Block over TCP/IP",@"smb",
                  @"Simple Object Access Protocol",@"soap",
                  @"Simple Object eXchange",@"sox",
                  @"sPearCat Host Discovery",@"spearcat",
                  @"Shared Clipboard Protocol",@"spike",
                  @"Spin Crisis",@"spincrisis",
                  @"launchTunes",@"spl-itunes",
                  @"netTunes",@"spr-itunes",
                  @"SplashData Synchronization Service",@"splashsync",
                  @"SSH Remote Login Protocol",@"ssh",
                  @"Screen Sharing",@"ssscreenshare",
                  @"Strateges",@"strateges",
                  @"Sun Grid Engine (Execution Host)",@"sge-exec",
                  @"Sun Grid Engine (Master)",@"sge-qmaster",
                  @"SousChef Recipe Sharing Protocol",@"souschef",
                  @"SPARQL Protocol and RDF Query Language",@"sparql",
                  @"Lexcycle Stanza service for discovering shared books",@"stanza",
                  @"Sticky Notes",@"stickynotes",
                  @"Message Submission",@"submission",
                  @"Supple Service protocol",@"supple",
                  @"Surveillus Networks Discovery Protocol",@"surveillus",
                  @"Subversion",@"svn",
                  @"Signwave Card Sharing Protocol",@"swcards",
                  @"Wireless home control remote control protocol",@"switcher",
                  @"Swordfish Protocol for Input/Output",@"swordfish",
                  @"Synchronize! Pro X",@"sxqdea",
                  @"Sybase Server",@"sybase-tds",
                  @"Syncopation Synchronization Protocol by Sonzea",@"syncopation",
                  @"Synchronize! X Plus 2.0",@"syncqdea",
                  @"Data Transmission and Synchronization",@"taccounting",
                  @"Tapinoma Easycontact receiver",@"tapinoma-ecs",
                  @"Task Coach Two-way Synchronization Protocol for iPhone",@"taskcoachsync",
                  @"tbricks internal protocol",@"tbricks",
                  @"Time Code",@"tcode",
                  @"Tracking Control Unit by RPM-PSI",@"tcu",
                  @"ARTIS Team Task",@"teamlist",
                  @"teleport",@"teleport",
                  @"Telnet",@"telnet",
                  @"Terascala Maintenance Protocol",@"tera-mp",
                  @"ThinkFlood RedEye IR bridge",@"tf-redeye",
                  @"Trivial File Transfer",@"tftp",
                  @"TI Connect Manager Discovery Service",@"ticonnectmgr",
                  @"Timbuktu",@"timbuktu",
                  @"TI Navigator Hub 1.0 Discovery Service",@"tinavigator",
                  @"TiVo Home Media Engine Protocol",@"tivo-hme",
                  @"TiVo Music Protocol",@"tivo-music",
                  @"TiVo Photos Protocol",@"tivo-photos",
                  @"TiVo Remote Protocol",@"tivo-remote",
                  @"TiVo Videos Protocol",@"tivo-videos",
                  @"Tomboy",@"tomboy",
                  @"ToothPics Dental Office Support Server",@"toothpicserver",
                  @"iPhone and iPod touch Remote Controllable",@"touch-able",
                  @"iPhone and iPod touch Remote Pairing",@"touch-remote",
                  @"Tryst",@"tryst",
                  @"TechTool Pro 4 Anti-Piracy Service",@"ttp4daemon",
                  @"Tunage Media Control Service",@"tunage",
                  @"TuneRanger",@"tuneranger",
                  @"Ubertragen",@"ubertragen",
                  @"Universal Description, Discovery and Integration",@"uddi",
                  @"Universal Description, Discovery and Integration Inquiry",@"uddi-inq",
                  @"Universal Description, Discovery and Integration Publishing",@"uddi-pub",
                  @"Universal Description, Discovery and Integration Subscription",@"uddi-sub",
                  @"Universal Description, Discovery and Integration Security",@"uddi-sec",
                  @"Universal Plug and Play",@"upnp",
                  @"Universal Switching Corporation products",@"uswi",
                  @"uTest",@"utest",
                  @"American Dynamics VideoEdge Decoder Control Service",@"ve-decoder",
                  @"American Dynamics VideoEdge Encoder Control Service",@"ve-encoder",
                  @"American Dynamics VideoEdge Recorder Control Service",@"ve-recorder",
                  @"visel Q-System services",@"visel",
                  @"Volley",@"volley",
                  @"Virtual Object System (using VOP/TCP)",@"vos",
                  @"VueProRenderCow",@"vue4rendercow",
                  @"VXI-11 TCP/IP Instrument Protocol",@"vxi-11",
                  @"World Wide Web Distributed Authoring and Versioning (WebDAV)",@"webdav",
                  @"WebDAV over SSL/TLS",@"webdavs",
                  @"Whamb",@"whamb",
                  @"Wired Server",@"wired",
                  @"WiTap Sample Game Protocol",@"witap",
                  @"Workgroup Server Discovery",@"wkgrpsvr",
                  @"Workgroup Manager",@"workstation",
                  @"Roku Cascade Wormhole Protocol",@"wormhole",
                  @"Novell collaboration workgroup",@"workgroup",
                  @"Web Services",@"ws",
                  @"Wyatt Technology Corporation HELEOS",@"wtc-heleos",
                  @"Wyatt Technology Corporation QELS",@"wtc-qels",
                  @"Wyatt Technology Corporation Optilab rEX",@"wtc-rex",
                  @"Wyatt Technology Corporation ViscoStar",@"wtc-viscostar",
                  @"Wyatt Technology Corporation DynaPro Plate Reader",@"wtc-wpr",
                  @"PictureSharing sample code",@"wwdcpic",
                  @"x-plane9",@"x-plane9",
                  @"Xcode Distributed Compiler",@"xcodedistcc",
                  @"xGate Remote Management Interface",@"xgate-rmi",
                  @"Xgrid",@"xgrid",
                  @"XMMS2 IPC Protocol",@"xmms2",
                  @"Xperientia Mobile Protocol",@"xmp",
                  @"XMPP Client Connection",@"xmpp-client",
                  @"XMPP Server Connection",@"xmpp-server",
                  @"Xsan Client",@"xsanclient",
                  @"Xsan Server",@"xsanserver",
                  @"Xsan System",@"xsansystem",
                  @"XServe Raid",@"xserveraid",
                  @"Xserve RAID Synchronization",@"xsync",
                  @"xTime License",@"xtimelicence",
                  @"xTime Project",@"xtshapro",
                  @"XUL (XML User Interface Language) transported over HTTP",@"xul-http",
                  @"Yakumo iPhone OS Device Control Protocol",@"yakumo",
                  @"Big Bang Backgammon",@"bigbangbackgammon",
                  @"Big Bang Checkers",@"bigbangcheckers",
                  @"ClipboardSharing",@"clipboardsharing",
                  @"InterBase Database Remote Protocol",@"gds_db",
                  @"Net Monitor Server",@"netmonitorserver",
                  @"OLPC Presence",@"presence_olpc",
                  @"Pop-Pop",@"pop_2_ambrosia",
                  @"ProfCast",@"profCastLicense",
                  @"World Book Encyclopedia",@"WorldBook2004ST",
                  nil];
   
}

@end
