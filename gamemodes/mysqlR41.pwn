#include <a_samp>
#include <a_mysqlR41>
#include <foreach>

//Configuring MySQL Stuff to set up the connection

#define MYSQL_HOST        "127.0.0.1" // Change this to your MySQL Remote IP or "localhost".
#define MYSQL_USER        "root" // Change this to your MySQL Database username.
#define MYSQL_PASS        "" // Change this to your MySQL Database password.
#define MYSQL_DATABASE    "sampdb" // Change this to your MySQL Database name.

// Well, don't just enter random information and expect it to work, information
// Should be valid and working fine.

#define DIALOG_REGISTER        (0)
#define DIALOG_LOGIN           (1)

// Make sure the dialog IDs above do not match any dialog ID you're using in your
// gamemode otherwise they won't do their job properly.

new MySQL: Database, Corrupt_Check[MAX_PLAYERS];

//Creating an enumerator to store player's data for further use (below).

//==============================================================================

enum ENUM_PLAYER_DATA
{
	ID,
	Name[25],

	Password[65],
	Salt[11],

	PasswordFails,

	Kills,
	Deaths,

	Score,
	Cash,
	Tokens,

	Explvl,
	Civlvl,
	Admlvl,
	Member,

	Cache: Player_Cache,
	bool:LoggedIn
}

new pInfo[MAX_PLAYERS][ENUM_PLAYER_DATA];

//==============================================================================

public OnGameModeInit()
{
	new MySQLOpt: option_id = mysql_init_options();
	mysql_set_option(option_id, AUTO_RECONNECT, true); // We will set that option to automatically reconnect on timeouts.

	Database = mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_PASS, MYSQL_DATABASE, option_id); // Setting up the "Database" handle on the given MySQL details above.

	if(Database == MYSQL_INVALID_HANDLE || mysql_errno(Database) != 0) // Checking if the database connection is invalid to shutdown.
	{
		print("I couldn't connect to the MySQL server, closing."); // Printing a message to the log.

		SendRconCommand("exit"); // Sending console command to shut down server.
		return 1;
	}

	print("I have connected to the MySQL server."); // If the given MySQL details were all okay, this message prints to the log.

	// Now, we will set up the information table of the player's information.

	mysql_tquery(Database, "CREATE TABLE IF NOT EXISTS `PLAYERS`\
	(`ID` int(11) NOT NULL AUTO_INCREMENT,\
	`USERNAME` varchar(24) NOT NULL,\
	`PASSWORD` char(65) NOT NULL,\
	`SALT` char(11) NOT NULL,\
	`SCORE` mediumint(7),\
	`TOKENS` mediumint(7),\
	`EXP` mediumint(7),\
	`CIVLIAN` mediumint(7),\
	`ADMIN` mediumint(7),\
	`MEMBER` mediumint(7),\
 	`KILLS` mediumint(7),\
 	`CASH` mediumint(7) NOT NULL DEFAULT '0',\
 	`DEATHS` mediumint(7) NOT NULL DEFAULT '0',\
	PRIMARY KEY (`ID`),\
 	UNIQUE KEY `USERNAME` (`USERNAME`))");

	// So, this code is probably the only one which you haven't understood.
	// Well, we firstly create a table only if not existing in the database which is "USERS".
	// We create "ID" and set it as a primary key with auto increment to use it in retrieving information and many more uses.
	// We create "USERNAME" and set it as a unique key, the USERNAME stores every player's name in the database so you can
	// Control the players in offline mode and when a player leaves everything storted like kills, deaths, password and Saltion key
	// Wouldn't be lost upon server's close or player's disconnection.
	// We store kills, deaths, score and cash as written above so they might be useful for further use.

	return 1;
}

main()
{
	print("\n----------------------------------");
	print(" Blank Gamemode by your name here");
	print("----------------------------------\n");
}

public OnGameModeExit()
{
	foreach(new i: Player)
    {
		if(IsPlayerConnected(i)) // Checking if the players stored in "i" are connected.
		{
			OnPlayerDisconnect(i, 1); // We do that so players wouldn't lose their data upon server's close.
		}
	}

	mysql_close(Database); // Closing the database.
	return 1;
}

