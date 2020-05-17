#define 	FILTERSCRIPT
#include 	<a_samp>
#include    <sqlitei>
#include    <sscanf2>
#include    <streamer>
#include    <YSI\y_iterate>
#include    <zcmd>

#define     MAX_GATES           100
#define     GATE_PASS_LEN   	8
#define     MOVE_SPEED          (1.65)

enum    _:e_gatestates
{
	GATE_STATE_CLOSED,
	GATE_STATE_OPEN
}

enum    _:e_gatedialogs
{
	DIALOG_GATE_PASSWORD = 12250,
	DIALOG_GATE_EDITMENU,
	DIALOG_GATE_NEWPASSWORD
}

enum    e_gate
{
	GateModel,
	GatePassword[GATE_PASS_LEN],
	Float: GatePos[3],
	Float: GateRot[3],
	Float: GateOpenPos[3],
	Float: GateOpenRot[3],
	GateState,
	bool: GateEditing,
	GateObject,
	Text3D: GateLabel
}

new
	GateData[MAX_GATES][e_gate],
	Iterator: Gates<MAX_GATES>,
	EditingGateID[MAX_PLAYERS] = {-1, ...},
	EditingGateType[MAX_PLAYERS] = {-1, ...},
	bool: HasGateAuth[MAX_PLAYERS][MAX_GATES];
	
new
	GateStates[2][16] = {"{E74C3C}Closed", "{2ECC71}Open"};

new
	DB: GateDB,
	DBStatement: LoadGates,
	DBStatement: AddGate,
	DBStatement: UpdateGate,
	DBStatement: RemoveGate;

stock GetXYInFrontOfPlayer(playerid, &Float:x, &Float:y, Float:distance)
{
	new Float:a;
	GetPlayerPos(playerid, x, y, a);
	GetPlayerFacingAngle(playerid, a);
	if (GetPlayerVehicleID(playerid))
	{
	    GetVehicleZAngle(GetPlayerVehicleID(playerid), a);
	}
	x += (distance * floatsin(-a, degrees));
	y += (distance * floatcos(-a, degrees));
}

stock GetClosestGate(playerid, Float: range = 5.0)
{
	new id = -1, Float: playerdist, Float: tempdist = 9999.0;
	foreach(new i : Gates)
	{
        playerdist = GetPlayerDistanceFromPoint(playerid, GateData[i][GatePos][0], GateData[i][GatePos][1], GateData[i][GatePos][2]);
        if(playerdist > range) continue;
	    if(playerdist <= tempdist)
	    {
	        tempdist = playerdist;
	        id = i;
	    }
	}
	
	return id;
}

stock SetGateState(id, gate_state, move = 1)
{
    new string[32];
	format(string, sizeof(string), "Gate #%d\n%s", id, GateStates[gate_state]);
	UpdateDynamic3DTextLabelText(GateData[id][GateLabel], 0xECF0F1FF, string);
	GateData[id][GateState] = gate_state;
	
	switch(move)
	{
	    case 1:
	    {
	        if(gate_state == GATE_STATE_CLOSED) {
	        	MoveDynamicObject(GateData[id][GateObject], GateData[id][GatePos][0], GateData[id][GatePos][1], GateData[id][GatePos][2], MOVE_SPEED, GateData[id][GateRot][0], GateData[id][GateRot][1], GateData[id][GateRot][2]);
			}else{
                MoveDynamicObject(GateData[id][GateObject], GateData[id][GateOpenPos][0], GateData[id][GateOpenPos][1], GateData[id][GateOpenPos][2], MOVE_SPEED, GateData[id][GateOpenRot][0], GateData[id][GateOpenRot][1], GateData[id][GateOpenRot][2]);
			}
		}

		case 2:
		{
		    if(gate_state == GATE_STATE_CLOSED) {
	        	SetDynamicObjectPos(GateData[id][GateObject], GateData[id][GatePos][0], GateData[id][GatePos][1], GateData[id][GatePos][2]);
				SetDynamicObjectRot(GateData[id][GateObject], GateData[id][GateRot][0], GateData[id][GateRot][1], GateData[id][GateRot][2]);
			}else{
                SetDynamicObjectPos(GateData[id][GateObject], GateData[id][GateOpenPos][0], GateData[id][GateOpenPos][1], GateData[id][GateOpenPos][2]);
				SetDynamicObjectRot(GateData[id][GateObject], GateData[id][GateOpenRot][0], GateData[id][GateOpenRot][1], GateData[id][GateOpenRot][2]);
			}
		}
	}
	
	return 1;
}

