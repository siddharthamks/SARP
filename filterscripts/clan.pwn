/*
		  X337 SIMPLE GANG SYSTEM
	Required Plugins : sscanf, mysql R39-2
*/
#include <a_samp> // SA-MP Team
#include <easy-mysql> // BlueG
#include <sscanf2> // Y-Less
#include <YSI\y_iterate> // Y-Less
#include <YSI\y_areas> // Y-Less
#include <zcmd> // Zeex

/*
							DATABASE CONNECTION
	You must define database connection below and recompile this filterscript
*/
#define HOSTNAME		"localhost"
#define USERNAME		"root"
#define PASSWORD		"sidmks.."
#define DATABASENAME	"clan"
/*
	-------------------------------------------------------------------------
*/


#define AUTOSAVE					30 // Save Player, Gangs, Zones data automatically! (In - Minutes);
#define MAX_ZONES					100 // Maximum Gang Zone
#define MAX_GANGS					100 // Maximum Gang
#define CAPTURE_TIME				60 // Capture Time
#define LOCKED_MINUTES				10
#define DIALOG_UNUSED				1337 // Dialog ID
#define DEFAULT_ZONE_COLOR			"000000AA" // Default hex colour for gang zone
#define REQUIRED_SCORE				9999999 // Required score to make a new gang
#define MAX_GANG_MEMBER				8 // Maximum gang member
#undef 	MAX_PLAYERS
	#define MAX_PLAYERS				50 // MAX_PLAYERS
#define DIALOG_SAVEZONE				DIALOG_UNUSED+1
#define DIALOG_CREATEGANG			DIALOG_UNUSED+2
#define DIALOG_GANGTAG				DIALOG_UNUSED+3
#define DIALOG_GANGCOLOUR			DIALOG_UNUSED+4
#define DIALOG_HEXCOLOUR			DIALOG_UNUSED+5
#define DIALOG_CREATEGANG_CONFIRM	DIALOG_UNUSED+6
#define DIALOG_GCP					DIALOG_UNUSED+7
#define strcpy(%0,%1) \
	strcat((%0[0] = '\0', %0), %1)
#define GANG_MEMBER					1
#define GANG_STAFF					2
#define GANG_LEADER					3

enum _gangzone
{
	ZoneID,
	Float:ZoneMinPos[2],
	Float:ZoneMaxPos[2],
	ZoneOwner,
	ZoneName[50],
	ZoneHolder,
	ZoneArea,
	ZoneLocked,
	bool:ZoneStatus,
	ZoneTimer
}
enum _player
{
	PlayerID,
	bool:CreatingZone,
	PlayerText:TDZone[2],
	PlayerGang,
	PlayerStatus,
	GangRequest,
	PlayerText:CaptureTD[2]
}
enum _gang
{
	GangID,
	GangColor[7],
	GangName[30],
	GangTag[4],
	GangScore,
	CurrentZone,
	GangTimer
}

new Player[MAX_PLAYERS][_player],
GangZone[MAX_ZONES][_gangzone],
Gang[MAX_GANGS][_gang],
Iterator:GangZones<MAX_ZONES>,
Iterator:Gangs<MAX_GANGS>,
Float:MinPos[MAX_PLAYERS][2],
Float:MaxPos[MAX_PLAYERS][2],
PlayerZone[MAX_PLAYERS],
TempGangName[MAX_PLAYERS][30],
TempGangTag[MAX_PLAYERS][4],
TempGangColour[MAX_PLAYERS][7],
connection,
AutoSaveTimer;

stock bool:CheckGang(gangid)
{
	new total = 0, query[128];
	mysql_format(connection, query, sizeof(query), "SELECT count(*) AS `total` FROM `member` WHERE `gang` = %d", Gang[gangid][GangID]);
	mysql_query(connection, query, true);
	total = (cache_num_rows() > 0) ? cache_get_field_content_int(0, "total") : 0;
	return (total >= MAX_GANG_MEMBER) ? false : true;
}

stock IsAlpha(const string[])
{
	for(new i = 0; i < strlen(string); i++)
	{
		if(string[i] == 45 || (string[i] >= 48 && string[i] <= 57) || (string[i] >= 65 && string[i] <= 90) || (string[i] >= 97 && string[i] <= 122))
			continue;

		return false;
	}
	return true;
}

stock HexToInt(string[]) // DracoBlue
{
	if (string[0] == 0) return 0;
	new i, cur=1, res = 0;
	for (i=strlen(string);i>0;i--) {
		if (string[i-1]<58) res=res+cur*(string[i-1]-48); else res=res+cur*(string[i-1]-65+10);

		cur=cur*16;
	}
	return res;
}

stock GetGangID(id)
{
	foreach(new i : Gangs)
		if(Gang[i][GangID] == id)
			return i;
	return -1;
}

stock GetID(const name[])
{
	foreach(new i : Player)
	{
		if(!strcmp(name, Name(i)))
			return i;
	}
	return -1;
}

SaveStats(playerid)
{
	new query[128], name[MAX_PLAYER_NAME], i = Player[playerid][PlayerGang];
	GetPlayerName(playerid, name, MAX_PLAYER_NAME);
	if(Iter_Contains(Gangs, i) && i != -1)
		mysql_format(connection, query, sizeof(query), "UPDATE `member` SET `gang` = %d, `status` = %d, `name` = '%e' WHERE `id` = '%d'", Gang[i][GangID], Player[playerid][PlayerStatus], name, Player[playerid][PlayerID]);
	else
		mysql_format(connection, query, sizeof(query), "UPDATE `member` SET `gang` = -1, `name` = '%e' WHERE `id` = %d", name, Player[playerid][PlayerID]);
	mysql_query(connection, query, false);
	return 1;
}

SaveGang(i)
{
	new query[128];
	mysql_format(connection, query, sizeof(query), "UPDATE `gang` SET `color` = '%e', `score` = %d WHERE `id` = '%d'", Gang[i][GangColor], Gang[i][GangScore], Gang[i][GangID]);
	mysql_query(connection, query, false);
	return 1;
}

SaveZone(i)
{
	if(GangZone[i][ZoneOwner] != -1 && Iter_Contains(Gangs, GangZone[i][ZoneOwner]))
	{
		new query[128];
		mysql_format(connection, query, sizeof(query), "UPDATE `zone` SET `owner` = '%d' WHERE `id` = '%d'", Gang[GangZone[i][ZoneOwner]][GangID], GangZone[i][ZoneID]);
		mysql_query(connection, query, false);
	}
	return 1;
}

LoadPlayerGang(playerid)
{
	Player[playerid][PlayerGang] = -1;
	Player[playerid][PlayerStatus] = GANG_MEMBER;
	Player[playerid][GangRequest] = -1;
	new name[MAX_PLAYER_NAME], query[128];
	GetPlayerName(playerid, name, MAX_PLAYER_NAME);
	mysql_format(connection, query, sizeof(query), "SELECT * FROM `member` WHERE `name` = '%e'", name);
	mysql_query(connection, query, true);
	new count = cache_num_rows();
	if(count > 0)
	{
		new id = cache_get_field_content_int(0, "gang");
		foreach(new i : Gangs)
		{
			if(Gang[i][GangID] == id)
			{
				Player[playerid][PlayerGang] = i;
				break;
			}
		}
		Player[playerid][PlayerStatus] = cache_get_field_content_int(0, "status");
		Player[playerid][PlayerID] = cache_get_field_content_int(0, "id");
	}
	else
	{
		mysql_format(connection, query, sizeof(query), "INSERT INTO `member`(`name`) VALUES ('%e')", name);
		mysql_query(connection, query, true);
		Player[playerid][PlayerID] = cache_insert_id();
	}
	return 1;
}

SendGangMessage(i, msg[])
{
	foreach(new p : Player)
	{
		if(i == Player[p][PlayerGang])
			SendClientMessage(p, -1, msg);
	}
	return 1;
}

stock Name(playerid)
{
	new name[MAX_PLAYER_NAME];
	GetPlayerName(playerid, name, MAX_PLAYER_NAME);
	return name;
}