public OnPlayerConnect(playerid)
{
	new DB_Query[115];

	//Resetting player information.
	pInfo[playerid][Kills] = 0;
	pInfo[playerid][Deaths] = 0;
	pInfo[playerid][PasswordFails] = 0;

	GetPlayerName(playerid, pInfo[playerid][Name], MAX_PLAYER_NAME); // Getting the player's name.
	Corrupt_Check[playerid]++;

	mysql_format(Database, DB_Query, sizeof(DB_Query), "SELECT * FROM `PLAYERS` WHERE `USERNAME` = '%e' LIMIT 1", pInfo[playerid][Name]);
	mysql_tquery(Database, DB_Query, "OnPlayerDataCheck", "ii", playerid, Corrupt_Check[playerid]);
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	Corrupt_Check[playerid]++;

	new DB_Query[256];
	//Running a query to save the player's data using the stored stuff.
	mysql_format(Database, DB_Query, sizeof(DB_Query), "UPDATE `PLAYERS` SET `KILLS` = %d,\
	`DEATHS` = %d,\
	`SCORE` = %d,\
	`CASH` = %d,\
	`TOKENS` = %d,\
	`EXPLVL` = %d,\
	`CIVLVL` = %d,\
	`ADMLVL` = %d,\
	`MEMBER` = %d, WHERE `ID` = %d LIMIT 1",
	pInfo[playerid][Score], pInfo[playerid][Cash], pInfo[playerid][Kills], pInfo[playerid][Deaths], pInfo[playerid][ID]);

	mysql_tquery(Database, DB_Query);

	if(cache_is_valid(pInfo[playerid][Player_Cache])) //Checking if the player's cache ID is valid.
	{
		cache_delete(pInfo[playerid][Player_Cache]); // Deleting the cache.
		pInfo[playerid][Player_Cache] = MYSQL_INVALID_CACHE; // Setting the stored player Cache as invalid.
	}

	pInfo[playerid][LoggedIn] = false;
	print("OnPlayerDisconnect has been called."); // Sending message once OnPlayerDisconnect is called.
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	if(killerid != INVALID_PLAYER_ID) // Checking if the killer of the player is valid.
	{
		//Increasing the kills of the killer and the deaths of the player.
	    pInfo[killerid][Kills]++;
	    pInfo[playerid][Deaths]++;
	}
	return 1;
}

public OnPlayerRequestSpawn(playerid)
{
	if(pInfo[playerid][LoggedIn] == false) return 0; // Ignoring the request incase player isn't logged in.
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	switch (dialogid)
	{
		case DIALOG_LOGIN:
		{
			if(!response) return Kick(playerid);

			new Salted_Key[65];
			SHA256_PassHash(inputtext, pInfo[playerid][Salt], Salted_Key, 65);

			if(strcmp(Salted_Key, pInfo[playerid][Password]) == 0)
			{
				// Now, password should be correct as well as the strings
				// Matched with each other, so nothing is wrong until now.

				// We will activate the cache of player to make use of it e.g.
				// Retrieve their data.

				cache_set_active(pInfo[playerid][Player_Cache]);

				// Okay, we are retrieving the information now..
            	cache_get_value_int(0, "ID", pInfo[playerid][ID]);

        		cache_get_value_int(0, "KILLS", pInfo[playerid][Kills]);
        		cache_get_value_int(0, "DEATHS", pInfo[playerid][Deaths]);

        		cache_get_value_int(0, "SCORE", pInfo[playerid][Score]);
        		cache_get_value_int(0, "CASH", pInfo[playerid][Cash]);
        		cache_get_value_int(0, "TOKENS", pInfo[playerid][Tokens]);

        		cache_get_value_int(0, "EXPLVL", pInfo[playerid][Explvl]);
        		cache_get_value_int(0, "CIVLVL", pInfo[playerid][Civlvl]);
        		cache_get_value_int(0, "ADMLVL", pInfo[playerid][Admlvl]);
        		cache_get_value_int(0, "MEMBER", pInfo[playerid][Member]);

        		SetPlayerScore(playerid, pInfo[playerid][Score]);

        		ResetPlayerMoney(playerid);
        		GivePlayerMoney(playerid, pInfo[playerid][Cash]);

				// So, we have successfully retrieved data? Now deactivating the cache.

				cache_delete(pInfo[playerid][Player_Cache]);
				pInfo[playerid][Player_Cache] = MYSQL_INVALID_CACHE;

				pInfo[playerid][LoggedIn] = true;
				SendClientMessage(playerid, 0x00FF00FF, "Logged in to the account.");
			}
			else
			{
			    new String[150];

				pInfo[playerid][PasswordFails] += 1;
				printf("%s has been failed to login. (%d)", pInfo[playerid][Name], pInfo[playerid][PasswordFails]);
				// Printing the message that someone has failed to login to his account.

				if (pInfo[playerid][PasswordFails] >= 3) // If the fails exceeded the limit we kick the player.
				{
					format(String, sizeof(String), "%s has been kicked Reason: {FF0000}(%d/3) Login fails.", pInfo[playerid][Name], pInfo[playerid][PasswordFails]);
					SendClientMessageToAll(0x969696FF, String);
					Kick(playerid);
				}
				else
				{
					// If the player didn't exceed the limits we send him a message that the password is wrong.
					format(String, sizeof(String), "Wrong password, you have %d out of 3 tries.", pInfo[playerid][PasswordFails]);
					SendClientMessage(playerid, 0xFF0000FF, String);

              		format(String, sizeof(String), "{FFFFFF}Welcome back, %s.\n\n{0099FF}This account is already registered.\n\
            		{0099FF}Please, input your password below to proceed to the game.\n\n", pInfo[playerid][Name]);
            		ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Login System", String, "Login", "Leave");
				}
			}
		}
		case DIALOG_REGISTER:
		{
			if(!response) return Kick(playerid);

			if(strlen(inputtext) <= 5 || strlen(inputtext) > 60)
			{
			    // If the password length is less than or equal to 5 and more than 60
			    // It repeats the process and shows error message as seen below.

		    	SendClientMessage(playerid, 0x969696FF, "Invalid password length, should be 5 - 60.");

				new String[150];

    	    	format(String, sizeof(String), "{FFFFFF}Welcome %s.\n\n{0099FF}This account is not registered.\n\
    	     	{0099FF}Please, input your password below to proceed.\n\n", pInfo[playerid][Name]);
	        	ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, "Registration System", String, "Register", "Leave");
			}
			else
			{

    			// Salting the player's password using SHA256 for a better security.

                for (new i = 0; i < 10; i++)
                {
                    pInfo[playerid][Salt][i] = random(79) + 47;
	    		}

	    		pInfo[playerid][Salt][10] = 0;
		    	SHA256_PassHash(inputtext, pInfo[playerid][Salt], pInfo[playerid][Password], 65);

		    	new DB_Query[225];

		    	// Storing player's information if everything goes right.
		    	mysql_format(Database, DB_Query, sizeof(DB_Query), "INSERT INTO `PLAYERS` (`USERNAME`, `PASSWORD`, `SALT`, `KILLS`, `DEATHS`, `SCORE`, `CASH`, `TOKENS`, `EXPLVL`, `CIVLVL`, `ADMLVL`, `MEMBER`)\
		    	VALUES ('%e', '%s', '%e', '20', '0', '0', '0', '0', '0', '0', '0', '0', '0')", pInfo[playerid][Name], pInfo[playerid][Password], pInfo[playerid][Salt]);
		     	mysql_tquery(Database, DB_Query, "OnPlayerRegister", "d", playerid);
		     }
		}
	}
	return 1;
}

