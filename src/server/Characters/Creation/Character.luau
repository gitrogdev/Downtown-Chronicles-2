--This script handles names, genders, and birthdays on the client
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local ScriptStorage = ReplicatedStorage.ReplicatedScripts
local Util = require(ScriptStorage.Util)

local ReplicatedConfig = ScriptStorage.Configuration
local CustomizationConfig = require(ReplicatedConfig.Customization)

local module = {}

---Sets up the character data page
---@param Pages Frame The Frame in the GUI containing the pages
---@param UNUSED Model Unused variable, exists for passing DisplayCharacter
---@param PageHandlers table A table containing all the page handling modules
---@return boolean
---@return TextButton
module.Setup = function(Pages: Frame, UNUSED: Model, PageHandlers: table)
    local CharacterPage = Pages:WaitForChild("CharacterPage")
    local CharacterBackground = CharacterPage:WaitForChild("Background")
    local BirthdayButton = CharacterBackground:WaitForChild("BirthdayButton")
    local BirthdayDisplay = CharacterBackground:WaitForChild("BirthdayDisplay")
    local DateFrame = CharacterBackground:WaitForChild("DateSelection")
    local GenderHolder = CharacterBackground:WaitForChild("GenderHolder")
    local FirstInput = CharacterBackground:WaitForChild("FirstName")
    local LastInput = CharacterBackground:WaitForChild("LastName")
    local NextPage = CharacterBackground:WaitForChild("NextPage")

    local DayHolder = DateFrame:WaitForChild("DayHolder")
    local MonthButton = DateFrame:WaitForChild("MonthButton")
    local YearButton = DateFrame:WaitForChild("YearButton")

    local BlankDay = DayHolder:WaitForChild("BlankSlot")
    local DayTemplate = DayHolder:WaitForChild("DayTemplate")

    local MonthHolder = MonthButton:WaitForChild("MonthHolder")
    local MonthTemplate = MonthHolder:WaitForChild("MonthTemplate")

    local YearHolder = YearButton:WaitForChild("YearHolder")
    local YearTemplate = YearHolder:WaitForChild("YearTemplate")

    local MaleButton = GenderHolder:WaitForChild("MaleButton")
    local FemaleButton = GenderHolder:WaitForChild("FemaleButton")

    local currentTime = os.date("!*t")
    local DayButtons = {}
    local gender = false
    local selectedDay, selectedMonth, selectedYear = 1, 1, currentTime.year - 18

    local function sanitizeName()
        FirstInput.Text = FirstInput.Text:sub(
            1,
            CustomizationConfig.Names.MaxLength
        )
        LastInput.Text = LastInput.Text:sub(
            1,
            CustomizationConfig.Names.MaxLength
        )

        for i, forbidden in ipairs(
            CustomizationConfig.Names.ForbiddenCharacters
        ) do
            FirstInput.Text = FirstInput.Text:gsub(forbidden, "")
            LastInput.Text = LastInput.Text:gsub(forbidden, "")
        end
    end

    local function updateDate()
        local monthName = Util.Months[selectedMonth]
        BirthdayDisplay.Text = `{selectedDay} {monthName} {selectedYear}`
        MonthButton.Text = monthName
        YearButton.Text = selectedYear
    end

    local function updateDays(month: number)
        for i, Child in ipairs(DayButtons) do
            Child:Destroy()
        end
        DayButtons = {}

        for i = 1, Util.DayOfWeek(1, selectedMonth, selectedYear) do
            local Filler = BlankDay:Clone()
            Filler.Parent = DayHolder
            Filler.Visible = true

            table.insert(DayButtons, Filler)
        end

        for day = 1, Util.DaysPerMonth[month] do
            local DayButton = DayTemplate:Clone()
            DayButton.Text = day
            DayButton.Parent = DayHolder
            DayButton.Visible = true

            DayButton.MouseButton1Click:Connect(function()
                selectedDay = day
                updateDate()
                DateFrame.Visible = false
            end)

            table.insert(DayButtons, DayButton)
        end

        if selectedDay > Util.DaysPerMonth[month] then
            selectedDay = Util.DaysPerMonth[month]
        end
    end

    for month = 1, 12 do
        local MonthSelector = MonthTemplate:Clone()
        MonthSelector.Text = Util.Months[month]
        MonthSelector.Parent =  MonthHolder
        MonthSelector.Visible = true

        MonthSelector.MouseButton1Click:Connect(function()
            selectedMonth = month
            updateDays(month)
            updateDate()
            MonthHolder.Visible = false
        end)
    end
    MonthHolder.CanvasSize = UDim2.fromOffset(0, 12 * 25)

    for year = currentTime.year - 13, currentTime.year - 100, -1 do
        local YearSelector = YearTemplate:Clone()
        YearSelector.Text = year
        YearSelector.Parent =  YearHolder
        YearSelector.Visible = true

        YearSelector.MouseButton1Click:Connect(function()
            selectedYear = year
            updateDays(selectedMonth)
            updateDate()
            YearHolder.Visible = false
        end)
    end
    YearHolder.CanvasSize = UDim2.fromOffset(0, 87 * 25)
    updateDays(1)
    updateDate()

    FirstInput:GetPropertyChangedSignal("Text"):Connect(sanitizeName)
    LastInput:GetPropertyChangedSignal("Text"):Connect(sanitizeName)

    BirthdayButton.MouseButton1Click:Connect(function()
        DateFrame.Visible = true
    end)

    MonthButton.MouseButton1Click:Connect(function()
        MonthHolder.Visible = true
    end)

    YearButton.MouseButton1Click:Connect(function()
        YearHolder.Visible = true
    end)

    MaleButton.MouseEnter:Connect(function()
        if gender then
            TweenService:Create(MaleButton, TweenInfo.new(0.5), {
                Size = UDim2.fromScale(0.1, 1)
            }):Play()
        end
    end)

    MaleButton.MouseLeave:Connect(function()
        if gender then
            TweenService:Create(MaleButton, TweenInfo.new(0.5), {
                Size = UDim2.fromScale(0.1, 0.8)
            }):Play()
        end
    end)

    MaleButton.MouseButton1Click:Connect(function()
        gender = false
        PageHandlers.Hairs.UpdateGender(gender)

        TweenService:Create(MaleButton, TweenInfo.new(0.5), {
            Size = UDim2.fromScale(0.1, 1)
        }):Play()
        TweenService:Create(FemaleButton, TweenInfo.new(0.5), {
            Size = UDim2.fromScale(0.1, 0.8)
        }):Play()
    end)

    FemaleButton.MouseEnter:Connect(function()
        if not gender then
            TweenService:Create(FemaleButton, TweenInfo.new(0.5), {
                Size = UDim2.fromScale(0.1, 1)
            }):Play()
        end
    end)

    FemaleButton.MouseLeave:Connect(function()
        if not gender then
            TweenService:Create(FemaleButton, TweenInfo.new(0.5), {
                Size = UDim2.fromScale(0.1, 0.8)
            }):Play()
        end
    end)

    FemaleButton.MouseButton1Click:Connect(function()
        gender = true
        PageHandlers.Hairs.UpdateGender(gender)

        TweenService:Create(FemaleButton, TweenInfo.new(0.5), {
            Size = UDim2.fromScale(0.1, 1)
        }):Play()
        TweenService:Create(MaleButton, TweenInfo.new(0.5), {
            Size = UDim2.fromScale(0.1, 0.8)
        }):Play()
    end)

    ---Provides the first name, surname, gender, and birth day, month, and year
    ---@return string
    ---@return string
    ---@return boolean
    ---@return number
    ---@return number
    ---@return number
    module.Results = function()
        return FirstInput.Text, LastInput.Text, gender,
        selectedDay, selectedMonth, selectedYear
    end

    return false, NextPage
end

return module