#include <a_samp> 			// SAMP Teamds
#include <easyDialog>   	// Emmet_
#include <sscanf2>      	// Emmet_
#include <izcmd>        	// Yashas
#include <easy-mysql>   	// ThePhenix
#include <timestamptodate>  // Jochemd
#include <streamer>         // Incognito

// MySQL Configuration
#define MYSQL_HOST    						"127.0.0.1"     	// Your MySQL's Host
#define MYSQL_USER    						"root"          	// Your MySQL's Username
#define MYSQL_PASS         					""              	// Your MySQL's Password
#define MYSQL_DB        					"sampdb"       	// Your MySQL's Database
#define mysql_debugging_enabled             true          		// Enable debug mode if you want change it

#define PLAYERS_TABLE                       "accounts"          // Table where all accounts will be saved
#define BANS_TABLE		       				"bans"              // Table where all Bans will be saved

// Configuration
#define READ_COMMANDS                                           // Comment to disable admins from reading commands
//#define REQUIRE_LOGIN                                           // Comment to disable players from forcing to login
//#define REQUIRE_REGISTER                                        // Comment to disable players from forcing to register
#define LOGIN_ATTEMPTS 						3                   // Max login attemps (Use 0 to disable it)
#define MAX_WARNS                           3                   // Max Warnings (After that number player will be kicked)

#define SAVE_LOGS                                               // Comment to disable log system
#if defined SAVE_LOGS
	#define LOGFILE                         "sbAdmin/Logs/"     // Place where Logs will be saved (If log system is on)
#endif

#define MAX_ADMIN_LEVELS                    7                   // Max admin levels where a player can get
#define MAX_CIVILIAN_LEVELS                	3                   // Max Civilian levels where a player can get

#define SPECTATE_TEXTDRAW     									// Comment to disable textdraws when you spec a player
#define USE_ANTIADVERT                                          // Comment to disable anti advert system by SickAttack


#define LEVEL1                              "Moderator"       // Name for level 1 admin
#define LEVEL2                              "Junior Administrator"      // Name for level 2 admin
#define LEVEL3                              "Senior Administrator"     // Name for level 3 admin
#define LEVEL4                              "Lead Administrator"        // Name for level 4 admin
#define LEVEL5                              "Server Manager"          // Name for level 5 admin
#define LEVEL6                              "Community Manager"          // Name for level 5 admin
#define LEVEL7                              "Community Owner"          // Name for level 5 admin

// Colors
#define COLOR_WHITE       					0xFFFFFFFF
#define COLOR_RED         					0xFF0000FF
#define COLOR_CYAN        					0x33CCFFFF
#define COLOR_LIGHTRED    					0xFF6347FF
#define COLOR_LIGHTGREEN  					0x9ACD32FF
#define COLOR_YELLOW      					0xFFFF00FF
#define COLOR_GREY        					0xAFAFAFFF
#define COLOR_PURPLE      					0xD0AEEBFF
#define COLOR_LIGHTYELLOW 					0xF5DEB3FF
#define COLOR_DARKBLUE    					0x1394BFFF
#define COLOR_ORANGE      					0xFFA500FF
#define COLOR_LIME        					0x00FF00FF
#define COLOR_GREEN       					0x33CC33FF
#define COLOR_BLUE        					0x2641FEFF
#define COLOR_LIGHTBLUE   					0x007FFFFF
#define COLOR_SERVER      					0xFFFF90FF

#define white 								"{FFFFFF}"
#define lightblue 							"{33CCFF}"
#define grey                                "{AFAFAF}"
#define orange                              "{FF8000}"
#define black                               "{2C2727}"
#define red                                 "{FF0000}"
#define yellow                              "{FFFF00}"
#define green                               "{33CC33}"
#define blue                                "{0080FF}"
#define purple                              "{D526D9}"
#define pink                                "{FF80FF}"
#define brown                               "{A52A2A}"

// Other defines & Macros
new sb_string[144];

#define Server(%0,%1) \
	SendClientMessage(%0, COLOR_SERVER, "{FFFFFF}[{3498DB}SERVER{FFFFFF}]: {FFFFFF}"%1)

#define Usage(%0,%1) \
	SendClientMessage(%0, COLOR_GREY, "Usage: {FFFFFF}/"%1)

#define Error(%0,%1) \
	SendClientMessage(%0, -1, "{FFFFFF}[{db2b42}ERROR{FFFFFF}]: {FFFFFF}"%1)

#define LevelCheck(%0,%1); \
	if(GetLevel(%0) < %1 && ! IsPlayerAdmin(%0)) \
	    return (format(sb_string, sizeof(sb_string), "{FFFFFF}[{db2b42}ERROR{FFFFFF}]: You must be level %i admin to use this command.", %1), \
			SendClientMessage(%0, -1, sb_string));

#define CitizenCheck(%0,%1); \
	if(GetCLevel(%0) < %1) \
	    return (format(sb_string, sizeof(sb_string), "{FFFFFF}[{db2b42}ERROR{FFFFFF}]: You must be level %i citizen to use this command.", %1), \
			SendClientMessage(%0, -1, sb_string));

#define MemberCheck(%1); \
	if(!IsPlayerMember(%1)) \
		return Error(playerid, "{FFFFFF}[{db2b42}ERROR{FFFFFF}]: You've not subscribed Premium Membership. Subscribe today!");

#define LOOP_PLAYERS(%0) \
			for(new %0 = 0, _%0 = GetPlayerPoolSize(); %0 <= _%0, IsPlayerConnected(%0); %0++)

#if !defined IsValidWeapon
	#define IsValidWeapon(%0) (%0 < 47)
#endif

// Some variables

new Text:announceTD;

//=================================================

enum sbAdmin
{
	// Saved data
    id,             	// Account ID
    username[24],   	// Registered username
    password[114],  	// Hashed password
    ip[16],         	// IP
    score,          	// Score
    
    tokens,             // Tokens
    exp,                // Experience
    level,          	// Admin Level
    member,         	// Membership
    civilian,          	// Civilian Level
    
    cash,           	// Cash/Money
    kills,          	// Kills
    deaths,         	// Deaths
	ohours,         	// Online Hours
	ominutes,       	// Online Minutes
	oseconds,       	// Online Seconds
	wanteds,        	// Wanteds
	mutedsec,       	// Muted seconds
	cmdmutedsec,    	// Command muted seconds
	jailedsec,      	// Jailed seconds
	warns,          	// Total warns
    
    // Not saved data
    loggedin,       	// Checks if player is logged in
	attempts,       	// Counts login attempts
	avehicle,       	// Counts admin vehicles
	thours,         	// total hours
	tminutes,       	// total minutes
	tseconds,       	// total seconds
	updatetimer,    	// Timer that is called each 1 sec
	specdata[2],        // Data that are used for Spectate system
	Float:specpos[4],   // Data that are used for Spectate system
	specid,             // Spectate ID
	bool:spec,          // Check for IsPlayerSpectating
	Float:pos[3],       // Data that are used for Spectate system
	int,                // Interior
	#if defined SPECTATE_TEXTDRAW
		PlayerText:specTD,
	#endif
	vw,                 // Virtual World
	jailed          	// Checks if player is jailed
};
new User[MAX_PLAYERS][sbAdmin];

//=================================================

new sbVehicles[212][] =
{
	{"Landstalker"},{"Bravura"},{"Buffalo"},{"Linerunner"},{"Perrenial"},{"Sentinel"},{"Dumper"},
	{"Firetruck"},{"Trashmaster"},{"Stretch"},{"Manana"},{"Infernus"},{"Voodoo"},{"Pony"},{"Mule"},
	{"Cheetah"},{"Ambulance"},{"Leviathan"},{"Moonbeam"},{"Esperanto"},{"Taxi"},{"Washington"},
	{"Bobcat"},{"Mr Whoopee"},{"BF Injection"},{"Hunter"},{"Premier"},{"Enforcer"},{"Securicar"},
	{"Banshee"},{"Predator"},{"Bus"},{"Rhino"},{"Barracks"},{"Hotknife"},{"Trailer 1"},{"Previon"},
	{"Coach"},{"Cabbie"},{"Stallion"},{"Rumpo"},{"RC Bandit"},{"Romero"},{"Packer"},{"Monster"},
	{"Admiral"},{"Squalo"},{"Seasparrow"},{"Pizzaboy"},{"Tram"},{"Trailer 2"},{"Turismo"},
	{"Speeder"},{"Reefer"},{"Tropic"},{"Flatbed"},{"Yankee"},{"Caddy"},{"Solair"},{"Berkley's RC Van"},
	{"Skimmer"},{"PCJ-600"},{"Faggio"},{"Freeway"},{"RC Baron"},{"RC Raider"},{"Glendale"},{"Oceanic"},
	{"Sanchez"},{"Sparrow"},{"Patriot"},{"Quad"},{"Coastguard"},{"Dinghy"},{"Hermes"},{"Sabre"},
	{"Rustler"},{"ZR-350"},{"Walton"},{"Regina"},{"Comet"},{"BMX"},{"Burrito"},{"Camper"},{"Marquis"},
	{"Baggage"},{"Dozer"},{"Maverick"},{"News Chopper"},{"Rancher"},{"FBI Rancher"},{"Virgo"},{"Greenwood"},
	{"Jetmax"},{"Hotring"},{"Sandking"},{"Blista Compact"},{"Police Maverick"},{"Boxville"},{"Benson"},
	{"Mesa"},{"RC Goblin"},{"Hotring Racer A"},{"Hotring Racer B"},{"Bloodring Banger"},{"Rancher"},
	{"Super GT"},{"Elegant"},{"Journey"},{"Bike"},{"Mountain Bike"},{"Beagle"},{"Cropdust"},{"Stunt"},
	{"Tanker"}, {"Roadtrain"},{"Nebula"},{"Majestic"},{"Buccaneer"},{"Shamal"},{"Hydra"},{"FCR-900"},
	{"NRG-500"},{"HPV1000"},{"Cement Truck"},{"Tow Truck"},{"Fortune"},{"Cadrona"},{"FBI Truck"},
	{"Willard"},{"Forklift"},{"Tractor"},{"Combine"},{"Feltzer"},{"Remington"},{"Slamvan"},
	{"Blade"},{"Freight"},{"Streak"},{"Vortex"},{"Vincent"},{"Bullet"},{"Clover"},{"Sadler"},
	{"Firetruck LA"},{"Hustler"},{"Intruder"},{"Primo"},{"Cargobob"},{"Tampa"},{"Sunrise"},{"Merit"},
	{"Utility"},{"Nevada"},{"Yosemite"},{"Windsor"},{"Monster A"},{"Monster B"},{"Uranus"},{"Jester"},
	{"Sultan"},{"Stratum"},{"Elegy"},{"Raindance"},{"RC Tiger"},{"Flash"},{"Tahoma"},{"Savanna"},
	{"Bandito"},{"Freight Flat"},{"Streak Carriage"},{"Kart"},{"Mower"},{"Duneride"},{"Sweeper"},
	{"Broadway"},{"Tornado"},{"AT-400"},{"DFT-30"},{"Huntley"},{"Stafford"},{"BF-400"},{"Newsvan"},
	{"Tug"},{"Trailer 3"},{"Emperor"},{"Wayfarer"},{"Euros"},{"Hotdog"},{"Club"},{"Freight Carriage"},
	{"Trailer 3"},{"Andromada"},{"Dodo"},{"RC Cam"},{"Launch"},{"Police Car (LSPD)"},{"Police Car (SFPD)"},
	{"Police Car (LVPD)"},{"Police Ranger"},{"Picador"},{"S.W.A.T. Van"},{"Alpha"},{"Phoenix"},{"Glendale"},
	{"Sadler"},{"Luggage Trailer A"},{"Luggage Trailer B"},{"Stair Trailer"},{"Boxville"},{"Farm Plow"},
	{"Utility Trailer"}
};

//=================================================
public OnFilterScriptInit()
{
    print("\n\n_________________________________________________________________");
	print("                        sbAdmin                                    \n");
	print("[sbAdmin]: Attempting to load administration system                  ");
    SQL::Connect(MYSQL_HOST, MYSQL_USER, MYSQL_DB, MYSQL_PASS);
    if(!SQL::ExistsTable(""PLAYERS_TABLE""))
    {
        new handle = SQL::Open(SQL::CREATE, ""PLAYERS_TABLE"");
        SQL::AddTableEntry(handle, "id", SQL_TYPE_INT, 11, true);
        SQL::AddTableEntry(handle, "username", SQL_TYPE_VCHAR, 24);
        SQL::AddTableEntry(handle, "password", SQL_TYPE_VCHAR, 114);
        SQL::AddTableEntry(handle, "ip", SQL_TYPE_VCHAR, 24);
        SQL::AddTableEntry(handle, "score", SQL_TYPE_INT);
        SQL::AddTableEntry(handle, "tokens", SQL_TYPE_INT);
        SQL::AddTableEntry(handle, "exp", SQL_TYPE_INT);
        SQL::AddTableEntry(handle, "cash", SQL_TYPE_INT);
        SQL::AddTableEntry(handle, "kills", SQL_TYPE_INT);
        SQL::AddTableEntry(handle, "deaths", SQL_TYPE_INT);
        SQL::AddTableEntry(handle, "member", SQL_TYPE_INT);
        SQL::AddTableEntry(handle, "level", SQL_TYPE_INT);
        SQL::AddTableEntry(handle, "hours", SQL_TYPE_INT);
        SQL::AddTableEntry(handle, "minutes", SQL_TYPE_INT);
        SQL::AddTableEntry(handle, "seconds", SQL_TYPE_INT);
        SQL::AddTableEntry(handle, "wanteds", SQL_TYPE_INT);
        SQL::AddTableEntry(handle, "laston", SQL_TYPE_VCHAR, 48);
        SQL::AddTableEntry(handle, "joined", SQL_TYPE_VCHAR, 48);
        SQL::AddTableEntry(handle, "mutedsec", SQL_TYPE_INT);
        SQL::AddTableEntry(handle, "cmdmutedsec", SQL_TYPE_INT);
        SQL::AddTableEntry(handle, "jailedsec", SQL_TYPE_INT);
        SQL::AddTableEntry(handle, "warns", SQL_TYPE_INT);
        
        SQL::Close(handle);
        print("[sbAdmin]: '"PLAYERS_TABLE"' table created successfully!");
    }
    else if(SQL::ExistsTable(""PLAYERS_TABLE""))
    {
        printf("[sbAdmin]: Total %d accounts loaded from '"PLAYERS_TABLE"'", SQL::CountRows(""PLAYERS_TABLE""));
	}
 	if(!SQL::ExistsTable(""BANS_TABLE""))
    {
        new handle = SQL::Open(SQL::CREATE, ""BANS_TABLE"");
        SQL::AddTableEntry(handle, "ban_id", SQL_TYPE_INT, 11, true);
        SQL::AddTableEntry(handle, "ban_username", SQL_TYPE_VCHAR, 24);
        SQL::AddTableEntry(handle, "ban_ip", SQL_TYPE_VCHAR, 24);
        SQL::AddTableEntry(handle, "ban_by", SQL_TYPE_VCHAR, 24);
        SQL::AddTableEntry(handle, "ban_on", SQL_TYPE_VCHAR, 24);
        SQL::AddTableEntry(handle, "ban_reason", SQL_TYPE_VCHAR, 24);
        SQL::AddTableEntry(handle, "ban_expire", SQL_TYPE_INT);
        SQL::Close(handle);
        
        print("[sbAdmin]: '"BANS_TABLE"' table created successfully!");
    }
    else if(SQL::ExistsTable(""BANS_TABLE""))
    {
        printf("[sbAdmin]: Total %d bans loaded from '"BANS_TABLE"'", SQL::CountRows(""BANS_TABLE""));
	}
    
    print("[sbAdmin]: sbAdmin Administration system loaded successfully         ");
    print("[sbAdmin]: Version: 1.2 											    ");
    print("\n                       sbAdmin                                     ");
    print("_________________________________________________________________\n\n");
    
    // Place the maps
    PlaceMaps();
    
    // Build text
    BuildTextdraws();
    return 1;
}

//=================================================

public OnPlayerConnect(playerid)
{
	// Hide Spectate textdraw (If it is enabled)
	#if defined SPECTATE_TEXTDRAW
		PlayerTextDrawHide(playerid, User[playerid][specTD]);
	#endif
	
	// Ban Checking system
	new
		string[6][24],
		string2[156],
		expire,
		DIALOG[676]
	;

    if(SQL::RowExistsEx(""BANS_TABLE"", "ban_username", GetName(playerid)))
    {
		new handle = SQL::OpenEx(SQL::READ, ""BANS_TABLE"", "ban_username", GetName(playerid));
        SQL::ReadString(handle, "ban_username", string[1], 24);
        SQL::ReadString(handle, "ban_ip", string[2], 24);
        SQL::ReadString(handle, "ban_by", string[3], 24);
        SQL::ReadString(handle, "ban_on", string[4], 24);
        SQL::ReadString(handle, "ban_reason", string[5], 24);
        SQL::ReadInt(handle, "ban_expire", expire);
        SQL::Close(handle);

        if(expire > gettime() || expire == 0)
        {

			strcat(DIALOG, ""white"Your account is banned from this server,\n\n");

		    format(string2, sizeof(string2), ""white"Username: "red"%s\n", string[1]);
			strcat(DIALOG, string2);

		    format(string2, sizeof(string2), ""white"IP: "red"%s\n", string[2]);
			strcat(DIALOG, string2);

		    format(string2, sizeof(string2), ""white"Banned by: "red"%s\n", string[3]);
			strcat(DIALOG, string2);

		    format(string2, sizeof(string2), ""white"Reason: "red"%s\n", string[5]);
			strcat(DIALOG, string2);

		    format(string2, sizeof(string2), ""white"Ban date: "red"%s\n", string[4]);
			strcat(DIALOG, string2);

		    new expire2[68];
			if(expire == 0) expire2 = "PERMANENT";
			else expire2 = ConvertTime(expire);
		    format(string2, sizeof(string2), ""white"Timeleft: "red"%s\n\n", expire2);
			strcat(DIALOG, string2);

			strcat(DIALOG, ""white"If you think that you got banned wrongfully, please make an appeal on our forums.\n");
			strcat(DIALOG, "Make sure you saved this box by pressing F8.");

			Dialog_Show(playerid, dialogUnused, DIALOG_STYLE_MSGBOX, "Notice", DIALOG, "Close", "");
            DelayKick(playerid);

            return true;
        }
        else
        {
            SQL::DeleteRowEx(""BANS_TABLE"", "ban_username", GetName(playerid));
            Server(playerid, "Your account's ban has expired.");
		}
    }

    else if(SQL::RowExistsEx(""BANS_TABLE"", "ban_ip", GetIP(playerid)))
    {
    	new handle = SQL::OpenEx(SQL::READ, ""BANS_TABLE"", "ban_ip", GetIP(playerid));
        SQL::ReadString(handle, "ban_username", string[1], 24);
        SQL::ReadString(handle, "ban_ip", string[2], 24);
        SQL::ReadString(handle, "ban_by", string[3], 24);
        SQL::ReadString(handle, "ban_on", string[4], 24);
        SQL::ReadString(handle, "ban_reason", string[5], 24);
        SQL::ReadInt(handle, "ban_expire", expire);
        SQL::Close(handle);

        if(expire > gettime() || expire == 0)
        {
			
			strcat(DIALOG, ""white"Your IP is banned from this server,\n\n");

		    format(string2, sizeof(string2), ""white"Username: "red"%s\n", string[1]);
			strcat(DIALOG, string2);

		    format(string2, sizeof(string2), ""white"IP: "red"%s\n", string[2]);
			strcat(DIALOG, string2);

		    format(string2, sizeof(string2), ""white"Banned by: "red"%s\n", string[3]);
			strcat(DIALOG, string2);

		    format(string2, sizeof(string2), ""white"Reason: "red"%s\n", string[5]);
			strcat(DIALOG, string2);

		    format(string2, sizeof(string2), ""white"Ban date: "red"%s\n", string[4]);
			strcat(DIALOG, string2);

		    new expire2[68];
			if(expire == 0) expire2 = "PERMANENT";
			else expire2 = ConvertTime(expire);
		    format(string2, sizeof(string2), ""white"Timeleft: "red"%s\n\n", expire2);
			strcat(DIALOG, string2);

			strcat(DIALOG, ""white"If you think that you got banned wrongfully, please make an appeal on our forums.\n");
			strcat(DIALOG, "Make sure you saved this box by pressing F8.");

			Dialog_Show(playerid, dialogUnused, DIALOG_STYLE_MSGBOX, "Notice", DIALOG, "Close", "");
            DelayKick(playerid);
            
            return true;
        }
        else
        {
            SQL::DeleteRowEx(""BANS_TABLE"", "ban_username", GetName(playerid));
            Server(playerid, "Your IP's ban has expired.");
		}
    }
    
	// Setting up the variables
    // Saved Data
	User[playerid][score] = 1;
	User[playerid][cash] = 1000;
	
	User[playerid][kills] = 0;
	User[playerid][deaths] = 0;
	User[playerid][level] = 0;
	
	User[playerid][tokens] = 0;
	User[playerid][exp] = 0;
	User[playerid][member] = 0;
	User[playerid][civilian] = 0;
	
	User[playerid][wanteds] = 0;
	User[playerid][ohours] = 0;
	User[playerid][ominutes] = 0;
	User[playerid][oseconds] = 0;
	User[playerid][mutedsec] = 0;
	User[playerid][cmdmutedsec] = 0;
	User[playerid][jailedsec] = 0;
	User[playerid][warns] = 0;
	
	// Not saved data
	User[playerid][loggedin] = 0;
	User[playerid][attempts] = 0;
	User[playerid][jailed] = 0;
	
	// Spectate System
	User[playerid][specdata][0] = 0;
	User[playerid][specdata][1] = 0;
	User[playerid][specpos][0] = 0.0;
	User[playerid][specpos][1] = 0.0;
	User[playerid][specpos][2] = 0.0;
	User[playerid][specpos][3] = 0.0;
	User[playerid][specid] = INVALID_PLAYER_ID;
	User[playerid][spec] = false;
	User[playerid][pos][0] = 0.0;
	User[playerid][pos][1] = 0.0;
	User[playerid][pos][2] = 0.0;
	User[playerid][int] = 0;
	User[playerid][vw] = 0;

	#if defined SPECTATE_TEXTDRAW
		User[playerid][specTD] = CreatePlayerTextDraw(playerid,17.000000, 170.000000, "~r~Spectate information");
		PlayerTextDrawBackgroundColor(playerid, User[playerid][specTD], 255);
		PlayerTextDrawFont(playerid, User[playerid][specTD], 1);
		PlayerTextDrawLetterSize(playerid, User[playerid][specTD], 0.130000, 0.699998);
		PlayerTextDrawColor(playerid, User[playerid][specTD], -1);
		PlayerTextDrawSetOutline(playerid, User[playerid][specTD], 1);
		PlayerTextDrawSetProportional(playerid, User[playerid][specTD], 1);
		PlayerTextDrawSetSelectable(playerid, User[playerid][specTD], 0);
	#endif
	
	// PunishmentHandle Timer
	User[playerid][updatetimer] = SetTimerEx("OnPlayerUpdater", 1000, true, "i", playerid);
    
    if(SQL::RowExistsEx(""PLAYERS_TABLE"", "username", GetName(playerid)))
    {
        // Get the player password and ID.
        new handle = SQL::OpenEx(SQL::READ, ""PLAYERS_TABLE"", "username", GetName(playerid));
        SQL::ReadString(handle, "password", User[playerid][password], 114);
        SQL::ReadInt(handle, "id", User[playerid][id]);
        SQL::Close(handle);
        
        //Show the login dialog
        Dialog_Show(playerid, dialogLogin, DIALOG_STYLE_PASSWORD, "Login", ""grey"Welcome back "red"%s"grey",\n\nPlease insert your password bellow.", "Login", "Leave", GetName(playerid));
    }
    else
    {
        // Show the register dialog
        Dialog_Show(playerid, dialogRegister, DIALOG_STYLE_PASSWORD, "Register", ""grey"Welcome "red"%s"grey",\n\nPlease insert your password bellow.", "Register", "Leave", GetName(playerid));
    }
    return 1;
}