forward public OnPlayerDataCheck(playerid, corrupt_check);
public OnPlayerDataCheck(playerid, corrupt_check)
{
	if (corrupt_check != Corrupt_Check[playerid]) return Kick(playerid);
	// You'd have asked already what's corrput_check and how it'd benefit me?
	// Well basically MySQL query takes long, incase a player leaves while its not proceeded
	// With ID 1 for example, then another player comes as ID 1 it'll basically corrupt the data
	// So, once the query is done, the player will have the wrong data assigned for himself.

	new String[150];

	if(cache_num_rows() > 0)
	{
		// If the player exists, everything is okay and nothing is wrongly detected
		// The player's password and Saltion key gets stored as seen below
		// So we won't have to get a headache just to match player's password.

		cache_get_value(0, "PASSWORD", pInfo[playerid][Password], 65);
		cache_get_value(0, "SALT", pInfo[playerid][Salt], 11);

		pInfo[playerid][Player_Cache] = cache_save();
		// ^ Storing the cache ID of the player for further use later.

		format(String, sizeof(String), "{FFFFFF}Welcome back, %s.\n\n{0099FF}This account is already registered.\n\
		{0099FF}Please, input your password below to proceed to the game.\n\n", pInfo[playerid][Name]);
		ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Login System", String, "Login", "Leave");
	}
	else
	{
		format(String, sizeof(String), "{FFFFFF}Welcome %s.\n\n{0099FF}This account is not registered.\n\
		{0099FF}Please, input your password below to proceed to the game.\n\n", pInfo[playerid][Name]);
		ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, "Registration System", String, "Register", "Leave");
	}
	return 1;
}

forward public OnPlayerRegister(playerid);
public OnPlayerRegister(playerid)
{
	// This gets called only when the player registers a new account.
	SendClientMessage(playerid, 0x00FF00FF, "You are now registered and has been logged in.");
    pInfo[playerid][LoggedIn] = true;
    return 1;
}

// End of script //