public OnFilterScriptInit()
{
	print("\n\n\n========================================================");
	print("||                 X-Gang System by X337               ||");
	connection = mysql_connect(HOSTNAME, USERNAME, DATABASENAME, PASSWORD);
	if(mysql_errno(connection) != 0)
	{
		print("\n++++++++++++++++++    WARNING    ++++++++++++++++++++++\n");
		print("X-Gang System Filterscript failed to connect to database !\n");
		print("++++++++++++++++++    WARNING    ++++++++++++++++++++++\n");
		SendRconCommand("unloadfs X-Gang");
	}
	else
	{
		mysql_log(LOG_ERROR | LOG_WARNING, LOG_TYPE_HTML);
		print("||           Succesfully connected to database !       ||");
		mysql_query(connection, "SELECT * FROM `zone`", true);
		new count = cache_num_rows(), TempString[56], time = GetTickCount(), i;
		for(new z = 0; z < count; z++)
		{
			i = Iter_Free(GangZones);
			GangZone[i][ZoneMinPos][0] = cache_get_field_content_float(z, "minx");
			GangZone[i][ZoneMinPos][1] = cache_get_field_content_float(z, "miny");
			GangZone[i][ZoneMaxPos][0] = cache_get_field_content_float(z, "maxx");
			GangZone[i][ZoneMaxPos][1] = cache_get_field_content_float(z, "maxy");
			GangZone[i][ZoneOwner]	= GetGangID(cache_get_field_content_int(z, "owner"));
			GangZone[i][ZoneID]	= cache_get_field_content_int(z, "id");
			cache_get_field_content(z, "name", TempString);
			format(GangZone[i][ZoneName], 50, "%s", TempString);
			GangZone[i][ZoneArea] = Area_AddBox(GangZone[i][ZoneMinPos][0], GangZone[i][ZoneMinPos][1], GangZone[i][ZoneMaxPos][0], GangZone[i][ZoneMaxPos][1]);
			GangZone[i][ZoneHolder] = GangZoneCreate(GangZone[i][ZoneMinPos][0], GangZone[i][ZoneMinPos][1], GangZone[i][ZoneMaxPos][0], GangZone[i][ZoneMaxPos][1]);
			GangZone[i][ZoneLocked] = 0;
			GangZone[i][ZoneStatus] = false;
			Iter_Add(GangZones, i);
		}
		printf("||         %d Zone(s) Succesfully Loaded!!! (%d ms)     ||", count, (GetTickCount() - time));
		mysql_query(connection, "SELECT * FROM `gang`", true);
		count = cache_num_rows(), time = GetTickCount();
		for(new z = 0; z < count; z++)
		{
			i = Iter_Free(Gangs);
			Gang[i][GangID] = cache_get_field_content_int(z, "id");
			Gang[i][GangScore] = cache_get_field_content_int(z, "score");
			Gang[i][CurrentZone] = -1;
			cache_get_field_content(z, "name", TempString);
			format(Gang[i][GangName], 30, "%s", TempString);
			cache_get_field_content(z, "color", TempString);
			format(Gang[i][GangColor], 7, "%s", TempString);
			cache_get_field_content(z, "tag", TempString);
			format(Gang[i][GangTag], 4, "%s", TempString);
			Iter_Add(Gangs, i);
		}
		printf("||         %d Gang(s) Succesfully Loaded!!! (%d ms)     ||", count, (GetTickCount() - time));
		print("========================================================");
		foreach(new p : Player)
		{
			CallLocalFunction("OnPlayerConnect", "d", p);
		}
		AutoSaveTimer = SetTimer("AutoSave", AUTOSAVE * 60000, true);
	}
	return 1;
}

public OnFilterScriptExit()
{
	AutoSave();
	foreach(new i : GangZones)
	{
		GangZoneDestroy(GangZone[i][ZoneHolder]);
		Area_Delete(GangZone[i][ZoneArea]);
	}
	Iter_Clear(GangZones);
	foreach(new i : Player)
	{
		PlayerTextDrawHide(i, Player[i][TDZone][0]);
		PlayerTextDrawHide(i, Player[i][TDZone][1]);
	}
	KillTimer(AutoSaveTimer);
	print("X-Gang System Filterscript unloaded!\n");
	return 1;
}

COMMAND:creategang(playerid, params[])
{
	if(GetPlayerScore(playerid) >= REQUIRED_SCORE)
	{
		if(Player[playerid][PlayerGang] == -1)
			ShowPlayerDialog(playerid, DIALOG_CREATEGANG, DIALOG_STYLE_INPUT, "X337 Gang System - Gang Name", "Insert the gang name below :", "Submit", "Cancel");
		else
			SendClientMessage(playerid, -1, "{FF0000}You already in gang!");
	}
	else
	{
		new string[128];
		format(string, sizeof(string), "{FF0000}You need %d score to create a gang!", REQUIRED_SCORE);
		SendClientMessage(playerid, -1, string);
	}
	return 1;
}

COMMAND:gangcolor(playerid, params[])
{
	new i = Player[playerid][PlayerGang];
	if(i != -1)
	{
		new color[7];
		if(sscanf(params, "h", color) || strlen(params) != 6)
			SendClientMessage(playerid, -1, "{FF0000}Invalid hex color!");
		else
		{
			new msg[56];
			format(msg, sizeof(msg), "{%s}Your gang color has been changed!", params);
			SendClientMessage(playerid, -1, msg);
			format(Gang[i][GangColor], 7, "%s", params);
		}
	}
	else
		SendClientMessage(playerid, -1, "{FF0000}You must be a gang leader to use this command!");
	return 1;
}

COMMAND:changeleader(playerid, params[])
{
	if(Player[playerid][PlayerGang] != -1)
	{
		if(Player[playerid][PlayerStatus] == GANG_LEADER)
		{
			new id;
			if(sscanf(params, "u", id))
			{
				SendClientMessage(playerid, -1, "{FF0000}Usage : /changeleader <playerid>");
			}
			else
			{
				if(IsPlayerConnected(id))
				{
					if(Player[playerid][PlayerGang] == Player[id][PlayerGang])
					{
						Player[playerid][PlayerStatus] = GANG_MEMBER;
						Player[id][PlayerStatus] = GANG_LEADER;
						new msg[56];
						format(msg, sizeof(msg), "{FF0000}Succesfully promoted %s as new gang leader!", Name(id));
						SendClientMessage(playerid, -1, msg);
						SendClientMessage(id, -1, "{FF0000}You have been promoted as new gang leader!");
						SaveStats(id);
						SaveStats(playerid);
					}
					else
						SendClientMessage(playerid, -1, "{FF0000}That player isn't your gang member!");
				}
				else
					SendClientMessage(playerid, -1, "{FF0000}That player isn't connected!");
			}
		}
		else
			SendClientMessage(playerid, -1, "{FF0000}You must be a gang leader to use this command!");
	}
	else
		SendClientMessage(playerid, -1, "{FF0000}You must be a gang member to use this command!");
	return 1;
}

COMMAND:territory(playerid, params[])
{
	new msg[512], p;
	foreach(new i : GangZones)
	{
		p = GangZone[i][ZoneOwner];
		if(p == -1)
			format(msg, sizeof(msg), "%s{B7B7B7}%s (-)\n", msg, GangZone[i][ZoneName]);
		else
			format(msg, sizeof(msg), "%s{%s}%s (%s)\n", msg, Gang[p][GangColor], GangZone[i][ZoneName], Gang[p][GangName]);
	}
	ShowPlayerDialog(playerid, DIALOG_UNUSED, DIALOG_STYLE_MSGBOX, "Territory", msg, "Close", "");
	return 1;
}