stock ToggleGateState(id, move = 1)
{
	if(GateData[id][GateState] == GATE_STATE_CLOSED) {
	    SetGateState(id, GATE_STATE_OPEN, move);
	}else{
	    SetGateState(id, GATE_STATE_CLOSED, move);
	}
	
	return 1;
}

stock ShowEditMenu(playerid, id)
{
    new string[128];
	format(string, sizeof(string), "Gate State\t%s\nGate Password\t%s\nEdit Gate Position\nEdit Opening Position\nRemove Gate", GateStates[ GateData[id][GateState] ], GateData[id][GatePassword]);
	ShowPlayerDialog(playerid, DIALOG_GATE_EDITMENU, DIALOG_STYLE_TABLIST, "Gate Editing", string, "Choose", "Cancel");
	return 1;
}

stock SaveGate(id)
{
    stmt_bind_value(UpdateGate, 0, DB::TYPE_STRING, GateData[id][GatePassword]);
	stmt_bind_value(UpdateGate, 1, DB::TYPE_FLOAT, GateData[id][GatePos][0]);
	stmt_bind_value(UpdateGate, 2, DB::TYPE_FLOAT, GateData[id][GatePos][1]);
	stmt_bind_value(UpdateGate, 3, DB::TYPE_FLOAT, GateData[id][GatePos][2]);
	stmt_bind_value(UpdateGate, 4, DB::TYPE_FLOAT, GateData[id][GateRot][0]);
	stmt_bind_value(UpdateGate, 5, DB::TYPE_FLOAT, GateData[id][GateRot][1]);
	stmt_bind_value(UpdateGate, 6, DB::TYPE_FLOAT, GateData[id][GateRot][2]);
	stmt_bind_value(UpdateGate, 7, DB::TYPE_FLOAT, GateData[id][GateOpenPos][0]);
	stmt_bind_value(UpdateGate, 8, DB::TYPE_FLOAT, GateData[id][GateOpenPos][1]);
	stmt_bind_value(UpdateGate, 9, DB::TYPE_FLOAT, GateData[id][GateOpenPos][2]);
	stmt_bind_value(UpdateGate, 10, DB::TYPE_FLOAT, GateData[id][GateOpenRot][0]);
	stmt_bind_value(UpdateGate, 11, DB::TYPE_FLOAT, GateData[id][GateOpenRot][1]);
	stmt_bind_value(UpdateGate, 12, DB::TYPE_FLOAT, GateData[id][GateOpenRot][2]);
	stmt_bind_value(UpdateGate, 13, DB::TYPE_INTEGER, id);
	stmt_execute(UpdateGate);
	return 1;
}

