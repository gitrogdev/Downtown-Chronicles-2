--Handles all nametags and name associations on the client
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer

local module = {}

module.Updates = {}

---Setup nametag updates for all characters
module.Setup = function()
    local function updateTags(Update: Player)
        local id: string = tostring(Update:GetAttribute("ID"))
        local key: string = `Character{id}Nametag`
        module.Updates[id] = {}

        local function updateTag(NameDisplay: TextLabel)
            local associated: table = HttpService:JSONDecode(
                Player:GetAttribute("NameAssociations")
            )
            local name: string = (not (
                Update:GetAttribute("Masked")
                or NameDisplay:GetAttribute("WasMasked")
            )) and associated[id] or "Stranger"
            NameDisplay.Text = `{name} \z
                ({NameDisplay:GetAttribute("FullID")})\z
                {(
                    NameDisplay:GetAttribute("Dead") and
                    `\n<font color=\"rgb(255,120,120)\">***DEAD***</font>`
                ) or (NameDisplay:GetAttribute("CanTalk") and "\n🎙️") or ""
                }`
        end

        for j, NameDisplay: TextLabel in ipairs(CollectionService:GetTagged(
            key
        )) do
            updateTag(NameDisplay)
            NameDisplay.AttributeChanged:Connect(function()
                updateTag(NameDisplay)
            end)
            table.insert(module.Updates[id], function()
                updateTag(NameDisplay)
            end)
        end

        CollectionService:GetInstanceAddedSignal(key):Connect(function(
            NameDisplay: TextLabel
        )
            updateTag(NameDisplay)
            NameDisplay.AttributeChanged:Connect(function()
                updateTag(NameDisplay)
            end)
            table.insert(module.Updates[id], function()
                updateTag(NameDisplay)
            end)
        end)

        Update:GetAttributeChangedSignal("Masked"):Connect(function()
            for j, NameDisplay: TextLabel in ipairs(CollectionService:GetTagged(
                key
            )) do
                if NameDisplay:GetAttribute("Dead") then
                    continue
                end
                
                updateTag(NameDisplay)
            end
        end)
    end

    for i, Update: Player in ipairs(Players:GetPlayers()) do
        if Update == Player then
            local id: number = Update:GetAttribute("ID")
            local key: string = `Character{id}Nametag`

            for j, NameDisplay: TextLabel in ipairs(CollectionService:GetTagged(
                key
            )) do
                NameDisplay.Parent:Destroy()
            end

            CollectionService:GetInstanceAddedSignal(key):Connect(function(
                NameDisplay: TextLabel
            )
                NameDisplay.Parent:Destroy()
            end)
        elseif Update:GetAttribute("ID") then
            updateTags(Update)
        else
            Update:GetAttributeChangedSignal("ID"):Once(function()
                updateTags(Update)
            end)
        end
    end

    Players.PlayerAdded:Connect(function(Update: Player)
        Update:GetAttributeChangedSignal("ID"):Once(function()
            updateTags(Update)
        end)
    end)

    module.Associated = HttpService:JSONDecode(
        Player:GetAttribute("NameAssociations")
    )

    CollectionService:GetInstanceAddedSignal("RoleplayText"):Connect(function(
        RoleplayAction: BillboardGui
    )
        local Head: Part = RoleplayAction.Parent
        if not (Head and Head.Name == "Head") then
            return
        end

        local Character: Model = Head.Parent
        local Actor: Player = Character and Players:GetPlayerFromCharacter(
            Character
        )
        if not Actor then
            return
        end

        local Display: TextLabel = RoleplayAction:WaitForChild("Display")

        local function applyAssociation()
            local associated: table = HttpService:JSONDecode(
                Player:GetAttribute("NameAssociations")
            )
            local associatedName: string =
                (Actor == Player and "Your character")
                or (
                    (not Actor:GetAttribute("Masked"))
                    and associated[tostring(Actor:GetAttribute("ID"))]
                ) or `Stranger ({Actor.UserId}-{Actor:GetAttribute("ID")})`

            Display.Text = Display.Text:gsub(
                `$\x7BAssociated\x7D`, associatedName
            )
        end
        applyAssociation()
        Display:GetPropertyChangedSignal("Text"):Connect(applyAssociation)
    end)

    Player:GetAttributeChangedSignal("NameAssociations"):Connect(function()
        local newAssociations = HttpService:JSONDecode(
            Player:GetAttribute("NameAssociations")
        )

        for id: string, name: string in pairs(newAssociations) do
            if module.Associated[id] ~= name and module.Updates[id] then
                for i, updateTag: () -> () in ipairs(module.Updates[id]) do
                    updateTag()
                end
            end
        end
        module.Associated = newAssociations
    end)
end

return module