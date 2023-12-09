local async = require("openmw.async")
local core = require("openmw.core")
local self = require("openmw.self")
local storage = require("openmw.storage")
local types = require("openmw.types")
local ui = require("openmw.ui")
local util = require("openmw.util")
local I = require("openmw.interfaces")
local L = core.l10n("SignpostFastTravel")
local travelSettings = storage.globalSection("SettingsGlobalTravel" .. "SignpostFastTravel")

-- local textStr = "%s\t(%s)"
local v2 = util.vector2

local function pad(h, v)
    return {props = {size = v2(h, v)}}
end

local function head(text)
    return {
        type = ui.TYPE.Text,
        template = I.MWUI.templates.textHeader,
        props = {text = text}
    }
end

local function closeMenu()
    I.UI.setMode()
    Menu:destroy()
end

local function teleport(location)
    local quest = types.Player.quests(self)["momw_sft_quest"]
    if quest and quest.stage == 20 then
        -- Finish the quest!
        quest:addJournalEntry(30)
    end
    closeMenu()
    core.sendGlobalEvent(
        "momw_sft_doTeleport",
        {
            actor = self,
            cell = location,
            pos = I.SignpostFastTravel.GetPoint(location),
            token = true
        }
    )
end

local function mousePress(event, data)
    if not data.props.win then
        closeMenu()
        return
    end
    if not data.props.win.currentPage then
        data.props.win.currentPage = 1
    end
    if data.props.text == "Next" then
        if data.props.win.currentPage == data.props.win.pages then return end
        data.props.win.currentPage = data.props.win.currentPage + 1
        data.props.win:reDraw()
        return
    elseif data.props.text == "Prev" then
        if data.props.win.currentPage == 1 then return end
        data.props.win.currentPage = data.props.win.currentPage - 1
        data.props.win:reDraw()
        return
    end

    -- Close the menu on right click
    if event.button == 3 then
        closeMenu()
        return
    end

    -- Not a row, bail out
    if not data.props.win then return end

    if data.props.selected then
        -- A selected row was clicked, closeMenu and doTeleport!
        teleport(data.props.location)
    else
        -- Select this row and reDraw()
        data.props.win.index = data.props.index
        data.props.win:reDraw()
    end
end

local function selectedText(win, index, location)
    return {
        type = ui.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {
            index = index,
            location = location,
            selected = true,
            text = location,
            textColor = util.color.rgb(1, 1, 1),
            win = win
        },
        events = {mousePress = async:callback(mousePress)}
    }
end

local function text(win, index, location)
    return {
        type = ui.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {
            index = index,
            location = location,
            text = location,
            win = win
        },
        events = {mousePress = async:callback(mousePress)}
    }
end

local function justText(str)
    return {
        type = ui.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {text = str}
    }
end

local function nextPrev(win, txt)
    local textAlignH
    if txt == "Prev" then
        textAlignH = ui.ALIGNMENT.Start
    elseif txt == "Next" then
        textAlignH = ui.ALIGNMENT.End
    end
    return {
        type = ui.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {
            text = txt,
            textAlignH = textAlignH,
            win = win
        },
        events = {mousePress = async:callback(mousePress)}
    }
end

