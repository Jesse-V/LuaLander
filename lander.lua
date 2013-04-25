
require 'classlib'

-------------- Global game constants--------------------
-- Time per move (1 second)
DELTA_TIME = 1.0

-- Starting values for the lander
LANDER_INIT_ALTITUDE = 50.0
LANDER_INIT_VELOCITY = 0.0
LANDER_INIT_FUEL = 10.0

-- Lander thruster strength
LANDER_THRUSTER_STRENGTH = 1.0

-- Lander explodes if it reaches the surface going faster than this
MAX_LANDING_VELOCITY = -1.5

-- Messages if lander lands/crashes
CRASHED_MSG = "Crashed. Come now, we have to be better than the Russians!\n"
LANDED_MSG = "Landed Safely! One small step for a man, one giant leap for mankind!\n"

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
	return "Altitude: " .. self.altitude .. " Velocity: " .. self.velocity .. " Fuel: " .. self.fuelReserve
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
	local actualBurnRate = burnRate

	-- Adjust requested burn rate if not enough fuel left, (fuelReserve / DELTA_TIME) if not enough left
	if (self.fuelReserve < burnRate) then
		actualBurnRate = self.fuelReserve / DELTA_TIME
	end

	-- Decrements the amount of fuel consumed from the fuel reserve
	self.fuelReserve = self.fuelReserve - actualBurnRate

	-- Move the lander to the next altitude and velocity
	self:nextAltitude()
	self:nextVelocity(actualBurnRate)
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

	for var = 1, self.altitude do
		strBuffer = strBuffer .. " "
	end

	return strBuffer .. ">#` (" .. self.altitude .. ", " .. self.velocity .. ")"
end



-- A coroutine which implements a strategy to land the lander safely by yielding
-- burn rates based on provided information
function strategyOne(velocity, altitude, fuel)
	while true do
		local newBurn = 1.0

		-- Todo coroutine should calculate your next burn rate given the provided information
		-- and then coroutine.yield the next burn rate (0.0 is no burn, 1.0 is full burn).
		-- Make sure you are pulling information back from your call to yield!
	end
end



-- The Game class models a game, which has a lander and a strategy
Game = class('Game')

-- Game constructor
function Game:__init(lander, strategy)
	self.lander = lander
	self.strategy = coroutine.create(strategy)
end



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
		local burnRate = 1 --strategyOne(self.velocity, self.altitude, self.fuelReserve)

		-- Move the lander to a new position by providing it with its new burn rate
		lander:move(1)
	end

	print("contact!")

	-- Print out the lander state
	--print(Lander)

	-- Print out the correct message depending on if the lander landed safely or not
	if (lander:landed()) then
		print(LANDED_MSG)
	else
		print(CRASHED_MSG)
	end
end



-- Start of the program, setup the game
local mars = Planet(MARS_GRAVITY, MARS_HEIGHT)
local pluto = Planet(PLUTO_GRAVITY, PLUTO_HEIGHT)
local myLander = Lander(LANDER_INIT_VELOCITY, LANDER_INIT_ALTITUDE, LANDER_INIT_FUEL, LANDER_THRUSTER_STRENGTH, pluto)
local game = Game(myLander, strategyOne)

-- Play the game
game:play()