public OnFilterScriptInit()
{
	GateDB = db_open("dyn_gates.db");
    db_query(GateDB, "CREATE TABLE IF NOT EXISTS gates (id INTEGER, model INTEGER, password TEXT, def_posx FLOAT, def_posy FLOAT, def_posz FLOAT, def_rotx FLOAT, def_roty FLOAT, def_rotz FLOAT, open_posx FLOAT, open_posy FLOAT, open_posz FLOAT, open_rotx FLOAT, open_roty FLOAT, open_rotz FLOAT)");

	LoadGates = db_prepare(GateDB, "SELECT * FROM gates");
    AddGate = db_prepare(GateDB, "INSERT INTO gates (id, model, password, def_posx, def_posy, def_posz) VALUES (?, ?, ?, ?, ?, ?)");
    UpdateGate = db_prepare(GateDB, "UPDATE gates SET password=?, def_posx=?, def_posy=?, def_posz=?, def_rotx=?, def_roty=?, def_rotz=?, open_posx=?, open_posy=?, open_posz=?, open_rotx=?, open_roty=?, open_rotz=? WHERE id=?");
	RemoveGate = db_prepare(GateDB, "DELETE FROM gates WHERE id=?");
	
	new id, model, password[GATE_PASS_LEN], Float: pos[3], Float: rot[3], Float: openpos[3], Float: openrot[3];
	stmt_bind_result_field(LoadGates, 0, DB::TYPE_INTEGER, id);
    stmt_bind_result_field(LoadGates, 1, DB::TYPE_INTEGER, model);
    stmt_bind_result_field(LoadGates, 2, DB::TYPE_STRING, password, GATE_PASS_LEN);
	stmt_bind_result_field(LoadGates, 3, DB::TYPE_FLOAT, pos[0]);
	stmt_bind_result_field(LoadGates, 4, DB::TYPE_FLOAT, pos[1]);
	stmt_bind_result_field(LoadGates, 5, DB::TYPE_FLOAT, pos[2]);
	stmt_bind_result_field(LoadGates, 6, DB::TYPE_FLOAT, rot[0]);
	stmt_bind_result_field(LoadGates, 7, DB::TYPE_FLOAT, rot[1]);
	stmt_bind_result_field(LoadGates, 8, DB::TYPE_FLOAT, rot[2]);
	stmt_bind_result_field(LoadGates, 9, DB::TYPE_FLOAT, openpos[0]);
	stmt_bind_result_field(LoadGates, 10, DB::TYPE_FLOAT, openpos[1]);
	stmt_bind_result_field(LoadGates, 11, DB::TYPE_FLOAT, openpos[2]);
	stmt_bind_result_field(LoadGates, 12, DB::TYPE_FLOAT, openrot[0]);
	stmt_bind_result_field(LoadGates, 13, DB::TYPE_FLOAT, openrot[1]);
	stmt_bind_result_field(LoadGates, 14, DB::TYPE_FLOAT, openrot[2]);

	if(stmt_execute(LoadGates))
	{
	    new label[32];
	    while(stmt_fetch_row(LoadGates))
	    {
            GateData[id][GateModel] = model;
			GateData[id][GatePassword] = password;
			GateData[id][GatePos][0] = pos[0];
			GateData[id][GatePos][1] = pos[1];
			GateData[id][GatePos][2] = pos[2];
			GateData[id][GateRot][0] = rot[0];
			GateData[id][GateRot][1] = rot[1];
			GateData[id][GateRot][2] = rot[2];
			GateData[id][GateOpenPos][0] = openpos[0];
			GateData[id][GateOpenPos][1] = openpos[1];
			GateData[id][GateOpenPos][2] = openpos[2];
			GateData[id][GateOpenRot][0] = openrot[0];
			GateData[id][GateOpenRot][1] = openrot[1];
			GateData[id][GateOpenRot][2] = openrot[2];
			
			format(label, sizeof(label), "Gate #%d\n%s", id, GateStates[GATE_STATE_CLOSED]);
			GateData[id][GateObject] = CreateDynamicObject(model, pos[0], pos[1], pos[2], rot[0], rot[1], rot[2]);
			GateData[id][GateLabel] = CreateDynamic3DTextLabel(label, 0xECF0F1FF, pos[0], pos[1], pos[2], 10.0);
			Iter_Add(Gates, id);
		}
	}
	
	return 1;
}

public OnFilterScriptExit()
{
	db_close(GateDB);
	return 1;
}

public OnPlayerConnect(playerid)
{
	EditingGateID[playerid] = -1;
	EditingGateType[playerid] = -1;
	for(new i; i < MAX_GATES; i++) HasGateAuth[playerid][i] = false;
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	if(EditingGateID[playerid] != -1) GateData[ EditingGateID[playerid] ][GateEditing] = false;
	return 1;
}

