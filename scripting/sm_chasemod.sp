#include <sourcemod>
#include <cstrike>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
    name        = "ChaseMod",
    author      = "rdbo",
    description = "Classic HNS (ChaseMod)",
    version     = "1.0.0",
    url         = ""
};

ConVar g_cvChaseModEnabled;

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    int health = GetClientHealth(victim);
    
    if (!g_cvChaseModEnabled.BoolValue || !IsClientInGame(attacker))
        return Plugin_Continue;
    
    if (damage >= health)
    {
        if (attacker == victim)
        {
            PrintToChat(victim, "[SM] You died.");
            return Plugin_Continue;
        }
        
        int victim_team = GetClientTeam(victim);
        int attacker_team = GetClientTeam(attacker);
        char victim_name[64] = { 0 };
        char attacker_name[64] = { 0 };
        
        GetClientName(victim, victim_name, sizeof(victim_name));
        GetClientName(attacker, attacker_name, sizeof(attacker_name));
        PrintToChat(victim, "[SM] You have been killed by '%s'", attacker_name);
        PrintToChat(attacker, "[SM] You killed '%s'", victim_name);
        
        CS_SwitchTeam(victim, attacker_team);
        CS_SwitchTeam(attacker, victim_team);
        
        CS_RespawnPlayer(victim);
        CS_RespawnPlayer(attacker);
    }
    
    return Plugin_Continue;
}

public void OnPluginStart()
{
    g_cvChaseModEnabled = CreateConVar("sm_chasemod_enabled", "1", "Enable ChaseMod");
    PrintToServer("[SM] ChaseMod Loaded");
}

public void OnClientPutInServer(int client)
{	
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void OnClientDisconnect(int client)
{
    SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}
