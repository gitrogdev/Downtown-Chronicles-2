--Handle handcuff keys on the client
local CollectionService = game:GetService("CollectionService")

local Tool: Tool = script.Parent

Tool.Equipped:Connect(function()
    for i, GrabPrompt: ProximityPrompt in ipairs(
        CollectionService:GetTagged("GrabPrompt")
    ) do
        GrabPrompt.ActionText = "Unlock handcuffs"
    end
end)

Tool.Unequipped:Connect(function()
    for i, GrabPrompt: ProximityPrompt in ipairs(
        CollectionService:GetTagged("GrabPrompt")
    ) do
        GrabPrompt.ActionText = "Grab"
    end
end)