COMMAND:gangmembers(playerid, params[])
{
	new i = Player[playerid][PlayerGang];
	if(i != -1)
	{
		new query[256];
		mysql_format(connection, query, sizeof(query), "SELECT * FROM `member` WHERE `gang` = %d", Gang[i][GangID]);
		mysql_query(connection, query, true);
		format(query, sizeof(query), "{FFFFFF}");
		new count = cache_num_rows();
		if(count > 0)
		{
			new TempString[MAX_PLAYER_NAME], tempid;
			for(new r = 0; r < count; r++)
			{
				cache_get_field_content(r, "name", TempString);
				tempid = GetID(TempString);
				format(query, sizeof(query), "%s%d. %s ", query, (r+1), TempString);
				if(IsPlayerConnected(tempid))
					strcat(query, "{FE9A2E}(ONLINE) ");
				else
					strcat(query, "{FF0000}(OFFLINE) ");
				if(cache_get_field_content_int(r, "status") == GANG_LEADER)
					strcat(query, "{58D3F7} (LEADER) ");
				if(cache_get_field_content_int(r, "status") == GANG_STAFF)
					strcat(query, "{58D3F7} (STAFF) ");
				strcat(query, "\n{FFFFFF}");
			}
			ShowPlayerDialog(playerid, DIALOG_UNUSED, DIALOG_STYLE_MSGBOX, "Gang Members", query, "Close", "");
		}
	}
	else
		SendClientMessage(playerid, -1, "{FF0000}You must be a gang member to use this command!");
	return 1;
}

COMMAND:gcp(playerid, params[])
{
	new i = Player[playerid][PlayerGang];
	if(i != -1)
	{
		if(Iter_Contains(Gangs, i))
		{
			new msg[256];
			format(msg, sizeof(msg), "{FFFFFF}Gang Name : {%s}%s {FFFFFF}", Gang[i][GangColor], Gang[i][GangName]);
			format(msg, sizeof(msg), "%s\nGang Tag : [%s]", msg, Gang[i][GangTag]);
			format(msg, sizeof(msg), "%s\nGang Score : %d", msg, Gang[i][GangScore]);
			format(msg, sizeof(msg), "%s\n{B7B7B7}Gang Member", msg);
			format(msg, sizeof(msg), "%s\n{B7B7B7}Territory", msg);
			ShowPlayerDialog(playerid, DIALOG_GCP, DIALOG_STYLE_LIST, "Gang Control Panel", msg, "Chooose", "Cancel");
		}
	}
	else
		SendClientMessage(playerid, -1, "{FF0000}You must be a gang member to use this command!");
	return 1;
}

COMMAND:leavegang(playerid, params[])
{
	new i = Player[playerid][PlayerGang];
	if(i != -1)
	{
		if(Player[playerid][PlayerStatus] != GANG_LEADER)
		{
			new msg[56];
			format(msg, sizeof(msg), "{FF0000}%s left the gang!", Name(playerid));
			SendGangMessage(Player[playerid][PlayerGang], msg);
			Player[playerid][PlayerGang] = -1;
			SaveStats(playerid);
		}
		else
			SendClientMessage(playerid, -1, "{FF0000}Gang leader can't use this command!");
	}
	return 1;
}

COMMAND:disbandgang(playerid, params[])
{
	new i = Player[playerid][PlayerGang];
	if(i != -1)
	{
		if(Player[playerid][PlayerStatus] == GANG_LEADER)
		{
			if(Gang[i][CurrentZone] == -1)
			{
				new query[256];
				format(query, sizeof(query), "{FF0000}%s has disbanded the gang!", Name(playerid));
				SendGangMessage(i, query);
				mysql_format(connection, query, sizeof(query), "DELETE FROM `gang` WHERE `id` = %d", Gang[i][GangID]);
				mysql_query(connection, query, false);
				foreach(new p : Player)
				{
					if(Player[p][PlayerGang] == i)
					{
						Player[p][PlayerGang] = -1;
						Player[p][PlayerStatus] = GANG_MEMBER;
					}
				}
				mysql_format(connection, query, sizeof(query), "UPDATE `member` SET `gang` = -1, `status` = 1 WHERE `gang` = %d", Gang[i][GangID]);
				mysql_query(connection, query, false);
				Iter_Remove(Gangs, i);
				foreach(new p : GangZones)
				{
					if(GangZone[p][ZoneOwner] == i)
					{
						GangZone[p][ZoneOwner] = -1;
						GangZoneShowForAll(GangZone[p][ZoneHolder], HexToInt(DEFAULT_ZONE_COLOR));
					}
				}
			}
		}
		else
			SendClientMessage(playerid, -1, "{FF0000}You must be gang leader to use this command!!");
	}
	else
		SendClientMessage(playerid, -1, "{FF0000}You must be gang leader to use this command!!");
	return 1;
}

COMMAND:topgang(playerid, params[])
{
	new query[128];
	mysql_format(connection, query, sizeof(query), "SELECT * FROM `gang` ORDER BY `score` DESC LIMIT 20");
	mysql_query(connection, query, true);
	new ganglist[512], count = cache_num_rows(), TempColor[7], TempName[30];
	if(count != 0)
	{
		for(new i = 0; i < count; i++)
		{
			cache_get_field_content(i, "color", TempColor);
			cache_get_field_content(i, "name", TempName);
			format(ganglist, sizeof(ganglist), "%s%d. {%s}%s {FFFFFF}- Score : %d\n", ganglist, (i+1), TempColor, TempName, cache_get_field_content_int(i, "score"));
		}
		format(ganglist, sizeof(ganglist), "%s\n* This top list updated every %d minutes", ganglist, AUTOSAVE);
		ShowPlayerDialog(playerid, DIALOG_UNUSED, DIALOG_STYLE_MSGBOX, "Top Gangs", ganglist, "Close", "");
	}
	else
		SendClientMessage(playerid, -1, "{FF0000}There's no gangs present!");
	return 1;
}

COMMAND:gangrank(playerid, params[])
{
	new TempName[30];
	if(sscanf(params, "s[30]", TempName))
	{
		SendClientMessage(playerid, -1, "{FF0000}Usage : /gangrank <gang name>");
	}
	else
	{
		new query[512];
		mysql_format(connection, query, sizeof(query), "SELECT `rank` FROM (SELECT `name`,`score`, @current := @current + 1 as `rank` from `gang`, (select @current := 0) r order by `score` desc) z WHERE `name` = '%e'", TempName);
		mysql_query(connection, query, true);
		if(cache_num_rows() != 0)
		{
			new msg[56];
			format(msg, sizeof(msg), "{FF0000}%s - {FFFF00}Rank : %d", TempName, cache_get_field_content_int(0, "rank"));
			SendClientMessage(playerid, -1, msg);
		}
		else
			SendClientMessage(playerid, -1, "404! Gang name not found!");
	}
	return 1;
}

COMMAND:promotestaff(playerid, params[])
{
	if(Player[playerid][PlayerStatus] == GANG_LEADER)
	{
		new id;
		if(sscanf(params, "u", id))
		{
			SendClientMessage(playerid, -1, "{FF0000}Usage : /promotestaff <playerid>");
		}
		else
		{
			if(IsPlayerConnected(id))
			{
				if(Player[id][PlayerGang] == Player[playerid][PlayerGang])
				{
					if(id != playerid)
					{
						if(Player[id][PlayerStatus] != GANG_STAFF)
						{
							SendClientMessage(playerid, -1, "{FF0000}Succesfully promoted a gang staff!");
							SendClientMessage(id, -1, "{FF0000}You have been promoted as a gang staff!");
							Player[id][PlayerStatus] = GANG_STAFF;
							SaveStats(id);
						}
						else
							SendClientMessage(playerid, -1, "{FF0000}That player already a gang staff!");
					}
					else
						SendClientMessage(playerid, -1, "{FF0000}You can't promote yourself!");
				}
				else
					SendClientMessage(playerid, -1, "{FF0000}That player isn't your gang member!");
			}
			else
				SendClientMessage(playerid, -1, "{FF0000}That player isn't connected!");
		}
	}
	else
		SendClientMessage(playerid, -1, "{FF0000}You must be gang leader to use this command!!");
	return 1;
}

