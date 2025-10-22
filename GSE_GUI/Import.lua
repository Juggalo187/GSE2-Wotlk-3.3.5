local GSE = GSE

local AceGUI = LibStub("AceGUI-3.0")
local L = GSE.L

local importframe = AceGUI:Create("Frame")
importframe.AutoCreateIcon = true
importframe:Hide()

importframe:SetTitle(L["GSE: Import a Macro String."])
importframe:SetStatusText(L["Import Macro from Forums"])
importframe:SetCallback("OnClose", function(widget)  importframe:Hide(); GSE.GUIShowViewer() end)
importframe:SetLayout("List")

local importsequencebox = AceGUI:Create("MultiLineEditBox")
importsequencebox:SetLabel(L["Macro Collection to Import."])
importsequencebox:SetNumLines(20)
importsequencebox:DisableButton(true)
importsequencebox:SetFullWidth(true)
importframe:AddChild(importsequencebox)

local createicondropdown = AceGUI:Create("CheckBox")
createicondropdown:SetLabel(L["Automatically Create Macro Icon"])
createicondropdown:SetWidth(250)
createicondropdown:SetType("checkbox")
createicondropdown:SetValue(true)
createicondropdown:SetCallback("OnValueChanged", function (obj,event,key)
    importframe.AutoCreateIcon = key
end)
importframe:AddChild(createicondropdown)

local recButtonGroup = AceGUI:Create("SimpleGroup")
recButtonGroup:SetLayout("Flow")

local recbutton = AceGUI:Create("Button")
recbutton:SetText(L["Import"])
recbutton:SetWidth(150)
recbutton:SetCallback("OnClick", function() 
    local importstring = importsequencebox:GetText()
    importstring = GSE.TrimWhiteSpace(importstring)
    
    if string.sub(importstring, 1, 18) == "GSE Simple Export:" then
        local success = GSE.SimpleImportSequence(importstring, importframe.AutoCreateIcon)
        if success then
            importsequencebox:SetText('')
            GSE.GUIImportFrame:Hide()
            GSE.GUIShowViewer()
        else
            StaticPopup_Show("GSE-MacroImportFailure")
        end
    else
        -- Show error for invalid format
        GSE.Print("Invalid import format. Please use the Simple Export format.")
        StaticPopup_Show("GSE-MacroImportFailure")
    end
end)
recButtonGroup:AddChild(recbutton)

importframe:AddChild(recButtonGroup)
GSE.GUIImportFrame = importframe

-- Simple Import Function
function GSE.SimpleImportSequence(importString, autoCreateIcon)
    local lines = GSE.SplitMeIntolines(importString)
    local sequence = {}
    local sequenceName = "Imported Macro"
    local currentSection = ""
    local currentVersion = 1
    
    sequence.MacroVersions = {}
    sequence.MacroVersions[1] = {
        KeyPress = {},
        KeyRelease = {},
        PreMacro = {},
        PostMacro = {},
        StepFunction = "Sequential"
    }
    
    for i, line in ipairs(lines) do
        line = GSE.TrimWhiteSpace(line)
        
        if line == "" then
            -- Skip empty lines
        elseif string.find(line, "GSE Simple Export:") then
            sequenceName = string.sub(line, 19):gsub("^%s*(.-)%s*$", "%1")
        elseif string.find(line, "Author:") then
            sequence.Author = string.sub(line, 8):gsub("^%s*(.-)%s*$", "%1")
        elseif string.find(line, "SpecID:") then
            sequence.SpecID = tonumber(string.sub(line, 8)) or 0
        elseif string.find(line, "Talents:") then
            sequence.Talents = string.sub(line, 9):gsub("^%s*(.-)%s*$", "%1")
		elseif string.find(line, "TOC:") then
    sequence.TOC = tonumber(string.sub(line, 5)) or tocversion
        elseif string.find(line, "=== Version") then
            -- Handle multiple versions if needed
            local versionNum = tonumber(string.match(line, "Version (%d+)"))
            if versionNum and versionNum > 1 then
                sequence.MacroVersions[versionNum] = GSE.CloneMacroVersion(sequence.MacroVersions[1])
                currentVersion = versionNum
            end
        elseif string.find(line, "KeyPress:") then
            currentSection = "KeyPress"
        elseif string.find(line, "Sequence:") then
            currentSection = "Sequence"
            -- Clear the sequence array
            for k in ipairs(sequence.MacroVersions[currentVersion]) do
                sequence.MacroVersions[currentVersion][k] = nil
            end
        elseif string.find(line, "KeyRelease:") then
            currentSection = "KeyRelease"
        elseif string.find(line, "PreMacro:") then
            currentSection = "PreMacro"
        elseif string.find(line, "PostMacro:") then
            currentSection = "PostMacro"
        else
            -- This is a content line - check if it's not empty and not a section header
            local content = line:gsub("^%s*(.-)%s*$", "%1")
            
            -- Remove leading spaces that indicate indentation but keep the content
            content = content:gsub("^%s+", "")
            
            if content ~= "" and not string.find(content, "^[%w]+:") then
                -- Only exclude lines that are section headers (word followed by colon at start)
                -- But allow colons within the content (like [mod:shift])
                
                if currentSection == "KeyPress" then
                    table.insert(sequence.MacroVersions[currentVersion].KeyPress, content)
                elseif currentSection == "Sequence" then
                    table.insert(sequence.MacroVersions[currentVersion], content)
                elseif currentSection == "KeyRelease" then
                    table.insert(sequence.MacroVersions[currentVersion].KeyRelease, content)
                elseif currentSection == "PreMacro" then
                    table.insert(sequence.MacroVersions[currentVersion].PreMacro, content)
                elseif currentSection == "PostMacro" then
                    table.insert(sequence.MacroVersions[currentVersion].PostMacro, content)
                end
            end
        end
    end
    
    -- Set default values
    sequence.Default = 1
    sequence.GSEVersion = GSE.VersionNumber
    sequence.EnforceCompatability = true
    
    -- Generate a unique name if it already exists
    local finalName = sequenceName
    local counter = 1
    while GSE.Library[GSE.GetCurrentClassID()] and GSE.Library[GSE.GetCurrentClassID()][finalName] do
        finalName = sequenceName .. " " .. counter
        counter = counter + 1
    end
    
    -- Save the sequence
    GSE.GUIUpdateSequenceDefinition(GSE.GetCurrentClassID(), finalName, sequence)
    
    -- Create macro icon if requested
    if autoCreateIcon then
        GSE.CheckMacroCreated(finalName, true)
    end
    
    GSE.Print("Successfully imported: " .. finalName)
    return true
end