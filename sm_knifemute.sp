#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>
#include <colors>

#define PLUGIN_VERSION "3.0"
 

bool g_bIsEnabled[MAXPLAYERS + 1];

ConVar g_cvarPluginEnabled;

public Plugin myinfo =
{
	name = "Mutes knife sounds",
	author = "Nano & GAMMACASE",
	description = "Mutes knife sounds against friendly targets when no damage is dealt.",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/marianzet1"
}

bool g_bPlayerHitted[MAXPLAYERS];
bool g_bPlayerDisable[MAXPLAYERS];

public void OnPluginStart()
{
	RegConsoleCmd("sm_knifemute", Command_muteknife, "Mutes knife sounds.");
	RegConsoleCmd("sm_muteknife", Command_muteknife, "Mutes knife sounds.");	
	RegConsoleCmd("sm_mk", Command_muteknife, "Mutes knife sounds.");		

	g_cvarPluginEnabled = CreateConVar("mk_enable", "1", "1 - Enable the plugin | 0 - Disable the plugin");	
	
	AddNormalSoundHook(NSound_CallBack);
	HookEvent("player_hurt", PlayerHurt_Event, EventHookMode_Pre);
}

public OnClientPostAdminCheck(Client)
{
    g_bIsEnabled[Client] = false;
}

public OnClientDisconnect(Client)
{
    g_bIsEnabled[Client] = false;
}

public Action Command_muteknife(int client, int args)
{
	if (!g_cvarPluginEnabled.BoolValue) {
		CPrintToChat(client, "{green}[{lightgreen}Mute-Knife{green}] The plugin is {purple}disabled{default}. Please try again later.");        
		return Plugin_Handled;
	}
	
	g_bPlayerDisable[client] = !g_bPlayerDisable[client];
	
	if(!g_bIsEnabled[client])
    {
		g_bIsEnabled[client] = true;
		CPrintToChat(client, "{green}[{lightgreen}Mute-Knife{green}] {purple}Disabled{default} the sound of the knifes.");
		PrintCenterText(client, "You have disabled the sound of the knifes");
		return Plugin_Changed;
    }
	else
	{
		g_bIsEnabled[client] = false;
		CPrintToChat(client, "{green}[{lightgreen}Mute-Knife{green}] {purple}Enabled{default} the sound of the knifes.");
		PrintCenterText(client, "You have enabled the sound of the knifes");
		return Plugin_Changed;
	}	

}	

public void OnClientPutInServer(int client)
{
	g_bPlayerHitted[client] = false;
	g_bPlayerDisable[client] = false;
}

public Action PlayerHurt_Event(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	
	g_bPlayerHitted[attacker] = true;
}

public Action NSound_CallBack(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	char classname[32];
	GetEdictClassname(entity, classname, sizeof(classname));
	
	if(StrContains(sample, "flesh") != -1 || StrContains(sample, "kevlar") != -1)
	{
		CheckClients(clients, numClients);
		
		return Plugin_Changed;
	}
	
	if(StrContains(classname, "knife") != -1)
	{
		int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		
		if(!IsValidClient(client, false))
			return Plugin_Continue;
		
		if(g_bPlayerHitted[client])
		{
			g_bPlayerHitted[client] = false;
			return Plugin_Continue;
		}
		
		CheckClients(clients, numClients);
		
		g_bPlayerHitted[client] = false;
		
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

stock void CheckClients(int[] clients, int &numClients)
{
	for(int i = 0; i < numClients; i++)
		if(g_bPlayerDisable[clients[i]])
		{
			for (int j = i; j < numClients-1; j++)
				clients[j] = clients[j+1];
			
			numClients--;
			i--;
		}
}

stock bool IsValidClient(int client, bool botcheck = true)
{
	return (1 <= client && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && (botcheck ? !IsFakeClient(client) : true)); 
}