COMMAND:demotestaff(playerid, params[])
{
	if(Player[playerid][PlayerStatus] == GANG_LEADER)
	{
		new id;
		if(sscanf(params, "u", id))
		{
			SendClientMessage(playerid, -1, "{FF0000}Usage : /demotestaff <playerid>");
		}
		else
		{
			if(IsPlayerConnected(id))
			{
				if(Player[id][PlayerGang] == Player[playerid][PlayerGang])
				{
					if(id != playerid)
					{
						if(Player[id][PlayerStatus] == GANG_STAFF)
						{
							SendClientMessage(playerid, -1, "{FF0000}Succesfully promoted a gang staff!");
							SendClientMessage(id, -1, "{FF0000}You have been demoted from gang staff!");
							Player[id][PlayerStatus] = GANG_MEMBER;
							SaveStats(id);
						}
						else
							SendClientMessage(playerid, -1, "{FF0000}That player isn't a gang staff!");
					}
					else
						SendClientMessage(playerid, -1, "{FF0000}You can't demote yourself!");
				}
				else
					SendClientMessage(playerid, -1, "{FF0000}That player isn't your gang member!");
			}
			else
				SendClientMessage(playerid, -1, "{FF0000}That player isn't connected!");
		}
	}
	else
		SendClientMessage(playerid, -1, "{FF0000}You must be gang leader to use this command!!");
	return 1;
}

COMMAND:createzone(playerid, params[])
{
	if(IsPlayerAdmin(playerid))
	{
		if(GetPlayerState(playerid) == PLAYER_STATE_ONFOOT)
		{
			if(!Player[playerid][CreatingZone])
			{
				new Float:z;
				Player[playerid][CreatingZone] = true;
				new msg[128];
				format(msg, sizeof(msg), "Gangzone Mode! Use arrow keys to make the zone bigger or less");
				SendClientMessage(playerid, -1, msg);
				format(msg, sizeof(msg), "Using ~k~~PED_FIREWEAPON~ + Arrow keys you minus the height or width.");
				SendClientMessage(playerid, -1, msg);
				format(msg, sizeof(msg), "Press ~k~~VEHICLE_ENTER_EXIT~ when you are done!");
				SendClientMessage(playerid, -1, msg);
				GetPlayerPos(playerid, MinPos[playerid][0], MinPos[playerid][1], z);
				GetPlayerPos(playerid, MaxPos[playerid][0], MaxPos[playerid][1], z);
				TogglePlayerControllable(playerid, false);
			}
			else
				SendClientMessage(playerid, -1, "You already in create zone mode, /cancelzone to cancel");
		}
		else
			SendClientMessage(playerid, -1, "You must be onfoot to create gang zone");
	}
	else
		SendClientMessage(playerid, -1, "{FF0000}You must be RCON admin to use this command!");
	return 1;
}

COMMAND:ganginvite(playerid, params[])
{
	new p;
	if(Player[playerid][PlayerStatus] == GANG_LEADER && Player[playerid][PlayerGang] != -1)
	{
		if(sscanf(params, "d", p))
		{
			SendClientMessage(playerid, -1, "{FF0000}Usage : /ganginvite <playerid>");
		}
		else
		{
			if(IsPlayerConnected(p))
			{
				if(Player[p][PlayerGang] == -1)
				{
					if(CheckGang(Player[playerid][PlayerGang]))
					{
						new msg[128];
						format(msg, sizeof(msg), "%s want you to join %s gang! (/acceptgang)", Name(playerid), Gang[Player[playerid][PlayerGang]][GangName]);
						SendClientMessage(p, -1, msg);
						format(msg, sizeof(msg), "You have invited %s to join your gang!", Name(p));
						SendClientMessage(playerid, -1, msg);
						Player[p][GangRequest] = Player[playerid][PlayerGang];
					}
					else
						SendClientMessage(playerid, -1, "{FF0000}Your gang member is full!");
				}
				else
					SendClientMessage(playerid, -1, "{FF0000}That player already a gang member!");
			}
			else
				SendClientMessage(playerid, -1, "{FF0000}That player isn't connected!");
		}
	}
	else
		SendClientMessage(playerid, -1, "{FF0000}You must be a gang leader to use this command!");
	return 1;
}

COMMAND:acceptgang(playerid, params[])
{
	if(Player[playerid][PlayerGang] == -1)
	{
		if(Player[playerid][GangRequest] != -1)
		{
			if(Iter_Contains(Gangs, Player[playerid][GangRequest]))
			{
				if(CheckGang(Player[playerid][GangRequest]))
				{
					Player[playerid][PlayerGang] = Player[playerid][GangRequest];
					Player[playerid][GangRequest] = -1;
					Player[playerid][PlayerStatus] = GANG_MEMBER;
					new msg[56];
					format(msg, sizeof(msg), "%s has joined the gang!", Name(playerid));
					SendGangMessage(Player[playerid][PlayerGang], msg);
				}
			}
			else
				SendClientMessage(playerid, -1, "{FF0000}Invalid Session!");
		}
	}
	else
		SendClientMessage(playerid, -1, "{FF0000}You already inside a gang!");
	return 1;
}

COMMAND:g(playerid, params[])
{
	new i = Player[playerid][PlayerGang];
	if(i != -1)
	{
		new	msg[128];
		format(msg, sizeof(msg), "{%s}* %s(%d) {FFFFFF}: %s", Gang[i][GangColor], Name(playerid), playerid, params);
		SendGangMessage(Player[playerid][PlayerGang], msg);
	}
	else
		SendClientMessage(playerid, -1, "{FF0000}You must be a gang member to use this command!");
	return 1;
}

COMMAND:capture(playerid, params[])
{
	if(Player[playerid][PlayerGang] != -1)
	{
		if(Gang[Player[playerid][PlayerGang]][CurrentZone] == -1)
		{
			new bool:found = false, i, total = 0, area = Area_GetPlayerAreas(playerid, 0);
			foreach(i : GangZones)
			{
				if(area == GangZone[i][ZoneArea])
				{
					found = true;
					break;
				}
			}
			if(found)
			{
				if(!GangZone[i][ZoneStatus])
				{
					if(GangZone[i][ZoneOwner] != Player[playerid][PlayerGang])
					{
						new tick = GetTickCount() - GangZone[i][ZoneLocked], msg[128];
						if(tick > (60000 * LOCKED_MINUTES))
						{
							format(msg, sizeof(msg), "Capturing ~g~%s", GangZone[i][ZoneName]);
							foreach(new p : Player)
							{
								if(Player[p][PlayerGang] == Player[playerid][PlayerGang])
								{
									if(Area_GetPlayerAreas(p, 0) == area)
										total++;
									PlayerTextDrawSetString(p, Player[p][CaptureTD][0], msg);
									PlayerTextDrawSetString(p, Player[p][CaptureTD][1], "-");
									PlayerTextDrawShow(p, Player[p][CaptureTD][0]);
									PlayerTextDrawShow(p, Player[p][CaptureTD][1]);
									Gang[Player[playerid][PlayerGang]][GangTimer] = CAPTURE_TIME;
								}
							}
							format(msg, sizeof(msg), "{FE9A2E}** %s gang trying to capture %s zone with %d gang member!", Gang[Player[playerid][PlayerGang]][GangName], GangZone[i][ZoneName], total);
							SendClientMessageToAll(-1, msg);
							GangZone[i][ZoneStatus] = true;
							GangZone[i][ZoneTimer] = SetTimerEx("AttackZone", 1000, true, "dd", Player[playerid][PlayerGang], i);
							Gang[Player[playerid][PlayerGang]][CurrentZone] = i;
							GangZoneFlashForAll(GangZone[i][ZoneHolder], HexToInt("FF0000AA"));
							if(GangZone[i][ZoneOwner] != -1)
							{
								format(msg, sizeof(msg), "{FF0000}* ALERT!!! %s gang trying to capture your territory in %s", Gang[Player[playerid][PlayerGang]][GangName], GangZone[i][ZoneName]);
								SendGangMessage(GangZone[i][ZoneOwner], msg);
							}
						}
						else
						{
							format(msg, sizeof(msg), "{FF0000}This Zone is locked, please wait %.2f minute(s) to capture!", floatdiv(60000 * LOCKED_MINUTES - tick, 60 * 1000));
							SendClientMessage(playerid, -1, msg);
						}
					}
					else
						SendClientMessage(playerid, -1, "{FF0000}Your gang already owned this zone!");
				}
				else
					SendClientMessage(playerid, -1, "{FF0000}Someone is trying to capture this zone!");
			}
			else
				SendClientMessage(playerid, -1, "{FF0000}You must be in gang zone to use this command!");
		}
		else
			SendClientMessage(playerid, -1, "{FF0000}Your gang already started a war, please wait!");
	}
	else
		SendClientMessage(playerid, -1, "{FF0000}You must be a gang member to use this command!");
	return 1;
}

