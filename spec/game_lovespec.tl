-- Integration specs run by `tecs integ`: boots the built shooter under real
-- LÖVE on a free MCP port and drives it live through tecs2d.testing.fixture.
-- The specs share one game instance and walk it through the state machine:
-- ready -> game -> paused -> game.
local fixture <const> = require("tecs2d.testing.fixture")
local luassert <const> = require("luassert")

describe("the space example", function()
    local app: fixture.App

    setup(function()
        app = fixture.start("build")
    end)

    teardown(function()
        fixture.stop(app)
    end)

    local function pressKey(key: string)
        app.client:call("send_love_event", {event = "keypressed", args = {key, key, false}})
        app.client:call("send_love_event", {event = "keyreleased", args = {key, key}})
    end

    local function currentState(): string
        return fixture.runLua(app, "return world:peekState()")[1]
    end

    local function waitForState(expected: string): string
        return fixture.eventually(fixture.callTimeout, function(): string
            local state = currentState()
            if state == expected then return state end
            return nil
        end)
    end

    local function countComponent(component: string): integer
        local values = fixture.runLua(app, string.format([[
            local shared = require("plugins.shared")
            local query = world:query({include = {shared.%s}})
            local count = 0
            for _, len in query:iter() do count = count + len end
            return tostring(count)
        ]], component))
        return math.floor(tonumber(values[1]) or -1)
    end

    it("boots into the ready state", function()
        luassert.equal("ready", waitForState("ready"))
    end)

    it("renders the starfield", function()
        local count = countComponent("Star")
        luassert.is_true(count > 0)
    end)

    it("starts gameplay when Enter is pressed", function()
        pressKey("return")
        luassert.equal("game", waitForState("game"))
    end)

    it("spawns one player", function()
        local count = fixture.eventually(fixture.callTimeout, function(): integer
            local players = countComponent("Player")
            if players == 1 then return players end
            return nil
        end)
        luassert.equal(1, count)
    end)

    it("fires bullets while Space is held", function()
        app.client:call("send_love_event",
            {event = "keypressed", args = {"space", "space", false}})
        local bullets = fixture.eventually(fixture.callTimeout, function(): integer
            local count = countComponent("Bullet")
            if count > 0 then return count end
            return nil
        end)
        app.client:call("send_love_event",
            {event = "keyreleased", args = {"space", "space"}})
        luassert.is_true(bullets > 0)
    end)

    it("pauses and resumes with Enter", function()
        pressKey("return")
        luassert.equal("paused", waitForState("paused"))
        pressKey("return")
        luassert.equal("game", waitForState("game"))
    end)
end)
