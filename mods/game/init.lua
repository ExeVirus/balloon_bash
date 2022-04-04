-- licensed as follows:
-- MIT License, ExeVirus (c) 2021
--
-- Please see the LICENSE file for more details

local spawn_time = 10
local time = 0

--Common node between styles, used for hidden floor to fall onto
minetest.register_node("game:ground",
{
  description = "Ground Block",
  tiles = {"ground.png"},
  light_source = 11,
})

--Override the default hand
minetest.register_item(":", {
    type = "none",
    wield_image = "wieldhand.png",
    wield_scale = {x = 1, y = 1, z = 2.5},
    range = 12,
    groups = {not_in_creative_inventory=1},
})

local num_balloons = 1
local rand = PcgRandom(os.time())

local function spawn_balloon()
    num_balloons = num_balloons + 1
    minetest.chat_send_all(num_balloons .. " balloons!")
    local players = minetest.get_connected_players()
    local player = players[rand:next(1,#players)] --random player
    local pos = player:get_pos()
    minetest.add_entity({
                            x=pos.x+rand:next(1,7)-3.5,
                            y=22,
                            z=pos.z+rand:next(1,7)-3.5,
    }, "game:balloon", nil)
    minetest.sound_play("balloon", {
        gain = 1.0,   -- default
        loop = false,
    })
    spawn_time = spawn_time + 3
end

local first = true -- first player?
local started = false -- delay
minetest.register_on_joinplayer(
function(player)
    player:hud_set_flags(
        {
            hotbar = false,
            healthbar = false,
            crosshair = true,
            wielditem = false,
            breathbar = false,
            minimap = false,
            minimap_radar = false,
        }
    )
    music = minetest.sound_play("balloon", {
        gain = 1.0,   -- default
        loop = false,
        to_player = player:get_player_name(),
    })

    player:set_physics_override({
        speed = 4.0,
        jump = 1.0,
        gravity = 4.0,
        sneak = false,
    })

    player:set_pos({x=0,y=1.1,z=0})
    player:set_look_horizontal(0)
    player:set_look_vertical(-0.5)
    minetest.sound_play("theme", {
        gain = 0.8,   -- default
        loop = true,
        to_player = player:get_player_name()
    })
    if first then
        minetest.add_entity({x=0,y=12,z=10}, "game:balloon", nil)
        first = false
        minetest.after(1, function() started = true end)
    end
end
)

minetest.register_globalstep(
function(dtime)
    if started then
        time = time + dtime
        if time > spawn_time then
            time = 0
            spawn_balloon()
        end
    end
end)

-- Balloon
local balloon = {
    initial_properties = {
        hp_max = 10,
        visual = "mesh",
        visual_size = {x=0.1,y=0.117,z=0.1},
        glow = 10,
        static_save = false,
        mesh = "balloon.obj",
        physical = true,
        collide_with_objects = false,
        collisionbox = {-0.6, -0.6, -0.6, 0.6, 0.6, 0.6},
        textures = {"balloon.1.png"},
    },

    --Physics, and collisions
    on_step = function(self, dtime, moveresult)
        if moveresult.touching_ground and started then
            minetest.clear_objects()
            minetest.chat_send_all("Try again!")
            local players = minetest.get_connected_players()
            for num=1, #players, 1 do
                local player = players[num]
                player:set_pos({x=0,y=1.1,z=0})
                player:set_look_horizontal(0)
                player:set_look_vertical(-0.5)
            end
            minetest.sound_play("lose", {
                gain = 1.0,   -- default
                loop = false,
            })
            num_balloons = 1
            minetest.add_entity({x=0,y=12,z=10}, "game:balloon", nil)
            time = 0
        else
            --slow our x,z velocities
            local vel = self.object:get_velocity()
            if vel == nil then vel = {x=0,y=0,z=0} end
            self.object:set_velocity({x=vel.x*0.97, y=vel.y*0.97, z=vel.z*0.97})
        end
    end,

    --Punch Physics
    on_punch = function(self, puncher, _, _, dir)
        self.object:set_velocity(dir*25)
        minetest.sound_play("punch", {
            gain = 1.0,   -- default
            loop = false,
            pos = self.object:get_pos()
        })
    end,

    --Setup fallspeed
    on_activate = function(self, staticdata, dtime_s)
        self.object:set_acceleration({x=0,y=-4.0,z=0})
        local props = self.object:get_properties()
        props.textures = {"balloon." .. rand:next(1,4) .. ".png"}
        self.object:set_properties(props)
    end,
}

minetest.register_entity("game:balloon", balloon)