//=================================================

Dialog:dialogRegister(playerid, response, listitem, inputtext[])
{
	if(!response)
	{
	    #if defined REQUIRE_REGISTER
	    	Server(playerid, "This server require players to register");
	    	DelayKick(playerid);
		#else
			new guestname[94];
			format(guestname, sizeof(guestname), "[Guest]%s", GetName(playerid));
   			SetPlayerName(playerid, guestname);

   			User[playerid][loggedin] = 0;

		    Server(playerid, "You have joined the server as guest.");
	    #endif
	}
	if(response)
	{
		if(strlen(inputtext) < 5)
		{
			Dialog_Show(playerid, dialogRegister, DIALOG_STYLE_PASSWORD, "Register", ""grey"Welcome "red"%s"grey",\n\nPlease insert your password bellow.\n\n"red"Invalid password (5+ letter).", "Register", "Leave", GetName(playerid));
			return 1;
		}

		SHA256_PassHash(inputtext, "", User[playerid][password], 114);
		new handle = SQL::Open(SQL::INSERT, ""PLAYERS_TABLE"");
		SQL::ToggleAutoIncrement(handle, true);
		SQL::WriteString(handle, "username", GetName(playerid));
		SQL::WriteString(handle, "password", User[playerid][password]);
		SQL::WriteString(handle, "ip", GetIP(playerid));
		SQL::WriteInt(handle, "cash", 1000);
		SQL::WriteInt(handle, "score", 1);
		
		SQL::WriteInt(handle, "tokens", 0);
		SQL::WriteInt(handle, "exp", 10);
		SQL::WriteInt(handle, "civilian", 0);
		SQL::WriteInt(handle, "member", 0);

		SQL::WriteInt(handle, "level", 0);
	    SQL::WriteInt(handle, "kills", 0);
	    SQL::WriteInt(handle, "deaths", 0);
	    SQL::WriteInt(handle, "wanteds", 0);
	    SQL::WriteInt(handle, "mutedsec", 0);
	    SQL::WriteInt(handle, "cmdmutedsec", 0);
	    SQL::WriteInt(handle, "jailedsec", 0);
	    SQL::WriteInt(handle, "warns", 0);
	    SQL::WriteInt(handle, "hours", 0);
	    SQL::WriteInt(handle, "minutes", 0);
	    SQL::WriteInt(handle, "seconds", 0);

	    new DATE[18], date[3];
		getdate(date[0], date[1], date[2]);
		format(DATE, sizeof(DATE), "%i/%i/%i", date[2], date[1], date[0]);

	    SQL::WriteString(handle, "laston", DATE);
	    SQL::WriteString(handle, "joined", DATE);
		User[playerid][id] = SQL::Close(handle);

		Server(playerid, "You have successfully registered on our server.");

		User[playerid][loggedin] = 1;
	}
	return 1;
}

//=================================================

Dialog:dialogLogin(playerid, response, listitem, inputtext[])
{
	if(!response)
	{
	    #if defined REQUIRE_LOGIN
	    	Server(playerid, "This server require players to login");
	    	DelayKick(playerid);
		#else
			new guestname[94];
			format(guestname, sizeof(guestname), "[Guest]%s", GetName(playerid));
   			SetPlayerName(playerid, guestname);
   			
   			User[playerid][loggedin] = 0;
   			
		    Server(playerid, "You have joined the server as guest.");
	    #endif
	}
	if(response)
	{
		new hash[114];
		SHA256_PassHash(inputtext, "", hash, 114);
		if(!strcmp(hash, User[playerid][password]))
		{
			//Load player data
			new handle = SQL::Open(SQL::READ, ""PLAYERS_TABLE"", "id", User[playerid][id]);
			SQL::ReadInt(handle, "score", User[playerid][score]);
			SQL::ReadInt(handle, "cash", User[playerid][cash]);
			SQL::ReadInt(handle, "kills", User[playerid][kills]);
			SQL::ReadInt(handle, "deaths", User[playerid][deaths]);
			SQL::ReadInt(handle, "level", User[playerid][level]);

			SQL::ReadInt(handle, "tokens", User[playerid][tokens]);
            SQL::ReadInt(handle, "exp", User[playerid][exp]);
            SQL::ReadInt(handle, "member", User[playerid][member]);
            SQL::ReadInt(handle, "civilian", User[playerid][civilian]);

			SQL::ReadInt(handle, "wanteds", User[playerid][wanteds]);
			SQL::ReadInt(handle, "mutedsec", User[playerid][mutedsec]);
			SQL::ReadInt(handle, "cmdmutedsec", User[playerid][cmdmutedsec]);
			SQL::ReadInt(handle, "jailedsec", User[playerid][jailedsec]);
			SQL::ReadInt(handle, "warns", User[playerid][warns]);

			SQL::ReadInt(handle, "hours", User[playerid][ohours]);
			SQL::ReadInt(handle, "minutes", User[playerid][ominutes]);
			SQL::ReadInt(handle, "seconds", User[playerid][oseconds]);
			SQL::Close(handle);

			SetPlayerScore(playerid, User[playerid][score]);
			GivePlayerMoney(playerid, User[playerid][cash]);

			if(User[playerid][jailedsec] >= 1)
			{
				User[playerid][jailed] = 1;
			}


			User[playerid][loggedin] = 1;
			User[playerid][attempts] = 0;

			Server(playerid, "You have successfully logged in your account");
		}
		else
		{
			Dialog_Show(playerid, dialogLogin, DIALOG_STYLE_PASSWORD, "Login", ""grey"Welcome back "red"%s"grey",\n\nPlease insert your password bellow.\n\n"red"Wrong password please try again.", "Login", "Leave", GetName(playerid));
			#if defined REQUIRE_LOGIN
				#if LOGIN_ATTEMPTS > 0
				    new string[114];
					User[playerid][attempts]++;
		   			if(User[playerid][attempts] >= LOGIN_ATTEMPTS)
		      		{
		        		format(string, sizeof(string), "* %s(%d) has been automatically kicked [Reason: Too many failed login attempts]", GetName(playerid), playerid);
		          		SendClientMessageToAll(COLOR_RED, string);
						DelayKick(playerid);
						return 1;
		    		}
					format(string, sizeof(string), "[WARNING]: "white"You have %i/"#LOGIN_ATTEMPTS" attempts left to login.", User[playerid][attempts]);
					SendClientMessage(playerid, COLOR_SERVER, string);
				#endif
			#endif
		}
	}
	return 1;
}

//=================================================

public OnPlayerDisconnect(playerid, reason)
{
    if(User[playerid][loggedin] == 1)
    {
        // Getting connected time
        GetPlayerConnectedTime(playerid, User[playerid][ohours], User[playerid][ominutes], User[playerid][oseconds]);

        new handle = SQL::Open(SQL::UPDATE, ""PLAYERS_TABLE"", "id", User[playerid][id]);
        SQL::WriteInt(handle, "score", GetPlayerScore(playerid));
        SQL::WriteInt(handle, "cash", GetPlayerMoney(playerid));
        SQL::WriteInt(handle, "level", User[playerid][level]);

		SQL::WriteInt(handle, "tokens", User[playerid][tokens]);
        SQL::WriteInt(handle, "exp", User[playerid][exp]);
        SQL::WriteInt(handle, "member", User[playerid][member]);
        SQL::WriteInt(handle, "civilian", User[playerid][civilian]);

		SQL::WriteInt(handle, "kills", User[playerid][kills]);
        SQL::WriteInt(handle, "deaths", User[playerid][deaths]);
        SQL::WriteInt(handle, "wanteds", User[playerid][wanteds]);
		SQL::WriteInt(handle, "hours", User[playerid][ohours]);
		SQL::WriteInt(handle, "minutes", User[playerid][ominutes]);
		SQL::WriteInt(handle, "seconds", User[playerid][oseconds]);
		SQL::WriteInt(handle, "mutedsec", User[playerid][mutedsec]);
		SQL::WriteInt(handle, "cmdmutedsec", User[playerid][cmdmutedsec]);
		SQL::WriteInt(handle, "jailedsec", User[playerid][jailedsec]);
		SQL::WriteInt(handle, "warns", User[playerid][warns]);

		new DATE[18], date[3];
		getdate(date[0], date[1], date[2]);
		format(DATE, sizeof(DATE), "%i/%i/%i", date[2], date[1], date[0]);
    	SQL::WriteString(handle, "laston", DATE);
    	print("User Saved\n");
		SQL::Close(handle);
    }
    
    // Kill Updater
    KillTimer(User[playerid][updatetimer]);
    
    // Spectate System
   	#if defined SPECTATE_TEXTDRAW
		PlayerTextDrawHide(playerid, User[playerid][specTD]);
	#endif
	
	LOOP_PLAYERS(i)
	{
		if(IsPlayerSpectating(i))
		{
		    if(User[i][spec] && User[i][specid] == playerid)
		    {
		        UpdatePlayerSpectating(playerid, 0, true);
			}
		}
	}
    return 1;
}

//=================================================

public OnPlayerRequestSpawn(playerid)
{
	#if defined REQUIRE_REGISTER && defined REQUIRE_LOGIN
	    if(User[playerid][loggedin] == 0)
		{
		    GameTextForPlayer(playerid, "~r~You must be logged in to spawn", 5000, 3);
		    return 0;
		}
	#endif
	return 1;
}

//=================================================

public OnPlayerText(playerid, text[])
{
	// Mute System
	if(IsPlayerMuted(playerid))
	{
		new string[144];
		format(string, sizeof(string), "You are muted, %i seconds left.", User[playerid][mutedsec]);
		SendClientMessage(playerid, COLOR_RED, string);
		return 0;
	}
	
	// Admin Chat system
	if(GetLevel(playerid) >= 1)
	{
		if(text[0] == '!')
		{
			new string[144];
			format(string, sizeof(string), "[Admin-Chat] %s(%i): "white"%s", GetName(playerid), playerid, text[1]);
			SendClientMessageToAdmins(COLOR_LIGHTBLUE, string);
		    return 0;
		}
	}

	// Anti Advert system
 	#if defined USE_ANTIADVERT
		if(IsAdvertisement(text))
		{
			if(GetLevel(playerid) >= 1)
			{
				new string[144];
				format(string, sizeof(string), "[ALERT] "white"%s(%i) "red"has tried to advertise the IP: "white"%s", GetName(playerid), playerid, text);
				SendClientMessageToAdmins(COLOR_RED, string);
			}
			SendClientMessage(playerid, COLOR_RED, "Advertising is not allowed, message blocked.");

			#if defined SAVE_LOGS
				new logstring[244];
				format(logstring, sizeof(logstring), "%s tried to advertise IP %s", GetName(playerid), text);
			    SaveLog("adverts.txt", logstring);
	    	#endif
			return 0;
		}
	#endif
	return 1;
}

//=================================================

public OnPlayerSpawn(playerid)
{
	new string[144];
	if(IsPlayerMuted(playerid))
 	{
		format(string, sizeof(string), "You are still muted, %i seconds left.", User[playerid][mutedsec]);
		SendClientMessage(playerid, COLOR_RED, string);
 	}
	if(IsPlayerCMDMuted(playerid))
 	{
		format(string, sizeof(string), "You are still command muted, %i seconds left.", User[playerid][cmdmutedsec]);
		SendClientMessage(playerid, COLOR_RED, string);
 	}
 	if(IsPlayerJailed(playerid))
 	{
 		format(string, sizeof(string), "You are still jailed, %i seconds left.", User[playerid][jailedsec]);
		SendClientMessage(playerid, COLOR_RED, string);
		
		JailPlayer(playerid);
	}
	
	// Hide spectate textdraw (If it is enabled
	#if defined SPECTATE_TEXTDRAW
		PlayerTextDrawHide(playerid, User[playerid][specTD]);
	#endif
	
	// Check if player is being spectaing
	LOOP_PLAYERS(i)
	{
		if(IsPlayerSpectating(i))
		{
		    if(User[i][specid] == playerid)
		    {
		        SetPlayerSpectating(i, playerid);
			}
		}
	}
	return 1;
}

//=================================================

public OnPlayerDeath(playerid, killerid, reason)
{
	// Spectate system
	#if defined SPECTATE_TEXTDRAW
		PlayerTextDrawHide(playerid, User[playerid][specTD]);
	#endif

    new Float:currentpos[3];
	GetPlayerPos(playerid, currentpos[0], currentpos[1], currentpos[2]);

	LOOP_PLAYERS(i)
	{
		if(IsPlayerSpectating(i))
		{
		    if(User[i][specid] == playerid)
		    {
				SetPlayerCameraPos(i, currentpos[0], currentpos[1], (currentpos[2] + 5.0));
				SetPlayerCameraLookAt(i, currentpos[0], currentpos[1], currentpos[2]);
			}
		}
	}

	User[playerid][deaths] ++;       // Add 1 death to victim
	User[playerid][wanteds] = 0;     // Reset player's wanteds
	
	if(killerid != INVALID_PLAYER_ID)
	{
		User[killerid][kills] ++;    // Add 1 kill to killer
		User[playerid][wanteds] ++;  // Add 1 wanted to killer
	}
	return 1;
}

//=================================================

public OnPlayerCommandReceived(playerid, cmdtext[])
{
    new string[144];
	// Read Commands
	#if defined READ_COMMANDS
	    LOOP_PLAYERS(i)
	    {
     		if(IsPlayerAdminEx(i) &&
				GetLevel(i) > GetLevel(playerid) &&
				i != playerid)
    		{
				format(string, sizeof(string), "* %s(%i) has used %s", GetName(playerid), playerid, cmdtext);
    			SendClientMessage(i, COLOR_GREY, string);
    			
    			#if defined SAVE_LOGS
    				SaveLog("commands.txt", string);
				#endif
			}
	    }
	#endif
	
	// CMD Mute System
	if(IsPlayerCMDMuted(playerid))
	{
		format(string, sizeof(string), "You are command muted, %i seconds left.", User[playerid][cmdmutedsec]);
		SendClientMessage(playerid, COLOR_RED, string);
		return 0;
	}
	
	// Prevent Jailed players to use commands
	if(IsPlayerJailed(playerid))
	{
		format(string, sizeof(string), "You can't use commands while your jailed, %i seconds left.", User[playerid][jailedsec]);
		SendClientMessage(playerid, COLOR_RED, string);
		return 0;
	}
	return 1;
}

//=================================================

public OnPlayerStateChange(playerid, newstate, oldstate)
{
	LOOP_PLAYERS(i)
	{
		if(IsPlayerSpectating(i))
		{
		    if(User[i][spec] && User[i][specid] == playerid)
		    {
		        UpdatePlayerSpectating(i, 0, false);
			}
		}
	}
	return 1;
}

//=================================================

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	if(User[playerid][spec] && IsPlayerAdminEx(playerid))
 	{
		if(newkeys == KEY_LOOK_BEHIND && IsPlayerSpectating(playerid))
	    {
	   		cmd_specoff(playerid, "");
	    }
	    if(newkeys == KEY_FIRE && IsPlayerSpectating(playerid))
	    {
	        UpdatePlayerSpectating(playerid, 0, false);
	    }
	    if(newkeys == KEY_ACTION && IsPlayerSpectating(playerid))
	    {
			UpdatePlayerSpectating(playerid, 1, false);
	    }
	}
    return 1;
}

//=================================================

// Player Commands
CMD:cmds(playerid, params[])
{
	new DIALOG[1246+200];

    strcat(DIALOG, ""orange"Player Commands\n\n");
	if(GetLevel(playerid) > 0)
	{
	    strcat(DIALOG, ""white"/acmds - "green"See all admin commands\n");
	}
	if(IsPlayerMember(playerid))
	{
	    strcat(DIALOG, ""white"/mcmds - "green"See all member commands\n");
	}
	strcat(DIALOG, ""white"/admins - "green"See online admins (50+ score)\n");
	strcat(DIALOG, ""white"/members - "green"See online members\n");
	strcat(DIALOG, ""white"/report - "green"Report a player to online admins\n");
	strcat(DIALOG, ""white"/stats - "green"Check your and others statistics\n");
	strcat(DIALOG, ""white"/ostats - "green"Check offline player's stats\n");
	strcat(DIALOG, ""white"/changepass - "green"Change your password\n");
	strcat(DIALOG, ""white"/changename - "green"Change your name\n");
	strcat(DIALOG, ""white"/register - "green"Register your account\n");
	strcat(DIALOG, ""white"/login - "green"To your account\n");

	Dialog_Show(playerid, dialogUnused, DIALOG_STYLE_MSGBOX, "Player Commands", DIALOG, "Close", "");
	return 1;
}

CMD:register(playerid, params[])
{
    if(SQL::RowExistsEx(""PLAYERS_TABLE"", "username", GetName(playerid))) return Error(playerid, "Your username is already registered, use /login.");
	if(User[playerid][loggedin] == 1) return Error(playerid, "You are already registered and logged in.");

	Dialog_Show(playerid, dialogRegister, DIALOG_STYLE_PASSWORD, "Register", ""grey"Welcome "red"%s"grey",\n\nPlease insert your password bellow.", "Register", "Leave", GetName(playerid));
	return 1;
}

CMD:login(playerid, params[])
{
    if(!SQL::RowExistsEx(""PLAYERS_TABLE"", "username", GetName(playerid))) return Error(playerid, "Your username is not registered, use /register.");
	if(User[playerid][loggedin] == 1) return Error(playerid, "You are already registered and logged in.");

	Dialog_Show(playerid, dialogLogin, DIALOG_STYLE_PASSWORD, "Login", ""grey"Welcome back "red"%s"grey",\n\nPlease insert your password bellow.", "Login", "Leave", GetName(playerid));
	return 1;
}

CMD:changename(playerid, params[])
{
    Dialog_Show(playerid, dialogName, DIALOG_STYLE_INPUT, "Change Name", ""white"Hello, please insert your password before continuing.", "Next", "Close");
	return 1;
}
Dialog:dialogName(playerid, response, listitem, inputtext[])
{
	if(response)
	{
		new hash[114];
		SHA256_PassHash(inputtext, "", hash, sizeof(hash));
		if(!strcmp(hash, User[playerid][password]))
		{
	        Dialog_Show(playerid, dialogName2, DIALOG_STYLE_INPUT, "Change Name", ""white"Access granted, please insert your new name bellow.", "Change", "Close");
		}
		else
		{
	        Dialog_Show(playerid, dialogName, DIALOG_STYLE_INPUT, "Change Name", ""white"Hello, please insert your password before continuing. \n\n"red"Wrong Password", "Next", "Close");
		}
	}
	return 1;
}
Dialog:dialogName2(playerid, response, listitem, inputtext[])
{
	if(response)
	{
		if(strlen(inputtext) > 24)
		{
			Dialog_Show(playerid, dialogName2, DIALOG_STYLE_INPUT, "Change Name", ""white"Access granted, please insert your new name bellow. \n\n"red"Invalid name length", "Change", "Close");
			return 1;
		}
		
		new handle = SQL::Open(SQL::UPDATE, ""PLAYERS_TABLE"", "id", User[playerid][id]);
		SQL::WriteString(handle, "username", inputtext);
		SQL::Close(handle);
		
		SetPlayerName(playerid, inputtext);

		Server(playerid, "You have successfully changed your name.");
	}
	return 1;
}

