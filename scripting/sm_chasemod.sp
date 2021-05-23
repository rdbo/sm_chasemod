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
ConVar g_cvRespawnHealth;

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if (!g_cvChaseModEnabled.BoolValue)
        return Plugin_Continue;
        
    int health = GetClientHealth(victim);
    
    if (!IsClientInGame(attacker) || attacker == victim)
    {
        if (damage >= health)
        {
            CS_RespawnPlayer(victim);
            SetEntityHealth(victim, g_cvRespawnHealth.IntValue);
            damage = 0.0;
            
            return Plugin_Continue;
        }
    }
    
    int victim_team = GetClientTeam(victim);
    int attacker_team = GetClientTeam(attacker);
    
    if (attacker_team != CS_TEAM_CT || victim_team != CS_TEAM_T || !(damagetype & DMG_SLASH))
    {
        damage = 0.0;
        return Plugin_Continue;
    }
    
    if (damage >= health)
    {
        if (attacker != victim)
        {
            char victim_name[64] = { 0 };
            char attacker_name[64] = { 0 };
            
            GetClientName(victim, victim_name, sizeof(victim_name));
            GetClientName(attacker, attacker_name, sizeof(attacker_name));
            PrintToChat(victim, "[SM] You have been killed by '%s'", attacker_name);
            PrintToChat(attacker, "[SM] You killed '%s'", victim_name);
            
            CS_SwitchTeam(victim, attacker_team);
            CS_SwitchTeam(attacker, victim_team);
            
            CS_RespawnPlayer(attacker);
        }
        
        CS_RespawnPlayer(victim);
        
        SetEntityHealth(victim, g_cvRespawnHealth.IntValue);
        SetEntityHealth(attacker, g_cvRespawnHealth.IntValue);
        
        damage = 0.0;
    }
    
    return Plugin_Continue;
}

public void OnPluginStart()
{
    g_cvChaseModEnabled = CreateConVar("sm_chasemod_enabled", "1", "Enable ChaseMod");
    g_cvRespawnHealth = CreateConVar("sm_chasemod_health", "100", "Respawn Health");
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