COMMAND:okickmember(playerid, params[])
{
	new TempName[MAX_PLAYER_NAME];
	if(sscanf(params, "s[24]", TempName))
	{
		SendClientMessage(playerid, -1, "{FF0000}Usage : /okickmember <member name>");
	}
	else
	{
		new query[256], i = Player[playerid][PlayerGang];
		mysql_format(connection, query, sizeof(query), "SELECT * FROM `member` WHERE `name` = '%e'", TempName);
		mysql_query(connection, query, true);
		if(cache_num_rows() != 0)
		{
			if(cache_get_field_content_int(0, "gang") == Gang[i][GangID])
			{
				if(cache_get_field_content_int(0, "id") != Player[playerid][PlayerID])
				{
					if(cache_get_field_content_int(0, "status") != GANG_LEADER)
					{
						mysql_format(connection, query, sizeof(query), "UPDATE `member` SET `gang` = -1, `status` = 1 WHERE `name` = '%e'", TempName);
						mysql_query(connection, query, false);
						format(query, sizeof(query), "{FF0000}%s has been kicked from gang!", TempName);
						SendGangMessage(i, query);
						new p = GetID(TempName);
						if(IsPlayerConnected(p))
						{
							SendClientMessage(p, -1, "{FF0000}You have been kicked from gang!");
							Player[p][PlayerGang] = -1;
							Player[p][PlayerStatus] = GANG_MEMBER;
						}
					}
					else
						SendClientMessage(playerid, -1, "{FF0000}You can't kick gang leader!");
				}
				else
					SendClientMessage(playerid, -1, "{FF0000}You can't kick yourself!");
			}
			else
				SendClientMessage(playerid, -1, "{FF0000}That player isn't in your gang!");
		}
		else
			SendClientMessage(playerid, -1, "{FF0000}404! Name not found!");
	}
	return 1;
}

COMMAND:kickmember(playerid, params[])
{
	new p;
	if(Player[playerid][PlayerStatus] != GANG_MEMBER && Player[playerid][PlayerGang] != -1)
	{
		if(sscanf(params, "d", p))
		{
			SendClientMessage(playerid, -1, "{FF0000}Usage : /kickmember <playerid>");
		}
		else
		{
			if(IsPlayerConnected(p))
			{
				if(Player[playerid][PlayerGang] == Player[p][PlayerGang])
				{
					if(playerid != p)
					{
						if(Player[p][PlayerStatus] != GANG_LEADER)
						{
							new msg[56], query[256];
							format(msg, sizeof(msg), "{FF0000}%s has been kicked from gang!", Name(p));
							SendGangMessage(Player[playerid][PlayerGang], msg);
							Player[p][PlayerGang] = -1;
							Player[p][PlayerStatus] = GANG_MEMBER;
							mysql_format(connection, query, sizeof(query), "UPDATE `member` SET `gang` = -1, `status` = 1 WHERE `id` = '%d'", Player[p][PlayerID]);
							mysql_query(connection, query, false);
						}
						else
							SendClientMessage(playerid, -1, "{FF0000}You can't kick gang leader!");
					}
					else
						SendClientMessage(playerid, -1, "{FF0000}You can't kick yourself!");
				}
				else
					SendClientMessage(playerid, -1, "{FF0000}That player isn't in your gang!");
			}
			else
				SendClientMessage(playerid, -1, "{FF0000}That player isn't connected!");
		}
	}
	else
		SendClientMessage(playerid, -1, "{FF0000}You must be a gang leader to use this command!");
	return 1;
}

public OnPlayerConnect(playerid)
{
	Player[playerid][CreatingZone] = false;
	Player[playerid][TDZone][0] = CreatePlayerTextDraw(playerid, 320.000000, 376.666290, "ZONE NAME");
	PlayerTextDrawLetterSize(playerid, Player[playerid][TDZone][0], 0.400000, 1.600000);
	PlayerTextDrawAlignment(playerid, Player[playerid][TDZone][0], 2);
	PlayerTextDrawColor(playerid, Player[playerid][TDZone][0], -1);
	PlayerTextDrawSetShadow(playerid, Player[playerid][TDZone][0], 0);
	PlayerTextDrawSetOutline(playerid, Player[playerid][TDZone][0], 1);
	PlayerTextDrawBackgroundColor(playerid, Player[playerid][TDZone][0], 255);
	PlayerTextDrawFont(playerid, Player[playerid][TDZone][0], 3);
	PlayerTextDrawSetProportional(playerid, Player[playerid][TDZone][0], 1);
	PlayerTextDrawSetShadow(playerid, Player[playerid][TDZone][0], 0);

	Player[playerid][TDZone][1] = CreatePlayerTextDraw(playerid, 318.000000, 391.599609, "Owned By : ~r~Unowned");
	PlayerTextDrawLetterSize(playerid, Player[playerid][TDZone][1], 0.264999, 1.310666);
	PlayerTextDrawAlignment(playerid, Player[playerid][TDZone][1], 2);
	PlayerTextDrawColor(playerid, Player[playerid][TDZone][1], -1);
	PlayerTextDrawSetShadow(playerid, Player[playerid][TDZone][1], 1);
	PlayerTextDrawSetOutline(playerid, Player[playerid][TDZone][1], 0);
	PlayerTextDrawBackgroundColor(playerid, Player[playerid][TDZone][1], 255);
	PlayerTextDrawFont(playerid, Player[playerid][TDZone][1], 1);
	PlayerTextDrawSetProportional(playerid, Player[playerid][TDZone][1], 1);
	PlayerTextDrawSetShadow(playerid, Player[playerid][TDZone][1], 1);

	Player[playerid][CaptureTD][0] = CreatePlayerTextDraw(playerid, 633.000000, 358.000030, "");
	PlayerTextDrawLetterSize(playerid, Player[playerid][CaptureTD][0], 0.323000, 1.357333);
	PlayerTextDrawAlignment(playerid, Player[playerid][CaptureTD][0], 3);
	PlayerTextDrawColor(playerid, Player[playerid][CaptureTD][0], -1);
	PlayerTextDrawSetShadow(playerid, Player[playerid][CaptureTD][0], 1);
	PlayerTextDrawSetOutline(playerid, Player[playerid][CaptureTD][0], 0);
	PlayerTextDrawBackgroundColor(playerid, Player[playerid][CaptureTD][0], 255);
	PlayerTextDrawFont(playerid, Player[playerid][CaptureTD][0], 1);
	PlayerTextDrawSetProportional(playerid, Player[playerid][CaptureTD][0], 1);
	PlayerTextDrawSetShadow(playerid, Player[playerid][CaptureTD][0], 1);

	Player[playerid][CaptureTD][1] = CreatePlayerTextDraw(playerid, 633.000000, 343.999938, "00:00");
	PlayerTextDrawLetterSize(playerid, Player[playerid][CaptureTD][1], 0.400000, 1.600000);
	PlayerTextDrawAlignment(playerid, Player[playerid][CaptureTD][1], 3);
	PlayerTextDrawColor(playerid, Player[playerid][CaptureTD][1], -1);
	PlayerTextDrawSetShadow(playerid, Player[playerid][CaptureTD][1], 0);
	PlayerTextDrawSetOutline(playerid, Player[playerid][CaptureTD][1], 1);
	PlayerTextDrawBackgroundColor(playerid, Player[playerid][CaptureTD][1], 255);
	PlayerTextDrawFont(playerid, Player[playerid][CaptureTD][1], 3);
	PlayerTextDrawSetProportional(playerid, Player[playerid][CaptureTD][1], 1);
	PlayerTextDrawSetShadow(playerid, Player[playerid][CaptureTD][1], 0);

	LoadPlayerGang(playerid);
	foreach(new i : GangZones)
	{
		if(GangZone[i][ZoneOwner] == -1)
			GangZoneShowForPlayer(playerid, GangZone[i][ZoneHolder], HexToInt(DEFAULT_ZONE_COLOR));
		else
		{
			new colour[9];
			format(colour, 9, "%s50", Gang[GangZone[i][ZoneOwner]][GangColor]);
			GangZoneShowForPlayer(playerid, GangZone[i][ZoneHolder], HexToInt(colour));
		}
	}
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	new i = Player[playerid][PlayerGang], msg[56];
	SaveStats(playerid);
	if(Iter_Contains(Gangs, i) && i != -1)
	{
		new zone = Gang[i][CurrentZone], total = -1;
		if(zone != -1)
		{
			total = 0;
			foreach(new p : Player)
			{
				if(Player[p][PlayerGang] == Player[playerid][PlayerGang])
				{
					if(Area_GetPlayerAreas(p, 0) == GangZone[zone][ZoneArea])
						total++;
				}
			}
		}
		if(total == 0)
		{
			format(msg, sizeof(msg), "{FF0000}** %s gang failed to capture %s zone!", Gang[Player[playerid][PlayerGang]][GangName], GangZone[zone][ZoneName]);
			SendClientMessageToAll(-1, msg);
			format(msg, sizeof(msg), "{FF0000}** %s zone will be locked for %d minutes!", GangZone[zone][ZoneName], LOCKED_MINUTES);
			SendClientMessageToAll(-1, msg);
			Gang[Player[playerid][PlayerGang]][CurrentZone] = -1;
			GangZone[zone][ZoneLocked] = GetTickCount();
			GangZone[zone][ZoneStatus] = false;
			GangZoneStopFlashForAll(GangZone[zone][ZoneHolder]);
		}
		format(msg, sizeof(msg), "%s has been logged out!", Name(playerid));
		SendGangMessage(i, msg);
	}
	return 1;
}

