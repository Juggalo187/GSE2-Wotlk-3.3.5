local GSE = GSE

local AceGUI = LibStub("AceGUI-3.0")
local L = GSE.L

local exportframe = AceGUI:Create("Frame")
exportframe:Hide()
exportframe.classid = 0
exportframe.sequencename = ""

exportframe:SetTitle(L["Gnome Sequencer: Export a Sequence String."])
exportframe:SetStatusText(L["Export a Sequence"])
exportframe:SetCallback("OnClose", function(widget)  exportframe:Hide() end)
exportframe:SetLayout("List")

local exportsequencebox = AceGUI:Create("MultiLineEditBox")
exportsequencebox:SetLabel(L["Sequence"])
exportsequencebox:SetNumLines(22)
exportsequencebox:DisableButton(true)
exportsequencebox:SetFullWidth(true)
exportframe:AddChild(exportsequencebox)

GSE.GUIExportframe = exportframe
exportframe.ExportSequenceBox = exportsequencebox

-- Simple Export Function
function GSE.SimpleExportSequence(sequence, sequenceName)
    if not sequence or not sequenceName then
        return "Invalid sequence data"
    end
    
    local exportLines = {}
    
    -- Add header
    table.insert(exportLines, "GSE Simple Export: " .. sequenceName)
    table.insert(exportLines, "Author: " .. (sequence.Author or "Unknown"))
    table.insert(exportLines, "SpecID: " .. (sequence.SpecID or "0"))
    table.insert(exportLines, "Talents: " .. (sequence.Talents or "None"))
    
    -- Add TOC version
    local gameversion, build, date, tocversion = GetBuildInfo()
    table.insert(exportLines, "TOC: " .. tocversion)
    
    table.insert(exportLines, "")
    
    -- Export the main macro versions
    if sequence.MacroVersions then
        for versionNum, versionData in ipairs(sequence.MacroVersions) do
            table.insert(exportLines, "=== Version " .. versionNum .. " ===")
            
            -- Key Press
            if versionData.KeyPress and #versionData.KeyPress > 0 then
                table.insert(exportLines, "KeyPress:")
                for _, line in ipairs(versionData.KeyPress) do
                    table.insert(exportLines, "  " .. line)
                end
            end
            
            -- Main Sequence
            table.insert(exportLines, "Sequence:")
            for i = 1, #versionData do
                table.insert(exportLines, "  " .. (versionData[i] or ""))
            end
            
            -- Key Release
            if versionData.KeyRelease and #versionData.KeyRelease > 0 then
                table.insert(exportLines, "KeyRelease:")
                for _, line in ipairs(versionData.KeyRelease) do
                    table.insert(exportLines, "  " .. line)
                end
            end
            
            -- Pre/Post Macro
            if versionData.PreMacro and #versionData.PreMacro > 0 then
                table.insert(exportLines, "PreMacro:")
                for _, line in ipairs(versionData.PreMacro) do
                    table.insert(exportLines, "  " .. line)
                end
            end
            
            if versionData.PostMacro and #versionData.PostMacro > 0 then
                table.insert(exportLines, "PostMacro:")
                for _, line in ipairs(versionData.PostMacro) do
                    table.insert(exportLines, "  " .. line)
                end
            end
            
            table.insert(exportLines, "")
        end
    end
    
    return table.concat(exportLines, "\n")
end

function GSE.GUIUpdateExportBox()
    GSE.GUIExportframe.ExportSequenceBox:SetText(GSE.SimpleExportSequence(GSE.GUIExportframe.sequence, exportframe.sequencename))
end

function GSE.GUIExportSequence(classid, sequencename)
    GSE.GUIExportframe.classid = classid
    GSE.GUIExportframe.sequencename = sequencename
    GSE.GUIExportframe.sequence = GSE.CloneSequence(GSE.Library[tonumber(exportframe.classid)][exportframe.sequencename])
    GSE.GUIExportframe.sequence.GSEVersion = GSE.VersionNumber
    GSE.GUIExportframe.sequence.EnforceCompatability = true
    GSE.GUIUpdateExportBox()
    GSE.GUIExportframe:Show()
end