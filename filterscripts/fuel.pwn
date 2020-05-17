#define 	FILTERSCRIPT
#include 	<a_samp>        // SA-MP Team
#include    <evf>           // http://forum.sa-mp.com/showthread.php?t=486060 - Emmet_
#include    <evi>           // http://forum.sa-mp.com/showthread.php?t=438678 - Vince
#include    <progress2>     // http://forum.sa-mp.com/showthread.php?t=537468 - [HLF]Southclaw
#include    <streamer>      // http://forum.sa-mp.com/showthread.php?t=102865 - Incognito
#include    <zcmd>          // http://forum.sa-mp.com/showthread.php?t=91354  - Zeex

#define     MAX_GAS_PUMPS       (78)
#define     UPDATE_RATE     	(1000)      // Fuel consume rate in milliseconds. (Default: 1000)
#define     LITRE_PRICE         (3)         // Pretty obvious I guess. (Default: 3)

enum    e_pump
{
	Float: pumpX,
	Float: pumpY,
	Float: pumpZ,
	pumpUser,
	Text3D: pumpLabel
}

new
	Float: PumpData[MAX_GAS_PUMPS][e_pump] = {
		{-85.2422, -1165.0312, 2.6328},
		{-90.1406, -1176.6250, 2.6328},
		{-92.1016, -1161.7891, 2.9609},
		{-97.0703, -1173.7500, 3.0312},
		{1941.6562, -1767.2891, 14.1406},
		{1941.6562, -1771.3438, 14.1406},
		{1941.6562, -1774.3125, 14.1406},
		{1941.6562, -1778.4531, 14.1406},
		{-1327.0312, 2685.5938, 49.4531},
		{-1327.7969, 2680.1250, 49.4531},
		{-1328.5859, 2674.7109, 49.4531},
		{-1329.2031, 2669.2812, 49.4531},
		{-1464.9375, 1860.5625, 31.8203},
		{-1465.4766, 1868.2734, 31.8203},
		{-1477.6562, 1859.7344, 31.8203},
		{-1477.8516, 1867.3125, 31.8203},
		{-1600.6719, -2707.8047, 47.9297},
		{-1603.9922, -2712.2031, 47.9297},
		{-1607.3047, -2716.6016, 47.9297},
		{-1610.6172, -2721.0000, 47.9297},
		{-1665.5234, 416.9141, 6.3828},
		{-1669.9062, 412.5312, 6.3828},
		{-1672.1328, 423.5000, 6.3828},
		{-1675.2188, 407.1953, 6.3828},
		{-1676.5156, 419.1172, 6.3828},
		{-1679.3594, 403.0547, 6.3828},
		{-1681.8281, 413.7812, 6.3828},
		{-1685.9688, 409.6406, 6.3828},
		{-2241.7188, -2562.2891, 31.0625},
		{-2246.7031, -2559.7109, 31.0625},
		{-2410.8047, 970.8516, 44.4844},
		{-2410.8047, 976.1875, 44.4844},
		{-2410.8047, 981.5234, 44.4844},
		{1378.9609, 461.0391, 19.3281},
		{1380.6328, 460.2734, 19.3281},
		{1383.3984, 459.0703, 19.3281},
		{1385.0781, 458.2969, 19.3281},
		{603.4844, 1707.2344, 6.1797},
		{606.8984, 1702.2188, 6.1797},
		{610.2500, 1697.2656, 6.1797},
		{613.7188, 1692.2656, 6.1797},
		{617.1250, 1687.4531, 6.1797},
		{620.5312, 1682.4609, 6.1797},
		{624.0469, 1677.6016, 6.1797},
		{655.6641, -558.9297, 15.3594},
		{655.6641, -560.5469, 15.3594},
		{655.6641, -569.6016, 15.3594},
		{655.6641, -571.2109, 15.3594},
		{1590.3516, 2193.7109, 11.3125},
		{1590.3516, 2204.5000, 11.3125},
		{1596.1328, 2193.7109, 11.3125},
		{1596.1328, 2204.5000, 11.3125},
		{1602.0000, 2193.7109, 11.3125},
		{1602.0000, 2204.5000, 11.3125},
		{2109.0469, 914.7188, 11.2578},
		{2109.0469, 925.5078, 11.2578},
		{2114.9062, 914.7188, 11.2578},
		{2114.9062, 925.5078, 11.2578},
		{2120.8203, 914.7188, 11.2578},
		{2120.8203, 925.5078, 11.2578},
		{2141.6719, 2742.5234, 11.2734},
		{2141.6719, 2753.3203, 11.2734},
		{2147.5312, 2742.5234, 11.2734},
		{2147.5312, 2753.3203, 11.2734},
		{2153.3125, 2742.5234, 11.2734},
		{2153.3125, 2753.3203, 11.2734},
		{2196.8984, 2470.2500, 11.3125},
		{2196.8984, 2474.6875, 11.3125},
		{2196.8984, 2480.3281, 11.3125},
		{2207.6953, 2470.2500, 11.3125},
		{2207.6953, 2474.6875, 11.3125},
		{2207.6953, 2480.3281, 11.3125},
		{2634.6406, 1100.9453, 11.2500},
		{2634.6406, 1111.7500, 11.2500},
		{2639.8750, 1100.9609, 11.2500},
		{2639.8750, 1111.7500, 11.2500},
		{2645.2500, 1100.9609, 11.2500},
		{2645.2500, 1111.7500, 11.2500}
	};