public OnPlayerUpdate(playerid) //RyDer
{
	if(Player[playerid][CreatingZone])
	{
		new Keys, UpDown, LeftRight;
		GetPlayerKeys(playerid, Keys, UpDown, LeftRight);
		TogglePlayerControllable(playerid, false);
		if(LeftRight == KEY_LEFT)
		{
			MinPos[playerid][0] -= 8.0;
			GangZoneDestroy(PlayerZone[playerid]);
			PlayerZone[playerid] = GangZoneCreate(MinPos[playerid][0], MinPos[playerid][1], MaxPos[playerid][0], MaxPos[playerid][1]);
			GangZoneShowForPlayer(playerid, PlayerZone[playerid], HexToInt("000000FF"));
		}
		else if(LeftRight & KEY_LEFT && Keys & KEY_FIRE)
		{
			MinPos[playerid][0] += 8.0;
			GangZoneDestroy(PlayerZone[playerid]);
			PlayerZone[playerid] = GangZoneCreate(MinPos[playerid][0], MinPos[playerid][1], MaxPos[playerid][0], MaxPos[playerid][1]);
			GangZoneShowForPlayer(playerid, PlayerZone[playerid], HexToInt("000000FF"));
		}
		else if(LeftRight == KEY_RIGHT)
		{
			MaxPos[playerid][0] += 8.0;
			GangZoneDestroy(PlayerZone[playerid]);
			PlayerZone[playerid] = GangZoneCreate(MinPos[playerid][0], MinPos[playerid][1], MaxPos[playerid][0], MaxPos[playerid][1]);
			GangZoneShowForPlayer(playerid, PlayerZone[playerid], HexToInt("000000FF"));
		}
		else if(LeftRight & KEY_RIGHT && Keys & KEY_FIRE)
		{
			MaxPos[playerid][0] -= 8.0;
			GangZoneDestroy(PlayerZone[playerid]);
			PlayerZone[playerid] = GangZoneCreate(MinPos[playerid][0], MinPos[playerid][1], MaxPos[playerid][0], MaxPos[playerid][1]);
			GangZoneShowForPlayer(playerid, PlayerZone[playerid], HexToInt("000000FF"));
		}
		else if(UpDown == KEY_UP)
		{
			MaxPos[playerid][1] += 8.0;
			GangZoneDestroy(PlayerZone[playerid]);
			PlayerZone[playerid] = GangZoneCreate(MinPos[playerid][0], MinPos[playerid][1], MaxPos[playerid][0], MaxPos[playerid][1]);
			GangZoneShowForPlayer(playerid, PlayerZone[playerid], HexToInt("000000FF"));
		}
		else if(UpDown & KEY_UP && Keys & KEY_FIRE)
		{
			MaxPos[playerid][1] -= 8.0;
			GangZoneDestroy(PlayerZone[playerid]);
			PlayerZone[playerid] = GangZoneCreate(MinPos[playerid][0], MinPos[playerid][1], MaxPos[playerid][0], MaxPos[playerid][1]);
			GangZoneShowForPlayer(playerid, PlayerZone[playerid], HexToInt("000000FF"));
		}
		else if(UpDown == KEY_DOWN)
		{
			MinPos[playerid][1] -= 8.0;
			GangZoneDestroy(PlayerZone[playerid]);
			PlayerZone[playerid] = GangZoneCreate(MinPos[playerid][0], MinPos[playerid][1], MaxPos[playerid][0], MaxPos[playerid][1]);
			GangZoneShowForPlayer(playerid, PlayerZone[playerid], HexToInt("000000FF"));
		}
		else if(UpDown & KEY_DOWN && Keys & KEY_FIRE)
		{
			MinPos[playerid][1] += 8.0;
			GangZoneDestroy(PlayerZone[playerid]);
			PlayerZone[playerid] = GangZoneCreate(MinPos[playerid][0], MinPos[playerid][1], MaxPos[playerid][0], MaxPos[playerid][1]);
			GangZoneShowForPlayer(playerid, PlayerZone[playerid], HexToInt("000000FF"));
		}
		else if(Keys & KEY_SECONDARY_ATTACK)
		{
			TogglePlayerControllable(playerid, true);
			Player[playerid][CreatingZone] = false;
			ShowPlayerDialog(playerid, DIALOG_SAVEZONE, DIALOG_STYLE_INPUT, "X337 Gang System", "Input gang zone name below, press \"Delete\" to delete current zone", "Save", "Delete");
		}
	}
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	if(Player[playerid][PlayerGang] != -1)
	{
		new zone = Gang[Player[playerid][PlayerGang]][CurrentZone], total = -1;
		if(zone != -1)
		{
			total = 0;
			foreach(new p : Player)
			{
				if(Player[p][PlayerGang] == Player[playerid][PlayerGang])
				{
					if(Area_GetPlayerAreas(p, 0) == GangZone[zone][ZoneArea])
						total++;
				}
			}
		}
		if(total == 0)
		{
			new msg[128];
			format(msg, sizeof(msg), "{FF0000}** %s gang failed to capture %s zone!", Gang[Player[playerid][PlayerGang]][GangName], GangZone[zone][ZoneName]);
			SendClientMessageToAll(-1, msg);
			format(msg, sizeof(msg), "{FF0000}** %s zone will be locked for %d minutes!", GangZone[zone][ZoneName], LOCKED_MINUTES);
			SendClientMessageToAll(-1, msg);
			Gang[Player[playerid][PlayerGang]][CurrentZone] = -1;
			GangZone[zone][ZoneLocked] = GetTickCount();
			GangZone[zone][ZoneStatus] = false;
			GangZoneStopFlashForAll(GangZone[zone][ZoneHolder]);
		}
	}
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	switch(dialogid)
	{
		case DIALOG_SAVEZONE:
		{
			if(response)
			{
				if(strlen(inputtext) < 3 || strlen(inputtext) > 50)
					ShowPlayerDialog(playerid, DIALOG_SAVEZONE, DIALOG_STYLE_INPUT, "X337 Gang System", "{FF0000}Gang zone name must be between 3 - 50 characters! \nInput gang zone name below, press \"Delete\" to delete current zone", "Save", "Delete");
				else
				{
					new query[256];
					mysql_format(connection, query, sizeof(query), "INSERT INTO `zone` (`minx`, `miny`, `maxx`, `maxy`, `name`) VALUES('%f', '%f', '%f', '%f', '%e')", MinPos[playerid][0], MinPos[playerid][1], MaxPos[playerid][0], MaxPos[playerid][1], inputtext);
					mysql_query(connection, query, true);
					GangZoneDestroy(PlayerZone[playerid]);
					new i = Iter_Free(GangZones);
					GangZone[i][ZoneMinPos][0] = MinPos[playerid][0];
					GangZone[i][ZoneMinPos][1] = MinPos[playerid][1];
					GangZone[i][ZoneMaxPos][0] = MaxPos[playerid][0];
					GangZone[i][ZoneMaxPos][1] = MaxPos[playerid][1];
					GangZone[i][ZoneOwner] = -1;
					format(GangZone[i][ZoneName], 50, "%s", inputtext);
					GangZone[i][ZoneID] = cache_insert_id();
					GangZone[i][ZoneArea] = Area_AddBox(MinPos[playerid][0], MinPos[playerid][1], MaxPos[playerid][0], MaxPos[playerid][1]);
					GangZone[i][ZoneHolder] = GangZoneCreate(MinPos[playerid][0], MinPos[playerid][1], MaxPos[playerid][0], MaxPos[playerid][1]);
					GangZone[i][ZoneLocked] = 0;
					GangZone[i][ZoneStatus] = false;
					GangZoneShowForAll(GangZone[i][ZoneHolder], HexToInt(DEFAULT_ZONE_COLOR));
					Iter_Add(GangZones, i);
				}
			}
			else
				GangZoneDestroy(PlayerZone[playerid]);
		}
		case DIALOG_CREATEGANG:
		{
			if(response)
			{
				if(strlen(inputtext) < 5 || strlen(inputtext) > 30)
				{
					ShowPlayerDialog(playerid, DIALOG_CREATEGANG, DIALOG_STYLE_INPUT, "X337 Gang System - Gang Name", "{FF0000}Gang name must be between 5 - 30 characters! \nInsert the gang name below :", "Submit", "Cancel");
				}
				else if(!IsAlpha(inputtext))
				{
					ShowPlayerDialog(playerid, DIALOG_CREATEGANG, DIALOG_STYLE_INPUT, "X337 Gang System - Gang Name", "{FF0000}Please insert only a-z,A-Z,0-9 character! \nInsert the gang name below :", "Submit", "Cancel");
				}
				else
				{
					strcpy(TempGangName[playerid], inputtext);
					ShowPlayerDialog(playerid, DIALOG_GANGTAG, DIALOG_STYLE_INPUT, "X337 Gang System - Gang Tag", "Insert the gang tag below :", "Submit", "Cancel");
				}
			}
		}
		case DIALOG_GANGTAG:
		{
			if(response)
			{
				if(strlen(inputtext) < 1 || strlen(inputtext) > 3)
				{
					ShowPlayerDialog(playerid, DIALOG_GANGTAG, DIALOG_STYLE_INPUT, "X337 Gang System - Gang Tag", "{FF0000}Gang tag must be between 1 - 3 character! \nInsert the gang tag below :", "Submit", "Cancel");
				}
				else if(!IsAlpha(inputtext))
				{
					ShowPlayerDialog(playerid, DIALOG_GANGTAG, DIALOG_STYLE_INPUT, "X337 Gang System - Gang Tag", "{FF0000}Please insert only a-z,A-Z,0-9 character! \nInsert the gang tag below :", "Submit", "Cancel");
				}
				else
				{
					strcpy(TempGangTag[playerid], inputtext);
					ShowPlayerDialog(playerid, DIALOG_GANGCOLOUR, DIALOG_STYLE_LIST, "X337 Gang System - Gang Colour",
					"{00FFFF}Aqua \n{000000}Black \n{0000FF}Blue \n{A52A2A}Brown \n{FF0000}Red \n{FFFFFF}Use HEX Colour", "Choose", "Cancel");
				}
			}
		}
		case DIALOG_GANGCOLOUR:
		{
			if(response)
			{
				switch(listitem)
				{
					case 0:
						strcpy(TempGangColour[playerid], "00FFFF");
					case 1:
						strcpy(TempGangColour[playerid], "000000");
					case 2:
						strcpy(TempGangColour[playerid], "0000FF");
					case 3:
						strcpy(TempGangColour[playerid], "A52A2A");
					case 4:
						strcpy(TempGangColour[playerid], "FF0000");
					case 5:
					{
						ShowPlayerDialog(playerid, DIALOG_HEXCOLOUR, DIALOG_STYLE_INPUT, "X337 Gang System - Hex Colour", "Enter hexadecimal colour below :", "Submit", "Back");
					}
				}
				if(listitem != 5)
				{
					new msg[128];
					format(msg, sizeof(msg), "Are you sure you want to make a gang? \
					\nGang Name : %s \
					\nGang Tag : [%s] \
					\nGang Colour : {%s}%s", TempGangName[playerid], TempGangTag[playerid], TempGangColour[playerid], TempGangColour[playerid]);
					ShowPlayerDialog(playerid, DIALOG_CREATEGANG_CONFIRM, DIALOG_STYLE_MSGBOX, "X337 Gang System - Create Gang", msg, "Sure", "Cancel");
				}
			}
		}
		case DIALOG_HEXCOLOUR:
		{
			if(response)
			{
				if(strlen(inputtext) != 6)
					ShowPlayerDialog(playerid, DIALOG_HEXCOLOUR, DIALOG_STYLE_INPUT, "X337 Gang System - Hex Colour", "{FF0000}Hex colour must be 6 character!\n{FFFFFF}Enter hexadecimal colour below :", "Submit", "Back");
				else
				{
					if(sscanf(inputtext, "h", TempGangColour[playerid]))
						ShowPlayerDialog(playerid, DIALOG_HEXCOLOUR, DIALOG_STYLE_INPUT, "X337 Gang System - Hex Colour", "{FF0000}Invalid HEX colour!\n{FFFFFF}Enter hexadecimal colour below :", "Submit", "Back");
					else
					{
						new msg[128];
						format(msg, sizeof(msg), "Are you sure you want to make a gang? \
						\nGang Name : %s \
						\nGang Tag : [%s] \
						\nGang Colour : {%s}%s", TempGangName[playerid], TempGangTag[playerid], TempGangColour[playerid], TempGangColour[playerid]);
						ShowPlayerDialog(playerid, DIALOG_CREATEGANG_CONFIRM, DIALOG_STYLE_MSGBOX, "X337 Gang System - Create Gang", msg, "Sure", "Cancel");
					}
				}
			}
			else
			{
				ShowPlayerDialog(playerid, DIALOG_GANGCOLOUR, DIALOG_STYLE_LIST, "X337 Gang System - Gang Colour",
				"{00FFFF}Aqua \n{000000}Black \n{0000FF}Blue \n{A52A2A}Brown \n{FF0000}Red \n{FFFFFF}Use HEX Colour", "Choose", "Cancel");
			}
		}
		case DIALOG_CREATEGANG_CONFIRM:
		{
			if(response)
			{
				new bool:found = false;
				foreach(new i : Gangs)
				{
					if(!strcmp(Gang[i][GangName], TempGangName[playerid], true))
					{
						found = true;
						SendClientMessage(playerid, -1, "{FF0000}Gang name already used!");
						break;
					}
					if(!strcmp(Gang[i][GangTag], TempGangTag[playerid], true))
					{
						found = true;
						SendClientMessage(playerid, -1, "{FF0000}Gang tag already used!");
						break;
					}
				}
				if(!found)
				{
					new query[256];
					mysql_format(connection, query, sizeof(query), "INSERT INTO `gang` (`name`, `color`, `tag`) VALUES('%e', '%e', '%e')", TempGangName[playerid], TempGangColour[playerid], TempGangTag[playerid]);
					mysql_query(connection, query, true);
					new i = Iter_Free(Gangs);
					strcpy(Gang[i][GangColor], TempGangColour[playerid]);
					Gang[i][GangID] = cache_insert_id();
					Gang[i][GangName] = TempGangName[playerid];
					Gang[i][GangScore] = 0;
					Gang[i][GangTag] = TempGangTag[playerid];
					Gang[i][CurrentZone] = -1;
					Player[playerid][PlayerGang] = i;
					Player[playerid][PlayerStatus] = GANG_LEADER;
					Iter_Add(Gangs, i);
					format(query, sizeof(query), "{%s}[%s]%s {FFFFFF}gang has been created!", TempGangColour[playerid], TempGangTag[playerid], TempGangName[playerid]);
					SendClientMessageToAll(-1, query);
					SaveStats(playerid);
				}
			}
		}
		case DIALOG_GCP:
		{
			if(response)
			{
				switch(listitem)
				{
					case 3:
						cmd_gangmembers(playerid, "");
					case 4:
						cmd_territory(playerid, "");
				}
			}
		}
	}
	return 1;
}

