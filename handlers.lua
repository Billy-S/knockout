local function carrierQuit(pName)
	if knockout.carrying[pName] then
		local cName = knockout.carrying[pName]
		local carried = minetest.get_player_by_name(cName)
		if carried then
			carried:set_detach()
		end
		knockout.knockout(cName)
		knockout.carrying[pName] = nil
	end
end

-- Globalstep to revive players
local gs_time = 0
minetest.register_globalstep(function(dtime)
	-- Decrease knockout time
	gs_time = gs_time + dtime
	if gs_time >= 1 then
		gs_time = 0
		for name, _ in pairs(knockout.knocked_out) do
			knockout.decrease_knockout_time(name, 1)
		end
	end
	-- Check for player drop
	for name, _ in pairs(knockout.carrying) do
		local p = minetest.get_player_by_name(name)
		if p:get_player_control().jump then
			carrierQuit(name)
		end
	end
end)

-- If the player is killed, they "wake up"
minetest.register_on_dieplayer(function(p)
	local pName = p:get_player_name()
	knockout.wake_up(pName)
	-- If the player is carrying another player, drop them
	carrierQuit(pName)
end)

-- If the player was carrying another player, drop them
minetest.register_on_leaveplayer(function(p, _)
	carrierQuit(p:get_player_name())
end)

-- Catch those pesky players that try to leave/join to get un-knocked out
minetest.register_on_joinplayer(function(p)
	local koed = false
	local pname = p:get_player_name()
	for name, _ in pairs(knockout.knocked_out) do
		if name == pname then
			koed = true
			break
		end
	end
	if koed then
		knockout.knockout(pname)
	end
end)

-- Catch whacks with various tools and calculate if the victim should be knocked out
minetest.register_on_punchplayer(function(player, hitter, time_from_last_punch, tool_capabilities, dir, damage)
	local tool = hitter:get_wielded_item():get_name() -- Get tool used
	local def = nil
	-- Get tool knockout def
	for name, tdef in pairs(knockout.tools) do
		if name == tool then
			def = tdef
			break
		end
	end
	if def == nil then return end
	-- Calculate
	local currHp = player:get_hp()
	if currHp <= def.max_health then
		local chanceMult = time_from_last_punch / tool_capabilities.full_punch_interval -- You can't knock people out with lots of love taps
		if chanceMult > 1 then chanceMult = 1 end
		if math.random() < def.chance * chanceMult then
			-- Knocked out
			local koTime = ((currHp / def.max_health) + 1) * def.max_time / 2
			knockout.knockout(player:get_player_name(), koTime)
		end
	end
end)