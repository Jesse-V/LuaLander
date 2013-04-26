
require 'classlib'

-------------- Global game constants--------------------
-- Time per move (1 second)
DELTA_TIME = 1.0

-- Starting values for the lander
LANDER_INIT_ALTITUDE = 50.0
LANDER_INIT_VELOCITY = 0.0
PLUTO_INIT_FUEL = 10.0
MARS_INIT_FUEL = 25.0

-- Lander thruster strength
LANDER_THRUSTER_STRENGTH = 1.0

-- Lander explodes if it reaches the surface going faster than this
MAX_LANDING_VELOCITY = -1.5

-- Messages if lander lands/crashes
CRASHED_MSG = "Crashed. Come now, we aren't North Korea!\n"
MOON_LANDING_MSG = "Landed safely on the Moon! That's one small step for a man, one giant leap for mankind.\n"
MARS_LANDING_MSG = "Landed safely on Mars! Let this historic occasion represent a new landmark for the freedom, curiosity, and ingenuity of all inhabitants of Earth.\n"

-- Planet constants
PLUTO_GRAVITY = 0.5
PLUTO_HEIGHT = 10.0

MARS_GRAVITY = 0.9
MARS_HEIGHT = 2.0

-----------------------------------------------------------------

-- The Planet class models a Planet, which has a gravity and a ground height.
Planet = class('Planet')

-- Planet constructor
function Planet:__init(gravity, ground)
	self.gravity = gravity
	self.ground = ground
end



-- The Lander class models a Lander, which has an altitude, velocity, fuel reserve, thruster strength,
-- and info about the planet it was designed to land on
Lander = class('Lander')

-- Lander constructor
function Lander:__init(velocity, altitude, fuel, thruster, planet)
	self.velocity = velocity
	self.altitude = altitude
	self.fuelReserve = fuel
	self.thrusterStrength = thruster
	self.planet = planet
end



-- Returns the next altitude given the provided change in time
function Lander:nextAltitude()
	self.altitude = self.altitude + (self.velocity * DELTA_TIME)
end



-- Returns the next velocity given the burn rate, the change in time, thruster strength, and planetary gravity
function Lander:nextVelocity(burnRate)
	self.velocity = self.velocity + (((self.thrusterStrength * burnRate) - self.planet.gravity) * DELTA_TIME)
end



-- Overload of tostring for the Lander class
-- Return a string containing the Lander state in the format: Altitude: 15.0 Velocity: -10.5 Fuel: 12.0
function Lander:__tostring()
	return "Raw altitude: " .. self.altitude .. " 	Velocity: " .. self.velocity .. "	Fuel: " .. self.fuelReserve
end



-- Checks if the lander has reached the surface, returns true if it has, false otherwise
-- Check if the lander has reached the surface and return the proper value
function Lander:reachedSurface()
	return self.altitude <= self.planet.ground
end



-- Checks if the lander has reached the surface and safely landed
-- Return true if the lander has reached the surface and did so at a safe velocity
function Lander:landed()
	return self:reachedSurface() and self.velocity >= MAX_LANDING_VELOCITY
end



 -- Moves the lander based on a requested burn rate and also validates that
 -- the requested burn rate is valid.
function Lander:move(burnRate)
	if (burnRate > 1) then
		burnRate = 1
	end

	-- Adjust requested burn rate if not enough fuel left, (fuelReserve / DELTA_TIME) if not enough left
	if (self.fuelReserve < burnRate) then
		burnRate = self.fuelReserve / DELTA_TIME
	end

	-- Decrements the amount of fuel consumed from the fuel reserve
	self.fuelReserve = self.fuelReserve - burnRate

	-- Move the lander to the next altitude and velocity
	self:nextAltitude()
	self:nextVelocity(burnRate)
end



-- Returns a string representation of the relative position of the lander to the
-- planetary surface with | representing planet surface and * being the lander.
-- For example:            |                 *
 function Lander:positionString()
	local strBuffer = ""

	for var = 1, self.planet.ground do
		strBuffer = strBuffer .. " "
	end
	strBuffer = strBuffer .. "|"

	local relativeAltitude = math.ceil(self.altitude - self.planet.ground)
	for var = 1, relativeAltitude do
		strBuffer = strBuffer .. " "
	end

	return strBuffer .. ">#`"-- (Alt:" .. self.altitude .. ", V:" .. self.velocity .. ", F:" .. self.fuelReserve .. ")"
end



-- A coroutine which implements a strategy to land the lander safely on Pluto
function plutoLandingStrategy(lander)
	while true do
		local newBurn = 0.0 -- 0.0 is no burn, 1.0 is full burn

		if (lander.altitude <= 35) then
			newBurn = 1.0
		end

		lander = coroutine.yield(newBurn)
	end
end



-- A coroutine which implements a strategy to land the lander safely on Mars
function marsLandingStrategy(lander)
	while true do
		-- burn rate of 0.9 will counter gravity acceleration, a full burn is a net +0.1 velocity
		local newBurn = 0.0

		if (lander.altitude < 50) then
			newBurn = 0.85
		end

		if (lander.altitude <= 25) then
			newBurn = 1.0 --full burn
		end

		lander = coroutine.yield(newBurn)
	end
end



-- The Game class models a game, which has a lander and a strategy
Game = class('Game')

-- Game constructor
function Game:__init(lander, strategy)
	self.lander = lander
	self.strategy = coroutine.create(strategy)
end



-- Start of the program, setup the game
local pluto = Planet(PLUTO_GRAVITY, PLUTO_HEIGHT)
local plutoLander = Lander(LANDER_INIT_VELOCITY, LANDER_INIT_ALTITUDE, PLUTO_INIT_FUEL, LANDER_THRUSTER_STRENGTH, pluto)
local plutoLandingGame = Game(plutoLander, plutoLandingStrategy)

local mars = Planet(MARS_GRAVITY, MARS_HEIGHT)
local marsLander = Lander(LANDER_INIT_VELOCITY, LANDER_INIT_ALTITUDE, MARS_INIT_FUEL, LANDER_THRUSTER_STRENGTH, mars)
local marsLandingGame = Game(marsLander, marsLandingStrategy)



-- Plays a Lua Lander game by getting burn rates from the strategy until the lander has
-- reached the surface. Determines the success of the landing and prints out a message
-- accordingly.
function Game:play()
	local strategy = self.strategy
	local lander = self.lander

	while (not lander:reachedSurface()) do

		-- Print the relative position of the lander
		print(lander:positionString())

		-- Get the burn rate from your strategy and pass it the next set of values to work on
		local status, burnRate = coroutine.resume(strategy, lander)
		if (not status) then
			print("COROUTINE ERROR!")
		end

		-- Move the lander to a new position by providing it with its new burn rate
		lander:move(burnRate)
	end

	lander.altitude = lander.planet.ground
	print(lander:positionString())

	-- Print out the lander state
	print(lander)

	-- Print out the correct message depending on if the lander landed safely or not
	if (lander:landed()) then
		if (lander.planet == mars) then
			print(MARS_LANDING_MSG)
		else
			print(MOON_LANDING_MSG)
		end
	else
		print(CRASHED_MSG)
	end
end



-- Play the game
print()
print()

print("Starting Pluto lander simulator")
plutoLandingGame:play()
print()

print("Starting Mars lander simulator")
marsLandingGame:play()
print()
