local load_time_start = os.clock()


local function pointed_thing_to_face_pos(player, pointed_thing)
	-- Get the four parameters

	local node_pos = pointed_thing.under
	local camera_pos = player:get_pos()
	local eye_offset_first = player:get_eye_offset()
	camera_pos.y = camera_pos.y + 1.625 + eye_offset_first.y / 10

	local pos_off = vector.multiply(
		vector.subtract(pointed_thing.above, pointed_thing.under),
		-0.437)

	local look_dir = player:get_look_dir()

	-- Get informations about the face

	local offset, nc
	local oc = {}
	for c, v in pairs(pos_off) do
		if v == 0 then
			oc[#oc + 1] = c
		else
			offset = v
			nc = c
		end
	end

	-- One coordinate of the fine position is known
	local fine_pos = {[nc] = node_pos[nc] + offset}

	-- The other ones are calculated here
	local f = (node_pos[nc] + offset - camera_pos[nc]) / look_dir[nc]
	for i = 1, #oc do
		fine_pos[oc[i]] = camera_pos[oc[i]] + look_dir[oc[i]] * f
	end

	return fine_pos
end

local entposs = {
	[2] = {delta = {x =  0.437, y = 0, z = 0}, yaw = math.pi * 1.5},
	[3] = {delta = {x = -0.437, y = 0, z = 0}, yaw = math.pi * 0.5},
	[4] = {delta = {x = 0, y = 0, z =  0.437}, yaw = 0},
	[5] = {delta = {x = 0, y = 0, z = -0.437}, yaw = math.pi},
}

local box = {
	type = "wallmounted",
	wall_top = {-8/16, 7/16, -8/16, 8/16, 8/16, 8/16}
}

digiline_screens.register_screen("digiline_touchscreen:touchscreen", {
		description = "digiline controlled touchscreen",
		drawtype = "nodebox",
		inventory_image = "digiline_touchscreen.png",
		wield_image = "digiline_touchscreen.png",
		tiles = {"digiline_touchscreen.png"},
		paramtype = "light",
		sunlight_propagates = true,
		paramtype2 = "wallmounted",
		node_box = box,
		selection_box = box,
		groups = {choppy = 3, dig_immediate = 2},
		light_source = 6,

		digiline = {receptor = {},},

		after_place_node = function (pos, placer, itemstack)
			local param2 = minetest.get_node(pos).param2
			if param2 == 0 or param2 == 1 then
				minetest.add_node(pos, {name = "digiline_screens:screen", param2 = 3})
			end
		end,

		on_punch = function(pos, node, puncher, pointed_thing)
			local diff = vector.subtract(pointed_thing.above, pointed_thing.under)
			local frontside = vector.round(vector.multiply(entposs[node.param2].delta, -2))
			if diff.y ~= 0 or diff.x ~= frontside.x or diff.z ~= frontside.z then
				return
			end
			local meta = minetest.get_meta(pos)
			local channel = meta:get_string("channel")
			local fine_pointed = pointed_thing_to_face_pos(puncher, pointed_thing)
			local msg = vector.subtract(fine_pointed, pos) -- relative pos
			if entposs[node.param2].delta.x ~= 0 then
				msg.x = msg.z
			end
			msg.z = nil
			-- make pos from up left to down right
			msg.y = -msg.y
			if node.param2 == 5 or node.param2 == 2 then
				msg.x = -msg.x
			end
			digilines.receptor_send(pos, digiline.rules.default, channel, msg)
		end,
	},

	16,
	16,
	entposs
)


local time = math.floor(tonumber(os.clock()-load_time_start)*100+0.5)/100
local msg = "[digiline_touchscreen] loaded after ca. "..time
if time > 0.05 then
	print(msg)
else
	minetest.log("info", msg)
end
