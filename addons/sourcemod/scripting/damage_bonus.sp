#include <sourcemod.inc>
#include <left4downtown.inc>
#include <sdkhooks>
#include <sdktools>

#define MAX(%0,%1) (((%0) > (%1)) ? (%0) : (%1))

public Plugin:myinfo =
{
	name = "Damage Scoring",
	author = "CanadaRox",
	description = "Custom damage scoring based on damage and a static bonus.  (It sounds as bad as vanilla but its not!!)",
	version = "0.9",
	url = "nope"
};

new Handle: hSurvivalBonusCvar;
new         iSurvivalBonusDefault;

new Handle: hTieBreakBonusCvar;
new         iTieBreakBonusDefault;

new Handle: hPluginEnabled;
new bool:   bPluginEnabled;

new Handle: hStaticBonusCvar;
new Handle: hMaxDamageCvar;
new Handle: hDamageMultiCvar;

new         iHealth[MAXPLAYERS + 1];
new         iTotalDamage[2];
new         iTotalBonus[2];

new         iRoundNumber;
new bool:   bInRound;

public OnPluginStart()
{
	// Score Change Triggers
	HookEvent("door_close", DoorClose_Event);
	HookEvent("player_death", PlayerDeath_Event);
	HookEvent("finale_vehicle_leaving", FinaleVehicleLeaving_Event, EventHookMode_PostNoCopy);

	HookEvent("round_start", RoundStart_Event, EventHookMode_PostNoCopy);
	HookEvent("round_end", RoundEnd_Event, EventHookMode_PostNoCopy);

	// Save default Cvar value
	hSurvivalBonusCvar = FindConVar("vs_survival_bonus");
	iSurvivalBonusDefault = GetConVarInt(hSurvivalBonusCvar);

	hTieBreakBonusCvar = FindConVar("vs_tiebreak_bonus");
	iTieBreakBonusDefault = GetConVarInt(hTieBreakBonusCvar);
	SetConVarInt(hTieBreakBonusCvar, 0);

	// Enable Cvar
	hPluginEnabled = CreateConVar("sm_dmgscore_enabled", "1", "Enable custom scoring based on distance, damage and survival bonus", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	bPluginEnabled = GetConVarBool(hPluginEnabled);
	//HookConVarChange(hPluginEnabled, CvarEnabled_Change);
	
	// Configuration Cvars
	hStaticBonusCvar = CreateConVar("sm_static_bonus", "25.0", "Extra static bonus that is awarded per survivor for completing the map", FCVAR_PLUGIN, true, 0.0);
	hMaxDamageCvar = CreateConVar("sm_max_damage", "800.0", "Max damage used for calculation (controls x in [x - damage])", FCVAR_PLUGIN);
	hDamageMultiCvar = CreateConVar("sm_damage_multi", "1.0", "Multiplier to apply to damage before subtracting it from the max damage", FCVAR_PLUGIN, true, 0.0);

	RegConsoleCmd("sm_damage", Damage_Cmd, "Prints the damage taken by both teams");
	RegConsoleCmd("sm_bonus", Bonus_Cmd, "Prints the damage bonus for the current round");
}

public OnPluginEnd()
{
	SetConVarInt(hSurvivalBonusCvar, iSurvivalBonusDefault);
	SetConVarInt(hTieBreakBonusCvar, iTieBreakBonusDefault);
}

public OnMapStart()
{
	iTotalDamage[0] = 0;
	iTotalDamage[1] = 0;

	iTotalBonus[0] = 0;
	iTotalBonus[1] = 0;
}

public OnMapEnd()
{
	iRoundNumber = 0;
	bInRound = false;
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
}

public Action:Damage_Cmd(client, args)
{
	if (client)
	{
		PrintToChat(client, "Team 1 damage taken: %d\nTeam 2 damage taken: %d", iTotalDamage[0], iTotalDamage[1]);
	}
	else
	{
		PrintToServer("Team 1 damage taken: %d\nTeam 2 damage taken: %d", iTotalDamage[0], iTotalDamage[1]);
	}
}

public Action:Bonus_Cmd(client, args)
{
	new iCurrentBonus = CalculateSurvivalBonus() * GetAliveSurvivors();

	if (client)
	{
		PrintToChat(client, "Current bonus: %d", iCurrentBonus);
	}
	else
	{
		PrintToServer("Current bonus: %d", iCurrentBonus);
	}
}


public RoundStart_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!bInRound)
	{
		bInRound = true;
		iRoundNumber++;
	}
}

public RoundEnd_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (bInRound)
	{
		bInRound = false;

		if (iRoundNumber == 1)
		{
			//PrintToChatAll("Bonus (Round 1): %d", iTotalBonus[0]);
		}
		else if (iRoundNumber == 2)
		{
			//PrintToChatAll("Bonus (Round 2): %d", iTotalBonus[1]);
		}
	}
}

public DoorClose_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetEventBool(event, "checkpoint"))
	{
		new iBonusPerSurvivor = CalculateSurvivalBonus();
		iTotalBonus[iRoundNumber - 1] = iBonusPerSurvivor * GetAliveSurvivors();
		SetConVarInt(hSurvivalBonusCvar, iBonusPerSurvivor);
	}
}