local function createMenu(win, cellData, selected)
    local body = {}
    local count = 1
    local rows = 0
    local pageMax = 15
    if not win.index then
        win.index = 1
    end
    if not win.pages then
        win.pages = 1
    end
    if not win.currentPage then
        win.currentPage = 1
    end
    local page = win.currentPage

    table.insert(body, head(L("name")))
    table.insert(body, pad(0, 10))
    if travelSettings:get("menuShowUsage") then
        table.insert(body, justText(L("menuUsage1")))
        table.insert(body, justText(L("menuUsage2")))
        table.insert(body, justText(L("menuUsage3")))
        if travelSettings:get("menuCostsToken") then
            table.insert(body, justText(L("menuUsage4")))
        end
    end
    table.insert(body, pad(0, 20))

    local names = {}
    for name, _ in pairs(cellData) do
        table.insert(names, name)
    end
    table.sort(names)

    for _, name in pairs(names) do
        if page > 1 and count <= (pageMax * (page - 1)) then
            count = count + 1
            goto continue
        end

        if count > pageMax * page then break end

        --TODO: Worth doing this? Seems to cause the index to be off by one..
        -- local currentCell = self.cell
        -- if currentCell and currentCell.name == name then
        --     -- Skip the current cell
        --     goto continue
        -- end

        -- local region
        -- for _, d in pairs(cellData[name]) do
        --     region = d.region
        --     break
        -- end

        -- THANKS: https://stackoverflow.com/a/20285006
        --TODO: Azura'S Coast !?!?
        -- local casedRegion = string.gsub(" ".. region, "%W%l", string.upper):sub(2)
        -- print(casedRegion)

        if count == selected then
            table.insert(body, selectedText(win, count, name))
            rows = rows + 1
        else
            table.insert(body, text(win, count, name))
            rows = rows + 1
        end
        table.insert(body, pad(0, 5))
        count = count + 1

        ::continue::
    end

    while count < pageMax and #names % rows ~= 0 do
        table.insert(body, justText(" "))
        rows = rows + 1
    end

    win.pages = #names / pageMax
    if win.pages > 1 then
        table.insert(body, pad(0, 15))
        local footerContent = {}

        if win.pages >= 3 and win.currentPage > 1 then
            table.insert(footerContent, nextPrev(win, L("menuPrev")))
        end
        if (win.pages >= 3 and win.currentPage > 1)
            and (win.pages > 1 and win.currentPage < win.pages)
        then
            table.insert(footerContent, justText(" | "))
        end
        if win.pages > 1 and page < win.pages then
            table.insert(footerContent, nextPrev(win, L("menuNext")))
        end

        local footer = {
            type = ui.TYPE.Flex,
            props = {horizontal = true},
            content = ui.content(footerContent)
        }
        table.insert(body, footer)
    end

    local xFactor = .25
    local yFactor = .45
    local screenSize = ui.screenSize()
    local maxHeight = 446
    local minHeight = 446
    if travelSettings:get("menuShowUsage") then
        -- 486 is how tall the window is with pageMax entries at 1080p
        maxHeight = 486
        minHeight = 486
    end
    local width, height = screenSize.x * xFactor, math.max(math.min(screenSize.y * yFactor, maxHeight), minHeight)

    win.reDraw = function(w)
        Menu:destroy()
        Menu = ui.create(createMenu(w, cellData, w.index).layout)
    end

    win.moveUp = function(w)
        local update = false
        if w.currentPage == 1 and w.index > 1 then
            update = true
        elseif w.currentPage > 1 and w.index > pageMax * (w.currentPage - 1) + 1 then
            update = true
        end
        if update then
            w.index = w.index - 1
            w:reDraw()
        end
    end

    win.moveDown = function(w)
        if w.index == #names or w.index == w.currentPage * pageMax then return end
        local update = false
        if w.currentPage == 1 and w.index < pageMax then
            update = true
        elseif w.currentPage > 1 and w.index < pageMax * w.currentPage then
            update = true
        end
        if update then
            w.index = w.index + 1
            w:reDraw()
        end
    end

    win.movePrev = function(w)
        if w.currentPage == 1 then return end
        local update = false
        if w.pages > 1 and w.currentPage > 1 then
            update = true
        end
        if update then
            w.index = math.max(w.index - pageMax, 1)
            w.currentPage = w.currentPage - 1
            w:reDraw()
        end
    end

    win.moveNext = function(w)
        if w.currentPage == w.pages then return end
        local update = false
        if w.pages > 1 and w.currentPage < w.pages then
            update = true
        end
        if update then
            w.index = math.min(w.index + pageMax, #names)
            w.currentPage = w.currentPage + 1
            w:reDraw()
        end
    end

    win.choose = function(w)
        teleport(names[w.index])
    end

    win.closeMenu = function()
        closeMenu()
    end

    win.layout = {
        layer = "Windows",
        template = I.MWUI.templates.boxTransparentThick,
        props = {
            relativePosition = v2(.5, .5),
            anchor = v2(.5, .5),
            win = win
        },
        events = {mousePress = async:callback(mousePress)},
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = {
                    position = v2(50, 20),
                    size = v2(width, height)
                },
                content = ui.content(body)
            }
        }
    }

    return win
end

local function travelMenu(visitedCells)
    I.UI.setMode("Interface", {windows = {}})
    local m = createMenu({}, visitedCells, 1)
    Menu = ui.create(m.layout)
    return m
end

--TODO: 2090 list:
--TODO: maybe show distance in the menu
--TODO: region
--TODO: scale justText to be a little smaller

return { travelMenu = travelMenu }
