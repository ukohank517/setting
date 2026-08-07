hs.loadSpoon("ShiftIt")
spoon.ShiftIt:bindHotkeys({
    left = { { 'cmd', 'shift' }, 'left' },
    right = { { 'cmd', 'shift' }, 'right' },
    down = { { 'cmd', 'shift' }, 'down' },
    maximum = {{ 'cmd', 'ctrl', 'shift' }, 'up' },
    toggleFullScreen = { { 'ctrl', 'alt', 'cmd' }, 'f' },
    -- toggleZoom = { { 'ctrl', 'alt', 'cmd' }, 'z' },
    -- center = { { 'ctrl', 'alt', 'cmd' }, 'c' },
    -- nextScreen = { { 'ctrl', 'alt', 'cmd' }, 'n' },
    -- previousScreen = { { 'ctrl', 'alt', 'cmd' }, 'p' },
    -- resizeOut = { { 'ctrl', 'alt', 'cmd' }, '=' },
    -- resizeIn = { { 'ctrl', 'alt', 'cmd' }, '-' }
})
-- spoon.ShiftIt:setWindowCyclingSizes({ 50 }, { 100, 80, 50})

local function moveToCorner(isRight, isBottom)
    local CORNER_WIDTH_RATIO = 0.475
    local CORNER_HEIGHT_RATIO = 0.5

    local win = hs.window.focusedWindow()
    if not win then return end

    local frame = win:screen():frame()
    local width = math.floor(frame.w * CORNER_WIDTH_RATIO)
    local height = math.floor(frame.h * CORNER_HEIGHT_RATIO)
    local x = isRight and (frame.x + frame.w - width) or frame.x
    local y = isBottom and (frame.y + frame.h - height) or frame.y

    win:setFrame({
        x = x,
        y = y,
        w = width,
        h = height,
    })
end

local cornerHotkeys = {
    { key = '1', isRight = false, isBottom = false },
    { key = '2', isRight = false, isBottom = true },
    { key = '3', isRight = true, isBottom = false },
    { key = '4', isRight = true, isBottom = true },
}

for _, binding in ipairs(cornerHotkeys) do
    local key = binding.key
    local isRight = binding.isRight
    local isBottom = binding.isBottom

    hs.hotkey.bind({ 'cmd' }, key, function()
        moveToCorner(isRight, isBottom)
    end)
end

hs.hotkey.bind({ 'cmd', 'shift' }, 'up', (function()
    local upCycleSteps = {
        { h = 100, w = 100, center = false },
        { h = 100, w = 95, center = true },
        { h = 80, w = 100, center = false },
        { h = 50, w = 100, center = false },
    }
    local upCycleState = {}

    return function()
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
    end
end)())
