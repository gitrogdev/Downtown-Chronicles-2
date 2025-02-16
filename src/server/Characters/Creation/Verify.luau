--This script handles the packaging and submission of character data on the client
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local ScriptStorage = ReplicatedStorage.ReplicatedScripts
local Communication = ScriptStorage.Communication
local CreateCharacter = Communication.CreateCharacter

local module = {}

---Sets up the submission page
---@param Pages Frame The Frame in the GUI containing the pages
---@param UNUSED Model Unused variable, exists for passing DisplayCharacter
---@param PageHandlers table A table containing all the page handling modules
---@return TextButton
module.Setup = function(Pages: ScreenGui, UNUSED: Model, PageHandlers: table)
    local VerifyPage = Pages:WaitForChild("VerifyPage")
    local VerifyBackground = VerifyPage:WaitForChild("Background")
    local LastPage = VerifyBackground:WaitForChild("LastPage")
    local SubmitButton = VerifyBackground:WaitForChild("SubmitButton")

    local cooldown
    SubmitButton.MouseButton1Click:Connect(function()
        if cooldown then
            return
        end
        cooldown = true

        local firstName, lastName, gender, birthDate, birthMonth, birthYear =
            PageHandlers.Character.Results()
        local ethnicity, hairColor, skinColor = PageHandlers.Coloring.Results()
        local face = PageHandlers.Faces.Results()
        local hair, facial = PageHandlers.Hairs.Results()

        local success, warning = CreateCharacter:InvokeServer(
            firstName,
            lastName,
            gender,
            birthDate, birthMonth, birthYear,
            ethnicity,
            hairColor,
            skinColor,
            face,
            hair,
            facial
        )
        if not success then
            if warning then
                StarterGui:SetCore("SendNotification", {
                    Title = "Character creation failed!";
                    Text = warning;
                    Duration = 10;
                })
            end
            cooldown = false
        end
    end)

    return LastPage
end

return module