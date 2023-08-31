local function IsUsable(macroID)
    local text = GetMacroBody(macroID)

    if text then
        local statement = text:match("/use ([^\n]+)")

        -- Set the icon to be a question mark
        local icon = 134400

        -- Evaluates macro options to check if the macro is not usable
        -- IMPORTANT! Requires a "known" condition for every Talent involved
        if statement and not SecureCmdOptionParse(statement) then
            local spellID = statement:match("known:(%d+)")

            -- Set the icon to match the Spell used in the "known" condition
            icon = spellID and select(3, GetSpellInfo(spellID))

            return false
        else
            return true
        end
    end
end

local function EditShadow(button, macroID)
    local r, g, b = button.icon:GetVertexColor()

    -- Check if the macro is not usable
    if not IsUsable(macroID) then

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

-- To avoid analyzing everything again, just check the category
-- IMPORTANT! In case of issues, add a check for the text of the macro
local function GetMacroID(button)
    local slot = button:GetPagedID(button) or button:CalculateAction(button) or button:GetAttribute("action") or 0

    if HasAction(slot) then
        local category, macroID = GetActionInfo(slot)

        if category == "macro" then
            return macroID
        end
    end
end

local function FixButtons()

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
            local macroID = GetMacroID(button)

            if macroID then
                EditShadow(button, macroID)

                -- Check if this button has been already hooked here
                if not button.isEditShadowHooked then

                    -- Do stuff when mouseover starts
                    button:HookScript("OnEnter", function()
                        local macroID = GetMacroID(button)
                        EditShadow(button, macroID)
                    end)

                    -- Do stuff when mousover ends, for drag-and-drop
                    button:HookScript("OnLeave", function()
                        local macroID = GetMacroID(button)
                        EditShadow(button, macroID)
                    end)

                    -- Note that this button has just been hooked here
                    button.isEditShadowHooked = true
                end
            end
        end
    end
end

local function FixMacros()

    -- Loop through account macros (1-120) and character macros (121-138)
    for macroID = 1, 138 do
        local text = GetMacroBody(macroID)

        if text then
            local statement = text:match("/use ([^\n]+)")

            -- Set the icon to be a question mark
            local icon = 134400

            -- Evaluates macro options to check if the macro is not usable
            -- IMPORTANT! Requires a "known" condition for every Talent involved
            if statement and not SecureCmdOptionParse(statement) then
                local spellID = statement:match("known:(%d+)")

                -- Set the icon to match the Spell used in the "known" condition
                icon = spellID and select(3, GetSpellInfo(spellID))
            end

            if not UnitAffectingCombat("player") then
                EditMacro(macroID, nil, icon)
            end
        end
    end
end

local function OnEvent(self, event, ...)

    if event == "ADDON_LOADED" then

        local addon = ...

        if addon == "Questionless" then

            -- Do stuff when the Macros window is being closed
            LoadAddOn("Blizzard_MacroUI")
            MacroFrame:HookScript("OnHide", function()
                FixMacros()
                FixButtons()
            end)
        end

    elseif event == "PLAYER_ENTERING_WORLD"
    or event == "PLAYER_SPECIALIZATION_CHANGED"
    or event == "TRAIT_CONFIG_UPDATED" then
        FixMacros()
        FixButtons()

    elseif event == "ACTIONBAR_UPDATE_USABLE"
    or event == "PLAYER_MOUNT_DISPLAY_CHANGED"
    or event == "SPELL_UPDATE_ICON"
    or event == "UPDATE_MOUSEOVER_UNIT"
    or event == "UPDATE_BONUS_ACTIONBAR" then
        FixButtons()
    end
end

local Questionless = CreateFrame("Frame")
Questionless:RegisterEvent("ADDON_LOADED")
Questionless:RegisterEvent("ACTIONBAR_UPDATE_USABLE")
Questionless:RegisterEvent("PLAYER_ENTERING_WORLD")
Questionless:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
Questionless:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
Questionless:RegisterEvent("SPELL_UPDATE_ICON")
Questionless:RegisterEvent("TRAIT_CONFIG_UPDATED")
Questionless:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
Questionless:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
Questionless:SetScript("OnEvent", OnEvent)