CMD:changepass(playerid, params[])
{
    Dialog_Show(playerid, dialogPassword, DIALOG_STYLE_INPUT, "Change Password", ""white"Hello, please insert your old password before continuing.", "Next", "Close");
	return 1;
}
Dialog:dialogPassword(playerid, response, listitem, inputtext[])
{
	if(response)
	{
		new hash[114];
		SHA256_PassHash(inputtext, "", hash, sizeof(hash));
		if(!strcmp(hash, User[playerid][password]))
		{
	        Dialog_Show(playerid, dialogPassword2, DIALOG_STYLE_INPUT, "Change Password", ""white"Access granted, please enter your new password.", "Change", "Close");
		}
		else
		{
	        Dialog_Show(playerid, dialogPassword, DIALOG_STYLE_INPUT, "Change Password", ""white"Hello, please insert your old password before continuing.\n\n"red"Wrong Password", "Next", "Close");
		}
	}
	return 1;
}
Dialog:dialogPassword2(playerid, response, listitem, inputtext[])
{
	if(response)
	{
		if(strlen(inputtext) < 5)
		{
			Dialog_Show(playerid, dialogPassword2, DIALOG_STYLE_INPUT, "Change Password", ""white"Access granted, please enter your new password.\n\n"red"Invalid Password (5+ letters)", "Change", "Close");
			return 1;
		}

		SHA256_PassHash(inputtext, "", User[playerid][password], 114);
		new handle = SQL::Open(SQL::UPDATE, ""PLAYERS_TABLE"", "id", User[playerid][id]);
		SQL::WriteString(handle, "password", User[playerid][password]);
		SQL::Close(handle);
		
		Server(playerid, "You have successfully changed your password.");
	}
	return 1;
}

CMD:ostats(playerid, params[])
{
	new name[MAX_PLAYER_NAME];
	if(sscanf(params, "s[24]", name)) return Usage(playerid, "ostats [username]");
	if(!strcmp(name, GetName(playerid))) return Error(playerid, "You can't use this command on yourself.");
	LOOP_PLAYERS(i)
	{
	    if(!strcmp(name, GetName(i), false))
	    {
	        return Error(playerid, "The specified username is online. Try /stats instead.");
	    }
	}
	if(!SQL::RowExistsEx(""PLAYERS_TABLE"", "username", name)) return Error(playerid, "Player doesn't exist in database.");


	new
	    DataStr[3][48],
	    DataInt[16],
	    DIALOG[700],
	    string[144],
	    yes[4] = "Yes",
	    no[3] = "No",
	    Float:ratio
	;

	new handle = SQL::OpenEx(SQL::READ, ""PLAYERS_TABLE"", "username", name);
	SQL::ReadString(handle, "laston", DataStr[1], 48);
	SQL::ReadString(handle, "joined", DataStr[2], 48);
	
	SQL::ReadInt(handle, "id", DataInt[1]);
	SQL::ReadInt(handle, "kills", DataInt[2]);
	SQL::ReadInt(handle, "deaths", DataInt[3]);
	SQL::ReadInt(handle, "score", DataInt[4]);
	SQL::ReadInt(handle, "cash", DataInt[5]);
	SQL::ReadInt(handle, "wanteds", DataInt[6]);
	SQL::ReadInt(handle, "level", DataInt[7]);
	
	SQL::ReadInt(handle, "tokens", DataInt[8]);
	SQL::ReadInt(handle, "exp", DataInt[9]);
	SQL::ReadInt(handle, "member", DataInt[10]);
	SQL::ReadInt(handle, "civilian", DataInt[11]);
	
	
	SQL::ReadInt(handle, "ohours", DataInt[12]);
	SQL::ReadInt(handle, "ominutes", DataInt[13]);
	SQL::ReadInt(handle, "oseconds", DataInt[14]);
	SQL::Close(handle);
	
	format(string, sizeof(string), ""white"You are now viewing "green"%s's"white" stats\n\n", name);
	strcat(DIALOG, string);
	
	format(string, sizeof(string), ""white"Account ID: "green"%i\n", DataInt[1]);
	strcat(DIALOG, string);
	
	format(string, sizeof(string), ""white"Kills: "green"%i\n", DataInt[2]);
	strcat(DIALOG, string);

	format(string, sizeof(string), ""white"Deaths: "green"%i\n", DataInt[3]);
	strcat(DIALOG, string);
	
	if(DataInt[3] <= 0) ratio = 0.0;
	else ratio = floatdiv(DataInt[2], DataInt[3]);
	format(string, sizeof(string), ""white"K/D Ratio: "green"%0.2f\n", ratio);
	strcat(DIALOG, string);
	
	format(string, sizeof(string), ""white"Score: "green"%i\n", DataInt[4]);
	strcat(DIALOG, string);

	format(string, sizeof(string), ""white"Money: "green"$%i\n", DataInt[5]);
	strcat(DIALOG, string);

	format(string, sizeof(string), ""white"Wanteds: "green"%i\n", DataInt[6]);
	strcat(DIALOG, string);

	format(string, sizeof(string), ""white"Admin Level: "green"%i\n", DataInt[7]);
	strcat(DIALOG, string);

	format(string, sizeof(string), ""white"Tokens: "green"%i\n", DataInt[8]);
	strcat(DIALOG, string);

	format(string, sizeof(string), ""white"Experience Level: "green"%s\n", DataInt[9]);
	strcat(DIALOG, string);

	format(string, sizeof(string), ""white"Member: "green"%s\n", ((DataInt[10] == 1) ? yes : no));
	strcat(DIALOG, string);

	format(string, sizeof(string), ""white"Civilian Level: "green"%s\n", DataInt[11]);
	strcat(DIALOG, string);

	format(string, sizeof(string), ""white"Online Time: "green"%02i hours %02i minutes %02i seconds\n", DataInt[10], DataInt[11], DataInt[12]);
	strcat(DIALOG, string);
	
	format(string, sizeof(string), ""white"Registered date: "green"%s\n", DataStr[1]);
	strcat(DIALOG, string);
	
	format(string, sizeof(string), ""white"Last Online: "green"%s\n", DataStr[2]);
	strcat(DIALOG, string);
	
	Dialog_Show(playerid, dialogUnused, DIALOG_STYLE_MSGBOX, "Stats", DIALOG, "Close", "");
	return 1;
}

CMD:stats(playerid, params[])
{
	new target;
	if(sscanf(params, "u", target))
	{
  		target = playerid;
		Server(playerid, "You can also use /stats [playerid]");
	}
	if(!IsPlayerConnected(target)) return Error(playerid, "Player is not connected.");
	if(User[target][loggedin] == 0) return Error(playerid, "Player is not logged in.");
    GetPlayerConnectedTime(target, User[target][ohours], User[target][ominutes], User[target][oseconds]);

	new
		DIALOG[676],
		string[156],
		data[2][48],
		yes[4] = "Yes",
		no[3] = "No",
		Float:ratio
	;
	
	new handle = SQL::OpenEx(SQL::READ, ""PLAYERS_TABLE"", "username", GetName(target));
 	SQL::ReadString(handle, "joined", data[1], 48);
 	SQL::Close(handle);
	
	format(string, sizeof(string), ""white"You are now viewing "green"%s(%i)'s"white" stats\n\n", GetName(target), target);
	strcat(DIALOG, string);
	
	format(string, sizeof(string), ""white"Account ID: "green"%i\n", User[target][id]);
	strcat(DIALOG, string);
	
	format(string, sizeof(string), ""white"Kills: "green"%i\n", User[target][kills]);
	strcat(DIALOG, string);
	
	format(string, sizeof(string), ""white"Deaths: "green"%i\n", User[target][deaths]);
	strcat(DIALOG, string);
	
	if(User[target][deaths] <= 0) ratio = 0.0;
	else ratio = floatdiv(User[target][kills], User[target][deaths]);
	format(string, sizeof(string), ""white"K/D Ratio: "green"%0.2f\n", ratio);
	strcat(DIALOG, string);
	
	format(string, sizeof(string), ""white"Score: "green"%i\n", GetPlayerScore(target));
	strcat(DIALOG, string);
	
	format(string, sizeof(string), ""white"Money: "green"$%i\n", GetPlayerMoney(target));
	strcat(DIALOG, string);
	
	format(string, sizeof(string), ""white"Wanteds: "green"%i\n", User[target][wanteds]);
	strcat(DIALOG, string);
	
	format(string, sizeof(string), ""white"Admin Level: "green"%i\n", User[target][level]);
	strcat(DIALOG, string);

	format(string, sizeof(string), ""white"Tokens: "green"%i\n", User[target][tokens]);
	strcat(DIALOG, string);
	
	format(string, sizeof(string), ""white"Experience Level: "green"%i\n", User[target][exp]);
	strcat(DIALOG, string);

	format(string, sizeof(string), ""white"Member: "green"%s\n", ((IsPlayerMember(target)) ? yes : no));
	strcat(DIALOG, string);

	format(string, sizeof(string), ""white"Civilian Level: "green"%s\n", User[target][civilian]);
	strcat(DIALOG, string);
	
	format(string, sizeof(string), ""white"Online Time: "green"%02i hours %02i minutes %02i seconds\n", User[target][ohours], User[target][ominutes], User[target][oseconds]);
	strcat(DIALOG, string);
	
	format(string, sizeof(string), ""white"Registered date: "green"%s\n", data[1]);
	strcat(DIALOG, string);
	
	format(string, sizeof(string), ""white"Jailed: "green"%s\n", ((IsPlayerJailed(target)) ? yes : no));
	strcat(DIALOG, string);
	
	format(string, sizeof(string), ""white"Muted: "green"%s\n", ((IsPlayerMuted(target)) ? yes : no));
	strcat(DIALOG, string);
	
	format(string, sizeof(string), ""white"Command Muted: "green"%s\n", ((IsPlayerCMDMuted(target)) ? yes : no));
	strcat(DIALOG, string);
	
	format(string, sizeof(string), ""white"Warnings: "green"%i/%i\n", User[target][warns], MAX_WARNS);
	strcat(DIALOG, string);

	Dialog_Show(playerid, dialogUnused, DIALOG_STYLE_MSGBOX, "Stats", DIALOG, "Close", "");
	return 1;
}

CMD:savestats(playerid, params[])
{
    if(User[playerid][loggedin] == 1)
    {
        // Getting connected time
        GetPlayerConnectedTime(playerid, User[playerid][ohours], User[playerid][ominutes], User[playerid][oseconds]);

        new handle = SQL::Open(SQL::UPDATE, ""PLAYERS_TABLE"", "id", User[playerid][id]);
        SQL::WriteInt(handle, "score", GetPlayerScore(playerid));
        SQL::WriteInt(handle, "cash", GetPlayerMoney(playerid));
        SQL::WriteInt(handle, "level", User[playerid][level]);

		SQL::WriteInt(handle, "tokens", User[playerid][tokens]);
        SQL::WriteInt(handle, "exp", User[playerid][exp]);
        SQL::WriteInt(handle, "member", User[playerid][member]);
        SQL::WriteInt(handle, "civilian", User[playerid][civilian]);

		SQL::WriteInt(handle, "kills", User[playerid][kills]);
        SQL::WriteInt(handle, "deaths", User[playerid][deaths]);
        SQL::WriteInt(handle, "wanteds", User[playerid][wanteds]);
		SQL::WriteInt(handle, "hours", User[playerid][ohours]);
		SQL::WriteInt(handle, "minutes", User[playerid][ominutes]);
		SQL::WriteInt(handle, "seconds", User[playerid][oseconds]);
		SQL::WriteInt(handle, "mutedsec", User[playerid][mutedsec]);
		SQL::WriteInt(handle, "cmdmutedsec", User[playerid][cmdmutedsec]);
		SQL::WriteInt(handle, "jailedsec", User[playerid][jailedsec]);
		SQL::WriteInt(handle, "warns", User[playerid][warns]);

		new DATE[18], date[3];
		getdate(date[0], date[1], date[2]);
		format(DATE, sizeof(DATE), "%i/%i/%i", date[2], date[1], date[0]);
    	SQL::WriteString(handle, "laston", DATE);
    	print("User Saved\n");
		SQL::Close(handle);
    }
    Server(playerid, "Stats saved.");
	return 1;
}

CMD:report(playerid, params[])
{
	new target, reason[98];
	if(sscanf(params, "us[98]", target, reason)) return Usage(playerid, "report [playerid] [reason]");
	if(strlen(reason) < 4) return Error(playerid, "The specified reason is very short.");
	if(!IsPlayerConnected(target)) return Error(playerid, "That player is not connected.");
	if(target == playerid) return Error(playerid, "You can't report yourself.");

	new hour, minute, second;
	gettime(hour, minute, second);

	new string[145];
	format(string, sizeof(string), "{FFFFFF}[{db2b42}ADMIN{FFFFFF}]: %s(%i) has reported %s(%i). Reason: %s", GetName(playerid), playerid, GetName(target), target, reason);
	SendClientMessageToAdmins(-1, string);

    #if defined SAVE_LOGS
		new string2[145];
		format(string, sizeof(string2), "[%02d:%02d] %s(%i) has reported %s(%i). Reason: %s ", hour, minute, GetName(playerid), playerid, GetName(target), target, reason);
		SaveLog("reports.txt", string2);
	#endif
	
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	format(string, sizeof(string), "Your report against %s(%i) has been sent to online admins.", GetName(target), target);
	SendClientMessage(playerid, -1, string);
	return 1;
}

CMD:admins(playerid, params[])
{
	if(GetPlayerScore(playerid) < 50) return Error(playerid, "Your experience level needs to be 5 in order to seeonline administrators.");
	new count = 0, string[828], rank[30];
	LOOP_PLAYERS(i)
	{
		if(IsPlayerConnected(i) && IsPlayerAdminEx(i))
		{
			count ++;
			switch(GetLevel(i))
			{
			    case 1: rank = ""LEVEL1"";
			    case 2: rank = ""LEVEL2"";
			    case 3: rank = ""LEVEL3"";
			    case 4: rank = ""LEVEL4"";
			    case 5: rank = ""LEVEL5"";
			    case 6: rank = ""LEVEL6"";
			    case 7: rank = ""LEVEL7"";
			}
			format(string, sizeof(string), "%s"white"%i. %s(%i) - "orange"(%s)\n", string, count, GetName(i), i, rank);
		}
	}
	format(string, sizeof(string), "%s\n\n"white"Total Online Admins: "yellow"%i", string, count);
	if(count > 0)
	{
		Dialog_Show(playerid, dialogUnused, DIALOG_STYLE_MSGBOX, "Online Administrators", string, "OK", "");
	}
	else if(count == 0) return Error(playerid, "There are currently no admins online");
	return 1;
}

CMD:members(playerid, params[])
{
	new count = 0, string[828];
	LOOP_PLAYERS(i)
	{
		if(IsPlayerConnected(i) && IsPlayerMember(i))
		{
			count ++;
			format(string, sizeof(string), "%s"white"%i. %s(%i)\n", string, count, GetName(i), i);
		}
	}
	format(string, sizeof(string), "%s\n\n"white"Total Online members: "yellow"%i", string, count);
	if(count > 0)
	{
		Dialog_Show(playerid, dialogUnused, DIALOG_STYLE_MSGBOX, "Online members", string, "OK", "");
	}
	else if(count == 0) return Error(playerid, "There are currently no members online");
	return 1;
}

// VIP Commands
CMD:mcmds(playerid, params[])
{
	MemberCheck(playerid);
	new DIALOG[1246+200];

	strcat(DIALOG, ""orange"Member Commands\n");
	strcat(DIALOG, ""white"• Member system is under development\n");

	Dialog_Show(playerid, dialogUnused, DIALOG_STYLE_MSGBOX, "Member Commands", DIALOG, "Close", "");
	return 1;
}

// Level 1 Commands
CMD:acmds(playerid, params[])
{
	LevelCheck(playerid, 1);
	
	new DIALOG[1246+546];

	if(GetLevel(playerid) >= 1 || IsPlayerAdmin(playerid))
	{
		strcat(DIALOG, ""orange""LEVEL1" (Level 1)\n");
  		strcat(DIALOG, ""white"/acmds /spec /specoff /weapons /spawn /goto /(ann)ounce /warn /remwarns\n");
  		strcat(DIALOG, ""white"/jailed /muted /cmdmuted /explode /disarm /freeze /unfreeze /slap /muted\n");
  		strcat(DIALOG, ""white"/unmute /respawncars /ip /car /fix /asay /kick\n\n");
	}
	if(GetLevel(playerid) >= 2 || IsPlayerAdmin(playerid))
	{
		strcat(DIALOG, ""orange""LEVEL2" (Level 2)\n");
  		strcat(DIALOG, ""white"/akill /jail /unjail /bring /cmdmute /uncmdmute /cleardwindows /ban /cc\n");
  		strcat(DIALOG, ""white"/aheal /aarmour /setinterior /setworld /jetpack\n\n");
	}
	if(GetLevel(playerid) >= 3 || IsPlayerAdmin(playerid))
	{
		strcat(DIALOG, ""orange""LEVEL3" (Level 3)\n");
		strcat(DIALOG, ""white"/fakedeath /giveweapon /sethealth /setarmour /healall /armourall\n");
		strcat(DIALOG, ""white"/givecash /givescore /unban /teleplayer\n\n");
	}
	if(GetLevel(playerid) >= 4 || IsPlayerAdmin(playerid))
	{
		strcat(DIALOG, ""orange""LEVEL4" (Level 4)\n");
		strcat(DIALOG, ""white"/oban /setcash /setscore /setwanteds /setkills /setdeaths /giveallscore\n");
		strcat(DIALOG, ""white"/giveallcash /giveallweapon /setalltime /setallweath\n\n");
	}
	if(GetLevel(playerid) >= 5 || IsPlayerAdmin(playerid))
	{
		strcat(DIALOG, ""orange""LEVEL5" (Level 5)\n");
		strcat(DIALOG, ""white"/fakecmd /fakechat /removeacc /setlevel /setmember /gmx\n\n");
	}
	strcat(DIALOG, ""orange"Use '!' specifier to speak on Admin's chat. Ex. !Hello\n");

	Dialog_Show(playerid, dialogUnused, DIALOG_STYLE_MSGBOX, "Admin Commands", DIALOG, "Close", "");
	return 1;
}

CMD:spec(playerid, params[])
{
	LevelCheck(playerid, 1);

    new target;
    if(sscanf(params, "u", target)) return Usage(playerid, "spec [playerid]");
	if(!IsPlayerConnected(target)) return Error(playerid, "The specified player is not conected.");
	if(!IsPlayerSpawned(target)) return Error(playerid, "The specified player is not spawned.");
	if(target == playerid) return Error(playerid, "You can't spectate to yourself.");
    if(IsPlayerSpectating(target)) return Error(playerid, "The specified player is spectating a player.");

	GetPlayerPos(playerid, User[playerid][pos][0], User[playerid][pos][1], User[playerid][pos][2]);

	#if defined SPECTATE_TEXTDRAW
		PlayerTextDrawShow(playerid, User[playerid][specTD]);
	#endif

	User[playerid][int] = GetPlayerInterior(playerid);
	User[playerid][vw] = GetPlayerVirtualWorld(playerid);

	SetPlayerSpectating(playerid, target);
	Server(playerid, "You can use LCTRL (KEY_ACTION) and RCTRL (KEY_FIRE) to switch players.");
	Server(playerid, "You can use MMB (KEY_LOOK_BEHIND) or /specoff to stop spectating.");
    return 1;
}

CMD:specoff(playerid, params[])
{
	LevelCheck(playerid, 1);

    if(!IsPlayerSpectating(playerid)) return Error(playerid, "You are not spectating anyone.");

	TogglePlayerSpectating(playerid, false);

	#if defined SPECTATE_TEXTDRAW
		PlayerTextDrawHide(playerid, User[playerid][specTD]);
	#endif

    User[playerid][spec] = false;
    User[playerid][specid] = INVALID_PLAYER_ID;

	SetPlayerPos(playerid, User[playerid][pos][0], User[playerid][pos][1], User[playerid][pos][2]);
    SetPlayerInterior(playerid, User[playerid][int]);
    SetPlayerVirtualWorld(playerid, User[playerid][vw]);
    return 1;
}

CMD:weapons(playerid, params[])
{
	LevelCheck(playerid, 1);

    new target;
	if(sscanf(params, "u", target)) return Usage(playerid, "weapons [playerid]");
	if(!IsPlayerConnected(target)) return Error(playerid, "The specified player is not conected.");

	new weap, ammo, count;
	for(new i = 0; i < 14; i++)
	{
		GetPlayerWeaponData(target, i, weap, ammo);
		if(ammo != 0 && weap != 0)
		{
			count++;
			break;
		}
	}

	if(count < 1) return Error(playerid, "Player has no weapons.");

	new string[144], message[144];
	format(message, sizeof(message), "%s(%i)'s Weapons: ", GetName(target), target);
	SendClientMessage(playerid, -1, message);

	new weaponname[28], x;
	for(new i = 0; i < 12; i++)
	{
		GetPlayerWeaponData(target, i, weap, ammo);
		if(ammo != 0 && weap != 0)
		{
			GetWeaponName(weap, weaponname, sizeof(weaponname));
			if(ammo == 65535 || ammo == 1) format(string, sizeof(string), "%s%s (1)", string, weaponname);
			else format(string, sizeof(string), "%s%s (%d)", string, weaponname, ammo);
   			x++;
			if(x >= 5)
			{
				SendClientMessage(playerid, -1, string);
    			x = 0;
				format(string, sizeof(string), "");
			}
			else format(string, sizeof(string), "%s, ", string);
		}
	}
	if(x <= 4 && x > 0)
	{
		string[strlen(string)-3] = ')';
		SendClientMessage(playerid, -1, string);
	}
	return 1;
}

