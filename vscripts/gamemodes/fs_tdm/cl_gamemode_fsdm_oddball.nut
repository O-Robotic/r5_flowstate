//Made by @CafeFPS

global function Oddball_HintCatalog
global function Cl_FsOddballInit
global function SetBallPosesionIconOnHud
global function FSDM_GameStateChanged
global function Oddball_BallOrCarrierEntityChanged

struct {
	var activeQuickHint
	var ballRui
} file

void function Cl_FsOddballInit()
{
	RegisterConCommandTriggeredCallback( "+scriptCommand5", AttemptThrowOddball )
	AddClientCallback_OnResolutionChanged( Cl_OnResolutionChanged )
	
	// Muy tarde amigo
	// RegisterNetworkedVariableChangeCallback_int( "FSDM_GameState", FSDM_GameStateChanged )
	// RegisterNetworkedVariableChangeCallback_ent( "FSDM_Oddball_BallOrCarrierEntity", Oddball_BallOrCarrierEntityChanged )
}

void function FSDM_GameStateChanged( entity player, int old, int new, bool actuallyChanged )
{
	if ( !actuallyChanged )
		return

	if( new == eTDMState.IN_PROGRESS )
	{
		Oddball_ToggleScoreboardVisibility( true )
	} else if( new == eTDMState.NEXT_ROUND_NOW )
	{
		Oddball_ToggleScoreboardVisibility( false )
		Oddball_HintCatalog( -1, 0 )
	}
}

void function Cl_OnResolutionChanged()
{
	if( GetGlobalNetInt( "FSDM_GameState" ) != eTDMState.IN_PROGRESS )
	{
		Oddball_ToggleScoreboardVisibility( false )
		return
	}
	
	Oddball_ToggleScoreboardVisibility( true )
}

void function AttemptThrowOddball( entity player )
{
	if ( player != GetLocalViewPlayer() || player != GetLocalClientPlayer() )
		return

	if ( IsControllerModeActive() )
	{
		if ( TryPingBlockingFunction( player, "quickchat" ) )
			return
	}

	player.ClientCommand( "CC_AttemptThrowOddball" )
}

void function Oddball_HintCatalog( int index, int eHandle )
{
	if( !IsValid( GetLocalViewPlayer() ) ) return

	switch(index)
	{
		case 0:
		Oddball_PermaHint( "%scriptCommand5% Throw Ball", true, 9999)
		break
		
		case -1:
		if(file.activeQuickHint != null)
		{
			RuiDestroyIfAlive( file.activeQuickHint )
			file.activeQuickHint = null
		}
		break
	}
}

void function Oddball_PermaHint( string hintText, bool blueText = false, float duration = 2.5)
{
	if(file.activeQuickHint != null)
	{
		RuiDestroyIfAlive( file.activeQuickHint )
		file.activeQuickHint = null
	}

	file.activeQuickHint = CreateFullscreenRui( $"ui/wraith_comms_hint.rpak" )

	RuiSetGameTime( file.activeQuickHint, "startTime", Time() )
	RuiSetGameTime( file.activeQuickHint, "endTime", duration )
	RuiSetBool( file.activeQuickHint, "commsMenuOpen", false )
	RuiSetString( file.activeQuickHint, "msg", hintText )
}

void function Oddball_ToggleScoreboardVisibility(bool show)
{
    Hud_SetVisible( HudElement( "FS_Oddball_YourTeam" ), show )
	Hud_SetVisible( HudElement( "FS_Oddball_YourTeamGoalScore" ), show )
	Hud_SetText( HudElement( "FS_Oddball_YourTeamGoalScore"), "/" + ODDBALL_POINTS_TO_WIN ) 
    Hud_SetVisible( HudElement( "FS_Oddball_YourTeamScore" ), show )
    Hud_SetVisible( HudElement( "FS_Oddball_AllyHas" ), false )
    Hud_SetVisible( HudElement( "FS_Oddball_EnemyTeam" ), show )
    Hud_SetVisible( HudElement( "FS_Oddball_EnemyTeamScore" ), show )
    Hud_SetVisible( HudElement( "FS_Oddball_EnemyHas" ), false )

	RuiSetImage( Hud_GetRui( HudElement( "FS_Oddball_EnemyHas" ) ), "basicImage", $"rui/flowstate_custom/oddball_red" )
	RuiSetImage( Hud_GetRui( HudElement( "FS_Oddball_AllyHas" ) ), "basicImage", $"rui/flowstate_custom/oddball_blue" )
	RuiSetImage( Hud_GetRui( HudElement( "FS_Oddball_Scoreboard_Frame" ) ), "basicImage", $"rui/flowstate_custom/scoreboard_bg_oddball" )
	
	Hud_SetVisible( HudElement( "FS_Oddball_Scoreboard_Frame" ), show )
	
	if( !show )
		return
	
	thread Oddball_StartBuildingTeamsScoreOnHud()
}