public OnPlayerEnterArea(playerid, areaid)
{
	foreach(new i : GangZones)
	{
		if(areaid == GangZone[i][ZoneArea])
		{
			PlayerTextDrawSetString(playerid, Player[playerid][TDZone][0], GangZone[i][ZoneName]);
			new msg[128];
			if(GangZone[i][ZoneOwner] == -1)
				format(msg, sizeof(msg), "Owned by : ~r~Unowned");
			else
				format(msg, sizeof(msg), "Owned by : ~r~%s", Gang[GangZone[i][ZoneOwner]][GangName]);
			PlayerTextDrawSetString(playerid, Player[playerid][TDZone][1], msg);
			PlayerTextDrawShow(playerid, Player[playerid][TDZone][0]);
			PlayerTextDrawShow(playerid, Player[playerid][TDZone][1]);
			return 1;
		}
	}
	return 1;
}

public OnPlayerLeaveArea(playerid, areaid)
{
	PlayerTextDrawHide(playerid, Player[playerid][TDZone][0]);
	PlayerTextDrawHide(playerid, Player[playerid][TDZone][1]);
	if(Player[playerid][PlayerGang] != -1)
	{
		new zone = Gang[Player[playerid][PlayerGang]][CurrentZone], total = -1;
		if(zone != -1)
		{
			total = 0;
			foreach(new p : Player)
			{
				if(Player[p][PlayerGang] == Player[playerid][PlayerGang])
				{
					if(Area_GetPlayerAreas(p, 0) == GangZone[zone][ZoneArea])
						total++;
				}
			}
		}
		if(total == 0)
		{
			new msg[128];
			format(msg, sizeof(msg), "{FF0000}** %s gang failed to capture %s zone!", Gang[Player[playerid][PlayerGang]][GangName], GangZone[zone][ZoneName]);
			SendClientMessageToAll(-1, msg);
			format(msg, sizeof(msg), "{FF0000}** %s zone will be locked for %d minutes!", GangZone[zone][ZoneName], LOCKED_MINUTES);
			SendClientMessageToAll(-1, msg);
			Gang[Player[playerid][PlayerGang]][CurrentZone] = -1;
			GangZone[zone][ZoneLocked] = GetTickCount();
			GangZone[zone][ZoneStatus] = false;
			GangZoneStopFlashForAll(GangZone[zone][ZoneHolder]);
		}
	}
	return 1;
}