public OnPlayerEditDynamicObject(playerid, STREAMER_TAG_OBJECT objectid, response, Float:x, Float:y, Float:z, Float:rx, Float:ry, Float:rz)
{
	if(EditingGateID[playerid] == -1) return 1;
	switch(response)
	{
		case EDIT_RESPONSE_FINAL:
		{
		    new id = EditingGateID[playerid];
		    GateData[id][GateEditing] = false;
		    
		    switch(EditingGateType[playerid])
		    {
				case GATE_STATE_CLOSED:
				{
				    Streamer_SetFloatData(STREAMER_TYPE_3D_TEXT_LABEL, GateData[id][GateLabel], E_STREAMER_X, x);
		            Streamer_SetFloatData(STREAMER_TYPE_3D_TEXT_LABEL, GateData[id][GateLabel], E_STREAMER_Y, y);
		            Streamer_SetFloatData(STREAMER_TYPE_3D_TEXT_LABEL, GateData[id][GateLabel], E_STREAMER_Z, z);
				    SetDynamicObjectPos(objectid, x, y, z);
				    SetDynamicObjectRot(objectid, rx, ry, rz);
				    GateData[id][GatePos][0] = x;
					GateData[id][GatePos][1] = y;
					GateData[id][GatePos][2] = z;
					GateData[id][GateRot][0] = rx;
					GateData[id][GateRot][1] = ry;
					GateData[id][GateRot][2] = rz;
					SendClientMessage(playerid, 0x2ECC71FF, "INFO: {FFFFFF}Edited gate's default position.");
					
					if(GateData[id][GateOpenPos][0] == 0.0 && GateData[id][GateOpenRot][0] == 0.0) {
				        GateData[id][GateEditing] = true;
		    			EditingGateType[playerid] = GATE_STATE_OPEN;
				        EditDynamicObject(playerid, objectid);
				        
				        SendClientMessage(playerid, 0xF39C12FF, "WARNING: {FFFFFF}This gate doesn't have an opening position.");
				        SendClientMessage(playerid, 0xF39C12FF, "WARNING: {FFFFFF}You can define an opening position now or you can do it later.");
				        SendClientMessage(playerid, 0xF39C12FF, "WARNING: {FFFFFF}People won't be able to open this gate until you define an opening position.");
				    }else{
				        EditingGateID[playerid] = -1;
		    			EditingGateType[playerid] = -1;
				    }
				    
				    SaveGate(id);
				}
				
				case GATE_STATE_OPEN:
				{
				    SendClientMessage(playerid, 0x2ECC71FF, "INFO: {FFFFFF}Edited gate's opening position.");
				    SetGateState(id, GATE_STATE_CLOSED, 2);
				    GateData[id][GateOpenPos][0] = x;
					GateData[id][GateOpenPos][1] = y;
					GateData[id][GateOpenPos][2] = z;
					GateData[id][GateOpenRot][0] = rx;
					GateData[id][GateOpenRot][1] = ry;
					GateData[id][GateOpenRot][2] = rz;

				    EditingGateID[playerid] = -1;
		    		EditingGateType[playerid] = -1;
		    		SaveGate(id);
				}
		    }
		}
		
		case EDIT_RESPONSE_CANCEL:
		{
            new id = EditingGateID[playerid];
            GateData[id][GateEditing] = false;
            
		    switch(EditingGateType[playerid])
		    {
				case GATE_STATE_CLOSED:
				{
				    SetDynamicObjectPos(objectid, GateData[id][GatePos][0], GateData[id][GatePos][1], GateData[id][GatePos][2]);
				    SetDynamicObjectRot(objectid, GateData[id][GateRot][0], GateData[id][GateRot][1], GateData[id][GateRot][2]);
				    GateData[id][GatePos][0] = x;
					GateData[id][GatePos][1] = y;
					GateData[id][GatePos][2] = z;
					GateData[id][GateRot][0] = rx;
					GateData[id][GateRot][1] = ry;
					GateData[id][GateRot][2] = rz;
					SendClientMessage(playerid, 0x2ECC71FF, "INFO: {FFFFFF}Cancelled editing gate's default position.");
				}

				case GATE_STATE_OPEN:
				{
				    SendClientMessage(playerid, 0x2ECC71FF, "INFO: {FFFFFF}Cancelled editing gate's opening position.");
				    
				    if(GateData[id][GateOpenPos][0] == 0.0 && GateData[id][GateOpenRot][0] == 0.0)
					{
				        SendClientMessage(playerid, 0xF39C12FF, "WARNING: {FFFFFF}This gate doesn't have an opening position.");
				        SendClientMessage(playerid, 0xF39C12FF, "WARNING: {FFFFFF}People won't be able to open it until you define an opening position.");
				    }

				    SetGateState(id, GATE_STATE_CLOSED, 2);
				    EditingGateID[playerid] = -1;
		    		EditingGateType[playerid] = -1;
				}
			}
		}
	}
	
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	if(dialogid == DIALOG_GATE_PASSWORD)
	{
	    if(!response) return 1;
		if(!strlen(inputtext)) return ShowPlayerDialog(playerid, DIALOG_GATE_PASSWORD, DIALOG_STYLE_PASSWORD, "Gate Password", "{E74C3C}You didn't write a password.\n{FFFFFF}Please enter this gate's password:", "Done", "Cancel");
		new id = GetClosestGate(playerid);
		if(id == -1) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You're not near a gate.");
		if(strcmp(GateData[id][GatePassword], inputtext)) return ShowPlayerDialog(playerid, DIALOG_GATE_PASSWORD, DIALOG_STYLE_PASSWORD, "Gate Password", "{E74C3C}Wrong password.\n{FFFFFF}Please enter this gate's password:", "Done", "Cancel");
		HasGateAuth[playerid][id] = true;
		ToggleGateState(id);
		return 1;
	}
	
	if(dialogid == DIALOG_GATE_EDITMENU)
	{
	    if(!IsPlayerAdmin(playerid)) return 1;
	    if(!response)
		{
		    if(EditingGateID[playerid] != -1) GateData[ EditingGateID[playerid] ][GateEditing] = false;
			EditingGateID[playerid] = -1;
			return 1;
		}
		
		new id = EditingGateID[playerid];
		if(id == -1) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You're not editing a gate.");
	    if(listitem == 0)
		{
			ToggleGateState(id);
			ShowEditMenu(playerid, id);
		}
		
	    if(listitem == 1) ShowPlayerDialog(playerid, DIALOG_GATE_NEWPASSWORD, DIALOG_STYLE_INPUT, "Change Gate Password", "Write a new password for selected gate:\nYou can leave this empty if you want to remove gate's password.", "Update", "Cancel");
		if(listitem == 2)
		{
		    SetGateState(id, GATE_STATE_CLOSED, 2);
		    EditingGateType[playerid] = GATE_STATE_CLOSED;
		    EditDynamicObject(playerid, GateData[id][GateObject]);
		    SendClientMessage(playerid, 0x2ECC71FF, "INFO: {FFFFFF}Editing gate's default position.");
		}
		
		if(listitem == 3)
		{
		    SetGateState(id, GATE_STATE_OPEN, 2);
		    EditingGateType[playerid] = GATE_STATE_OPEN;
		    EditDynamicObject(playerid, GateData[id][GateObject]);
		    SendClientMessage(playerid, 0x2ECC71FF, "INFO: {FFFFFF}Editing gate's opening position.");
		}
		
		if(listitem == 4)
		{
		    GateData[id][GateEditing] = false;
		    GateData[id][GatePos][0] = GateData[id][GatePos][1] = GateData[id][GatePos][2] = 0.0;
		    GateData[id][GateRot][0] = GateData[id][GateRot][1] = GateData[id][GateRot][2] = 0.0;
			GateData[id][GateOpenPos][0] = GateData[id][GateOpenPos][1] = GateData[id][GateOpenPos][2] = 0.0;
			GateData[id][GateOpenRot][0] = GateData[id][GateOpenRot][1] = GateData[id][GateOpenRot][2] = 0.0;
			DestroyDynamicObject(GateData[id][GateObject]);
			DestroyDynamic3DTextLabel(GateData[id][GateLabel]);
			Iter_Remove(Gates, id);
			
			stmt_bind_value(RemoveGate, 0, DB::TYPE_INTEGER, id);
			stmt_execute(RemoveGate);
			
		    foreach(new i : Player) if(EditingGateID[i] == id) EditingGateID[i] = -1;
		    SendClientMessage(playerid, 0x2ECC71FF, "INFO: {FFFFFF}Gate removed.");
		}
		
		return 1;
	}
	
	if(dialogid == DIALOG_GATE_NEWPASSWORD)
	{
	    if(!IsPlayerAdmin(playerid)) return 1;
		new id = EditingGateID[playerid];
		if(id == -1) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You're not editing a gate.");
		if(!response) return ShowEditMenu(playerid, id);
	    format(GateData[id][GatePassword], GATE_PASS_LEN, "%s", inputtext);
	    foreach(new i : Player) HasGateAuth[i][id] = false;
	    SendClientMessage(playerid, 0x2ECC71FF, "INFO: {FFFFFF}Password updated.");
	    SaveGate(id);
	    ShowEditMenu(playerid, id);
	    return 1;
	}
	
	return 0;
}