void function SetBallPosesionIconOnHud( int team )
{
	switch( team )
	{
		case -1:
			Hud_SetVisible( HudElement( "FS_Oddball_AllyHas" ), false )
			Hud_SetVisible( HudElement( "FS_Oddball_EnemyHas" ), false )
		break
		
		case 0:
			Hud_SetVisible( HudElement( "FS_Oddball_AllyHas" ), true )
			Hud_SetVisible( HudElement( "FS_Oddball_EnemyHas" ), false )
		break
		
		case 1:
			Hud_SetVisible( HudElement( "FS_Oddball_AllyHas" ), false )
			Hud_SetVisible( HudElement( "FS_Oddball_EnemyHas" ), true )
		break
	}
}

void function Oddball_StartBuildingTeamsScoreOnHud()
{
	entity player = GetLocalClientPlayer()

	int localscore = 0
	int enemyscore = 0
	string str_localscore = ""
	string str_enemyscore = ""

	while( GetGlobalNetInt( "FSDM_GameState" ) == eTDMState.IN_PROGRESS )
	{
		localscore = 0
		enemyscore = 0
		str_localscore = ""
		str_enemyscore = ""

		localscore += player.GetPlayerNetInt( "oddball_ballHeldTime" )

		foreach( sPlayer in GetPlayerArray() )
		{
			if( sPlayer == player )
				continue

			if( sPlayer.GetTeam() == player.GetTeam() )
			{
				localscore += sPlayer.GetPlayerNetInt( "oddball_ballHeldTime" )
			} else
			{
				enemyscore += sPlayer.GetPlayerNetInt( "oddball_ballHeldTime" )
			}
		}
		
		if( localscore >= ODDBALL_POINTS_TO_WIN )
		{
			localscore = ODDBALL_POINTS_TO_WIN
		}else if( enemyscore >= ODDBALL_POINTS_TO_WIN )
		{
			enemyscore = ODDBALL_POINTS_TO_WIN
		}

		str_localscore = localscore.tostring()
		str_enemyscore = enemyscore.tostring() + "/" + ODDBALL_POINTS_TO_WIN.tostring()
		
		Hud_SetText( HudElement( "FS_Oddball_YourTeamScore"), str_localscore ) 
		Hud_SetText( HudElement( "FS_Oddball_EnemyTeamScore"), str_enemyscore ) 

		wait 0.01
	}
}

void function Oddball_BallOrCarrierEntityChanged( entity player, entity oldEnt, entity newEnt, bool actuallyChanged )
{
	entity localViewPlayer = GetLocalViewPlayer()

	if ( !IsValid( localViewPlayer ) || !IsValid( newEnt ) )
	{
		if( file.ballRui != null )
		{
			RuiDestroyIfAlive( file.ballRui )
			file.ballRui = null
		}
		return
	}
	
	string msg
	asset icon

	if( newEnt.IsPlayer() && newEnt != localViewPlayer && newEnt.GetTeam() == localViewPlayer.GetTeam() )
	{
		msg = ""//"Defend"
		icon = $"rui/flowstate_custom/oddball_blue"
	} else if( newEnt.IsPlayer() && newEnt != localViewPlayer && newEnt.GetTeam() != localViewPlayer.GetTeam() )
	{
		msg = ""//"Kill"
		icon = $"rui/flowstate_custom/oddball_red"
	} else if( !newEnt.IsPlayer() )
	{
		msg = "Pick Up"//"Pick Up"
		icon = $"rui/flowstate_custom/oddball_red"
	}
	
	Oddball_CreateBallRUI( newEnt, msg, icon )
}

var function Oddball_CreateBallRUI( entity ballOrCarrier, string text, asset icon )
{
	if( file.ballRui != null )
	{
		RuiDestroyIfAlive( file.ballRui )
		file.ballRui = null
		
		if( ballOrCarrier == GetLocalViewPlayer() )
			return
	}

    if( !IsValid( ballOrCarrier ) )
        return

	var rui = CreateFullscreenRui( $"ui/overhead_icon_generic.rpak", HUD_Z_BASE - 20 )
	RuiSetImage( rui, "icon", icon )
	RuiSetBool( rui, "isVisible", true )
	RuiSetBool( rui, "pinToEdge", true )
	RuiTrackFloat3( rui, "pos", ballOrCarrier, RUI_TRACK_OVERHEAD_FOLLOW )
	RuiSetFloat2( rui, "iconSize", <30,30,0> )
	RuiSetFloat( rui, "distanceFade", 100000 )
	RuiSetBool( rui, "adsFade", true )
	RuiSetString( rui, "hint", text )
	
	file.ballRui = rui
    return rui
}