new
	UsingPumpID[MAX_PLAYERS] = {-1, ...},
	RefuelTimer[MAX_PLAYERS] = {-1, ...},
	Float: FuelBought[MAX_PLAYERS],
	PlayerText: FuelText[MAX_PLAYERS],
	PlayerBar: FuelBar[MAX_PLAYERS] = {INVALID_PLAYER_BAR_ID, ...};

new
	Float: Fuel[MAX_VEHICLES] = {100.0, ...},
	Float: VehicleLastCoords[MAX_VEHICLES][3];

Pump_Update(id)
{
    new string[96];
	format(string, sizeof(string), "Gas Pump\n\n{2ECC71}$%d / Litre\n%s/refuel", LITRE_PRICE, (IsPlayerConnected(PumpData[id][pumpUser])) ? ("{E74C3C}") : ("{FFFFFF}"));
	return UpdateDynamic3DTextLabelText(PumpData[id][pumpLabel], 0xF1C40FFF, string);
}

Pump_Closest(playerid, Float: range = 6.0)
{
	new id = -1, Float: dist = range, Float: tempdist;
	for(new i; i < MAX_GAS_PUMPS; i++)
	{
	    tempdist = GetPlayerDistanceFromPoint(playerid, PumpData[i][pumpX], PumpData[i][pumpY], PumpData[i][pumpZ]);

	    if(tempdist > range) continue;
		if(tempdist <= dist)
		{
			dist = tempdist;
			id = i;
		}
	}

	return id;
}

