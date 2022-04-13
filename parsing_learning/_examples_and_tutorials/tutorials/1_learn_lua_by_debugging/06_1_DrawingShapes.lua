-- Author: Nameous Changey
--- Developed using LifeBoatAPI - Stormworks Lua plugin for VSCode - https://code.visualstudio.com/download (search "Stormworks Lua with LifeboatAPI" extension)
--- If you have any issues, please report them here: https://github.com/nameouschangey/STORMWORKS_VSCodeExtension/issues - by Nameous Changey
------------------------------------------------------------------------------------------------------------------------------------------------------------


-- F6 to run!
-- Try changing the colours, or drawing some new shapes as well

tickCounter = 0 -- we'll use this in onTick

onTick = function()
    tickCounter = tickCounter + 1 -- add 1 each tick, so we can count how many ticks

    ticksWrappedInto10Seconds = tickCounter % 600 -- (%) gives us the modulo/remainder; aka, a number wrapped around into that range
    percentOf10Seconds = ticksWrappedInto10Seconds / 600 -- divide our number that's between 0->600, by 600, and it'll be in the range 0->1. aka 0.1 is 10%, etc.
                                                         -- this is just a handy maths trick we can use
end


onDraw = function()
    -- we're going to use the values we calculate in onTick, in onDraw
    -- because these variables are all "global", we can use them anywhere
    -- think of there being one GIANT heap of all our variable boxes; we can find any of them easily
    canStickABreakpointHereAndSee = percentOf10Seconds

    -- the `screen` variable, provided by the game is a table containing all the drawing functions we want

    screen.setColor(255,100,100) -- set the drawing color for all future shapes (till the next setColor() call. Red, Green, Blue out of 255)
    screen.drawCircle(16,16, percentOf10Seconds * 30) -- draw a circle at x=16, y=16, with a radius that grows to 30 every 10 seconds

    screen.setColor(100,255,100)
    screen.drawText(10,32,"EXAMPLE!") -- draw a piece of text, where the top left is at 10,30

    -- remember you can type `screen.` and let VSCode suggest things that will work. Don't try to memorize everything
end