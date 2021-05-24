#include <sourcemod>
#include <cstrike>
#include <sdkhooks>
#include <sdktools>

#define MAX_WEAPONS 48

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
    if (!g_cvChaseModEnabled.BoolValue || !IsClientInGame(attacker))
        return Plugin_Continue;
    
    if (GetClientTeam(attacker) != CS_TEAM_CT)
        return Plugin_Handled;
        
    return Plugin_Continue;
}

public Action HkPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    
    if (!g_cvChaseModEnabled.BoolValue || !IsClientInGame(attacker))
        return Plugin_Continue;
        
    if (GetClientTeam(attacker) != CS_TEAM_CT)
        return Plugin_Handled;
        
    return Plugin_Continue;
}

public Action HkPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_cvChaseModEnabled.BoolValue)
        return Plugin_Continue;
    
    int client = GetClientOfUserId(event.GetInt("userid"));
    
    if (!IsClientInGame(client))
        return Plugin_Continue;
        
    int team = GetClientTeam(client);
    
    RemoveWeapons(client);
    
    if (team == CS_TEAM_CT)
    {
        AddWeapon(client, "weapon_knife");
    }
    
    return Plugin_Continue;
}

public Action HkRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_cvChaseModEnabled.BoolValue)
        return Plugin_Continue;
    
    for (int i = 1; i < MaxClients; ++i)
    {
        if (IsClientInGame(i))
        {
            int team = GetClientTeam(i);
            switch (team)
            {
            case CS_TEAM_CT:
                {
                    CS_SwitchTeam(i, CS_TEAM_T);
                }
            case CS_TEAM_T:
                {
                    CS_SwitchTeam(i, CS_TEAM_CT);
                }
            }
        }
    }
    
    return Plugin_Continue;
}

public void OnPluginStart()
{
    PrintToServer("[SM] ChaseMod Loaded");
    g_cvChaseModEnabled = CreateConVar("sm_chasemod_enabled", "1", "Enable ChaseMod");
    HookEvent("round_end", HkRoundEnd, EventHookMode_PostNoCopy);
    HookEvent("player_spawn", HkPlayerSpawn, EventHookMode_PostNoCopy);
    HookEvent("player_death", HkPlayerDeath, EventHookMode_Pre);
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

void RemoveWeapons(int client)
{
    int offset = FindDataMapInfo(client, "m_hMyWeapons");
    
    for (int i = 0; i < MAX_WEAPONS; ++i)
    {
        offset += 4;
        int weapon = GetEntDataEnt2(client, offset);
        if (weapon == -1)
            continue;
        
        if (RemovePlayerItem(client, weapon))
            AcceptEntityInput(weapon, "Kill");
    }
}

void AddWeapon(int client, char[] classname)
{
    float origin[3];
    float angles[3];
    
    GetEntPropVector(client, Prop_Send, "m_vecOrigin", origin);
    GetEntPropVector(client, Prop_Data, "m_angAbsRotation", angles);
    
    int weapon = CreateEntityByName(classname, -1);
    
    if (weapon != -1)
    {
        TeleportEntity(weapon, origin, angles, NULL_VECTOR);
        DispatchSpawn(weapon);
        SetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity", client);
        EquipPlayerWeapon(client, weapon);
        SetEntPropEnt(client, Prop_Data, "m_hActiveWeapon", weapon);
        ChangeEdictState(client, FindDataMapInfo(client, "m_hActiveWeapon"));
    }
}