Fuel_InitPlayer(playerid)
{
	UsingPumpID[playerid] = -1;
	RefuelTimer[playerid] = -1;
	FuelBought[playerid] = 0.0;

	FuelText[playerid] = CreatePlayerTextDraw(playerid, 40.000000, 305.000000, "~b~~h~Refueling...~n~~n~~w~Price: ~g~~h~$0 ~y~~h~(0.00L)");
	PlayerTextDrawBackgroundColor(playerid, FuelText[playerid], 255);
	PlayerTextDrawFont(playerid, FuelText[playerid], 1);
	PlayerTextDrawLetterSize(playerid, FuelText[playerid], 0.240000, 1.100000);
	PlayerTextDrawColor(playerid, FuelText[playerid], -1);
	PlayerTextDrawSetOutline(playerid, FuelText[playerid], 1);
	PlayerTextDrawSetProportional(playerid, FuelText[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, FuelText[playerid], 0);

	FuelBar[playerid] = CreatePlayerProgressBar(playerid, 498.0, 104.0, 113.0, 6.2, 0xF1C40FFF, 100.0, 0);
	return 1;
}

Fuel_ResetPlayer(playerid)
{
	if(UsingPumpID[playerid] != -1)
	{
	    PumpData[ UsingPumpID[playerid] ][pumpUser] = INVALID_PLAYER_ID;
	    Pump_Update(UsingPumpID[playerid]);
	}

	if(RefuelTimer[playerid] != -1)
	{
	    KillTimer(RefuelTimer[playerid]);
	    RefuelTimer[playerid] = -1;

	    PlayerTextDrawHide(playerid, FuelText[playerid]);
	}

    UsingPumpID[playerid] = -1;
 	FuelBought[playerid] = 0.0;
	return 1;
}

Vehicle_StartEngine(vehicleid)
{
	if(Fuel[vehicleid] < 0.1) return 0;
	SetVehicleParams(vehicleid, VEHICLE_TYPE_ENGINE, 1);
	return 1;
}

Vehicle_IsANoFuelVehicle(model)
{
	switch(model)
	{
		case 481, 509, 510: return 1;
		default: return 0;
	}

	return 0;
}

Float: Vehicle_GetSpeed(vehicleid)
{
    new Float: vx, Float: vy, Float: vz, Float: vel;
	vel = GetVehicleVelocity(vehicleid, vx, vy, vz);
	vel = (floatsqroot(((vx*vx)+(vy*vy))+(vz*vz)) * 181.5);
	return vel;
}

public OnFilterScriptInit()
{
	ManualVehicleEngineAndLights();

	for(new i; i < MAX_GAS_PUMPS; i++)
	{
	    PumpData[i][pumpUser] = INVALID_PLAYER_ID;
	    PumpData[i][pumpLabel] = CreateDynamic3DTextLabel("Gas Pump", 0xF1C40FFF, PumpData[i][pumpX], PumpData[i][pumpY], PumpData[i][pumpZ] + 0.75, 7.5);
	    Pump_Update(i);
	}

	for(new i, p = GetPlayerPoolSize(); i <= p; i++)
	{
	    if(!IsPlayerConnected(i)) continue;
	    Fuel_InitPlayer(i);
	}

	for(new i, v = GetVehiclePoolSize(); i <= v; i++)
	{
	    if(!IsValidVehicle(i)) continue;
		if(Vehicle_IsANoFuelVehicle( GetVehicleModel(i) )) SetVehicleParams(i, VEHICLE_TYPE_ENGINE, 1);
	}

	SetTimer("ConsumeFuel", UPDATE_RATE, true);
	return 1;
}

public OnFilterScriptExit()
{
	for(new i, p = GetPlayerPoolSize(); i <= p; i++)
	{
	    if(!IsPlayerConnected(i)) continue;
	    Fuel_ResetPlayer(i);
	    HidePlayerProgressBar(i, FuelBar[i]);
	}

	return 1;
}

public OnPlayerConnect(playerid)
{
	Fuel_InitPlayer(playerid);
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	Fuel_ResetPlayer(playerid);
	return 1;
}

public OnVehicleSpawn(vehicleid)
{
	Fuel[vehicleid] = 100.0;
	return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
	if(newstate == PLAYER_STATE_DRIVER)
	{
	    new id = GetPlayerVehicleID(playerid);
	    if(Vehicle_IsANoFuelVehicle( GetVehicleModel(id) )) return SetVehicleParams(id, VEHICLE_TYPE_ENGINE, 1);
	    SendClientMessage(playerid, -1, "You can start/stop the engine by pressing N.");
		ShowPlayerProgressBar(playerid, FuelBar[playerid]);
		SetPlayerProgressBarValue(playerid, FuelBar[playerid], Fuel[id]);
		GetVehiclePos(GetPlayerVehicleID(playerid), VehicleLastCoords[id][0], VehicleLastCoords[id][1], VehicleLastCoords[id][2]);
	}

	if(oldstate == PLAYER_STATE_DRIVER)
	{
	    Fuel_ResetPlayer(playerid);
		HidePlayerProgressBar(playerid, FuelBar[playerid]);
	}

	return 1;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	if(GetPlayerState(playerid) == PLAYER_STATE_DRIVER && (newkeys & KEY_NO))
	{
	    new id = GetPlayerVehicleID(playerid);
	    if(Vehicle_IsANoFuelVehicle( GetVehicleModel(id) )) return 1;

	    if(GetVehicleParams(id, VEHICLE_TYPE_ENGINE)) {
	        SetVehicleParams(id, VEHICLE_TYPE_ENGINE, 0);
	    }else{
	        Vehicle_StartEngine(id);

	        if(UsingPumpID[playerid] != -1)
	        {
	            new Float: x, Float: y, Float: z;
	            GetPlayerPos(playerid, x, y, z);
	            CreateExplosionForPlayer(playerid, x, y, z, 6, 8.0);
			}
	    }
	}

	return 1;
}

public OnPlayerUpdate(playerid)
{
	if(GetPlayerState(playerid) == PLAYER_STATE_DRIVER)
	{
		new vid = GetPlayerVehicleID(playerid);
	    if(GetPVarInt(playerid, "FuelLastUpdate") < GetTickCount() && UsingPumpID[playerid] == -1 && !Vehicle_IsANoFuelVehicle( GetVehicleModel(vid) ))
	    {
	        SetPlayerProgressBarValue(playerid, FuelBar[playerid], Fuel[vid]);
	        SetPVarInt(playerid, "FuelLastUpdate", GetTickCount() + (UPDATE_RATE + 50));
	    }
	}

	return 1;
}

forward ConsumeFuel();
public ConsumeFuel()
{
    new Float: mass, Float: speed, Float: dist;
    for(new i = 1, ps = GetVehiclePoolSize(); i <= ps; i++)
    {
        if(!IsValidVehicle(i)) continue;
        if(Vehicle_IsANoFuelVehicle( GetVehicleModel(i) )) continue;
		if(!GetVehicleParams(i, VEHICLE_TYPE_ENGINE)) continue;
		dist = GetVehicleDistanceFromPoint(i, VehicleLastCoords[i][0], VehicleLastCoords[i][1], VehicleLastCoords[i][2]);
		mass = GetVehicleModelInfoAsFloat(GetVehicleModel(i), "fMass");
		speed = Vehicle_GetSpeed(i) + 0.001;
		Fuel[i] -= ((mass / (mass * 4.5)) * ((speed / 60) + 0.015) / 30) * ((dist / 10) + 0.001);
		if(Fuel[i] < 0.1) SetVehicleParams(i, VEHICLE_TYPE_ENGINE, 0);
		GetVehiclePos(i, VehicleLastCoords[i][0], VehicleLastCoords[i][1], VehicleLastCoords[i][2]);
    }

	return 1;
}

forward Refuel(playerid, vehicleid);
public Refuel(playerid, vehicleid)
{
    new price = floatround(0.5 * LITRE_PRICE);
    if(GetPlayerMoney(playerid) < price)
	{
		SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You don't have enough money.");
		Fuel_ResetPlayer(playerid);
		Vehicle_StartEngine(vehicleid);
		return 1;
	}

    FuelBought[playerid] += 0.5;
	Fuel[vehicleid] += 0.5;

	new string[64];
	format(string, sizeof(string), "~b~~h~Refueling...~n~~n~~w~Price: ~g~~h~$%d ~y~~h~(%.2fL)", floatround(FuelBought[playerid] * LITRE_PRICE), FuelBought[playerid]);
	PlayerTextDrawSetString(playerid, FuelText[playerid], string);
	SetPlayerProgressBarValue(playerid, FuelBar[playerid], Fuel[vehicleid]);
	GivePlayerMoney(playerid, -price);

	if(Fuel[vehicleid] > 100.0)
	{
		Fuel[vehicleid] = 100.0;
		Fuel_ResetPlayer(playerid);
		Vehicle_StartEngine(vehicleid);
	}

	return 1;
}

CMD:refuel(playerid, params[])
{
    if(GetPlayerState(playerid) != PLAYER_STATE_DRIVER) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You can't use this command if you're not a driver.");
	if(UsingPumpID[playerid] == -1) {
	    if(GetPlayerMoney(playerid) < 1) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You don't have enough money.");
	    if(Fuel[ GetPlayerVehicleID(playerid) ] > 99.0) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}Your vehicle doesn't need a refuel.");
		new id = Pump_Closest(playerid);
		if(id == -1) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You're not near a gas pump.");
		if(IsPlayerConnected(PumpData[id][pumpUser])) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}The pump you want to use is not available.");
		UsingPumpID[playerid] = id;
		PumpData[id][pumpUser] = playerid;
		Pump_Update(id);

		new vid = GetPlayerVehicleID(playerid);
		SetVehicleParams(vid, VEHICLE_TYPE_ENGINE, 0);
		PlayerTextDrawSetString(playerid, FuelText[playerid], "~b~~h~Refueling...~n~~n~~w~Price: ~g~~h~$0 ~y~~h~(0.00L)");
		PlayerTextDrawShow(playerid, FuelText[playerid]);
		RefuelTimer[playerid] = SetTimerEx("Refuel", 350, true, "ii", playerid, vid);

		SendClientMessage(playerid, -1, "You can write /refuel again to stop refueling.");
	}else{
	    Fuel_ResetPlayer(playerid);
	    Vehicle_StartEngine( GetPlayerVehicleID(playerid) );
	}

	return 1;
}

CMD:arefuel(playerid, params[])
{
	if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}Only RCON admins can use this command.");
	new id = GetPlayerVehicleID(playerid);
	if(!IsValidVehicle(id)) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You're not in a vehicle.");
	Fuel[id] = 100.0;
	SendClientMessage(playerid, -1, "Vehicle refueled.");
	return 1;
}

CMD:arefuelall(playerid, params[])
{
	if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}Only RCON admins can use this command.");
	for(new i, v = GetVehiclePoolSize(); i <= v; i++) if(IsValidVehicle(i)) Fuel[i] = 100.0;
	SendClientMessageToAll(-1, "A RCON admin has refueled all vehicles.");
	return 1;
}
