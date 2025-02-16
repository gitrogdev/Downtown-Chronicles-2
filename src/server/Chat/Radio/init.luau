--Handle all radio communications on the server
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local RadioClient = script.RadioClient

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedCommunication = ReplicatedScripts.Communication
local ReplicatedConfig = ReplicatedScripts.Configuration

local InitializeRadio = ReplicatedCommunication.InitializeRadio
local ToggleRadio = ReplicatedCommunication.ToggleRadio

local Sounds = require(ReplicatedConfig.Sounds)

local ServerScripts = ServerScriptService.ServerScripts
local Util = require(ServerScripts.Util)

local PartStorage = ServerStorage.Parts
local ToolStorage: Folder = PartStorage.Tools

local Relays = {}

---Initialize a new radio device
---@param Player Player The Player initializing a radio
---@param Radio Tool The radio to initialize
InitializeRadio.OnServerEvent:Connect(function(Player: Player, Radio: Tool)
    local Inventory = Player.PlayerGui:FindFirstChild("Inventory")
    if not Inventory then
        return warn(
            `{script}.InitializeRadio.OnServerEvent: No inventory found for \z
            player {Player}!`
        )
    end

    if not (Radio:IsA("Tool") and (
        Radio.Parent == Inventory
        or (Player.Character and Radio.Parent == Player.Character))
    ) then
        return warn(
            `{script}.InitializeRadio.OnServerEvent: The item {Radio} is \z
            not in {Player}'s inventory!`
        )
    end

    if Radio:GetAttribute("FileName") ~= "ShoulderRadio" then
        return warn(
            `{script}.InitializeRadio.OnServerEvent: The item {Radio} is \z
            not a radio!`
        )
    end

    local Handle: Part = Radio:FindFirstChild("Handle");
    if not Handle then
        return warn(
            `{script}.InitializeRadio.OnServerEvent: No handle found for \z
            radio {Radio}!`
        )
    end

    local RadioEmitter: AudioEmitter = Handle:FindFirstChild("RadioEmitter")
    if not RadioEmitter then
        return warn(
            `{script}.InitializeRadio.OnServerEvent: No emitter found for \z
            radio {Radio}!`
        )
    end

    local InputDevice: AudioDeviceInput =
        Player:FindFirstChildOfClass("AudioDeviceInput")

    local Wire: Wire = RadioEmitter:FindFirstChildOfClass("Wire")
        or Util.CreateInstance("Wire", {
            Parent = RadioEmitter;
            TargetInstance = RadioEmitter;
        })
    Wire.SourceInstance = Radio:GetAttribute("Active") and InputDevice or nil;
end)

---Toggle the status of a radio
---@param Player Player The Player toggling the radio
---@param Radio Tool The radio being toggled
ToggleRadio.OnServerEvent:Connect(function(Player: Player, Radio: Tool)
    if not (Radio:IsA("Tool") and
        (Player.Character and Radio.Parent == Player.Character)
    ) then
        return warn(
            `{script}.ToggleRadio.OnServerEvent: The item {Radio} is not \z
            equipped by {Player}!`
        )
    end

    if Radio:GetAttribute("FileName") ~= "ShoulderRadio" then
        return warn(
            `{script}.ToggleRadio.OnServerEvent: The item {Radio} is not a \z
            radio!`
        )
    end

    local Handle: Part = Radio:FindFirstChild("Handle");
    if not Handle then
        return warn(
            `{script}.ToggleRadio.OnServerEvent: No handle found for radio \z
            {Radio}!`
        )
    end

    local RadioEmitter: AudioEmitter = Handle:FindFirstChild("RadioEmitter")
    if not RadioEmitter then
        return warn(
            `{script}.ToggleRadio.OnServerEvent: No emitter found for radio \z
            {Radio}!`
        )
    end

    local status = not Radio:GetAttribute("Active")
    Radio:SetAttribute("Active", status)
    local RadioSound: Sound = Util.CreateInstance("Sound", {
        Parent = Handle;
        RollOffMaxDistance = 10;
        RollOffMinDistance = 2;
        SoundId = status and Sounds.RadioOn or Sounds.RadioOff;
    })

    RadioSound.Ended:Once(function()
        RadioSound:Destroy()
    end)

    RadioSound:Play()

    local Wire: Wire = RadioEmitter:FindFirstChildOfClass("Wire")
    local InputDevice: AudioDeviceInput =
        Player:FindFirstChildOfClass("AudioDeviceInput")
    if status and InputDevice then
        Wire.SourceInstance = InputDevice
    else
        Wire.SourceInstance = nil
    end
end)