CMD:spawn(playerid, params[])
{
	LevelCheck(playerid, 1);

    new target;
    if(sscanf(params, "u", target)) return Usage(playerid, "spawn [playerid]");
	if(!IsPlayerConnected(target)) return Error(playerid, "The specified player is not conected.");
	if(GetLevel(playerid) < GetLevel(target)) return Error(playerid, "You can't use this command on this player.");

	SpawnPlayer(target);
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "{FFFFFF}[{3498DB}ADMIN{FFFFFF}]: %s(%i) has spawned you.", GetName(playerid), playerid);
	SendClientMessage(target, -1, string);
	
	format(string, sizeof(string), "* You have respawned %s(%i).", GetName(target), target);
	SendClientMessage(playerid, -1, string);
	return 1;
}

CMD:goto(playerid, params[])
{
	LevelCheck(playerid, 1);

	new target;
	if(sscanf(params, "u", target)) return Usage(playerid, "goto [playerid]");
	if(!IsPlayerConnected(target)) return Error(playerid, "The specified player is not conected.");
	if(target == playerid) return Error(playerid, "You can't teleport to yourself.");

	new Float:currentpos[3];
	GetPlayerPos(target, currentpos[0], currentpos[1], currentpos[2]);
	SetPlayerInterior(playerid, GetPlayerInterior(target));
	SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(target));
	if(GetPlayerState(playerid) == 2)
	{
		SetVehiclePos(GetPlayerVehicleID(playerid), currentpos[0] + 2.5, currentpos[1], currentpos[2]);
		LinkVehicleToInterior(GetPlayerVehicleID(playerid), GetPlayerInterior(target));
		SetVehicleVirtualWorld(GetPlayerVehicleID(playerid), GetPlayerVirtualWorld(target));
	}
	else SetPlayerPos(playerid, currentpos[0] + 2.0, currentpos[1], currentpos[2]);
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "You have teleported to %s(%i)'s position.", GetName(target), target);
	SendClientMessage(playerid, -1, string);
	
	format(string, sizeof(string), "{FFFFFF}[{3498DB}ADMIN{FFFFFF}]: %s(%i) teleported to your location.", GetName(playerid), playerid);
	SendClientMessage(target, -1, string);
	return 1;
}

CMD:announce(playerid, params[]) return cmd_ann(playerid, params);
CMD:ann(playerid, params[])
{
	LevelCheck(playerid, 1);

	new message[144];
	if(sscanf(params, "s[35]", message)) return Usage(playerid, "ann [message]");

	TextDrawSetString(announceTD, message);
	TextDrawHideForAll(announceTD);
	TextDrawShowForAll(announceTD);

	SetTimer("hideAnnouncement", 5000, false);
	return 1;
}

CMD:warn(playerid, params[])
{
	LevelCheck(playerid, 2);

	new target, reason[128], DIALOG[600], string2[144];
    if(sscanf(params, "uS(No Reason)[128]", target, reason)) return Usage(playerid, "warn [playerid] [reason(No Reason)]");
	if(!IsPlayerConnected(target)) return Error(playerid, "The specified player is not conected.");
    if(target == playerid) return Error(playerid, "You can't warn yourself.");
	if(GetLevel(playerid) < GetLevel(target)) return Error(playerid, "You can't use this command on this player.");

    User[target][warns] += 1;

	new string[144];
	format(string, sizeof(string), "* %s(%i) has been warned by Admin %s(%i) "orange"[Reason: %s] [Warnings: %i/%i]", GetName(target), target, GetName(playerid), playerid, reason, User[target][warns], MAX_WARNS);
	SendClientMessageToAll(COLOR_RED, string);

	#if defined SAVE_LOGS
		SaveLog("warns.txt", string);
	#endif

	if(GetPlayerWarns(target) == MAX_WARNS)
	{
		format(string, sizeof(string), "* %s(%i) has been automatically kicked [Reason: Exceeded maximum warnings] [Warnings: %i/%i]", GetName(target), target, User[target][warns], MAX_WARNS);
	    SendClientMessageToAll(COLOR_RED, string);
	    User[target][warns] = 0;

		DelayKick(target);
		return 1;
	}

	format(string2, sizeof(string2), "You have received a warning\n", GetName(target));
	strcat(DIALOG, string2);

	format(string2, sizeof(string2), ""white"Admin: "red"%s\n", GetName(playerid));
	strcat(DIALOG, string2);

	format(string2, sizeof(string2), ""white"Reason: "red"%s\n", reason);
	strcat(DIALOG, string2);

	format(string2, sizeof(string2), ""white"Total Warnings: "red"%i/%i\n\n", GetPlayerWarns(target), MAX_WARNS);
	strcat(DIALOG, string2);

	strcat(DIALOG, ""white"If you think that you got warned wrongfully, please place a report on our forums.\n");

	Dialog_Show(target, dialogUnused, DIALOG_STYLE_MSGBOX, "Notice", DIALOG, "Close", "");
	return 1;
}

CMD:remwarns(playerid, params[])
{
	LevelCheck(playerid, 2);

    new target, reason[45];
    if(sscanf(params, "u", target, reason)) return Usage(playerid, "remwarns [playerid]");
	if(!IsPlayerConnected(target)) return Error(playerid, "The specified player is not conected.");
	if(GetLevel(playerid) < GetLevel(target)) return Error(playerid, "You can't use this command on this player.");

	User[target][warns] = 0;

	new string[144];
	format(string, sizeof(string), "{FFFFFF}[{3498DB}ADMIN{FFFFFF}]: %s(%i) has removed your warnings.", GetName(playerid), playerid);
	SendClientMessage(target, -1, string);

	format(string, sizeof(string), "* You have removed %s(%i)'s warnings.", GetName(target), target);
	SendClientMessage(playerid, -1, string);
	return 1;
}

CMD:jailed(playerid, params[])
{
	LevelCheck(playerid, 1);

	new DIALOG[98+670], string[128];
	new count = 0;

	LOOP_PLAYERS(i)
	{
	    if(IsPlayerJailed(i))
	    {
	        count++;
	    	format(string, sizeof(string), "%i. %s - Unjail in %i secs..", count, GetName(i), User[i][jailedsec]);
	        strcat(DIALOG, string);
			
	    }
	}
	if(count == 0) return Error(playerid, "No jailed players found.");

	else
	{
	    Dialog_Show(playerid, dialogUnused, DIALOG_STYLE_LIST, "Jailed Players", DIALOG, "Close", "");
	}
	return 1;
}

CMD:muted(playerid, params[])
{
	LevelCheck(playerid, 1);

	new DIALOG[98+670], string[128];
	new count = 0;

	LOOP_PLAYERS(i)
	{
	    if(IsPlayerMuted(i))
	    {
	        count++;
	    	format(string, sizeof(string), "%i. %s - Unmute in %i secs..", count, GetName(i), User[i][mutedsec]);
	        strcat(DIALOG, string);

	    }
	}
	if(count == 0) return Error(playerid, "No muted players found.");

	else
	{
	    Dialog_Show(playerid, dialogUnused, DIALOG_STYLE_LIST, "Muted Players", DIALOG, "Close", "");
	}
	return 1;
}

CMD:cmdmuted(playerid, params[])
{
	LevelCheck(playerid, 1);

	new DIALOG[98+670], string[128];
	new count = 0;

	LOOP_PLAYERS(i)
	{
	    if(IsPlayerCMDMuted(i))
	    {
	        count++;
	    	format(string, sizeof(string), "%i. %s - Unmute in %i secs..", count, GetName(i), User[i][cmdmutedsec]);
	        strcat(DIALOG, string);

	    }
	}
	if(count == 0) return Error(playerid, "No command muted players found.");

	else
	{
	    Dialog_Show(playerid, dialogUnused, DIALOG_STYLE_LIST, "Command Muted Players", DIALOG, "Close", "");
	}
	return 1;
}

CMD:explode(playerid, params[])
{
	LevelCheck(playerid, 1);

	new target;
	if(sscanf(params, "u", target)) return Usage(playerid, "explode [playerid]");
	if(!IsPlayerConnected(target)) return Error(playerid, "The specified player is not conected.");
	if(GetLevel(playerid) < GetLevel(target)) return Error(playerid, "You can't use this command on this player.");

	new Float:currentpos[3];
	GetPlayerPos(target, currentpos[0], currentpos[1], currentpos[2]);
	CreateExplosion(currentpos[0], currentpos[1], currentpos[2], 12, 1.00);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "You have exploded %s(%i).", GetName(target), target);
	SendClientMessage(playerid, -1, string);
	return 1;
}

CMD:disarm(playerid, params[])
{
	LevelCheck(playerid, 1);

	new target;
	if(sscanf(params, "u", target)) return Usage(playerid, "disarm [playerid]");
	if(!IsPlayerConnected(target)) return Error(playerid, "The specified player is not conected.");
	if(GetLevel(playerid) < GetLevel(target)) return Error(playerid, "You can't use this command on this player.");

	ResetPlayerWeapons(target);
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "{FFFFFF}[{3498DB}ADMIN{FFFFFF}]: %s(%i) has disarmed you.", GetName(playerid), playerid);
	SendClientMessage(target, -1, string);
	
	format(string, sizeof(string), "You have disarmed %s(%i).", GetName(target), target);
	SendClientMessage(playerid, -1, string);
	return 1;
}

CMD:freeze(playerid, params[])
{
	LevelCheck(playerid, 1);

	new target, reason[35];
	if(sscanf(params, "uS(No Reason)[35]", target, reason)) return Usage(playerid, "freeze [playerid] [reason(Default No Reason)]");
	if(!IsPlayerConnected(target)) return Error(playerid, "The specified player is not conected.");
	if(GetLevel(playerid) < GetLevel(target)) return Error(playerid, "You can't use this command on this player.");

	TogglePlayerControllable(target, false);
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "{FFFFFF}[{3498DB}ADMIN{FFFFFF}]: %s(%i) has freezed you "orange"[Reason: %s].", GetName(playerid), playerid, reason);
	SendClientMessage(target, COLOR_RED, string);
	
	format(string, sizeof(string), "You have freezed %s(%i).", GetName(target), target);
	SendClientMessage(playerid, COLOR_RED, string);
	return 1;
}

CMD:unfreeze(playerid, params[])
{
	LevelCheck(playerid, 1);

	new target;
	if(sscanf(params, "u", target)) return Usage(playerid, "unfreeze [playerid]");
	if(!IsPlayerConnected(target)) return Error(playerid, "The specified player is not conected.");
	if(GetLevel(playerid) < GetLevel(target)) return Error(playerid, "You can't use this command on this player.");

	TogglePlayerControllable(target, true);
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "{FFFFFF}[{3498DB}ADMIN{FFFFFF}]: %s(%i) has unfreezed you.", GetName(playerid), playerid);
	SendClientMessage(target, COLOR_RED, string);
	
	format(string, sizeof(string), "You have unfreezed %s(%i).", GetName(target), target);
	SendClientMessage(playerid, COLOR_RED, string);
	return 1;
}

CMD:slap(playerid, params[])
{
	LevelCheck(playerid, 1);

    new target;
	if(sscanf(params, "u", target)) return Usage(playerid, "slap [playerid]");
	if(!IsPlayerConnected(target)) return Error(playerid, "The specified player is not conected.");
	if(GetLevel(playerid) < GetLevel(target)) return Error(playerid, "You can't use this command on this player.");

	new Float:currentpos[3];
	GetPlayerPos(target, currentpos[0], currentpos[1], currentpos[2]);
	SetPlayerPos(target, currentpos[0], currentpos[1], currentpos[2] + 5.0);

    PlayerPlaySound(playerid, 1190, 0.0, 0.0, 0.0);
    PlayerPlaySound(target, 1190, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "You have slapped %s(%i).", GetName(target), target);
	SendClientMessage(playerid, -1, string);
	return 1;
}

CMD:mute(playerid, params[])
{
	LevelCheck(playerid, 1);

	new target, time, reason[128];
	if(sscanf(params, "uI(60)S(No Reason)[128]", target, time, reason)) return Usage(playerid, "mute [playerid] [seconds(Default 60)] [reason(Default No Reason)]");
	if(!IsPlayerConnected(target)) return Error(playerid, "The specified player is not conected.");
	if(GetLevel(playerid) < GetLevel(target)) return Error(playerid, "You can't use this command on this player.");
	if(time > 5*60 || time < 10) return Error(playerid, "Mute time is invalid (10 - 360 seconds).");
	if(target == playerid) return Error(playerid, "You cannot mute yourself.");
	if(IsPlayerMuted(target)) return Error(playerid, "The specified player is already muted.");

	User[target][mutedsec] = time;
	
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "* %s(%i) has been muted by Admin %s(%i) for %i seconds "orange"[Reason: %s]", GetName(target), target, GetName(playerid), playerid, time, reason);
	SendClientMessageToAll(COLOR_RED, string);
	
	#if defined SAVE_LOGS
		SaveLog("mutes.txt", string);
	#endif
	return 1;
}

CMD:unmute(playerid, params[])
{
	LevelCheck(playerid, 1);

	new target;
	if(sscanf(params, "u", target)) return Usage(playerid, "unmute [playerid]");
	if(!IsPlayerConnected(target)) return Error(playerid, "The specified player is not conected.");
	if(GetLevel(playerid) < GetLevel(target)) return Error(playerid, "You can't use this command on this player.");
	if(!IsPlayerMuted(target)) return Error(playerid, "The specified player is not muted.");

	User[target][mutedsec] = 0;
	
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "* %s(%i) has been unmuted by Admin %s(%i)", GetName(target), target, GetName(playerid), playerid);
	SendClientMessageToAll(COLOR_RED, string);
	return 1;
}

CMD:respawncars(playerid, params[])
{
	LevelCheck(playerid, 1);

	for(new cars; cars < MAX_VEHICLES; cars++)
	{
	    LOOP_PLAYERS(i)
	    {
			PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);
	        if(GetPlayerVehicleID(i) == cars)
	        {
	            if(GetPlayerState(i) == PLAYER_STATE_DRIVER)
	            {
					if(GetLevel(playerid) < GetLevel(i))
            		{
            			SetVehicleToRespawn(cars);
					}
				}
				else SetVehicleToRespawn(cars);
			}
			else SetVehicleToRespawn(cars);
        }
	}

	new string[144];
	format(string, sizeof(string), "{FFFFFF}[{3498DB}ADMIN{FFFFFF}]: %s(%i) has respawned all vehicles.", GetName(playerid), playerid);
	SendClientMessageToAll(COLOR_BLUE, string);
	return 1;
}

CMD:ip(playerid, params[])
{
	LevelCheck(playerid, 1);

	new target;
	if(sscanf(params, "u", target)) return Usage(playerid, "ip [playerid]");
	if(!IsPlayerConnected(target)) return Error(playerid, "That player is not connected");

	if(GetLevel(playerid) < GetLevel(target)) return Error(playerid, "You can't use this command on this player.");

	new string[144];
	format(string, sizeof(string), "%s(%i)'s IP is %s", GetName(target), target, GetIP(target));
	SendClientMessage(playerid, COLOR_ORANGE, string);
	return 1;
}

CMD:v(playerid, params[]) return cmd_car(playerid, params);
CMD:car(playerid, params[])
{
	LevelCheck(playerid, 1);

    new vehicle[32], model, color[2];
	if(sscanf(params, "s[32]I(-1)I(-1)", vehicle, color[0], color[1])) return Usage(playerid, "car [name/id] [color1(optional)] [color2(optional)]");

	if(IsNumericString(vehicle)) model = strval(vehicle);
    else model = GetVehicleModelIDFromName(vehicle);

	if(model < 400 || model > 611) return Error(playerid, "Invalid vehicle ID or vehicle name");

	new Float:currentpos[4];
	GetPlayerPos(playerid, currentpos[0], currentpos[1], currentpos[2]);
    GetPlayerFacingAngle(playerid, currentpos[3]);

	if(IsPlayerInAnyVehicle(playerid)) SetPlayerPos(playerid, currentpos[0] + 3.0, currentpos[1], currentpos[2]);

	if(color[0] == -1) color[0] = random(256);
	if(color[1] == -1) color[1] = random(256);

	if(User[playerid][avehicle] != -1) RemoveAVeh(User[playerid][avehicle]);

	User[playerid][avehicle] = CreateVehicle(model, currentpos[0] + 3.0, currentpos[1], currentpos[2], currentpos[3], color[0], color[1], -1);
    SetVehicleVirtualWorld(User[playerid][avehicle], GetPlayerVirtualWorld(playerid));
    LinkVehicleToInterior(User[playerid][avehicle], GetPlayerInterior(playerid));
    PutPlayerInVehicle(playerid, User[playerid][avehicle], 0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "You have spawned a %s(id: %i), with colors %i, %i", sbVehicles[model - 400], model, color[0], color[1]);
	SendClientMessage(playerid, COLOR_ORANGE, string);
	return 1;
}

CMD:fix(playerid, params[]) return cmd_repair(playerid, params);
CMD:repair(playerid, params[])
{
	LevelCheck(playerid, 1);

	if(IsPlayerInAnyVehicle(playerid))
	{
		RepairVehicle(GetPlayerVehicleID(playerid));
		GameTextForPlayer(playerid, "~b~~h~~h~~h~Vehicle Repaired", 5000, 3);
  		SetVehicleHealth(GetPlayerVehicleID(playerid), 1000.0);
		PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
  		return 1;
	}
	Error(playerid, "You must be in car to use this command");
	return 1;
}

CMD:asay(playerid, params[])
{
	LevelCheck(playerid, 1);

	new message[135];
	if(sscanf(params, "s[135]", message)) return Usage(playerid, "asay [message]");

	new string[144];
	format(string, sizeof(string), "Admin %s(%i) says %s", GetName(playerid), playerid, message);
    SendClientMessageToAll(COLOR_RED, string);
    
	return 1;
}

CMD:kick(playerid, params[])
{
	LevelCheck(playerid, 1);

    new target, reason[45];
	if(sscanf(params, "us[128]", target, reason)) return Usage(playerid, "kick [playerid] [reason]");
	if(!IsPlayerConnected(target)) return Error(playerid, "That player is not connected.");
	if(GetLevel(playerid) < GetLevel(target)) return Error(playerid, "You can't use this command on this player.");
	if(target == playerid) return Error(playerid, "You can't kick yourself");

	new message[144];
	format(message, sizeof(message), "* %s(%i) has been kicked by Admin %s(%i) "orange"[Reason: %s]", GetName(target), target, GetName(playerid), playerid, reason);
	SendClientMessageToAll(COLOR_RED, message);

	#if defined SAVE_LOGS
		SaveLog("kicks.txt", message);
	#endif

	DelayKick(target);
	return 1;
}

// Level 2 Commands
CMD:jetpack(playerid, params[])
{
	LevelCheck(playerid, 2);

	new target;
	if(sscanf(params, "u", target) || !sscanf(params, "u", target) && playerid == target)
	{
	    SetPlayerSpecialAction(playerid, SPECIAL_ACTION_USEJETPACK);
		Server(playerid, "You have successfully spawned a jetpack.");
		Server(playerid, "You can also give jetpack to players with /jetpack [playerid].");
		PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
		return 1;
	}

	if(!IsPlayerConnected(target)) return Error(playerid, "The specified player is not conected.");
	if(GetLevel(playerid) < GetLevel(target)) return Error(playerid, "You can't use this command on this player.");

	SetPlayerSpecialAction(target, SPECIAL_ACTION_USEJETPACK);
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "{FFFFFF}[{3498DB}ADMIN{FFFFFF}]: %s(%i) has given you a jetpack.", GetName(playerid), playerid);
	SendClientMessage(target, -1, string);
	
	format(string, sizeof(string), "{FFFFFF}[{3498DB}ADMIN{FFFFFF}]: You've given %s(%i) a jetpack.", GetName(target), target);
	SendClientMessage(playerid, -1, string);
	return 1;
}

CMD:aheal(playerid, params[])
{
	LevelCheck(playerid, 2);

	new target;
    if(sscanf(params, "u", target)) return Usage(playerid, "aheal [playerid]");
	if(!IsPlayerConnected(target)) return Error(playerid, "The specified player is not conected.");

    SetPlayerHealth(target, 100.0);
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "Admin %s(%i) has healed you.", GetName(playerid), playerid);
	SendClientMessage(target, -1, string);
	format(string, sizeof(string), "You have healed %s(%i).", GetName(target), target);
	SendClientMessage(playerid, -1, string);
	return 1;
}

CMD:aarmour(playerid, params[])
{
	LevelCheck(playerid, 2);

	new target;
    if(sscanf(params, "u", target)) return Usage(playerid, "aarmour [playerid]");
	if(! IsPlayerConnected(target)) return Error(playerid, "The specified player is not conected.");

    SetPlayerArmour(target, 100.0);
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "{FFFFFF}[{3498DB}ADMIN{FFFFFF}]: %s(%i) has armoured you.", GetName(playerid), playerid);
	SendClientMessage(target, -1, string);
	format(string, sizeof(string), "You have armoured %s(%i).", GetName(target), target);
	SendClientMessage(playerid, -1, string);
	return 1;
}