CMD:gate(playerid, params[])
{
	new id = GetClosestGate(playerid);
	if(id == -1) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You're not near a gate.");
	if(GateData[id][GateEditing]) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}This gate is being edited, you can't use it.");
	if(GateData[id][GateOpenPos][0] == 0.0 && GateData[id][GateOpenRot][0] == 0.0) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}This gate has no opening position.");
	if(!strlen(GateData[id][GatePassword])) {
	    ToggleGateState(id);
	}else{
	    if(HasGateAuth[playerid][id]) {
	        ToggleGateState(id);
		}else{
		    ShowPlayerDialog(playerid, DIALOG_GATE_PASSWORD, DIALOG_STYLE_PASSWORD, "Gate Password", "This gate is password protected.\nPlease enter this gate's password:", "Done", "Cancel");
		}
	}
	
	return 1;
}

CMD:creategate(playerid, params[])
{
	if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}Only RCON admins can use this command.");
	if(EditingGateID[playerid] != -1) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You can't create a gate while editing one.");
	new id = Iter_Free(Gates);
	if(id == -1) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}Gate limit reached, you can't place any more gates.");
	new model, password[GATE_PASS_LEN];
	if(sscanf(params, "iS()["#GATE_PASS_LEN"]", model, password)) return SendClientMessage(playerid, 0xF39C12FF, "USAGE: {FFFFFF}/creategate [model id] [password (optional)]");
	GateData[id][GateModel] = model;
	GateData[id][GatePassword] = password;
	
	new Float: x, Float: y, Float: z;
	GetPlayerPos(playerid, x, y, z);
	GetXYInFrontOfPlayer(playerid, x, y, 3.0);
	
	GateData[id][GatePos][0] = x;
	GateData[id][GatePos][1] = y;
	GateData[id][GatePos][2] = z;
	GateData[id][GateRot][0] = GateData[id][GateRot][1] = GateData[id][GateRot][2] = 0.0;
	GateData[id][GateOpenPos][0] = GateData[id][GateOpenPos][1] = GateData[id][GateOpenPos][2] = 0.0;
	GateData[id][GateOpenRot][0] = GateData[id][GateOpenRot][1] = GateData[id][GateOpenRot][2] = 0.0;
	GateData[id][GateState] = GATE_STATE_CLOSED;
	GateData[id][GateEditing] = true;
	GateData[id][GateObject] = CreateDynamicObject(model, x, y, z, 0.0, 0.0, 0.0);
	new string[32];
	format(string, sizeof(string), "Gate #%d\n%s", id, GateStates[GATE_STATE_CLOSED]);
	GateData[id][GateLabel] = CreateDynamic3DTextLabel(string, 0xECF0F1FF, x, y, z, 10.0);
	Iter_Add(Gates, id);
	
	stmt_bind_value(AddGate, 0, DB::TYPE_INTEGER, id);
	stmt_bind_value(AddGate, 1, DB::TYPE_INTEGER, model);
	stmt_bind_value(AddGate, 2, DB::TYPE_STRING, password);
	stmt_bind_value(AddGate, 3, DB::TYPE_FLOAT, x);
	stmt_bind_value(AddGate, 4, DB::TYPE_FLOAT, y);
	stmt_bind_value(AddGate, 5, DB::TYPE_FLOAT, z);
	stmt_execute(AddGate);
	
	EditingGateID[playerid] = id;
	EditingGateType[playerid] = GATE_STATE_CLOSED;
	EditDynamicObject(playerid, GateData[id][GateObject]);
	SendClientMessage(playerid, 0x2ECC71FF, "INFO: {FFFFFF}Gate created, now you can edit it.");
	return 1;
}

CMD:editgate(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}Only RCON admins can use this command.");
	if(EditingGateID[playerid] != -1) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You're already editing a gate.");
	new id;
	sscanf(params, "I(-2)", id);
	if(id == -2) id = GetClosestGate(playerid);
	if(id == -1) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You're not near a gate.");
	if(GateData[id][GateEditing]) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}Gate is being edited.");
	if(!IsPlayerInRangeOfPoint(playerid, 20.0, GateData[id][GatePos][0], GateData[id][GatePos][1], GateData[id][GatePos][2])) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You're not near the gate you want to edit.");
	GateData[id][GateEditing] = true;
	EditingGateID[playerid] = id;
	ShowEditMenu(playerid, id);
	return 1;
}
