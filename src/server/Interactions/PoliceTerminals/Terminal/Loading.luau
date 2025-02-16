--Handles the loading screens for the police terminal on the client
local module = {}

---Show an error screen
---@param message string The error message to display
---@param onConfirm function The action to take upon confirming the error
function module:Error(message: string, onConfirm: () -> ())
    local Page: Frame = self:ShowPage("LoadingFailed")
    local BackButton: TextButton = Page:WaitForChild("BackButton")
    local ResultText: TextLabel = Page:WaitForChild("ResultText")

    BackButton.MouseButton1Click:Once(onConfirm)
    ResultText.Text = message
end

---Show a loading screen until a function is complete
---@param waitFor function The function to complete
function module:Load(waitFor: () -> ())
    local Page: Frame = self:ShowPage("LoadingScreen")
    local BarHolder: Frame = Page:WaitForChild("BarHolder")
    local BarTemplate: Frame = BarHolder:WaitForChild("BarTemplate")

    local gotResult: boolean
    task.spawn(function()
        while not gotResult do
            local LoadingBars: table = {}
            for i = 1, 10 do
                if gotResult then
                    break
                end

                local LoadingBar: Frame = BarTemplate:Clone()
                LoadingBar.Visible = true
                LoadingBar.Parent = BarHolder
                table.insert(LoadingBars, LoadingBar)

                task.wait(0.5)
            end

            for i, Bar: Frame in ipairs(LoadingBars) do
                Bar:Destroy()
            end
        end
    end)

    waitFor()
    gotResult = true
end

return module