CMD:setinterior(playerid, params[])
{
	LevelCheck(playerid, 2);

	new target, interiorid;
	if(sscanf(params, "ui", target, interiorid)) return Usage(playerid, "setinterior [playerid] [interiorid]");
	if(! IsPlayerConnected(target)) return Error(playerid, "The specified player is not conected.");
	if(GetLevel(playerid) < GetLevel(target)) return Error(playerid, "You can't use this command on this player.");

	SetPlayerInterior(target, interiorid);
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "{FFFFFF}[{3498DB}ADMIN{FFFFFF}]: %s(%i) has setted your interior to %i.", GetName(playerid), playerid, interiorid);
	SendClientMessage(target, -1, string);
	format(string, sizeof(string), "You have setted %s(%i)'s interior to %i.", GetName(target), target, interiorid);
	SendClientMessage(playerid, -1, string);
	return 1;
}

CMD:setworld(playerid, params[])
{
	LevelCheck(playerid, 2);

	new target, worldid;
	if(sscanf(params, "ui", target, worldid)) return Usage(playerid, "setworld [playerid] [worldid]");
	if(! IsPlayerConnected(target)) return Error(playerid, "The specified player is not conected.");
	if(GetLevel(playerid) < GetLevel(target)) return Error(playerid, "You can't use this command on this player.");

	SetPlayerVirtualWorld(target, id);
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "{FFFFFF}[{3498DB}ADMIN{FFFFFF}]: %s(%i) has setted your virtual world to %i.", GetName(playerid), playerid, worldid);
	SendClientMessage(target, -1, string);
	format(string, sizeof(string), "You have setted %s(%i)'s virtual world to %i.", GetName(target), target, worldid);
	SendClientMessage(playerid, -1, string);
	return 1;
}

CMD:cc(playerid, params[])
{
	LevelCheck(playerid, 2);

	for(new i; i < 250; i++)
	{
		SendClientMessageToAll(-1, "");
		PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);
	}

	new string[144];
	format(string, sizeof(string), "{FFFFFF}[{3498DB}ADMIN{FFFFFF}]: %s(%i) has cleared the chat.", GetName(playerid), playerid);
    SendClientMessageToAll(-1, string);
	return 1;
}

CMD:akill(playerid, params[])
{
	LevelCheck(playerid, 2);

	new target;
    if(sscanf(params, "u", target)) return Usage(playerid, "akill [playerid]");
	if(!IsPlayerConnected(target)) return Error(playerid, "The specified player is not conected.");
	if(GetLevel(playerid) < GetLevel(target)) return Error(playerid, "You can't use this command on this player.");

    SetPlayerHealth(target, 0.0);
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "* You have killed %s(%i).", GetName(target), target);
	SendClientMessage(playerid, -1, string);
	
	format(string, sizeof(string), "{FFFFFF}[{3498DB}ADMIN{FFFFFF}]: %s(%i) has killed you.", GetName(playerid), playerid);
	SendClientMessage(playerid, -1, string);
	return 1;
}

CMD:jail(playerid, params[])
{
	LevelCheck(playerid, 2);

	new target, time, reason[128];
	if(sscanf(params, "uI(60)S(No Reason)[128]", target, time, reason)) return Usage(playerid, "jail [playerid] [seconds(Default 60)] [reason(Default No Reason)]");
	if(!IsPlayerConnected(target)) return Error(playerid, "The specified player is not conected.");
	if(GetLevel(playerid) < GetLevel(target)) return Error(playerid, "You can't use this command on this player.");
	if(time > 5*60 || time < 10) return Error(playerid, "Invalid jail time (10 - 360 seconds).");
	if(target == playerid) return Error(playerid, "You can't jail yourself.");
	if(IsPlayerJailed(target)) return Error(playerid, "Player is already jailed.");

	User[target][jailed] = 1;
	User[target][jailedsec] = time;
	JailPlayer(target);
	
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "* %s(%i) has been jailed by Admin %s(%i) for %i seconds "orange"[Reason: %s]", GetName(target), target, GetName(playerid), playerid, time, reason);
	SendClientMessageToAll(COLOR_RED, string);
	
	#if defined SAVE_LOGS
		SaveLog("jails.txt", string);
	#endif
	return 1;
}

CMD:unjail(playerid, params[])
{
	LevelCheck(playerid, 2);

	new target;
	if(sscanf(params, "u", target)) return Usage(playerid, "unjail [playerid]");
	if(!IsPlayerConnected(target)) return Error(playerid, "The specified player is not conected.");
	if(GetLevel(playerid) < GetLevel(target)) return Error(playerid, "You can't use this command on this player.");
	if(!IsPlayerJailed(target)) return Error(playerid, "Player is not jailed.");
	
	User[target][jailed] = 0;
	User[target][jailedsec] = 0;
	UnJailPlayer(target);
	
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "* %s(%i) has been unjailed by Admin %s(%i)", GetName(target), target, GetName(playerid), playerid);
	SendClientMessageToAll(COLOR_RED, string);
	return 1;
}

CMD:get(playerid, params[]) return cmd_bring(playerid, params);
CMD:bring(playerid, params[])
{
	LevelCheck(playerid, 2);
	
	new target;
	if(sscanf(params, "u", target)) return Usage(playerid, "bring [playerid]");
	if(!IsPlayerConnected(target)) return Error(playerid, "The specified player is not conected.");
	if(target == playerid) return Error(playerid, "You can't bring yourself.");
	if(GetLevel(playerid) < GetLevel(target)) return Error(playerid, "You can't use this command on this player.");

	new Float:currentpos[3];
	GetPlayerPos(playerid, currentpos[0], currentpos[1], currentpos[2]);
	if(GetPlayerState(target) == PLAYER_STATE_DRIVER)
	{
		SetVehiclePos(GetPlayerVehicleID(target), currentpos[0] + 3.0, currentpos[1], currentpos[2]);
		LinkVehicleToInterior(GetPlayerVehicleID(target), GetPlayerInterior(playerid));
		SetVehicleVirtualWorld(GetPlayerVehicleID(target), GetPlayerVirtualWorld(playerid));
	}
	else
	{
		SetPlayerPos(target, currentpos[0] + 2.5, currentpos[1], currentpos[2]);
	}
	SetPlayerInterior(target, GetPlayerInterior(playerid));
	SetPlayerVirtualWorld(target, GetPlayerVirtualWorld(playerid));
	
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "{FFFFFF}[{3498DB}ADMIN{FFFFFF}]: %s(%i) has teleported you to his/her position.", GetName(playerid), playerid);
	SendClientMessage(target, COLOR_GREEN, string);
	
	format(string, sizeof(string), "* You have teleported %s(%i) to your position.", GetName(target), target);
	SendClientMessage(playerid, COLOR_GREEN, string);
	return 1;
}

CMD:cmdmute(playerid, params[])
{
	LevelCheck(playerid, 2);

	new target, time, reason[128];
	if(sscanf(params, "uI(60)S(No Reason)[128]", target, time, reason)) return Usage(playerid, "cmdmute [playerid] [seconds(Default 60)] [reason(Default No Reason)]");
	if(!IsPlayerConnected(target)) return Error(playerid, "The specified player is not conected.");
	if(GetLevel(playerid) < GetLevel(target)) return Error(playerid, "You can't use this command on this player.");
	if(time > 5*60 || time < 10) return Error(playerid, "CMD mute time is invalid (10 - 360 seconds).");
	if(target == playerid) return Error(playerid, "You cannot CMD mute yourself.");
	if(IsPlayerCMDMuted(playerid)) return Error(playerid, "The specified player is already CMD muted.");

	User[target][cmdmutedsec] = time;

	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "* %s(%i) has been CMD muted by Admin %s(%i) for %i seconds "orange"[Reason: %s]", GetName(target), target, GetName(playerid), playerid, time, reason);
	SendClientMessageToAll(COLOR_RED, string);
	
	#if defined SAVE_LOGS
		SaveLog("cmdmutes.txt", string);
	#endif
	return 1;
}

CMD:uncmdmute(playerid, params[])
{
	LevelCheck(playerid, 2);

	new target;
	if(sscanf(params, "u", target)) return Usage(playerid, "uncmdmute [playerid]");
	if(!IsPlayerConnected(target)) return Error(playerid, "The specified player is not conected.");
	if(GetLevel(playerid) < GetLevel(target)) return Error(playerid, "You can't use this command on this player.");
	if(!IsPlayerMuted(playerid)) return Error(playerid, "The specified player is not CMD muted.");

	User[target][cmdmutedsec] = 0;

	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "* %s(%i) has been CMD unmuted by Admin %s(%i)", GetName(target), target, GetName(playerid), playerid);
	SendClientMessageToAll(COLOR_RED, string);
	return 1;
}

CMD:cleardwindow(playerid, params[])
{
	LevelCheck(playerid, 2);

	for(new i = 0; i < 20; i++)
	{
		SendDeathMessage(6000, 5005, 255);
	}

	new string[144];
	format(string, sizeof(string), "{FFFFFF}[{3498DB}ADMIN{FFFFFF}]: %s(%i has cleared all players death window.", GetName(playerid), playerid);
	SendClientMessageToAll(COLOR_BLUE, string);
	return 1;
}

CMD:ban(playerid, params[])
{
	LevelCheck(playerid, 2);

	new target, reason[35], days;
	if(sscanf(params, "is[35]I(0)", target, reason, days)) return Usage(playerid, "ban [playerid] [reason] [days(0 for permanent ban)]");
	if(!IsPlayerConnected(target)) return Error(playerid, "The specified player is not conected, use /oban instead.");
    if(target == playerid) return Error(playerid, "You can't ban yourself.");
	if(GetLevel(playerid) < GetLevel(target)) return Error(playerid, "You cannot use this command on higher level admin.");
	if(days < 0) return Error(playerid, "Invalid days, must be greater than 0 for temp ban, or 0 for permanent ban.");
	if(strlen(reason) < 3 || strlen(reason) > 35) return Error(playerid, "Invalid reason length, must be b/w 0-35 characters.");

	new bandate[18], date[3], time;
	getdate(date[0], date[1], date[2]);
	format(bandate, sizeof(bandate), "%02i/%02i/%i", date[2], date[1], date[0]);

	if(days == 0) time = 0;
	else time = ((days * 24 * 60 * 60) + gettime());
	
	new handle = SQL::Open(SQL::INSERT, ""BANS_TABLE"");
	
	SQL::ToggleAutoIncrement(handle, true);
	SQL::WriteString(handle, "ban_username", GetName(target));
	SQL::WriteString(handle, "ban_ip", GetIP(target));
	SQL::WriteString(handle, "ban_by", GetName(playerid));
	SQL::WriteString(handle, "ban_on", bandate);
	SQL::WriteString(handle, "ban_reason", reason);
	SQL::WriteInt(handle, "ban_expire", time);
	
    SQL::Close(handle);

	if(days == 0)
	{
	    new string[144];
	    format(string, sizeof(string), "* %s(%i) has been banned by Admin %s(%d) "orange"[Reason: %s]", GetName(target), target, GetName(playerid), playerid, reason);
		SendClientMessage(target, COLOR_RED, string);
		
		#if defined SAVE_LOGS
			SaveLog("bans.txt", string);
		#endif
	}
	else
	{
	    new string[258];
	    format(string, sizeof(string), "* %s(%i) has been temp banned by Admin %s(%d) "orange"[Reason: %s] [Days: %i]", GetName(target), target, GetName(playerid), playerid, reason, days);
		SendClientMessage(target, COLOR_RED, string);
		
		#if defined SAVE_LOGS
			SaveLog("bans.txt", string);
		#endif
		
	    format(string, sizeof(string), "* Temp banned for %i days "orange"[Unban on %s]", days, ConvertTime(time));
		SendClientMessage(target, COLOR_RED, string);
	}
 	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	DelayKick(target);
	return 1;
}

// Level 3 Commands
CMD:teleplayer(playerid, params[])
{
	LevelCheck(playerid, 3);
	
	new target, target2;
	if(sscanf(params, "u", target, target2)) return Usage(playerid, "teleplayer [playerid] [targetid]");
	if(!IsPlayerConnected(target)) return Error(playerid, "The specified player is not conected.");
	if(!IsPlayerConnected(target2)) return Error(playerid, "The specified player is not conected.");
	if(target == playerid) return Error(playerid, "You can't tele yourself.");
	if(target2 == playerid) return Error(playerid, "You can't tele yourself.");
	
	new Float:currentpos[3];
	GetPlayerPos(target2, currentpos[0], currentpos[1], currentpos[2]);
	if(GetPlayerState(target) == PLAYER_STATE_DRIVER)
	{
		SetVehiclePos(GetPlayerVehicleID(target), currentpos[0] + 3.0, currentpos[1], currentpos[2]);
		LinkVehicleToInterior(GetPlayerVehicleID(target), GetPlayerInterior(target2));
		SetVehicleVirtualWorld(GetPlayerVehicleID(target), GetPlayerVirtualWorld(target2));
	}
	else
	{
		SetPlayerPos(target, currentpos[0] + 2.5, currentpos[1], currentpos[2]);
	}
	SetPlayerInterior(target, GetPlayerInterior(target2));
	SetPlayerVirtualWorld(target, GetPlayerVirtualWorld(target2));

    PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(target2, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "{FFFFFF}[{3498DB}ADMIN{FFFFFF}]: %s(%i) has teleported you to %s(%i)'s position.", GetName(playerid), playerid, GetName(target2), target2);
	SendClientMessage(target, COLOR_GREEN, string);

	format(string, sizeof(string), "{FFFFFF}[{3498DB}ADMIN{FFFFFF}]: %s(%i) has teleported %s(%i) to your position.", GetName(playerid), playerid, GetName(target), target);
	SendClientMessage(target2, COLOR_GREEN, string);
	
	format(string, sizeof(string), "* You have teleported %s(%i) to %s(%i)'s position.", GetName(target), target, GetName(target2), target2);
	SendClientMessage(target, COLOR_GREEN, string);
	return 1;
}

CMD:fakedeath(playerid, params[])
{
	LevelCheck(playerid, 3);

	new target, killerid, weaponid;
	if(sscanf(params, "uui", target, killerid, weaponid)) return Usage(playerid, "fakedeath [playerid] [killerid] [weapon]");
	if(!IsPlayerConnected(target)) return Error(playerid, "The specified player is not conected.");
	if(!IsPlayerConnected(killerid)) return Error(playerid, "The specified killer is not conected.");
	if(!IsValidWeapon(weaponid)) return Error(playerid, "Invalid weapon id.");

	new weaponname[35];
	GetWeaponName(weaponid, weaponname, sizeof(weaponname));
	SendDeathMessage(killerid, target, weaponid);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "[FAKEDEATH] %s has killed %s with a %s", GetName(target), GetName(killerid), weaponname);
	SendClientMessage(playerid, COLOR_BLUE, string);
	return 1;
}

CMD:giveweapon(playerid, params[])
{
	LevelCheck(playerid, 3);

	new target, weapon[32], ammo;
	if(sscanf(params, "us[32]I(250)", target, weapon, ammo)) return Usage(playerid, "giveweapon [playerid] [weapon] [ammo(Default 250)]");
	if(!IsPlayerConnected(target)) return Error(playerid, "The specified player is not conected.");
	if(GetLevel(playerid) < GetLevel(target)) return Error(playerid, "You can't this command on this player.");

	new weaponid;
	if(!IsNumericString(weapon)) weaponid = GetWeaponIDFromName(weapon);
	else weaponid = strval(weapon);

	if(!IsValidWeapon(weaponid)) return Error(playerid, "Invalid weapon id.");

	GetWeaponName(weaponid, weapon, sizeof(weapon));
	GivePlayerWeapon(target, weaponid, ammo);
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "{FFFFFF}[{3498DB}ADMIN{FFFFFF}]: %s(%i) has given you a %s with %i ammo.", GetName(playerid), playerid, weapon, ammo);
	SendClientMessage(target, -1, string);
	format(string, sizeof(string), "{FFFFFF}[{3498DB}ADMIN{FFFFFF}]: You've given %s(%i) a %s with %i ammo.", GetName(target), target, weapon, ammo);
	SendClientMessage(playerid, -1, string);
	return 1;
}

CMD:sethealth(playerid, params[])
{
	LevelCheck(playerid, 3);

	new target, Float:amount;
	if(sscanf(params, "uf", target, amount)) return Usage(playerid, "sethealth [playerid] [amount]");
	if(!IsPlayerConnected(target)) return Error(playerid, "The specified player is not conected.");
	if(GetLevel(playerid) < GetLevel(target)) return Error(playerid, "You can't use this command on this player.");

	SetPlayerHealth(target, amount);
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "{FFFFFF}[{3498DB}ADMIN{FFFFFF}]: %s(%i) has set your health to %0.2f.", GetName(playerid), playerid, amount);
	SendClientMessage(target, -1, string);
	
	format(string, sizeof(string), "* You have setted %s(%i)'s health to %.2f.", GetName(target), target, amount);
	SendClientMessage(playerid, -1, string);
	return 1;
}

CMD:setarmour(playerid, params[])
{
	LevelCheck(playerid, 3);

	new target, Float:amount;
	if(sscanf(params, "uf", target, amount)) return Usage(playerid, "setarmour [playerid] [amount]");
	if(!IsPlayerConnected(target)) return Error(playerid, "The specified player is not conected.");
	if(GetLevel(playerid) < GetLevel(target)) return Error(playerid, "You can't use this command on this player.");

	SetPlayerArmour(target, amount);
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "{FFFFFF}[{3498DB}ADMIN{FFFFFF}]: %s(%i) has setted your armour to %0.2f.", GetName(playerid), playerid, amount);
	SendClientMessage(target, -1, string);
	format(string, sizeof(string), "* You have setted %s(%i)'s armour to %.2f.", GetName(target), target, amount);
	SendClientMessage(playerid, -1, string);
	return 1;
}

CMD:healall(playerid, params[])
{
	LevelCheck(playerid, 3);

	LOOP_PLAYERS(i)
	{
		SetPlayerHealth(i, 100.0);
		PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);
	}

    new string[144];
	format(string, sizeof(string), "{FFFFFF}[{3498DB}ADMIN{FFFFFF}]: %s(%i) has healed all players.", GetName(playerid), playerid);
    SendClientMessageToAll(COLOR_BLUE, string);
	return 1;
}

CMD:armourall(playerid, params[])
{
	LevelCheck(playerid, 3);

	LOOP_PLAYERS(i)
	{
		SetPlayerArmour(i, 100.0);
		PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);
	}

    new string[144];
	format(string, sizeof(string), "{FFFFFF}[{3498DB}ADMIN{FFFFFF}]: %s(%i) has armoured all players.", GetName(playerid), playerid);
    SendClientMessageToAll(COLOR_BLUE, string);
	return 1;
}

CMD:givecash(playerid, params[])
{
	LevelCheck(playerid, 3);

	new target, amount;
	if(sscanf(params, "ui", target, amount)) return Usage(playerid, "givecash [playerid] [amount]");
	if(!IsPlayerConnected(target)) return Error(playerid, "The specified player is not conected.");

	GivePlayerMoney(target, amount);
	
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "Admin %s(%i) has given you $%i cash.", GetName(playerid), playerid, amount);
	SendClientMessage(target, -1, string);
	format(string, sizeof(string), "You have given %s(%i) $%i cash.", GetName(target), target, amount);
	SendClientMessage(playerid, -1, string);
	return 1;
}

CMD:givescore(playerid, params[])
{
	LevelCheck(playerid, 3);

	new target, amount;
	if(sscanf(params, "ui", target, amount)) return Usage(playerid, "givescore [playerid] [amount]");
	if(!IsPlayerConnected(target)) return Error(playerid, "The specified player is not conected.");

	SetPlayerScore(target, (GetPlayerScore(playerid) + amount));

	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "Admin %s(%i) has given you %i score.", GetName(playerid), playerid, amount);
	SendClientMessage(target, -1, string);
	format(string, sizeof(string), "You have given %s(%i) %i score.", GetName(target), target, amount);
	SendClientMessage(playerid, -1, string);
	return 1;
}

CMD:unban(playerid, params[])
{
	LevelCheck(playerid, 3);

	new name[24];
	if(sscanf(params,"s[24]", name)) return Usage(playerid, "unban [username]");
	
    if(SQL::RowExistsEx(""BANS_TABLE"", "ban_username", name))
    {
       SQL::DeleteRowEx(""BANS_TABLE"", "ban_username", name);
    }
    else return Error(playerid, "The specified username is not banned.");

	new string[144];
	format(string, sizeof(string), "* You have unbanned user %s successfully.", name);
	SendClientMessage(playerid, COLOR_RED, string);

	#if defined SAVE_LOGS
		new logstring[244];
		format(logstring, sizeof(logstring), "Admin %s unbanned %s", GetName(playerid), name);
	    SaveLog("unbans.txt", logstring);
    #endif
	return 1;
}

