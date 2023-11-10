Questionless = LibStub("AceAddon-3.0"):NewAddon("Questionless", "AceBucket-3.0", "AceEvent-3.0")

function Questionless:EditShadow(button, macroID)
    local _, icon, text = GetMacroInfo(macroID)

    if text then
        local statement = text:match("/use ([^\n]+)")

        -- Get the current color
        local r, g, b = button.icon:GetVertexColor()

        -- Evaluates macro options to check if the macro is not usable
        -- IMPORTANT! Requires a "known" condition for every Talent involved
        if statement and not SecureCmdOptionParse(statement) then

            -- Check if the icon hasn't been altered by other addons
            if r == 1 and g == 1 and b == 1 then
                button.icon:SetVertexColor(0.5, 0.5, 0.5)
            end
        else
            -- Check if the icon hasn't been altered by other addons
            if r == 0.5 and g == 0.5 and b == 0.5 then
                button.icon:SetVertexColor(1, 1, 1)
            end
        end
    end
end

-- To avoid analyzing everything again, just check the category
-- IMPORTANT! In case of issues, add a check for the text of the macro
function Questionless:GetMacroID(button)
    local slot = button:GetPagedID(button) or button:CalculateAction(button) or button:GetAttribute("action") or 0

    if HasAction(slot) then
        local category, macroID = GetActionInfo(slot)

        if category == "macro" then
            return macroID
        end
    end
end

function Questionless:FixButton(button)

    local macroID = self:GetMacroID(button)

    if macroID then
        self:EditShadow(button, macroID)

        -- Check if this button has been already hooked here
        if not button.isEditShadowHooked then

            -- Do stuff when mouseover starts
            button:HookScript("OnEnter", function()
                self:FixButton(button)
            end)

            -- Do stuff when mousover ends, for drag-and-drop
            button:HookScript("OnLeave", function()
                self:FixButton(button)
            end)

            -- Note that this button has just been hooked here
            button.isEditShadowHooked = true
        end
    end
end

function Questionless:FixMacro(macroID)

    local _, icon, text = GetMacroInfo(macroID)

    -- Check if the macro has text and has a question mark as icon
    if text and icon == 134400 then
        local statement = text:match("/use ([^\n]+)")

        -- Evaluates macro options to check if the macro is not usable
        -- IMPORTANT! Requires a "known" condition for every Talent involved
        if statement and not SecureCmdOptionParse(statement) then
            local spellID = statement:match("known:(%d+)")

            -- Set the icon to match the Spell used in the "known" condition
            icon = spellID and select(3, GetSpellInfo(spellID))
        end

        -- Check if in combat and if the icon should be changed
        if not UnitAffectingCombat("player") and icon then
            EditMacro(macroID, nil, icon)
        end
    end
end

function Questionless:FixButtons()

    -- Action Bars 1-8 (in order)
    local bars = {
        "Action",
        "MultiBarBottomLeft",
        "MultiBarBottomRight",
        "MultiBarRight",
        "MultiBarLeft",
        "MultiBar5",
        "MultiBar6",
        "MultiBar7",
    }

    for _, bar in pairs(bars) do
        for slot = 1, 12 do
            local button = _G[bar .. "Button" .. slot]
            self:FixButton(button)
        end
    end
end

function Questionless:FixMacros()

    -- Loop through account macros (1-120) and character macros (121-138)
    for macroID = 1, 138 do
        self:FixMacro(macroID)
    end
end

function Questionless:OnEnable()

    -- Do stuff when the Macros window is being closed
    LoadAddOn("Blizzard_MacroUI")
    MacroFrame:HookScript("OnHide", function()
        self:FixMacros()
        self:FixButtons()
    end)

    -- Nature's Swiftness
    self:RegisterEvent("ACTIONBAR_UPDATE_USABLE", function()
        self:FixButtons()
    end)

    self:RegisterEvent("PLAYER_ENTERING_WORLD", function()
        self:FixMacros()
        self:FixButtons()
    end)

    -- Traveler's Tundra Mammoth
    self:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED", function()
        self:FixButtons()
    end)

    self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", function()
        self:FixMacros()
        self:FixButtons()
    end)

    -- Cloudburst Totem
    self:RegisterEvent("SPELL_UPDATE_ICON", function()
        self:FixButtons()
    end)

    -- Talent changes within the same Specialization
    self:RegisterEvent("TRAIT_CONFIG_UPDATED", function()
        self:FixMacros()
        self:FixButtons()
    end)

    -- Dragonriding
    self:RegisterEvent("UPDATE_BONUS_ACTIONBAR", function()
        self:FixButtons()
    end)

    self:RegisterEvent("UPDATE_MOUSEOVER_UNIT", function()
        self:FixButtons()
    end)
end