public PlayerDeath_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (client && IsSurvivor(client))
	{
		new iBonusPerSurvivor = CalculateSurvivalBonus();
		iTotalBonus[iRoundNumber - 1] = iBonusPerSurvivor * GetAliveSurvivors();
		SetConVarInt(hSurvivalBonusCvar, iBonusPerSurvivor);
	}
}

public FinaleVehicleLeaving_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i < MaxClients; i++)
	{
		if (IsClientInGame(i) && IsSurvivor(i) && IsPlayerIncap(i))
		{
			ForcePlayerSuicide(i);
		}
	}
	
	new iBonusPerSurvivor = CalculateSurvivalBonus();
	iTotalBonus[iRoundNumber - 1] = iBonusPerSurvivor * GetAliveSurvivors();
	SetConVarInt(hSurvivalBonusCvar, iBonusPerSurvivor);
}

/* Record the health of a survivor JUST BEFORE he/she takes damage */
public OnTakeDamage(victim, attacker, inflictor, Float:damage, damagetype)
{
	iHealth[victim] = (!IsSurvivor(victim) || (IsPlayerIncap(victim) && !IsPlayerHanging(victim))) ? 0 : (GetSurvivorPermanentHealth(victim) + GetSurvivorTempHealth(victim));
}

/* Add to the total damage done based on the state (normal/incap/hanging) of the survivor and his/her health AFTER taking damage */
//NOTE: what would happen if a player shot the witch and then ledged themselves?
//NOTE: what would happen in custom campaigns with recoverable loss of health while underwater?
public OnTakeDamagePost(victim, attacker, inflictor, Float:damage, damagetype)
{
	if (iHealth[victim])
	{
		if (!IsPlayerAlive(victim) || (IsPlayerIncap(victim) && !IsPlayerHanging(victim)))
		{
			iTotalDamage[iRoundNumber-1] += iHealth[victim];
		}
		else
		{
			if (IsPlayerHanging(victim))
			{
				iTotalDamage[iRoundNumber-1] += (iHealth[victim] - (GetSurvivorPermanentHealth(victim) + GetSurvivorTempHealth(victim)))/3;
			}
			else
			{
				iTotalDamage[iRoundNumber-1] += iHealth[victim] - (GetSurvivorPermanentHealth(victim) + GetSurvivorTempHealth(victim));
			}
		}
	}
}

stock GetDamage(round=-1)
{
	return (round == -1) ? iTotalDamage[iRoundNumber-1] : iTotalDamage[round];
}

stock bool:IsPlayerIncap(client) return bool:GetEntProp(client, Prop_Send, "m_isIncapacitated");
stock bool:IsPlayerHanging(client) return bool:GetEntProp(client, Prop_Send, "m_isHangingFromLedge");

stock GetSurvivorTempHealth(client)
{
	new temphp = RoundToCeil(GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - ((GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * GetConVarFloat(FindConVar("pain_pills_decay_rate")))) - 1;
	return (temphp > 0 ? temphp : 0);
}

stock GetSurvivorPermanentHealth(client) return GetEntProp(client, Prop_Send, "m_iHealth");

stock CalculateSurvivalBonus()
{
	new iAllSurvivors = GetAllSurvivors();
	new iMapDistance = L4D_GetVersusMaxCompletionScore();

	new Float:fPercentageOfDamageReceived = ((GetDamage() < GetConVarFloat(hMaxDamageCvar)) ? GetDamage() : GetConVarFloat(hMaxDamageCvar)) / GetConVarFloat(hMaxDamageCvar);

	new Float:fPercentageOfBonusReceived = (fPercentageOfDamageReceived * fPercentageOfDamageReceived) - (2.0 * fPercentageOfDamageReceived) + 1.0;

	if (fPercentageOfBonusReceived < 0.0)
	{
		fPercentageOfBonusReceived = 0.0;
	}
	else if (fPercentageOfBonusReceived > 1.0)
	{
		fPercentageOfBonusReceived = 1.0;
	}

	return RoundToFloor( ((iMapDistance * fPercentageOfBonusReceived) / iAllSurvivors) + GetConVarFloat(hStaticBonusCvar) );
}

stock GetAliveSurvivors()
{
	new iAliveCount;
	new iSurvivorCount;
	for (new i = 1; i < MaxClients && iSurvivorCount < 4; i++)
	{
		if (IsSurvivor(i))
		{
			iSurvivorCount++;
			if (IsPlayerAlive(i)) iAliveCount++;
		}
	}
	return iAliveCount;
}

stock GetAllSurvivors()
{
	new iSurvivorCount;
	for (new i = 1; i < MaxClients && iSurvivorCount < 4; i++)
	{
		if (IsSurvivor(i))
		{
			iSurvivorCount++;
		}
	}
	return iSurvivorCount;
}

stock bool:IsSurvivor(client)
{
	return IsClientInGame(client) && GetClientTeam(client) == 2;
}