// Level 4 Commands
CMD:oban(playerid, params[])
{
	LevelCheck(playerid, 4);

	new name[MAX_PLAYER_NAME], reason[35], days;
	if(sscanf(params, "s[24]s[35]I(0)", name, reason, days)) return Usage(playerid, "oban [username] [reason] [days(0 for permanent)]");
    if(!strcmp(name, GetName(playerid))) return Error(playerid, "You can't ban yourself.");
	LOOP_PLAYERS(i)
	{
	    if(!strcmp(name, GetName(i), false))
	    {
	        return Error(playerid, "The specified username is online. Try /ban instead.");
	    }
	}
	
	new playerIP[18], admin;
 	new handle2 = SQL::OpenEx(SQL::READ, ""PLAYERS_TABLE"", "username", name);
  	SQL::ReadString(handle2, "ip", playerIP, 114);
  	SQL::ReadInt(handle2, "level", admin);
    SQL::Close(handle2);
    
   	if(GetLevel(playerid) < admin) return Error(playerid, "You can't use this command on this player.");
	
 	if(SQL::RowExistsEx(""BANS_TABLE"", "ban_username", name)) return Error(playerid, "Player is already banned.");
    if(!SQL::RowExistsEx(""PLAYERS_TABLE"", "username", name)) return Error(playerid, "Player doesn't exist in database.");
	if(days < 0) return Error(playerid, "Invalid days, must be greater than 0 for temp ban, or 0 for permanent ban.");
	if(strlen(reason) < 3 || strlen(reason) > 35) return Error(playerid, "Invalid reason length, must be b/w 0-35 characters.");

	new bandate[18], date[3], time;
	getdate(date[0], date[1], date[2]);
	format(bandate, sizeof(bandate), "%02i/%02i/%i", date[2], date[1], date[0]);

	if(days == 0) time = 0;
	else time = ((days * 24 * 60 * 60) + gettime());
	
	new handle = SQL::Open(SQL::INSERT, ""BANS_TABLE"");
	SQL::ToggleAutoIncrement(handle, true);
	SQL::WriteString(handle, "ban_username", name);
	SQL::WriteString(handle, "ban_ip", playerIP);
	SQL::WriteString(handle, "ban_by", GetName(playerid));
	SQL::WriteString(handle, "ban_on", bandate);
	SQL::WriteString(handle, "ban_reason", reason);
	SQL::WriteInt(handle, "ban_expire", time);
    SQL::Close(handle);

	if(days == 0)
	{
	    new string[144];
	    format(string, sizeof(string), "* %s has been offline banned by Admin %s(%d) "orange"[Reason: %s]", name, GetName(playerid), playerid, reason);
		SendClientMessageToAll(COLOR_RED, string);
		
		#if defined SAVE_LOGS
			SaveLog("bans.txt", string);
		#endif
	}
	else
	{
	    new string[144];
	    format(string, sizeof(string), "* %s has been offline temp banned by Admin %s(%d) "orange"[Reason: %s] [Days: %i]", name, GetName(playerid), playerid, reason, days);
		SendClientMessageToAll(COLOR_RED, string);
		
		#if defined SAVE_LOGS
			SaveLog("bans.txt", string);
		#endif
		
	    format(string, sizeof(string), "* Banned for %i days [Unban on %s]", days, ConvertTime(time));
		SendClientMessageToAll(COLOR_RED, string);
	}

	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
	return 1;
}

CMD:setcash(playerid, params[])
{
	LevelCheck(playerid, 4);

	new target, amount;
	if(sscanf(params, "ui", target, amount)) return Usage(playerid, "setcash [playerid] [amount]");
	if(!IsPlayerConnected(target)) return Error(playerid, "The specified player is not conected.");
	if(GetLevel(playerid) < GetLevel(target)) return Error(playerid, "You can't use this command on this player.");

	ResetPlayerMoney(target);
	GivePlayerMoney(target, amount);
	
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "Admin %s(%i) has setted your money to $%i.", GetName(playerid), playerid, amount);
	SendClientMessage(target, -1, string);
	
	format(string, sizeof(string), "You have setted %s(%i)'s money to $%i.", GetName(target), target, amount);
	SendClientMessage(playerid, -1, string);
	return 1;
}

CMD:setscore(playerid, params[])
{
	LevelCheck(playerid, 4);

	new target, amount;
	if(sscanf(params, "ui", target, amount)) return Usage(playerid, "setscore [playerid] [amount]");
	if(!IsPlayerConnected(target)) return Error(playerid, "The specified player is not conected.");
	if(GetLevel(playerid) < GetLevel(target)) return Error(playerid, "You can't use this command on this player.");

	SetPlayerScore(target, amount);

	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "Admin %s(%i) has setted your score to %i.", GetName(playerid), playerid, amount);
	SendClientMessage(target, -1, string);

	format(string, sizeof(string), "You have setted %s(%i)'s score to %i.", GetName(target), target, amount);
	SendClientMessage(playerid, -1, string);
	return 1;
}

CMD:setwanteds(playerid, params[])
{
	LevelCheck(playerid, 4);

	new target, amount;
	if(sscanf(params, "ui", target, amount)) return Usage(playerid, "setwanteds [playerid] [amount]");
	if(!IsPlayerConnected(target)) return Error(playerid, "The specified player is not conected.");
	if(GetLevel(playerid) < GetLevel(target)) return Error(playerid, "You can't use this command on this player.");

	User[target][wanteds] = amount;

	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "Admin %s(%i) has setted your wanteds to %i.", GetName(playerid), playerid, amount);
	SendClientMessage(target, -1, string);

	format(string, sizeof(string), "You have setted %s(%i)'s wanteds to %i.", GetName(target), target, amount);
	SendClientMessage(playerid, -1, string);
	return 1;
}

CMD:setkills(playerid, params[])
{
	LevelCheck(playerid, 4);

	new target, amount;
	if(sscanf(params, "ui", target, amount)) return Usage(playerid, "setkills [playerid] [amount]");

	if(!IsPlayerConnected(target)) return Error(playerid, "The specified player is not conected.");

	if(GetLevel(playerid) < GetLevel(target)) return Error(playerid, "You can't use this command on this player.");

	User[target][kills] = amount;
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "Admin %s(%i) has setted your kills to %i.", GetName(playerid), playerid, amount);
	SendClientMessage(target, -1, string);
	format(string, sizeof(string), "You have setted %s(%i)'s kills to %i.", GetName(target), target, amount);
	SendClientMessage(playerid, -1, string);
	return 1;
}

CMD:setdeaths(playerid, params[])
{
	LevelCheck(playerid, 4);

	new target, amount;
	if(sscanf(params, "ui", target, amount)) return Usage(playerid, "setdeaths [playerid] [amount]");

	if(!IsPlayerConnected(target)) return Error(playerid, "The specified player is not conected.");

	if(GetLevel(playerid) < GetLevel(target)) return Error(playerid, "You can't use this command on this player.");

	User[target][deaths] = amount;
	
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "Admin %s(%i) has set your deaths to %i.", GetName(playerid), playerid, amount);
	SendClientMessage(target, -1, string);
	format(string, sizeof(string), "You have set %s(%i)'s deaths to %i.", GetName(target), target, amount);
	SendClientMessage(playerid, -1, string);
	return 1;
}

CMD:giveallscore(playerid, params[])
{
	LevelCheck(playerid, 4);

	new amount;
	if(sscanf(params, "i", amount)) return Usage(playerid, "giveallscore [amount]");

	LOOP_PLAYERS(i)
	{
        PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);
		SetPlayerScore(i, GetPlayerScore(i) + amount);
	}

	new string[144];
	format(string, sizeof(string), "{FFFFFF}[{3498DB}ADMIN{FFFFFF}]: %s(%i) has given all players %i score.", GetName(playerid), playerid, amount);
	SendClientMessageToAll(COLOR_BLUE, string);
	return 1;
}

CMD:giveallcash(playerid, params[])
{
	LevelCheck(playerid, 4);

	new amount;
	if(sscanf(params, "i", amount)) return Usage(playerid, "giveallcash [amount]");

	LOOP_PLAYERS(i)
	{
        PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);
		GivePlayerMoney(i, amount);
	}

	new string[144];
	format(string, sizeof(string), "{FFFFFF}[{3498DB}ADMIN{FFFFFF}]: %s(%i) has given all players $%i.", GetName(playerid), playerid, amount);
	SendClientMessageToAll(COLOR_BLUE, string);
	return 1;
}

CMD:giveallweapon(playerid, params[])
{
	LevelCheck(playerid, 4);

	new weapon[32], ammo;
	if(sscanf(params, "s[32]I(250)", weapon, ammo)) return Usage(playerid, "giveallweapon [weapon] [ammo]");

	new weaponid;
	if(!IsNumericString(weapon)) weaponid = GetWeaponIDFromName(weapon);
	else weaponid = strval(weapon);

	if(!IsValidWeapon(weaponid)) return Error(playerid, "Invalid weapon id.");

	GetWeaponName(weaponid, weapon, sizeof(weapon));
   	LOOP_PLAYERS(i) GivePlayerWeapon(i, weaponid, ammo) && PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "{FFFFFF}[{3498DB}ADMIN{FFFFFF}]: %s(%i) has given all players a %s with %i ammo.", GetName(playerid), playerid, weapon, ammo);
	SendClientMessageToAll(COLOR_BLUE, string);
	return 1;
}

CMD:setalltime(playerid, params[])
{
	LevelCheck(playerid, 4);

	new hour;
	if(sscanf(params, "i", hour)) return Usage(playerid, "setalltime [hour]");

	if(hour < 0 || hour > 24) return Error(playerid, "Invalid time hour, must be b/w 0-24.");

	LOOP_PLAYERS(i)
	{
        PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);
		SetPlayerTime(i, hour, 0);
	}

	new string[144];
	format(string, sizeof(string), "{FFFFFF}[{3498DB}ADMIN{FFFFFF}]: %s(%i) has setted all players hour to %i.", GetName(playerid), playerid, hour);
	SendClientMessageToAll(COLOR_BLUE, string);
	return 1;
}

CMD:setallweather(playerid, params[])
{
	LevelCheck(playerid, 4);

	new weatherid;
	if(sscanf(params, "i", weatherid)) return Usage(playerid, "setallweather [weatherid]");

	if(weatherid < 0 || weatherid > 45) return Error(playerid, "Invalid weather id, must be b/w 0-45.");

	LOOP_PLAYERS(i)
	{
        PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);
		SetPlayerWeather(i, weatherid);
	}

	new string[144];
	format(string, sizeof(string), "{FFFFFF}[{3498DB}ADMIN{FFFFFF}]: %s(%i) has setted all players weather to %i.", GetName(playerid), playerid, weatherid);
	SendClientMessageToAll(COLOR_BLUE, string);
	return 1;
}

CMD:giveallexp(playerid, params[])
{
	LevelCheck(playerid, 4);

	new amount;
	if(sscanf(params, "i", amount)) return Usage(playerid, "giveallexp [amount]");

	LOOP_PLAYERS(i)
	{
        PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);
		User[i][exp] = i + amount;
	}

	new string[144];
	format(string, sizeof(string), "{FFFFFF}[{3498DB}ADMIN{FFFFFF}]: %s(%i) has given all players %i experience point.", GetName(playerid), playerid, amount);
	SendClientMessageToAll(COLOR_BLUE, string);
	return 1;
}

// Level 5 Commands
CMD:fakecmd(playerid, params[])
{
	LevelCheck(playerid, 5);

	new target, cmdtext[45];
	if(sscanf(params, "us[45]", target, cmdtext)) return Usage(playerid, "fakecmd [playerid] [command]");
	if(!IsPlayerConnected(target)) return Error(playerid, "The specified player is not conected.");
	if(GetLevel(playerid) < GetLevel(target)) return Error(playerid, "You can't use this command on this player.");
	if(strfind(cmdtext, "/", false) == -1) return Error(playerid, "Fake command is invalid, '/' is missing.");

	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
	CallRemoteFunction("OnPlayerCommandText", "is", target, cmdtext);

	new string[144];
	format(string, sizeof(string), "[FAKECMD] %s(%i) used %s", GetName(target), target, cmdtext);
	SendClientMessage(playerid, -1, string);
	return 1;
}

CMD:fakechat(playerid, params[])
{
	LevelCheck(playerid, 5);

	new target, text[129];
	if(sscanf(params, "us[129]", target, text)) return Usage(playerid, "fakechat [playerid] [text]");
	if(!IsPlayerConnected(target)) return Error(playerid, "The specified player is not conected.");
	if(GetLevel(playerid) < GetLevel(target)) return Error(playerid, "You can't use this command on this player.");
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

    new string[144];
	format(string, sizeof(string), "%s: {FFFFFF}%s", GetName(target), text);
    SendClientMessageToAll(GetPlayerColor(target), string);

	format(string, sizeof(string), "[FAKECHAT] %s(%i) typed %s", GetName(target), target, text);
	SendClientMessage(playerid, -1, string);
	return 1;
}

CMD:removeacc(playerid, params[])
{
	LevelCheck(playerid, 5);

    new name[MAX_PLAYER_NAME], admin, accountID;
	if(sscanf(params, "s[24]", name)) return Usage(playerid, "removeacc [username]");
    
   	new handle = SQL::OpenEx(SQL::READ, ""PLAYERS_TABLE"", "username", name);
  	SQL::ReadInt(handle, "level", admin);
  	SQL::ReadInt(handle, "id", accountID);
    SQL::Close(handle);
    
    if(GetLevel(playerid) < admin) return Error(playerid, "You can't use this command on this player.");
    if(!SQL::RowExistsEx(""PLAYERS_TABLE"", "username", name)) return Error(playerid, "Player doesn't exist in database.");
    if(!strcmp(GetName(playerid), name, false)) return Error(playerid, "You can't remove your own account.");
    
    // If player is online
   	LOOP_PLAYERS(i)
	{
	    if(!strcmp(name, GetName(i), true))
	    {
	        new string[144];
	        format(string, sizeof(string), "{FFFFFF}[{3498DB}ADMIN{FFFFFF}]: %s(%i) has removed your account from database.", GetName(playerid), playerid);
         	SendClientMessage(i, COLOR_RED, string);
			DelayKick(i);
			break;
	    }
	}
	
	new string2[144];
	SendClientMessage(playerid, -1, "Account removed successfully.");
	format(string2, sizeof(string2), "Account Name: %s | Account ID: %i", name, accountID);
	SendClientMessage(playerid, -1, string2);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
	
	SQL::DeleteRowEx(""PLAYERS_TABLE"", "username", name);
	return 1;
}

CMD:setlevel(playerid, params[])
{
	LevelCheck(playerid, 5);

	new target, alevel;
	if(sscanf(params, "ui", target, alevel)) return Usage(playerid, "setlevel [playerid] [level]");
	if(!IsPlayerConnected(target)) return Error(playerid, "Player is not connected");
	if(GetLevel(playerid) < GetLevel(target)) return Error(playerid, "You can't use this command on a higher admin");
	if(alevel < 0 || alevel > MAX_ADMIN_LEVELS) return Error(playerid, "Invalid level (0-"#MAX_ADMIN_LEVELS")");
	if(alevel == GetLevel(target)) return Error(playerid, "Player is already on this level!");

	new string[144];
	if(target == playerid)
	{
		format(string, sizeof(string), "{FFFFFF}[{3498DB}ADMIN{FFFFFF}]: You've set your own admin level to %i.", alevel);
		SendClientMessage(target, -1, string);
		PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	}
	else
	{
		format(string, sizeof(string), "{FFFFFF}[{3498DB}ADMIN{FFFFFF}]: %s(%i) has set your admin level to %i.", GetName(playerid), playerid, alevel);
		SendClientMessage(target, -1, string);

		format(string, sizeof(string), "{FFFFFF}[{3498DB}ADMIN{FFFFFF}]: You've set %s(%i)'s admin level to %i.", GetName(target), target, alevel);
	 	SendClientMessage(playerid, -1, string);
		PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
		PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
	}

 	#if defined SAVE_LOGS
 		SaveLog("staff.txt", string);
	#endif

    User[target][level] = alevel;
	return 1;
}

CMD:setmember(playerid, params[])
{
	LevelCheck(playerid, 5);

	new target, hlevel;
	if(sscanf(params, "ui", target, hlevel)) return Usage(playerid, "setmember [playerid] [0/1]");
	if(!IsPlayerConnected(target)) return Error(playerid, "Player is not connected");
	if(GetLevel(playerid) < GetLevel(target)) return Error(playerid, "You can't use this command on a higher admin");
	if(hlevel < 0 || hlevel > 1) return Error(playerid, "Invalid level (0-1)");
	if(hlevel == User[target][member]) return Error(playerid, "Player is already on this level");

	new string[144];
	if(target == playerid)
	{
		SendClientMessage(target, -1, "{FFFFFF}[{3498DB}ADMIN{FFFFFF}]: You've given yourself a premium membership.");
	}
	else
	{
		format(string, sizeof(string), "{FFFFFF}[{3498DB}ADMIN{FFFFFF}]: %s(%i) has given you premium membership.", GetName(playerid), playerid);
		SendClientMessage(target, -1, string);

		format(string, sizeof(string), "{FFFFFF}[{3498DB}ADMIN{FFFFFF}]: You've given %s(%i)'s premium membership.", GetName(target), target);
	 	SendClientMessage(playerid, -1, string);
	}
 	#if defined SAVE_LOGS
 		SaveLog("staff.txt", string);
	#endif

	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

    User[target][member] = hlevel;
	return 1;
}

CMD:setcivilian(playerid, params[])
{
	LevelCheck(playerid, 5);

	new target, clevel;
	if(sscanf(params, "ui", target, clevel)) return Usage(playerid, "setcivilian [playerid] [level]");
	if(!IsPlayerConnected(target)) return Error(playerid, "Player is not connected");
	if(GetLevel(playerid) < GetLevel(target)) return Error(playerid, "You can't use this command on a higher admin");
	if(clevel < 0 || clevel > MAX_CIVILIAN_LEVELS) return Error(playerid, "Invalid level (0-"#MAX_ADMIN_LEVELS")");
	if(clevel == GetLevel(target)) return Error(playerid, "Player is already on this level!");

	new string[144];
	if(target == playerid)
	{
		format(string, sizeof(string), "{FFFFFF}[{3498DB}ADMIN{FFFFFF}]: You've set your own civilian level to %i.", clevel);
		SendClientMessage(target, -1, string);
		PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	}
	else
	{
		format(string, sizeof(string), "{FFFFFF}[{3498DB}ADMIN{FFFFFF}]: %s(%i) has set your civilian level to %i.", GetName(playerid), playerid, clevel);
		SendClientMessage(target, -1, string);

		format(string, sizeof(string), "{FFFFFF}[{3498DB}ADMIN{FFFFFF}]: You've set %s(%i)'s civilian level to %i.", GetName(target), target, clevel);
	 	SendClientMessage(playerid, -1, string);
		PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
		PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
	}

 	#if defined SAVE_LOGS
 		SaveLog("civilian.txt", string);
	#endif

    User[target][civilian] = clevel;
	return 1;
}

CMD:gmx(playerid, params[])
{
	LevelCheck(playerid, 5);

	new time;
	if(sscanf(params, "I", time)) return Usage(playerid, "gmx [seconds]");
	if(time < 0 || time > 5*60) return Error(playerid, "Invalid restart time (0 - 360 seconds).");
	if(time > 0)
	{
		new string[144];
		format(string, sizeof(string), "{FFFFFF}[{3498DB}ADMIN{FFFFFF}]: %s(%i) has setted the server to restart in %i seconds.", GetName(playerid), playerid, time);
		SendClientMessageToAll(-1, string);
		
		SetTimer("GMXTimer", 1000 * time, false);
	}
	else
	{
		new string[144];
		format(string, sizeof(string), "{FFFFFF}[{3498DB}ADMIN{FFFFFF}]: %s(%i) has setted the server to restart.", GetName(playerid), playerid);
		SendClientMessageToAll(-1, string);

		SendRconCommand("gmx");
	}
	return 1;
}

//=================================================

GetName(playerid)
{
    new name[24];
    GetPlayerName(playerid, name, sizeof(name));
    return name;
}

//=================================================

GetIP(playerid)
{
	new p_ip[18];
	GetPlayerIp(playerid, p_ip, sizeof(p_ip));
	return p_ip;
}

//=================================================

_TogglePlayerSpectating(playerid, set)
{
	if(set)
	{
		if(GetPlayerState(playerid) != PLAYER_STATE_SPECTATING)
		{
		    TogglePlayerSpectating(playerid, true);
		}
	}
	else
	{
		if(GetPlayerState(playerid) == PLAYER_STATE_SPECTATING)
		{
		    TogglePlayerSpectating(playerid, false);
		}
	}
}
#if defined _ALS_TogglePlayerSpectating
    #undef TogglePlayerSpectating
#else
    #define _ALS_TogglePlayerSpectating
#endif
#define TogglePlayerSpectating _TogglePlayerSpectating

//=================================================

ConvertTime(time)
{
	new string[68];
	new values[6];
    TimestampToDate(time, values[0], values[1], values[2], values[3], values[4], values[5], 0, 0);
    format(string, sizeof(string), "%i.%i.%i (%i hrs %i mins %i secs)", values[0], values[1], values[2], values[3], values[4], values[5]);
    return string;
}

//=================================================

SendClientMessageToAdmins(color, message[])
{
	LOOP_PLAYERS(i)
	{
	    if(User[i][level] >= 1)
	    {
	        SendClientMessage(i, color, message);
	    }
	}
	return 1;
}

/*SendClientMessageToHelpers(color, message[])
{
	LOOP_PLAYERS(i)
	{
	    if(User[i][helper] >= 1)
	    {
	        SendClientMessage(i, color, message);
	    }
	}
	return 1;
}

SendClientMessageToVips(color, message[])
{
	LOOP_PLAYERS(i)
	{
	    if(User[i][vip] >= 1)
	    {
	        SendClientMessage(i, color, message);
	    }
	}
	return 1;
}*/

//=================================================

DelayKick(playerid) return SetTimerEx("OnPlayerKicked", (10 + GetPlayerPing(playerid)), false, "i", playerid);
forward OnPlayerKicked(playerid);
public OnPlayerKicked(playerid) return Kick(playerid);

//=================================================

forward GMXTimer();
public GMXTimer()
{
	SendRconCommand("gmx");
	return 1;
}

//=================================================

IsPlayerMember(playerid)
{
	if(User[playerid][member] > 0 || IsPlayerAdmin(playerid)) return true;
	return false;
}

//=================================================

GetLevel(playerid)
{
	return User[playerid][level];
}

//=================================================

IsPlayerAdminEx(playerid)
{
	if(User[playerid][level] > 0 || IsPlayerAdmin(playerid)) return true;
	return false;
}

//=================================================

GetPlayerWarns(playerid)
{
	return User[playerid][warns];
}

//=================================================

GetVehicleModelIDFromName(vname[])
{
	for(new i = 0; i < 211; i++)
	{
		if(strfind(sbVehicles[i], vname, true) != -1 )
		return i + 400;
	}
	return -1;
}

//=================================================

IsNumericString(str[])
{
	new ch, i;
	while ((ch = str[i++])) if (!('0' <= ch <= '9')) return false;
	return true;
}

//=================================================

stock IsNumeric(const string[])
{
	return !sscanf(string, "{d}");
}

//=================================================

IsPlayerMuted(playerid)
{
	if(User[playerid][mutedsec] > 0) return true;
	return false;
}

//=================================================

IsPlayerCMDMuted(playerid)
{
	if(User[playerid][cmdmutedsec] > 0) return true;
	return false;
}

//=================================================

IsPlayerJailed(playerid)
{
	if(User[playerid][jailed] == 1) return true;
	return false;
}

//=================================================

SetPlayerSpectating(playerid, targetid)
{
    TogglePlayerSpectating(playerid, true);

	if(GetPlayerInterior(playerid) != GetPlayerInterior(targetid))
    {
    	SetPlayerInterior(playerid, GetPlayerInterior(targetid));
   	}
    if(GetPlayerVirtualWorld(playerid) != GetPlayerVirtualWorld(targetid))
    {
    	SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(targetid));
    }

    if(IsPlayerInAnyVehicle(targetid))
    {
        PlayerSpectateVehicle(playerid, GetPlayerVehicleID(targetid));
    }
    else
    {
        PlayerSpectatePlayer(playerid, targetid);
    }

	new string[144];
    format(string, sizeof(string),"-> You are now spectating %s(%i).", GetName(targetid), targetid);
    SendClientMessage(playerid, -1, string);

    User[playerid][spec] = true;
    User[playerid][specid] = targetid;
	return true;
}

//=================================================

UpdatePlayerSpectating(playerid, type = 0, bool:forcestop = false)
{
	switch(type)
	{
	    case 0:
	    {
			new check = 0;
		  	LOOP_PLAYERS(i)
			{
				if(i < User[i][specid]) i = (User[playerid][specid] + 1);
			    if(i > GetPlayerPoolSize()) i = 0, check += 1;

				if(check > 1) break;

				if(IsPlayerSpawned(i))
				{
					if(i != playerid)
					{
			    		if(!IsPlayerSpectating(i))
			    		{
							SetPlayerSpectating(playerid, i);
			    			break;
						}
					}
				}
		 	}

		 	if(forcestop)
			{
				cmd_specoff(playerid, "");
		 		Error(playerid, "There was no player to spectate further.");
		 	}
		 	else
		 	{
		 	    SetPlayerSpectating(playerid, User[playerid][specid]);
		 	}
	 	}
	 	case 1:
	 	{
			new check = 0;
		  	LOOP_PLAYERS(i)
			{
				if(i > User[i][specid]) i = (User[playerid][specid] - 1);
			    if(i < 0) i = GetPlayerPoolSize(), check += 1;

				if(check > 1) break;

				if(IsPlayerSpawned(i))
				{
					if(i != playerid)
					{
			    		if(! IsPlayerSpectating(i))
			    		{
							SetPlayerSpectating(playerid, i);
							break;
						}
					}
				}
		 	}

		 	if(forcestop)
			{
				cmd_specoff(playerid, "");
		 		Error(playerid, "There was no player to spectate back.");
	 		}
		 	else
		 	{
		 	    SetPlayerSpectating(playerid, User[playerid][specid]);
		 	}
	 	}
	 	case 2:
	 	{
	 	    if(GetPlayerInterior(playerid) != GetPlayerInterior(User[playerid][specid]))
		    {
		    	SetPlayerInterior(playerid, GetPlayerInterior(User[playerid][specid]));
		   	}
		    if(GetPlayerVirtualWorld(playerid) != GetPlayerVirtualWorld(User[playerid][specid]))
		    {
		    	SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(User[playerid][specid]));
		    }

		    if(IsPlayerInAnyVehicle(User[playerid][specid]))
		    {
		        PlayerSpectateVehicle(playerid, GetPlayerVehicleID(User[playerid][specid]));
		    }
		    else
		    {
		        PlayerSpectatePlayer(playerid, User[playerid][specid]);
		    }
	 	}
	}
	return true;
}