forward AttackZone(gangid, zoneid);
public AttackZone(gangid, zoneid)
{
	if(Gang[gangid][CurrentZone] == zoneid && Iter_Contains(Gangs, gangid))
	{
		Gang[gangid][GangTimer]--;
		if(Gang[gangid][GangTimer] > 0)
		{
			new minutes = Gang[gangid][GangTimer] / 60, seconds = Gang[gangid][GangTimer] % 60, msg[10];
			format(msg, sizeof(msg), "%02d:%02d", minutes, seconds);
			foreach(new p : Player)
			{
				if(Player[p][PlayerGang] == gangid)
					PlayerTextDrawSetString(p, Player[p][CaptureTD][1], msg);
			}
		}
		else
		{
			KillTimer(GangZone[zoneid][ZoneTimer]);
			new msg[128];
			format(msg, sizeof(msg), "Owned by : ~r~%s", Gang[gangid][GangName]);
			foreach(new p : Player)
			{
				if(Player[p][PlayerGang] == gangid)
				{
					PlayerTextDrawHide(p, Player[p][CaptureTD][0]);
					PlayerTextDrawHide(p, Player[p][CaptureTD][1]);
				}
				if(Area_GetPlayerAreas(p, 0) == GangZone[zoneid][ZoneArea])
					PlayerTextDrawSetString(p, Player[p][TDZone][1], msg);

			}
			GangZoneStopFlashForAll(GangZone[zoneid][ZoneHolder]);
			new colour[9];
			format(colour, 9, "%s50", Gang[gangid][GangColor]);
			GangZoneShowForAll(GangZone[zoneid][ZoneHolder], HexToInt(colour));
			GangZone[zoneid][ZoneOwner] = gangid;
			format(msg, sizeof(msg), "{FF0000}** %s gang succesfully captured %s zone!", Gang[gangid][GangName], GangZone[zoneid][ZoneName]);
			SendClientMessageToAll(-1, msg);
			format(msg, sizeof(msg), "{FF0000}** %s zone will be locked for %d minutes!", GangZone[zoneid][ZoneName], LOCKED_MINUTES);
			SendClientMessageToAll(-1, msg);
			Gang[gangid][CurrentZone] = -1;
			GangZone[zoneid][ZoneLocked] = GetTickCount();
			GangZone[zoneid][ZoneStatus] = false;
			Gang[gangid][GangScore]+=5;
		}
	}
	else
	{
		foreach(new p : Player)
		{
			if(Player[p][PlayerGang] == gangid)
			{
				PlayerTextDrawHide(p, Player[p][CaptureTD][0]);
				PlayerTextDrawHide(p, Player[p][CaptureTD][1]);
			}
		}
		KillTimer(GangZone[zoneid][ZoneTimer]);
		GangZoneStopFlashForAll(GangZone[zoneid][ZoneHolder]);
	}
	return 1;
}

forward AutoSave();
public AutoSave()
{
	foreach(new i : Player)
		SaveStats(i);
	foreach(new i : Gangs)
		SaveGang(i);
	foreach(new i : GangZones)
		SaveZone(i);
	return 1;
}

COMMAND:gangcmds(playerid, params[])
{
	new msg[512];
	strcat(msg, "/creategang /gangcolor /changeleader /territory /gangmembers \n");
	strcat(msg, "/gcp /leavegang /disbandgang /topgang /gangrank /promotestaff \n");
	strcat(msg, "/demotestaff /createzone /ganginvite /acceptgang /g /capture \n");
	strcat(msg, "/okickmember /kickmember\n");
	ShowPlayerDialog(playerid, DIALOG_UNUSED, DIALOG_STYLE_MSGBOX, "X337 Gang System - Commands", msg, "Close", "");
}

/*
	SQL DUMP <X-Gang.sql>
-- phpMyAdmin SQL Dump
-- version 4.2.7.1
-- http://www.phpmyadmin.net
-- --------------------------------------------------------

--
-- Table structure for table `gang`
--

CREATE TABLE IF NOT EXISTS `gang` (
`id` int(10) NOT NULL,
  `name` varchar(30) NOT NULL,
  `color` varchar(6) NOT NULL,
  `tag` varchar(3) NOT NULL,
  `score` int(10) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `member`
--

CREATE TABLE IF NOT EXISTS `member` (
`id` int(10) NOT NULL,
  `name` varchar(30) NOT NULL,
  `status` int(1) NOT NULL DEFAULT '1',
  `gang` int(10) NOT NULL DEFAULT '-1'
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `zone`
--

CREATE TABLE IF NOT EXISTS `zone` (
`id` int(10) NOT NULL,
  `minx` varchar(10) NOT NULL,
  `miny` varchar(10) NOT NULL,
  `maxx` varchar(10) NOT NULL,
  `maxy` varchar(10) NOT NULL,
  `owner` int(10) NOT NULL DEFAULT '-1',
  `name` varchar(50) NOT NULL DEFAULT 'Undefined Zone'
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `gang`
--
ALTER TABLE `gang`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `member`
--
ALTER TABLE `member`
 ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `name` (`name`);

--
-- Indexes for table `zone`
--
ALTER TABLE `zone`
 ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `gang`
--
ALTER TABLE `gang`
MODIFY `id` int(10) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `member`
--
ALTER TABLE `member`
MODIFY `id` int(10) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `zone`
--
ALTER TABLE `zone`
MODIFY `id` int(10) NOT NULL AUTO_INCREMENT;
-- ------------------------------------------------
*/
