
find_flat_land = {};

--dofile(minetest.get_modpath( minetest.get_current_modname() ).."/detect_flat_land.lua");
--dofile(minetest.get_modpath( minetest.get_current_modname() ).."/detect_local_extrema.lua");

dofile(minetest.get_modpath( minetest.get_current_modname() ).."/detect_flat_land_fast.lua");
dofile(minetest.get_modpath( minetest.get_current_modname() ).."/build_simple_hut.lua");

--- just a node that can be colored and thus visualize the created segments
minetest.register_node("find_flat_land:segment", {
	description = "Segment Indicator",
	tiles = {"default_clay.png"},
	is_ground_content = false,
	groups = {oddly_breakable_by_hand=3,cracky=3,snappy=3,sappy=3},
	paramtype2 = "color",
	palette = "unifieddyes_palette_extended.png",
	});


minetest.register_on_generated(function(minp, maxp, seed)
	-- the flat_area-detection works below sealevel as well
	if( minp.y < -64 or minp.y > 500) then
		return;
	end
 

	local heightmap = minetest.get_mapgen_object('heightmap');
	if( not( heightmap )) then
		return;
	end

	local t_last = minetest.get_us_time();
--	local chunksize = maxp.x-minp.x+1;
--	local res = find_flat_land.detect_local_extrema( heightmap, minp, maxp );

	find_flat_land.simple_hut_generate( heightmap, minp, maxp);

	print( 'TIME ELAPSED: '..tostring( minetest.get_us_time() - t_last ) );
end);
