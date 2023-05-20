hs.loadSpoon("ShiftIt")
spoon.ShiftIt:bindHotkeys({
    left = { { 'cmd' }, 'left' },
    right = { { 'cmd' }, 'right' },
    up = { { 'cmd' }, 'up' },
    down = { { 'cmd' }, 'down' },
    upleft = { { 'cmd' }, '1' },
    upright = { { 'cmd' }, '2' },
    botleft = { { 'cmd' }, '3' },
    botright = { { 'cmd' }, '4' },
    maximum = {{ 'shift', 'cmd' }, 'up' },
    toggleFullScreen = { { 'ctrl', 'alt', 'cmd' }, 'f' },
    -- toggleZoom = { { 'ctrl', 'alt', 'cmd' }, 'z' },
    -- center = { { 'ctrl', 'alt', 'cmd' }, 'c' },
    -- nextScreen = { { 'ctrl', 'alt', 'cmd' }, 'n' },
    -- previousScreen = { { 'ctrl', 'alt', 'cmd' }, 'p' },
    -- resizeOut = { { 'ctrl', 'alt', 'cmd' }, '=' },
    -- resizeIn = { { 'ctrl', 'alt', 'cmd' }, '-' }
})
spoon.ShiftIt:setWindowCyclingSizes({ 50, 33, 67 }, { 50 })