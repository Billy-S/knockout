-- Punch boxes™ - Automating the tedious task of knocking players out.

local base_tile = 'default_chest_top.png^[colorize:#f008'
local punchbox_tile = base_tile .. '^punchbox.png'

local knock_out_players = function(pos, dir, stasis_pos)
    local candidates = minetest.get_objects_inside_radius(pos, 1)
    
    for _, victim in ipairs(candidates) do
        victim:set_hp(1)
        if victim:is_player() then
            -- Stop punch box traps
            if dir then
                victim:set_pos(vector.subtract(victim:get_pos(), dir))
            end
            
            -- Knock the player out
            knockout.knockout(victim:get_player_name(), 15)
            
            -- Stasis integration
            if stasis_pos then
                minetest.item_place(
                    ItemStack(''),
                    victim,
                    {
                        type  = 'node',
                        above = vector.add(stasis_pos, {x=0,y=1,z=0}),
                        under = stasis_pos,
                    }
                )
                stasis_pos = false
            end
        end
    end
    
    return stasis_pos
end

knockout.activate_punchbox = function(pos)
    local node = minetest.get_node(pos)
    local dir  = minetest.facedir_to_dir(node.param2)
    local target_pos = vector.subtract(pos, dir) 
    
    local def = minetest.registered_nodes[minetest.get_node(target_pos).name]
    if def and def.buildable_to then
        minetest.set_node(target_pos, {
            name = 'knockout:punchbox_fist',
            param2 = node.param2,
        })
    end
    minetest.after(0.6, function(pos, node)
        if minetest.get_node(pos).name == 'knockout:punchbox_fist' then
            minetest.set_node(pos, node)
        end
    end, target_pos, {name = 'air'})
    
    -- Automatically put players in Mk3 Stasis Chambers.
    local stasis_pos = vector.add(pos, dir)
    if minetest.get_node(stasis_pos).name ~= 'stasis:chamber' then
        stasis_pos = false
    end
    
    stasis_pos = knock_out_players(target_pos, dir, stasis_pos)
    knock_out_players({
        x = target_pos.x,
        y = target_pos.y - 1,
        z = target_pos.z,
    }, dir, stasis_pos)
end

minetest.register_node('knockout:punchbox', {
    description = 'Punch box',
    tiles = {
        punchbox_tile .. '^[transformR90',
        punchbox_tile .. '^[transformR270',
        punchbox_tile,
        punchbox_tile .. '^[transformR180',
        base_tile,
        base_tile     .. '^punchbox_front.png',
    },
    paramtype = 'light',
    paramtype2 = 'facedir',
    groups = {choppy = 2, oddly_breakable_by_hand = 2},
    
    on_rightclick = knockout.activate_punchbox,
    
    mesecons = {
        effector = {
            action_on = knockout.activate_punchbox,
        },
    },
})

minetest.register_node('knockout:punchbox_fist', {
    description = 'Punch box fist',
    tiles = {
        punchbox_tile .. '^[transformR90',
        punchbox_tile .. '^[transformR270',
        punchbox_tile,
        punchbox_tile .. '^[transformR180',
        base_tile,
        base_tile     .. '^punchbox_front.png',
    },
    
    drawtype = 'nodebox',
    node_box = {
        type = 'fixed',
        fixed = {
            {-0.15, -0.15, -0.4, 0.15, 0.15, 0.5},
            {-0.2, -0.2, -0.3, 0.2, 0.2, 0},
            {-0.25, -0.25, -0.2, 0.25, 0.25, -0.1},
        },
    },
    
    paramtype = 'light',
    paramtype2 = 'facedir',
    
    groups = {not_in_creative_inventory = 1, dig_immediate = 3},
    drop = {},
})
