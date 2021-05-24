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
    if (!g_cvChaseModEnabled.BoolValue || !IsClientInGame(attacker) || !(damagetype & (DMG_SLASH | DMG_BULLET)))
        return Plugin_Continue;
    
    int attacker_team = GetClientTeam(attacker);
    
    if (!(damagetype & DMG_SLASH) || attacker_team != CS_TEAM_CT)
        return Plugin_Handled;
        
    return Plugin_Continue;
}

public Action HkRoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
    for (int i = 1; i < MaxClients; ++i)
    {
        if (IsClientInGame(i))
        {
            int team = GetClientTeam(i);
            switch (team)
            {
            case CS_TEAM_CT:
                CS_SwitchTeam(i, CS_TEAM_T);
            case CS_TEAM_T:
                CS_SwitchTeam(i, CS_TEAM_CT);
            }
        }
    }
    
    return Plugin_Continue;
}

public void OnPluginStart()
{
    g_cvChaseModEnabled = CreateConVar("sm_chasemod_enabled", "1", "Enable ChaseMod");
    HookEvent("round_end", HkRoundEnd, EventHookMode_PostNoCopy);
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
