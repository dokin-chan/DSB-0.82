-- Startup script for a custom dungeon
--
-- Note that this file is parsed by ESB, but its lua_manifest is not.
-- That means you should put any essential variables, custom messages,
-- and so on in here, but not a lot of complex code, or the limited
-- subset of DSB's Lua commands supported by ESB will probably run into
-- something unrecognized.

-- The "leader_mystery" function invoked via the "func" exvar
-- of the button in the trolin room
function leader_mystery(id, what, data_parm)
	local leader = dsb_get_leader()
	dsb_write(player_colors[leader + 1],
		dsb_get_charname(dsb_ppos_char(leader)) ..
		" WONDERS WHAT THIS BUTTON DOES...")
end

-- The monster reviver, invoked via function_caller
function monster_reviver(id, lev, xc, yc, tile, data, sender)
	-- This tells us what we can revive, and to what
	local revive = {
		s_slice = "screamer",
		worm_round = "worm",
		drumstick = "rat",
		shank = "hellhound",
		d_steak = "dragon"
	}	
	
	-- No operating object
	if (not data or data == 0) then return end
	
	local arch = dsb_find_arch(data)
	local name = arch.ARCH_NAME
	if (revive[name]) then
		-- Search for a monster on all locations and fail if one is there
		for d=0,4 do
			if (search_for_type(lev, xc, yc, d, "MONSTER")) then
				return
			end
		end
		
		-- Nothing there, create a monster
		local monster = dsb_spawn(revive[name], lev, xc, yc, CENTER)
		dsb_set_facedir(monster, dsb_rand(0, 3))
		
		-- Temporary blue haze and zapping sound
		local haze = dsb_spawn("bluehaze", lev, xc, yc, CENTER)
		dsb_msg(3, haze, M_DESTROY, 0)
		dsb_sound(snd.zap)
		
		-- Consume the item that did the reviving
		dsb_msg(0, data, M_DESTROY, 0)
	end	
end

-- These functions are used to create the fullscreen renderer
-- seen when clicking on the gor face after the Corridor of Pain.
function dragon_show(id, what, data_parm)
	-- Temporary global variables
	dbmp = gfx.dragon_front
	dflip = false

    -- Invoke the renderer, with the drawing function and tick function set.
    -- It will exit on click, not display a mouse pointer, and fade in/out.
	dsb_fullscreen(dragon_draw, EXIT_ON_CLICK, dragon_spin, false, true)
end

-- Executed every frame and used to draw the screen
function dragon_draw(bmp, mx, my)	
	dsb_bitmap_draw(gfx.lordchaos_front, bmp, 260, 240, 0)
	
	local w = dsb_bitmap_width(dbmp)
	local h = dsb_bitmap_height(dbmp)
	dsb_bitmap_draw(dbmp, bmp, mx - w/2, my - h/2, dflip) 
end

-- Executed every tick
function dragon_spin()
	if (dbmp == gfx.dragon_front) then
		dbmp = gfx.dragon_side
	elseif (dbmp == gfx.dragon_side) then
		if (dflip) then dbmp = gfx.dragon_front
		else dbmp = gfx.dragon_back end
		dflip = false
	elseif (dbmp == gfx.dragon_back) then
		dbmp = gfx.dragon_side
		dflip = true
	end	
end

-- rhelper.c patch test:
-- draw_interface() now calls sys_render_post_interface()
function sys_render_post_interface(bmp, interface_vs, con_x, con_y, con_w, con_h, wake_x, wake_y)
	local marker = "RHELPER POST-INTERFACE HOOK"
	local marker_y = wake_y + 22

	dsb_bitmap_rect(bmp, wake_x - 124, marker_y - 10, wake_x + 124, marker_y + 10, {255, 64, 64}, false)
	dsb_bitmap_textout(bmp, sys_font, marker, wake_x, marker_y - 6, CENTER, {255, 255, 0})
	dsb_bitmap_textout(bmp, sys_font, "VS:" .. interface_vs, wake_x, marker_y + 6, CENTER, {255, 255, 255})

	-- During sleep/wakeup display, draw TEST.pcx over the wakeup text position.
	if (gfx and gfx.test_log and dsb_get_sleepstate and dsb_get_sleepstate()) then
		local tw = dsb_bitmap_width(gfx.test_log)
		local th = dsb_bitmap_height(gfx.test_log)
		local tx = wake_x - math.floor(tw / 2)
		local ty = wake_y - math.floor(th / 2)
		dsb_bitmap_rect(bmp, tx - 4, ty - 2, tx + tw + 4, ty + th + 2, {0, 0, 0}, true)
		dsb_bitmap_draw(gfx.test_log, bmp, tx, ty, false)
	end

	-- Draw TEST.pcx in the lower console/log area.
	if (gfx and gfx.test_log and con_x and con_y) then
		dsb_bitmap_draw(gfx.test_log, bmp, con_x + 4, con_y + 2, false)
	end
end

lua_manifest = {
	"graphics.lua",
	"new_magic.lua"
}
