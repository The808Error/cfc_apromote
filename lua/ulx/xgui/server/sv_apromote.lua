------------------------------
-- APromoteGUI by Lead4u    //
-- Steam: Lead4u2           //
-- Version: 2.1             //
-- Date: 03-11-2015         //
-- If your looking in here  //
-- feel free to send me a   //
-- message about any issues //
------------------------------

--[[ TODO: Fix cfc_time so that we can enable this line
if ULib==nil or GetConVarString("utime_welcome")== "" then print("WARNING: Missing dependancy UTime/ULX/ULib APromote is now inactive.") return end
]]
util.AddNetworkString( "APromoteShinys" )

ULib.ucl.registerAccess( "apromote_settings", "superadmin", "Allows managing all settings related to APromote.", "XGUI" )

local APromote = {}
local set = {} APromote.set = set
local grp = {} APromote.grp = grp


local function APUpdateGroups()
	for k, v in pairs(ULib.ucl.groups) do
		if ( APromote["grp"][k] == nil and k ~= "user") then
			print("Added " .. k .. " to APromote.")
			APromote["grp"][k] = -1
		end
	end

	for k, v in pairs(APromote["grp"]) do
		if k ~= nil and not ULib.ucl.groups[k] or k == "user" then
			print("Removed " .. k .. " from APromote.")
			APromote["grp"][k] = nil
		end
	end

	xgui.sendDataTable( {}, "AP_SendData" )
	file.Write("apromote/settings.txt", util.TableToJSON(APromote))
end

local function loadAP()
	xgui.addDataType( "AP_SendData", function()
		return APromote.grp
	end, "apromote_settings", 0, 0 )
	
	-- File Stuffs
	if not file.Exists("apromote/settings.txt", "DATA") then
		for k, v in pairs(ULib.ucl.groups) do
			APromote.grp[k] = -1
		end
		APromote.set.ap_enabled = 1
		APromote.set.ap_snd_enabled = 1
		APromote.set.ap_snd_scope = 1
		APromote.set.ap_effect_enabled = 1
		APromote.set.ap_auto_demote = 0
		file.CreateDir("apromote")
		file.Write("apromote/settings.txt", util.TableToJSON(APromote))
	else 
		APromote = util.JSONToTable(file.Read( "apromote/settings.txt" ))
	end

	-- ConVars
	ULib.replicatedWritableCvar("ap_enabled","rep_ap_enabled", APromote.set.ap_enabled, false,false,"apromote_settings")
	ULib.replicatedWritableCvar("ap_snd_enabled","rep_ap_snd_enabled",APromote.set.ap_snd_enabled ,false,false,"apromote_settings")
	ULib.replicatedWritableCvar("ap_snd_scope","rep_ap_snd_scope",APromote.set.ap_snd_scope ,false,false,"apromote_settings")
	ULib.replicatedWritableCvar("ap_effect_enabled","rep_ap_effect_enabled",APromote.set.ap_effect_enabled ,false,false,"apromote_settings")
	ULib.replicatedWritableCvar("ap_auto_demote","rep_ap_auto_demote",APromote.set.ap_auto_demote ,false,false,"apromote_settings")

	-- Data and Hook Add	
	xgui.sendDataTable( {}, "AP_SendData" )
	hook.Add( "UCLChanged", "doApUpdateSV", APUpdateGroups )
end

local function cVarChange( sv_cvar, cl_cvar, ply, old_val, new_val )
	if ( sv_cvar =="ap_enabled" or sv_cvar=="ap_snd_enabled" or sv_cvar=="ap_snd_scope" or sv_cvar=="ap_effect_enabled" or sv_cvar=="ap_auto_demote" ) then
		APromote["set"][sv_cvar] = new_val
		file.Write("apromote/settings.txt", util.TableToJSON(APromote))
	end
end


local function PlayRankSound( ply )
	net.Start( "APromoteShinys" )
	net.WriteBool( GetConVarNumber( "ap_snd_enabled" ) == 1 )
	net.WriteBool( GetConVarNumber( "ap_effect_enabled" ) == 1 )

	if GetConVarNumber( "ap_effect_enabled" ) == 1 then
		net.WritePlayer( ply )
	end

	net.Broadcast()
end
	
local function isValidCommand( command, compare )
	for k in pairs( compare ) do
		if command[1] == k then
			if isnumber( command[2] ) then
				return true
			end
		end
	end

	return false
end

concommand.Add("APGroup", function( ply, cmd, args )
	if not ply:query( "apromote_settings" ) then return end
	if not isValidCommand( args, APromote.grp ) then return end

	APromote.grp[args[1]] = tonumber(args[2])
	xgui.sendDataTable( {}, "AP_SendData" )
	file.Write("apromote/settings.txt", util.TableToJSON(APromote))
end)
 
local function checkPlayer( ply ) 
	local plyhours = tonumber(math.floor((ply:GetUTime() + CurTime() - ply:GetUTimeStart())/60/60))
	local usrgrp = ply:GetUserGroup()
	local Rank = ""
	local Hours = 0

	for k, v in pairs(APromote.grp) do
		v = tonumber(v)

		if plyhours >= v and v >= Hours then
			if v >= 0 then
				Rank = k
				Hours = v
			end
		end
	end

	if not ply:IsUserGroup(Rank) and Rank ~= "" then
		if tonumber(APromote.grp[usrgrp]) == -1 then return end
		if GetConVarNumber("ap_auto_demote") == 0 and APromote.grp[usrgrp] ~= nil and Hours < APromote.grp[usrgrp] then return end
		
		RunConsoleCommand( "ulx", "adduserid", ply:SteamID(), Rank )
		PlayRankSound( ply )
	end
end

timer.Create("doAPUpdateTimer",10,0, function()
	if GetConVarNumber( "ap_enabled" ) ~= 1 then return end

	for _, ply in player.Iterator() do
		if not ply:IsBot() then
			checkPlayer( ply )
		end
	end
end)

xgui.addSVModule( "AP_LoadAP", loadAP )
hook.Add( "ULibReplicatedCvarChanged", "APGroupCVAR", cVarChange )