//=================================================

IsPlayerSpectating(playerid)
{
	if(GetPlayerState(playerid) == PLAYER_STATE_SPECTATING) return true;
	return false;
}

//=================================================

IsPlayerSpawned(playerid)
{
	switch(GetPlayerState(playerid))
	{
	    case PLAYER_STATE_ONFOOT, PLAYER_STATE_DRIVER, PLAYER_STATE_PASSENGER, PLAYER_STATE_SPAWNED: return true;
	    default: return false;
	}
	return false;
}

//=================================================

RemoveAVeh(vehicleid)
{
    LOOP_PLAYERS(i)
	{
        new Float:X, Float:Y, Float:Z;
    	if(IsPlayerInVehicle(i, vehicleid))
		{
	  		RemovePlayerFromVehicle(i);
	  		GetPlayerPos(i, X, Y, Z);
	 		SetPlayerPos(i, X, Y+3, Z);
	    }
	    SetVehicleParamsForPlayer(vehicleid, i, 0, 1);
	}
    SetTimerEx("OnVehicleRespawned", 1000, 0, "i", vehicleid);
}

//=================================================

forward OnVehicleRespawned(vehicleid);
public OnVehicleRespawned(vehicleid) return DestroyVehicle(vehicleid);

//=================================================

forward OnPlayerUpdater(playerid);
public OnPlayerUpdater(playerid)
{
	new string[244];
	// Mute System
	if(IsPlayerMuted(playerid))
	{
 		User[playerid][mutedsec] --;
	}
	
	// CMD Mute System
	if(IsPlayerCMDMuted(playerid))
	{
 		User[playerid][cmdmutedsec] --;
	}
	
	// Jail system
	if(IsPlayerJailed(playerid))
	{
	
	    if(User[playerid][jailedsec] >= 1)
	    {
	        User[playerid][jailedsec] --;
	    }
	    else if(User[playerid][jailedsec] <= 0)
	    {
	        UnJailPlayer(playerid);
	    }
	}
	#if defined SPECTATE_TEXTDRAW
	    if(User[playerid][spec])
	    {
	        if(IsPlayerConnected(User[playerid][specid]))
	        {
	            new target = User[playerid][specid];
	            new arg_s[96], Float:arg_f, Float:arg_speed[3], arg_weaps[13][2];
	            strcat(string, "~r~Username: ");
	            strcat(string, "~w~");
	            strcat(string, GetName(target));
	            strcat(string, " (");
	            format(arg_s, sizeof(arg_s), "%i", target);
	            strcat(string, arg_s);
	            strcat(string, ")");
	            strcat(string, "~n~");
	            strcat(string, "~r~Health: ");
	            strcat(string, "~w~");
	            GetPlayerHealth(target, arg_f);
	            format(arg_s, sizeof(arg_s), "%0.2f", arg_f);
	            strcat(string, arg_s);
	            strcat(string, "~n~");
	            strcat(string, "~r~Armour: ");
	            strcat(string, "~w~");
	            GetPlayerArmour(target, arg_f);
	            format(arg_s, sizeof(arg_s), "%0.2f", arg_f);
	            strcat(string, arg_s);
	            strcat(string, "~n~");
	            strcat(string, "~r~Ping: ");
	            strcat(string, "~w~");
	            format(arg_s, sizeof(arg_s), "%i", GetPlayerPing(target));
	            strcat(string, arg_s);
	            strcat(string, "~n~");
	            strcat(string, "~r~IP.: ");
	            strcat(string, "~w~");
	            strcat(string, GetIP(target));
	            strcat(string, "~n~");
	            strcat(string, "~r~Skinid: ");
	            strcat(string, "~w~");
	            format(arg_s, sizeof(arg_s), "%i", GetPlayerSkin(target));
	            strcat(string, arg_s);
	            strcat(string, "~n~");
	            strcat(string, "~r~Teamid: ");
	            strcat(string, "~w~");
	            format(arg_s, sizeof(arg_s), "%i", GetPlayerTeam(target));
	            strcat(string, arg_s);
	            strcat(string, "~n~");
	            strcat(string, "~r~Money: ");
	            strcat(string, "~w~");
	            format(arg_s, sizeof(arg_s), "~g~$~w~%i", GetPlayerMoney(target));
	            strcat(string, arg_s);
	            strcat(string, "~n~");
	            strcat(string, "~r~Score: ");
	            strcat(string, "~w~");
	            format(arg_s, sizeof(arg_s), "%i", GetPlayerScore(target));
	            strcat(string, arg_s);
	            strcat(string, "~n~");
	            strcat(string, "~r~Camera target player: ");
	            strcat(string, "~w~");
	            if(GetPlayerCameraTargetPlayer(target) != INVALID_PLAYER_ID)
	            {
		            strcat(string, GetName(GetPlayerCameraTargetPlayer(target)));
		            strcat(string, " (");
		            format(arg_s, sizeof(arg_s), "%i", GetPlayerScore(target));
		            strcat(string, arg_s);
		            strcat(string, ")");
         		}
	            else
	            {
	            	strcat(string, "No Player");
	            }
	            strcat(string, "~n~");
	            strcat(string, "~r~Weapon target player: ");
	            strcat(string, "~w~");
	            if(GetPlayerTargetPlayer(target) != INVALID_PLAYER_ID)
	            {
		            strcat(string, GetName(GetPlayerTargetPlayer(target)));
		            strcat(string, " (");
		            format(arg_s, sizeof(arg_s), "%i", GetPlayerScore(target));
		            strcat(string, arg_s);
		            strcat(string, ")");
         		}
	            else
	            {
	            	strcat(string, "No Player");
	            }
	            strcat(string, "~n~");
	            strcat(string, "~r~Speed: ");
	            strcat(string, "~w~");
	            if(!IsPlayerInAnyVehicle(playerid))
	            {
		            GetPlayerVelocity(target, arg_speed[0], arg_speed[1], arg_speed[2]);
				    arg_f = floatsqroot((arg_speed[0] * arg_speed[0]) + (arg_speed[1] * arg_speed[1]) + (arg_speed[2] * arg_speed[2])) * 179.28625;
		            format(arg_s, sizeof(arg_s), "%0.2f MPH", arg_f);
		            strcat(string, arg_s);
				}
				else
				{
		            strcat(string, "0.0 MPH");
				}
	            strcat(string, "~n~");
	            strcat(string, "~r~Vehicle Speed: ");
	            strcat(string, "~w~");
	            if(IsPlayerInAnyVehicle(playerid))
	            {
		            GetVehicleVelocity(GetPlayerVehicleID(target), arg_speed[0], arg_speed[1], arg_speed[2]);
				    arg_f = floatsqroot((arg_speed[0] * arg_speed[0]) + (arg_speed[1] * arg_speed[1]) + (arg_speed[2] * arg_speed[2])) * 179.28625;
		            format(arg_s, sizeof(arg_s), "%0.2f MPH", arg_f);
		            strcat(string, arg_s);
				}
				else
				{
		            strcat(string, "0.0 MPH");
				}
	            strcat(string, "~n~");
	            strcat(string, "~r~Position: ");
	            strcat(string, "~w~");
	            GetPlayerPos(playerid, arg_speed[0], arg_speed[1], arg_speed[2]);
			    format(arg_s, sizeof(arg_s), "%f, %f, %f", arg_speed[0], arg_speed[1], arg_speed[2]);
	            strcat(string, arg_s);
	            strcat(string, "~n~");
	            strcat(string, "~r~~h~Weapons:");
	            strcat(string, "~w~");
	            new count = 0;
	            for(new i; i < 13; i++)
	            {
	                GetPlayerWeaponData(target, i, arg_weaps[i][0], arg_weaps[i][1]);
	                if(arg_weaps[i][0] != 0)
	                {
	                    count += 1;

	            		strcat(string, "~n~");
	            		format(arg_s, sizeof(arg_s), "%i. ", count);
	            		strcat(string, arg_s);
	                    GetWeaponName(arg_weaps[i][0], arg_s, sizeof(arg_s));
	            		strcat(string, arg_s);
	            		strcat(string, " [Ammo: ");
	            		format(arg_s, sizeof(arg_s), "%i", arg_weaps[i][1]);
	            		strcat(string, arg_s);
	            		strcat(string, "]");
	            	}
	            }
	            strcat(string, "~n~");
	            strcat(string, "~n~");
	            strcat(string, "~r~You can use LCTRL (KEY_ACTION) and RCTRL (KEY_FIRE) to switch players");
				strcat(string, "~n~");
	            strcat(string, "~r~You can use MMB (KEY_LOOK_BEHIND) or /specoff to stop spectating");

				PlayerTextDrawSetString(playerid, User[playerid][specTD], string);
	        }
	    }
	#endif
	return 1;
}

//=================================================

forward hideAnnouncement();
public hideAnnouncement()
{
	TextDrawHideForAll(announceTD);
	return 1;
}

//=================================================

JailPlayer(playerid)
{
    LoadObjects(playerid);

	SetCameraBehindPlayer(playerid);
	SetPlayerPos(playerid, 1770.14, -1564.66, 1738.69);
	SetPlayerFacingAngle(playerid, 180);
	SetPlayerInterior(playerid, 3);
	
	Server(playerid, "You have been placed on jail.");
	return 1;
}

//=================================================

UnJailPlayer(playerid)
{
	User[playerid][jailed] = 0;
	SpawnPlayer(playerid);
	SetPlayerInterior(playerid, 0);

	Server(playerid, "You have been released from jail.");
	return 1;
}

//=================================================

LoadObjects(playerid)
{
    SetTimerEx("ObjectsLoaded", 2000, false, "i", playerid);
    TogglePlayerControllable(playerid, false);
    GameTextForPlayer(playerid, "~w~Objects ~r~Loading", 1000, 5);
    return 1;
}

//=================================================

forward ObjectsLoaded(playerid);
public ObjectsLoaded(playerid)
{
    TogglePlayerControllable(playerid, true);
    GameTextForPlayer(playerid, "~w~Objects ~g~Loaded", 4000,5);
    return 1;
}

//=================================================

GetPlayerConnectedTime(playerid, &hours, &minutes, &seconds)
{
	new connected_time = NetStats_GetConnectedTime(playerid);
	new CurrentTime[3];

	CurrentTime[2] = (connected_time / 1000) % 60;
	CurrentTime[1] = (connected_time / (1000 * 60)) % 60;
	CurrentTime[0] = (connected_time / (1000 * 60 * 60));

	new SavedTime[3];
	SavedTime[2] = SQL::GetIntEntry(""PLAYERS_TABLE"", "seconds", "id", User[playerid][id]);
	SavedTime[1] = SQL::GetIntEntry(""PLAYERS_TABLE"", "minutes", "id", User[playerid][id]);
	SavedTime[0] = SQL::GetIntEntry(""PLAYERS_TABLE"", "hours", "id", User[playerid][id]);

	new TotalTime[3];
	TotalTime[2] = CurrentTime[2] + SavedTime[2];
	TotalTime[1] = CurrentTime[1] + SavedTime[1];
	TotalTime[0] = CurrentTime[0] + SavedTime[0];
	if (TotalTime[2] >= 60)
	{
	    TotalTime[2] = 0;
	    TotalTime[1]++;

	    if (TotalTime[1] >= 60)
	    {
	        TotalTime[1] = 0;
	        TotalTime[2]++;
	    }
	}
	
	seconds = TotalTime[2];
	minutes = TotalTime[1];
	hours = TotalTime[0];
	return true;
}

//=================================================

GetWeaponIDFromName(WeaponName[])
{
	if(strfind("molotov", WeaponName, true) != -1) return 18;
	for(new i = 0; i <= 46; i++)
	{
		switch(i)
		{
			case 0,19,20,21,44,45: continue;
			default:
			{
				new name[32];
				GetWeaponName(i,name,32);
				if(strfind(name,WeaponName,true) != -1) return i;
			}
		}
	}
	return -1;
}

//=================================================

#if defined SAVE_LOGS
	forward SaveLog(filename[], text[]);
	public SaveLog(filename[], text[])
	{
		new string[256];

		if(!fexist(LOGFILE))
		{
		    printf("[sbAdmin]: Unable to overwrite '%s' at the '%s', '%s' missing.", filename, LOGFILE, LOGFILE);
		    print("No logs has been saved to your server database.");

		    format(string, sizeof string, "[sbAdmin]: Attempting to overwrite '%s' at the '%s' which is missing.", filename, LOGFILE);
		    SendClientMessageToAdmins(COLOR_RED, string);
		    SendClientMessageToAdmins(-1, "[sbAdmin]: Logs will not be saved, contact an "LEVEL5"");
		    return 0;
		}

		new File:file,
			filepath[128+40]
		;

		new year, month, day;
		new hour, minute, second;

		getdate(year, month, day);
		gettime(hour, minute, second);
		format(filepath, sizeof(filepath), ""LOGFILE"%s", filename);
		file = fopen(filepath, io_append);
		format(string, sizeof(string),"[%02d/%02d/%02d | %02d:%02d:%02d] %s\r\n", month, day, year, hour, minute, second, text);
		fwrite(file, string);
		fclose(file);
		return 1;
	}
#endif

//=================================================

BuildTextdraws()
{
	announceTD = TextDrawCreate(320.000000, 140.000000, "");
	TextDrawAlignment(announceTD, 2);
	TextDrawBackgroundColor(announceTD, 1055);
	TextDrawFont(announceTD, 1);
	TextDrawLetterSize(announceTD, 0.329999, 1.500002);
	TextDrawColor(announceTD, -1);
	TextDrawSetOutline(announceTD, 1);
	TextDrawSetProportional(announceTD, 1);
	TextDrawSetSelectable(announceTD, 0);
	return 1;
}

//=================================================

// Special thanks to SickAttack
#if defined USE_ANTIADVERT
	IsAdvertisement(text[])
	{
		new message[128], extract[2], element[4][4], count_1, count_2, temp, bool:number_next = false, bool:next_number = false, bool:advert = false;
		strcpy(message, text, sizeof(message));

		for(new i = 0, j = strlen(message); i < j; i ++)
		{
			switch(message[i])
			{
				case '0'..'9':
				{
					if(next_number) continue;

					number_next = false;

					strmid(extract, message[i], 0, 1);
					strcat(element[count_1], extract);
					count_2 ++;

					if(count_2 == 3 || message[i + 1] == EOS)
					{
						strmid(extract, message[i + 1], 0, 1);
						if(IsNumeric(extract))
						{
							element[0][0] = EOS;
							element[1][0] = EOS;
							element[2][0] = EOS;
							element[3][0] = EOS;
							count_1 = 0;
							count_2 = 0;
							next_number = true;
							continue;
						}

						temp = strval(element[count_1]);

						if(count_1 == 0)
						{
							if(temp <= 255)
							{
								count_1 ++;
								count_2 = 0;
							}
							else
							{
								element[count_1][0] = EOS;
								count_2 = 0;
								next_number = true;
							}
						}
						else
						{
							if(temp <= 255)
							{
								count_1 ++;
								count_2 = 0;
							}
							else
							{
								element[0][0] = EOS;
								element[1][0] = EOS;
								element[2][0] = EOS;
								element[3][0] = EOS;
								count_1 = 0;
								count_2 = 0;
								next_number = true;
							}
						}
					}

					if(count_1 == 4)
					{
						advert = true;
						break;
					}
				}
				default:
				{
					next_number = false;

					if(number_next) continue;

					if(!isnull(element[count_1]))
					{
						temp = strval(element[count_1]);

						if(count_1 == 0)
						{
							if(temp <= 255)
							{
								count_1 ++;
								count_2 = 0;
								number_next = true;
							}
							else
							{
								element[count_1][0] = EOS;
								count_2 = 0;
							}
						}
						else
						{
							if(temp <= 255)
							{
								count_1 ++;
								count_2 = 0;
								number_next = true;
							}
							else
							{
								element[0][0] = EOS;
								element[1][0] = EOS;
								element[2][0] = EOS;
								element[3][0] = EOS;
								count_1 = 0;
								count_2 = 0;
							}
						}

						if(count_1 == 4)
						{
							advert = true;
							break;
						}
					}
				}
			}
		}
		return advert;
	}
#endif

//=================================================

