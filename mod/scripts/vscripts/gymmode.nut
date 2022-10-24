global function GymMode_Init

struct {
    bool enabled
    int midHealth
    int maxHealth
    int minHealth
    int aboveMidChange
    int belowMidChange
    bool showMaxHealth

    table<entity, int> playerMaxHealths
} file

void function GymMode_Init()
{
    file.enabled = GetConVarBool("gymmode_enabled")
    if (!file.enabled) {
        Log("GymMode is disabled")
        return
    }

    file.midHealth = GetConVarInt("gymmode_mid_health")
    file.maxHealth = GetConVarInt("gymmode_max_health")
    file.minHealth = GetConVarInt("gymmode_min_health")
    file.aboveMidChange = GetConVarInt("gymmode_above_mid_change")
    file.belowMidChange = GetConVarInt("gymmode_below_mid_change")
    file.showMaxHealth = GetConVarBool("gymmode_show_max_health")

    AddCallback_OnClientConnected(OnClientConnected)
    AddCallback_OnPlayerRespawned(OnPlayerRespawned)
    AddCallback_OnPlayerKilled(OnPlayerKilled)
    AddCallback_OnClientDisconnected(OnClientDisconnected)

    Log("GymMode is enabled")
}

void function OnClientConnected(entity player)
{
    file.playerMaxHealths[player] <- file.midHealth
}

void function OnPlayerRespawned(entity player)
{
    int maxHealth = file.playerMaxHealths[player]
    player.SetMaxHealth(maxHealth)
    ShowMaxHealth(player)
}

void function OnPlayerKilled(entity victim, entity attacker, var damageInfo)
{
    // ignore suicides
    if (victim == attacker || !victim.IsPlayer() || !attacker.IsPlayer() || GetGameState() != eGameState.Playing) {
        return
    }

    AddMaxHealth(victim)
    ReduceMaxHealth(attacker)

    ShowMaxHealth(victim)
    ShowMaxHealth(attacker)
}

void function OnClientDisconnected(entity player)
{
    if (player in file.playerMaxHealths) {
        delete file.playerMaxHealths[player]
    }
}

// victims get new max health after respawn
void function AddMaxHealth(entity victim)
{
    int currentMaxHealth = file.playerMaxHealths[victim]
    if (currentMaxHealth >= file.maxHealth) {
        return
    }

    if (currentMaxHealth >= file.midHealth) {
        int newMaxHealth = minint(currentMaxHealth + file.aboveMidChange, file.maxHealth)
        file.playerMaxHealths[victim] <- newMaxHealth
    } else {
        int newMaxHealth = currentMaxHealth + file.belowMidChange
        file.playerMaxHealths[victim] <- newMaxHealth
    }
}

// attackers get new max health right away
void function ReduceMaxHealth(entity attacker)
{
    int currentMaxHealth = file.playerMaxHealths[attacker]
    if (currentMaxHealth <= file.minHealth) {
        return
    }

    if (currentMaxHealth > file.midHealth) {
        int newMaxHealth = currentMaxHealth - file.aboveMidChange
        file.playerMaxHealths[attacker] <- newMaxHealth
        attacker.SetMaxHealth(newMaxHealth)
    } else {
        int newMaxHealth = maxint(currentMaxHealth - file.belowMidChange, file.minHealth)
        file.playerMaxHealths[attacker] <- newMaxHealth
        attacker.SetMaxHealth(newMaxHealth)
    }
}

void function ShowMaxHealth(entity player)
{
    if (!file.showMaxHealth) {
        return
    }

    int maxHealth = file.playerMaxHealths[player]
    string message = format("Max. HP: %d", maxHealth)
    SendHudMessage(player, message, -0.925, 0.4, 220, 224, 255, 255, 0.15, 9999, 1)
}

void function Log(string s)
{
    print("[GymMode] " + s)
}
