--This script handles the server-side portion of object interactions
local CollectionService = game:GetService("CollectionService")
local ServerScriptService = game:GetService("ServerScriptService")

local ATMHandler = require(script.ATMs)
local BlindsHandler = require(script.Blinds)
local BookingHandler = require(script.Booking)
local DoorHandler = require(script.Doors)
local EvidenceHandler = require(script.Evidence)
local LockerHandler = require(script.Lockers)
local MailboxHandler = require(script.Mailboxes)
local NPCHandler = require(script.NPCs)
local SeatHandler = require(script.Seats)
local SlotsHandler = require(script.Slots)
local TerminalHandler = require(script.PoliceTerminals)
local TrashHandler = require(script.Trash)
local WireHandler = require(script.Wires)

local ServerScripts = ServerScriptService.ServerScripts
local PrisonHandler = require(ServerScripts.Prison)
local SanitationHandler = require(ServerScripts.Jobs.Sanitation)

local setupFuncs = {
    ATM = ATMHandler.Setup;
    BarbedWire = WireHandler.BarbedWire;
    Blinds = BlindsHandler.new;
    BookingCamera = BookingHandler.new;
    Door = DoorHandler.Setup;
    EvidenceLocker = EvidenceHandler.NewLocker;
    JackpotLight = SlotsHandler.AddLight;
    Locker = LockerHandler.new;
    Mailbox = MailboxHandler.new;
    NBCFLockdown = PrisonHandler.LockdownButton;
    NPC = NPCHandler.Setup;
    PoliceTerminal = TerminalHandler.new;
    RazorWire = WireHandler.RazorWire;
    RVM = TrashHandler.NewRVM;
    SanitationEquipment = SanitationHandler.EquipmentLocker;
    SanitationReturn = SanitationHandler.ReturnLocker;
    SlotMachine = SlotsHandler.Setup;
    TankRefill = SanitationHandler.TankRefill;
    TrashCan = TrashHandler.NewCan;
}

local processed = {}

local module = {}
module.Seats = {}

---Searches the workspace for all interactible objects and sets them up
module.Setup = function()
    local function process(Object: Instance)
        --Prevents duplicate setup of the same object
        if processed[Object] then
            return
        elseif Object:IsA("Seat") then
            table.insert(module.Seats, SeatHandler.Setup(Object) or {})
        end
        processed[Object] = true
    end

    for tag, setupFunc in pairs(setupFuncs) do
        module[`{tag}s`] = {}
        for i, Model in ipairs(CollectionService:GetTagged(tag)) do
            table.insert(module[`{tag}s`], setupFunc(Model))
        end
        CollectionService:GetInstanceAddedSignal(tag):Connect(setupFunc)
    end

    for i, Child in ipairs(workspace:GetDescendants()) do
        process(Child)
    end
    workspace.DescendantAdded:Connect(process)
end

return module