local module = {}

---Create a new shoulder radio
---@param attributes table The saved attributes to load
---@param itemData table The item configuration
---@return Tool
module.NewShoulder = function(attributes: table, itemData: table): Tool
    attributes = attributes or {
        SerialNo = Util.Serialize("Radio");
    }

    attributes.DisplayName = itemData.DisplayName
    local Tool = Util.CreateInstance("Tool", {
        CanBeDropped = false;
    }, attributes)

    for i, Child in ipairs(ToolStorage[itemData.Name]:GetChildren()) do
        Child:Clone().Parent = Tool
    end
    RadioClient:Clone().Parent = Tool

    local Handle: Part = Tool:WaitForChild("Handle")
    Util.WeldChildren(Tool, Handle, true)

    local Listener: AudioListener = Util.CreateInstance("AudioListener", {
        AudioInteractionGroup = "Radios";
        Parent = Handle;
    })

    local Relay: Folder = module.Relay(Listener.AudioInteractionGroup)
    local ListenerWire: Wire = Util.CreateInstance("Wire", {
        Parent = Listener;
        SourceInstance = Listener;
        TargetInstance = Relay:FindFirstChildOfClass("AudioEqualizer");
    })

    local Emitter: AudioEmitter = Util.CreateInstance("AudioEmitter", {
        Parent = Handle;
    })
    Emitter:SetDistanceAttenuation({
        [3] = 1;
        [5] = 0;
    })

    local EmitterWire: AudioEmitter = Util.CreateInstance("Wire", {
        Parent = Emitter;
        SourceInstance = Relay:FindFirstChildOfClass("AudioDistortion");
        TargetInstance = Emitter;
    })

    local RadioEmitter: AudioEmitter = Util.CreateInstance("AudioEmitter", {
        AudioInteractionGroup = Listener.AudioInteractionGroup;
        Name = "RadioEmitter";
        Parent = Handle;
    })
    
    Tool:GetAttributeChangedSignal("FromArmory"):Once(function()
        Relay = module.Relay(Listener.AudioInteractionGroup)
        Listener.AudioInteractionGroup =
            `{Tool:GetAttribute("FromArmory")}Radios`
        RadioEmitter.AudioInteractionGroup = Listener.AudioInteractionGroup

        ListenerWire.TargetInstance =
            Relay:FindFirstChildOfClass("AudioEqualizer")
        EmitterWire.SourceInstance =
            Relay:FindFirstChildOfClass("AudioDistortion")
    end)

    return Tool
end

---Set up a radio relay
---@param key string The key for the relay
---@return Folder
module.Relay = function(key: string): Folder
    if Relays[key] then
        return Relays[key]
    end

    local Relay: Folder = Util.CreateInstance("Folder", {
        Name = key;
        Parent = ReplicatedStorage;
    })
    Relays[key] = Relay

    local Equalizer: AudioEqualizer = Util.CreateInstance("AudioEqualizer", {
        Parent = Relay;
    })

    local Chorus: AudioChorus = Util.CreateInstance("AudioChorus", {
        Parent = Relay;
    })

    Util.CreateInstance("Wire", {
        Parent = Chorus;
        SourceInstance = Equalizer;
        TargetInstance = Chorus;
    })

    local Distortion: AudioDistortion = Util.CreateInstance("AudioDistortion", {
        Level = 0.25;
        Parent = Relay;
    })

    Util.CreateInstance("Wire", {
        Parent = Distortion;
        SourceInstance = Chorus;
        TargetInstance = Distortion;
    })

    return Relay
end

return module