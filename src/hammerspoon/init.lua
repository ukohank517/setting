hs.loadSpoon("ShiftIt")
spoon.ShiftIt:bindHotkeys({
    left = { { 'cmd', 'shift' }, 'left' },
    right = { { 'cmd', 'shift' }, 'right' },
    down = { { 'cmd', 'shift' }, 'down' },
    upleft = { { 'cmd' }, '1' },
    upright = { { 'cmd' }, '2' },
    botleft = { { 'cmd' }, '3' },
    botright = { { 'cmd' }, '4' },
    maximum = {{ 'cmd', 'ctrl', 'shift' }, 'up' },
    toggleFullScreen = { { 'ctrl', 'alt', 'cmd' }, 'f' },
    -- toggleZoom = { { 'ctrl', 'alt', 'cmd' }, 'z' },
    -- center = { { 'ctrl', 'alt', 'cmd' }, 'c' },
    -- nextScreen = { { 'ctrl', 'alt', 'cmd' }, 'n' },
    -- previousScreen = { { 'ctrl', 'alt', 'cmd' }, 'p' },
    -- resizeOut = { { 'ctrl', 'alt', 'cmd' }, '=' },
    -- resizeIn = { { 'ctrl', 'alt', 'cmd' }, '-' }
})
spoon.ShiftIt:setWindowCyclingSizes({ 50 }, { 100, 80, 50})

local upCycleSteps = {
    { h = 100, w = 100, center = false },
    { h = 100, w = 95, center = true },
    { h = 80, w = 100, center = false },
    { h = 50, w = 100, center = false },
}
local upCycleState = {}

hs.hotkey.bind({ 'cmd', 'shift' }, 'up', function()
    local win = hs.window.focusedWindow()
    if not win then return end

    local winId = win:id()
    local currentIndex = upCycleState[winId] or 0
    local nextIndex = (currentIndex % #upCycleSteps) + 1
    upCycleState[winId] = nextIndex

    local step = upCycleSteps[nextIndex]

    local frame = win:screen():frame()
    local width = math.floor(frame.w * (step.w / 100))
    local height = math.floor(frame.h * (step.h / 100))
    local x = step.center and (frame.x + math.floor((frame.w - width) / 2)) or frame.x

    win:setFrame({
        x = x,
        y = frame.y,
        w = width,
        h = height,
    })
end)