PlaceMaps()
{
	CreateDynamicObject(7191,1759.3388672,-1602.4755859,1734.9488525,0.0000000,359.2474365,179.9945068); //
	CreateDynamicObject(14856,1757.1634521,-1588.1893311,1735.8120117,0.0000000,0.0000000,182.0000000); //
	CreateDynamicObject(8661,1775.4768066,-1555.7030029,1733.9429932,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(8661,1775.5107422,-1575.5996094,1733.9429932,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(8661,1773.9160156,-1585.5395508,1743.4429932,271.9995117,179.9945068,179.9945068); //
	CreateDynamicObject(8661,1769.3701172,-1560.2636719,1743.8931885,90.0000000,179.9945068,179.9945068); //
	CreateDynamicObject(8661,1755.5429688,-1565.8349609,1743.8681641,90.0000000,164.4987183,285.4902954); //
	CreateDynamicObject(8661,1780.4873047,-1566.7968750,1743.9184570,271.9940186,179.9945068,270.7415771); //
	CreateDynamicObject(7191,1763.6158447,-1602.3254395,1734.9488525,0.0000000,359.2474365,179.9945068); //
	CreateDynamicObject(7191,1767.8378906,-1602.2255859,1734.9488525,0.0000000,359.2474365,179.9945068); //
	CreateDynamicObject(14856,1779.0579834,-1587.5596924,1735.8120117,0.0000000,0.0000000,1.2495117); //
	CreateDynamicObject(7191,1772.0864258,-1602.0699463,1734.9488525,0.0000000,359.2474365,179.9945068); //
	CreateDynamicObject(7191,1776.3354492,-1601.9881592,1734.9488525,0.0000000,359.2474365,179.9945068); //
	CreateDynamicObject(7191,1780.6092529,-1601.9577637,1734.9488525,0.0000000,359.2474365,179.9945068); //
	CreateDynamicObject(7191,1780.6083984,-1601.9570312,1738.8985596,0.0000000,359.2474365,179.9945068); //
	CreateDynamicObject(7191,1776.3553467,-1601.9653320,1738.8985596,0.0000000,359.2474365,179.9945068); //
	CreateDynamicObject(7191,1772.1040039,-1602.0228271,1738.8985596,0.0000000,359.2474365,179.9945068); //
	CreateDynamicObject(7191,1767.8559570,-1602.2055664,1738.8985596,0.0000000,359.2474365,179.9945068); //
	CreateDynamicObject(7191,1763.6304932,-1602.2875977,1738.8985596,0.0000000,359.2474365,179.9945068); //
	CreateDynamicObject(7191,1759.3823242,-1602.4952393,1738.8985596,0.0000000,359.2474365,179.9945068); //
	CreateDynamicObject(8661,1774.9119873,-1585.8381348,1737.7172852,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(8661,1774.9062500,-1586.2128906,1737.7172852,0.0000000,179.9999390,0.0000000); //
	CreateDynamicObject(14856,1757.1630859,-1588.1884766,1739.5620117,0.0000000,0.0000000,181.9995117); //
	CreateDynamicObject(14856,1779.0576172,-1587.5595703,1739.5625000,0.0000000,0.0000000,1.2469482); //
	CreateDynamicObject(14856,1756.6878662,-1558.7972412,1735.8120117,0.0000000,0.0000000,181.4970093); //
	CreateDynamicObject(7191,1759.4707031,-1544.4438477,1734.9488525,0.0000000,359.2474365,359.9945068); //
	CreateDynamicObject(7191,1763.7202148,-1544.3764648,1734.9488525,0.0000000,359.2419434,359.9890137); //
	CreateDynamicObject(7191,1767.9682617,-1544.2838135,1734.9488525,0.0000000,359.2419434,359.9890137); //
	CreateDynamicObject(14856,1778.7756348,-1558.3518066,1735.8120117,0.0000000,0.0000000,1.2469482); //
	CreateDynamicObject(7191,1772.2685547,-1544.3099365,1734.9488525,0.0000000,359.2419434,359.9890137); //
	CreateDynamicObject(7191,1776.5231934,-1544.2121582,1734.9488525,0.0000000,359.2419434,359.9890137); //
	CreateDynamicObject(7191,1780.5192871,-1544.1015625,1734.9488525,0.0000000,359.2419434,0.4890137); //
	CreateDynamicObject(8661,1775.4921875,-1559.5787354,1737.6934814,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(7191,1780.4685059,-1544.1010742,1738.8750000,0.0000000,359.2419434,0.4888916); //
	CreateDynamicObject(7191,1776.2663574,-1544.2237549,1738.8750000,0.0000000,359.2419434,0.4888916); //
	CreateDynamicObject(7191,1772.0139160,-1544.3225098,1738.8750000,0.0000000,359.2419434,0.4888916); //
	CreateDynamicObject(7191,1767.7136230,-1544.3187256,1738.8750000,0.0000000,359.2419434,0.4888916); //
	CreateDynamicObject(7191,1763.4619141,-1544.3909912,1738.8750000,0.0000000,359.2419434,0.4888916); //
	CreateDynamicObject(7191,1759.2349854,-1544.4659424,1738.8750000,0.0000000,359.2419434,0.4888916); //
	CreateDynamicObject(14856,1756.6875000,-1558.7968750,1739.5617676,0.0000000,0.0000000,181.4941406); //
	CreateDynamicObject(14856,1778.7753906,-1558.3515625,1739.5620117,0.0000000,0.0000000,1.2469482); //
	CreateDynamicObject(8661,1775.4921875,-1559.5781250,1737.6934814,0.0000000,179.9945068,0.0000000); //
	CreateDynamicObject(8661,1758.6054688,-1576.8515625,1741.3966064,0.0000000,180.2471924,0.0000000); //
	CreateDynamicObject(8661,1796.8046875,-1573.7988281,1737.6929932,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(8661,1796.8046875,-1573.7988281,1737.6929932,0.0000000,180.0000000,0.0000000); //
	CreateDynamicObject(8614,1759.4495850,-1570.4389648,1736.4675293,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(970,1774.7596436,-1569.5825195,1738.2449951,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(970,1770.6550293,-1569.5819092,1738.2449951,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(970,1766.5239258,-1569.5954590,1738.2449951,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(970,1764.4404297,-1569.5966797,1738.2449951,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(970,1760.3516846,-1569.6000977,1738.2449951,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(970,1776.8194580,-1571.7288818,1738.2695312,0.0000000,0.0000000,90.5000000); //
	CreateDynamicObject(970,1776.8634033,-1573.7910156,1738.2449951,0.0000000,0.0000000,90.4998779); //
	CreateDynamicObject(970,1774.8477783,-1575.8577881,1738.2449951,0.0000000,0.0000000,180.4998779); //
	CreateDynamicObject(970,1770.7470703,-1575.8815918,1738.2449951,0.0000000,0.0000000,180.4998779); //
	CreateDynamicObject(970,1766.6242676,-1575.9301758,1738.2449951,0.0000000,0.0000000,180.4998779); //
	CreateDynamicObject(970,1762.4991455,-1575.9755859,1738.2449951,0.0000000,0.0000000,180.4998779); //
	CreateDynamicObject(970,1758.3935547,-1576.0017090,1738.2449951,0.0000000,0.0000000,180.4998779); //
	CreateDynamicObject(970,1754.2669678,-1576.0084229,1738.2449951,0.0000000,0.0000000,180.4998779); //
	CreateDynamicObject(970,1753.4927979,-1576.0433350,1738.2449951,0.0000000,0.0000000,180.4998779); //
	CreateDynamicObject(8661,1757.4633789,-1557.0551758,1741.3966064,0.0000000,180.2471924,0.0000000); //
	CreateDynamicObject(8661,1761.1757812,-1557.2333984,1741.4466553,0.0000000,359.7418213,0.0000000); //
	CreateDynamicObject(8661,1760.8068848,-1557.2219238,1741.3715820,0.0000000,180.2416992,0.0000000); //
	CreateDynamicObject(8661,1758.5277100,-1574.4494629,1741.5217285,0.0000000,0.2471924,0.0000000); //
	CreateDynamicObject(8661,1763.0654297,-1589.0302734,1741.5217285,0.0000000,0.2471924,0.0000000); //
	CreateDynamicObject(8661,1761.8243408,-1589.0578613,1741.3966064,0.0000000,180.2471924,0.0000000); //
	CreateDynamicObject(14387,1780.9128418,-1577.6300049,1740.5070801,0.0000000,0.0000000,92.0000000); //
	CreateDynamicObject(14387,1780.7963867,-1574.7548828,1738.7320557,0.0000000,0.0000000,91.9995117); //
	CreateDynamicObject(14387,1780.6972656,-1574.7872314,1738.7320557,0.0000000,113.9999695,269.9996338); //
	CreateDynamicObject(14387,1780.6909180,-1577.2197266,1740.2563477,0.0000000,113.9996338,269.9945068); //
	CreateDynamicObject(970,1778.5164795,-1577.0081787,1742.0205078,0.0000000,0.0000000,90.4943848); //
	CreateDynamicObject(8661,1775.0488281,-1576.2343750,1744.9672852,0.0000000,179.9945068,0.0000000); //
	CreateDynamicObject(8661,1775.4042969,-1562.4902344,1746.9672852,0.0000000,179.9945068,0.0000000); //
	CreateDynamicObject(8614,1754.3951416,-1570.4387207,1732.7175293,0.0000000,179.2500000,0.0000000); //
	CreateDynamicObject(2205,1778.9362793,-1571.5363770,1733.9429932,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(2205,1778.0222168,-1572.8785400,1733.9429932,0.0000000,0.0000000,89.5000000); //
	CreateDynamicObject(2205,1779.3442383,-1573.8327637,1733.9429932,0.0000000,0.0000000,178.9946289); //
	CreateDynamicObject(2190,1779.5219727,-1571.4400635,1734.8795166,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(2190,1777.9218750,-1572.6606445,1734.8795166,0.0000000,0.0000000,89.2500000); //
	CreateDynamicObject(2776,1779.9310303,-1572.2644043,1734.4404297,0.0000000,0.0000000,232.0000000); //
	CreateDynamicObject(14819,1780.7757568,-1575.8271484,1735.0928955,358.2500305,0.2501221,91.2576599); //
	CreateDynamicObject(14401,1767.8037109,-1573.5908203,1734.2686768,0.0000000,0.0000000,91.9940186); //
	CreateDynamicObject(3858,1760.9343262,-1571.0079346,1744.4094238,0.0000000,0.0000000,260.0000000); //
	CreateDynamicObject(8661,1778.7847900,-1553.5157471,1751.2926025,90.0000000,180.0054932,269.2335205); //
	CreateDynamicObject(8661,1778.3208008,-1567.1134033,1751.2425537,89.2498169,269.9998169,89.2366333); //
	CreateDynamicObject(970,1778.4766846,-1572.8826904,1742.0205078,0.0000000,0.0000000,90.9943848); //
	CreateDynamicObject(3858,1760.9335938,-1571.0078125,1744.4094238,0.0000000,0.0000000,79.9969482); //
	CreateDynamicObject(3089,1764.1071777,-1568.7672119,1742.8266602,0.0000000,0.0000000,34.0000000); //
	CreateDynamicObject(2173,1758.0897217,-1572.2486572,1741.5235596,0.0000000,0.0000000,216.0000000); //
	CreateDynamicObject(2173,1760.3353271,-1570.6602783,1741.5235596,0.0000000,0.0000000,215.9967041); //
	CreateDynamicObject(2173,1762.6174316,-1569.1575928,1741.5235596,0.0000000,0.0000000,215.2467041); //
	CreateDynamicObject(2173,1762.4538574,-1570.6696777,1741.5235596,0.0000000,0.0000000,35.4941406); //
	CreateDynamicObject(2173,1760.2321777,-1572.2497559,1741.5235596,0.0000000,0.0000000,35.4913330); //
	CreateDynamicObject(2173,1757.9882812,-1573.8432617,1741.5235596,0.0000000,0.0000000,35.4913330); //
	CreateDynamicObject(1671,1763.5197754,-1571.3277588,1741.9614258,0.0000000,0.0000000,218.0000000); //
	CreateDynamicObject(1671,1761.2962646,-1572.9020996,1741.9614258,0.0000000,0.0000000,215.4962311); //
	CreateDynamicObject(1671,1759.0114746,-1574.5195312,1741.9614258,0.0000000,0.0000000,215.4913330); //
	CreateDynamicObject(1671,1757.0166016,-1571.6016846,1741.9614258,0.0000000,0.0000000,31.4913330); //
	CreateDynamicObject(1671,1759.2440186,-1569.9787598,1741.9614258,0.0000000,0.0000000,35.4868164); //
	CreateDynamicObject(1671,1761.5261230,-1568.5364990,1741.9614258,0.0000000,0.0000000,35.4858398); //
	CreateDynamicObject(2187,1760.5855713,-1570.3542480,1741.5122070,0.0000000,0.0000000,214.0000000); //
	CreateDynamicObject(2187,1760.5849609,-1570.3535156,1742.2379150,0.0000000,0.0000000,213.9971924); //
	CreateDynamicObject(2187,1760.8128662,-1569.0754395,1742.2379150,0.0000000,0.0000000,36.4971619); //
	CreateDynamicObject(2187,1760.8125000,-1569.0751953,1741.4381104,0.0000000,0.0000000,36.4965820); //
	CreateDynamicObject(2187,1758.2767334,-1571.8021240,1742.2379150,0.0000000,0.0000000,213.9971924); //
	CreateDynamicObject(2187,1758.2763672,-1571.8017578,1741.4121094,0.0000000,0.0000000,213.9971924); //
	CreateDynamicObject(2187,1758.5090332,-1570.4970703,1741.4121094,0.0000000,0.0000000,34.2471619); //
	CreateDynamicObject(2187,1758.5087891,-1570.4970703,1742.2366943,0.0000000,0.0000000,34.2443848); //
	CreateDynamicObject(2187,1762.1694336,-1571.0229492,1741.5061035,0.0000000,0.0000000,34.0000000); //
	CreateDynamicObject(2187,1762.1689453,-1571.0224609,1742.2318115,0.0000000,0.0000000,33.9971924); //
	CreateDynamicObject(2187,1759.9272461,-1572.5755615,1742.2318115,0.0000000,0.0000000,33.9971924); //
	CreateDynamicObject(2187,1759.9267578,-1572.5751953,1741.4060059,0.0000000,0.0000000,33.9971924); //
	CreateDynamicObject(2187,1759.6702881,-1573.8476562,1742.2379150,0.0000000,0.0000000,213.9971924); //
	CreateDynamicObject(2187,1759.6699219,-1573.8476562,1741.4621582,0.0000000,0.0000000,213.9971924); //
	CreateDynamicObject(2187,1761.9296875,-1572.3258057,1742.2379150,0.0000000,0.0000000,213.9971924); //
	CreateDynamicObject(2187,1761.9296875,-1572.3251953,1741.4121094,0.0000000,0.0000000,213.9971924); //
	CreateDynamicObject(8661,1766.4588623,-1559.2015381,1751.2675781,271.2688599,168.6280518,259.3778076); //
	CreateDynamicObject(8661,1766.9233398,-1559.1123047,1751.2675781,271.2634583,168.6236572,78.8761292); //
	CreateDynamicObject(2136,1767.3325195,-1569.9263916,1741.4822998,0.0000000,0.0000000,90.0000000); //
	CreateDynamicObject(2135,1767.3481445,-1570.8608398,1741.4837646,0.0000000,0.0000000,90.0000000); //
	CreateDynamicObject(2828,1778.9792480,-1573.7318115,1734.8795166,0.0000000,0.0000000,326.0000000); //
	CreateDynamicObject(2139,1767.3896484,-1571.8475342,1741.4835205,0.0000000,0.0000000,90.0000000); //
	CreateDynamicObject(2139,1767.3603516,-1567.9683838,1741.4835205,0.0000000,0.0000000,90.0000000); //
	CreateDynamicObject(2140,1767.4088135,-1572.8157959,1741.4838867,0.0000000,0.0000000,87.0000000); //
	CreateDynamicObject(2164,1776.0461426,-1567.0831299,1741.4696045,0.0000000,0.0000000,359.2500000); //
	CreateDynamicObject(2163,1774.2558594,-1567.1708984,1741.5002441,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(2208,1767.0778809,-1585.1064453,1741.5029297,0.0000000,0.0000000,91.5000000); //
	CreateDynamicObject(2208,1767.0032959,-1582.4022217,1741.5029297,0.0000000,0.0000000,153.4996338); //
	CreateDynamicObject(2208,1764.4655762,-1581.1422119,1741.5029297,0.0000000,0.0000000,153.4954834); //
	CreateDynamicObject(2208,1762.1202393,-1579.9860840,1741.5029297,0.0000000,0.0000000,183.4954834); //
	CreateDynamicObject(2208,1759.5886230,-1580.1437988,1741.5029297,0.0000000,0.0000000,183.4936523); //
	CreateDynamicObject(2637,1770.8051758,-1570.4884033,1741.8735352,0.0000000,0.0000000,90.0000000); //
	CreateDynamicObject(2637,1770.8111572,-1572.3884277,1741.8735352,0.0000000,0.0000000,90.0000000); //
	CreateDynamicObject(2776,1771.9637451,-1572.6562500,1741.9592285,0.0000000,0.0000000,272.0000000); //
	CreateDynamicObject(2776,1771.9259033,-1571.4854736,1741.9592285,0.0000000,0.0000000,271.9995117); //
	CreateDynamicObject(2776,1771.9973145,-1570.2535400,1741.9592285,0.0000000,0.0000000,271.9995117); //
	CreateDynamicObject(2776,1770.2476807,-1572.9060059,1741.9592285,0.0000000,0.0000000,91.9995117); //
	CreateDynamicObject(2776,1769.6883545,-1571.5091553,1741.9592285,0.0000000,0.0000000,91.9940186); //
	CreateDynamicObject(2776,1769.7230225,-1570.2498779,1741.9592285,0.0000000,0.0000000,91.9940186); //
	CreateDynamicObject(2776,1770.0451660,-1567.3060303,1741.9592285,0.0000000,0.0000000,1.7440186); //
	CreateDynamicObject(2776,1770.0449219,-1567.3056641,1742.1093750,0.0000000,0.0000000,1.7413330); //
	CreateDynamicObject(2776,1770.0449219,-1567.3056641,1742.2845459,0.0000000,0.0000000,1.7413330); //
	CreateDynamicObject(1713,1777.7474365,-1571.4503174,1741.4388428,0.0000000,0.0000000,272.0000000); //
	CreateDynamicObject(1713,1776.7827148,-1574.2749023,1741.4388428,0.0000000,0.0000000,178.9995117); //
	CreateDynamicObject(3962,1775.3117676,-1571.7060547,1741.5023193,0.0392456,90.4985352,359.7497253); //
	CreateDynamicObject(8661,1778.1085205,-1554.0021973,1751.2926025,90.0000000,179.9945068,90.9919434); //
	CreateDynamicObject(1429,1774.6732178,-1567.4151611,1742.6916504,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(2964,1773.1020508,-1578.4581299,1741.4648438,0.0000000,0.0000000,180.0000000); //
	CreateDynamicObject(2008,1756.0985107,-1583.4029541,1741.5482178,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(2008,1759.1009521,-1583.3901367,1741.5482178,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(2008,1762.0266113,-1583.3752441,1741.5482178,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(2190,1760.8291016,-1580.0938721,1742.3681641,0.0000000,0.0000000,342.0000000); //
	CreateDynamicObject(2190,1767.2740479,-1584.0732422,1742.3681641,0.0000000,0.0000000,259.9989014); //
	CreateDynamicObject(2776,1762.8975830,-1584.4860840,1742.0198975,0.0000000,0.0000000,184.0000000); //
	CreateDynamicObject(2776,1759.9997559,-1584.6210938,1742.0198975,0.0000000,0.0000000,183.9990234); //
	CreateDynamicObject(2776,1756.9647217,-1584.6823730,1742.0198975,0.0000000,0.0000000,183.9990234); //
	CreateDynamicObject(2776,1760.1267090,-1581.2440186,1742.0198975,0.0000000,0.0000000,135.9990234); //
	CreateDynamicObject(2776,1765.6030273,-1584.4368896,1742.0198975,0.0000000,0.0000000,147.9942627); //
	CreateDynamicObject(2602,1758.9934082,-1561.9260254,1734.4664307,0.0000000,0.0000000,268.0000000); //
	CreateDynamicObject(2602,1763.2186279,-1561.8996582,1734.4664307,0.0000000,0.0000000,267.9949951); //
	CreateDynamicObject(2602,1767.5178223,-1561.8721924,1734.4664307,0.0000000,0.0000000,267.9949951); //
	CreateDynamicObject(2602,1771.8062744,-1561.8575439,1734.4664307,0.0000000,0.0000000,267.9949951); //
	CreateDynamicObject(2602,1776.0793457,-1561.9962158,1734.4664307,0.0000000,0.0000000,267.9949951); //
	CreateDynamicObject(2602,1780.0523682,-1561.7204590,1734.4664307,0.0000000,0.0000000,267.9949951); //
	CreateDynamicObject(2602,1780.1115723,-1582.5888672,1734.4664307,0.0000000,0.0000000,267.9949951); //
	CreateDynamicObject(2602,1775.8510742,-1583.1767578,1734.4664307,0.0000000,0.0000000,267.9949951); //
	CreateDynamicObject(2602,1771.5657959,-1583.7680664,1734.4664307,0.0000000,0.0000000,267.9949951); //
	CreateDynamicObject(2602,1767.3300781,-1584.3520508,1734.4664307,0.0000000,0.0000000,267.9949951); //
	CreateDynamicObject(2602,1762.9997559,-1584.0653076,1734.4664307,0.0000000,0.0000000,267.9949951); //
	CreateDynamicObject(2602,1758.8037109,-1584.3908691,1734.4664307,0.0000000,0.0000000,267.9949951); //
	CreateDynamicObject(1800,1756.0372314,-1585.6010742,1733.9429932,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(1800,1759.9868164,-1585.6198730,1733.9429932,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(1800,1764.2355957,-1585.6398926,1733.9429932,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(1800,1768.4360352,-1585.6601562,1733.9429932,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(1800,1772.6612549,-1585.6807861,1733.9429932,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(1800,1776.9354248,-1585.7015381,1733.9429932,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(1800,1777.1528320,-1565.1075439,1733.9429932,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(1800,1772.9020996,-1565.1015625,1733.9429932,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(1800,1768.6270752,-1565.1192627,1733.9429932,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(1800,1764.3767090,-1565.1132812,1733.9429932,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(1800,1760.1014404,-1565.1063232,1733.9429932,0.0000000,0.0000000,0.0000000); //
	CreateDynamicObject(1800,1756.1010742,-1565.0988770,1733.9429932,0.0000000,0.0000000,0.0000000); //
	return 1;
}

//=================================================
