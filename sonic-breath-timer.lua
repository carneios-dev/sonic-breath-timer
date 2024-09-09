local f = CreateFrame("Frame")

local drowningMusicDuration = 15000 -- Drowning music duration in milliseconds (15 seconds).

local drowningMusicFile = "Interface\\AddOns\\sonic-breath-timer\\sonic_drowning_music.ogg"
local breathSoundFile = "Interface\\AddOns\\sonic-breath-timer\\sonic_breath_sound.ogg"

local drowningMusicPlaying = false
local drowningSoundHandle = nil
local previousProgress = nil
local breathHasPlayed = false

local function PlayDrowningSound()
    local willPlay, soundHandle = PlaySoundFile(drowningMusicFile, "Master")
    if willPlay then
        drowningSoundHandle = soundHandle
        drowningMusicPlaying = true
    end
end

local function PlayBreathSound()
    PlaySoundFile(breathSoundFile, "Master")
    breathHasPlayed = true
end

local function StopDrowningSound()
    if drowningSoundHandle and drowningMusicPlaying then
        StopSound(drowningSoundHandle)
        drowningMusicPlaying = false
        drowningSoundHandle = nil
    end
end

local function CheckBreath()
    local timer = GetMirrorTimerInfo(2)

    if timer == "BREATH" then
        -- Counts backwards from maxvalue.
        local breathTimerProgress = GetMirrorTimerProgress(timer)

        -- Ensure breathTimerProgress is not negative.
        if breathTimerProgress < 0 then
            breathTimerProgress = 0
        end

        -- Start drowning music when breath time used exceeds the threshold.
        if breathTimerProgress <= drowningMusicDuration and not drowningMusicPlaying and not breathHasPlayed then
            PlayDrowningSound()
        end

        if previousProgress and breathTimerProgress > previousProgress and not breathHasPlayed then
            StopDrowningSound()
            PlayBreathSound()
        elseif previousProgress and breathTimerProgress <= previousProgress and breathHasPlayed then
            -- This state happens when the player is losing breath again,
            -- so we just need to allow for the breath sound to be played again.
            breathHasPlayed = false
        end

        previousProgress = breathTimerProgress -- Update our snapshot value.
    end
end

local function OnMirrorTimerEvent(self, event, timerName)
    if timerName == "BREATH" then
        if event == "MIRROR_TIMER_START" then
            -- Start continuously checking breath when breath timer starts.
            self:SetScript("OnUpdate", CheckBreath)
        end
    end
end

-- Register mirror timer start event, which will be used by the handler for evaluating the breath state.
f:RegisterEvent("MIRROR_TIMER_START")

f:SetScript("OnEvent", OnMirrorTimerEvent) -- Breath state handler.
