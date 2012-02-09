#pragma semicolon 1

#include <sourcemod>
#include <weapons>

public Plugin:myinfo =
{
	name = "L4D Magic Pickups",
	author = "CanadaRox",
	description = "Lots of customization for single pickup weapons",
	version = "AOL",
	url = "https://www.github.com/CanadaRox/sourcemod-plugins/tree/master/l4d_magicpickups"
}

new WeaponId:replacement_wepid[_:WeaponId];

public OnPluginStart()
{
	HookEvent("spawner_give_item", SpawnerGiveItem_Event, EventHookMode_Post);

	RegServerCmd("l4d_magicpickup_set", SetReplacement_Cmd, "Sets up a replacement");
	RegServerCmd("l4d_magicpickup_clear", ClearReplacement_Cmd, "Clears all replacements");

	ClearRepArray();

	L4D2Weapons_Init();
}

stock ClearRepArray()
{
	for (new i = 0; i < sizeof(replacement_wepid); i++)
	{
		replacement_wepid[i] = WeaponId:0;
	}
}

public Action:ClearReplacement_Cmd(args)
{
	ClearRepArray();
}

public Action:SetReplacement_Cmd(args)
{
	if (args < 2)
	{
		PrintToServer("Usage: l4d_magicpickup_set <current_wepid> <replacement_wepid> (0 replacement disables the replacement)");
		return Plugin_Handled;
	}

	decl String:sbuff[4];
	decl WeaponId:current_wepid, WeaponId:rep_wepid;

	GetCmdArg(1, sbuff, sizeof(sbuff));
	current_wepid = WeaponId:StringToInt(sbuff);
	GetCmdArg(2, sbuff, sizeof(sbuff));
	rep_wepid = WeaponId:StringToInt(sbuff);

	replacement_wepid[current_wepid] = rep_wepid;

	return Plugin_Handled;
}

/*
bool:IsWeaponHeld(WeaponId:weapon, userId)
{
	new client = GetClientOfUserId(userId);

	PrintToChatAll("User %d is client %d", userId, client);

	if (client > 0 && IsClientConnected(client) && IsClientInGame(client))
	{
		new WeaponId:heldWeapon = IdentifyWeapon(GetPlayerWeaponSlot(client, 0));

		PrintToChatAll("User %d is holding %d; comparing with %d", userId, _:heldWeapon, _:weapon);

		if (_:heldWeapon == _:weapon)
		{
			return true;
		}
	}

	return false;
}

public Action:SpawnerGiveItemPre_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	new spawner = GetEventInt(event, "spawner");
	new userId = GetEventInt(event, "userid");
	new WeaponId:spawner_wepid = IdentifyWeapon(spawner);
	if (IsWeaponHeld(spawner_wepid, userId))
	{
		PrintToChatAll("Weapon %d already held by user %d; stopping events", _:spawner_wepid, userId);
		return Plugin_Handled;
	}

	PrintToChatAll("Weapon %d not held by user %d", _:spawner_wepid, userId);
	return Plugin_Continue;
}*/

public SpawnerGiveItem_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	new spawner = GetEventInt(event, "spawner");
	new WeaponId:spawner_wepid = IdentifyWeapon(spawner);
	if (replacement_wepid[spawner_wepid] != WeaponId:0)
	{
		ConvertWeaponSpawn(spawner, replacement_wepid[spawner_wepid]);
	}
}

