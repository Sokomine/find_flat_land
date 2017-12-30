
find_flat_land = {};

dofile(minetest.get_modpath( minetest.get_current_modname() ).."/detect_flat_land.lua");
dofile(minetest.get_modpath( minetest.get_current_modname() ).."/detect_segments.lua");

local first_segment_done = false;

-- just a node that can be colored and thus visualize the created segments
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
	local chunksize = maxp.x-minp.x+1;


	-- this heightmap will store our changes (if any)
	local heightmap2 = {};
	if( first_segment_done ) then
		heightmap2 = heightmap;

	-- for the first mapchunk generated in the map: visualize the segments
	else
		first_segment_done = true;
		-- we want to seperate the heightmap into connected segments
		local segment = {};
		local segment_list = {};
		-- initial segmentation
		find_flat_land.detect_segments( heightmap, minp, maxp, segment, segment_list );
		-- some positions may have been assigned to diffrent segments althgouh they
		-- really lie in the same segment; this cannot be detected by find_flat_land.detect_segments
		-- and needs to be corrected here
		segment_list = find_flat_land.merge_segments_with_same_height( heightmap, minp, maxp, segment, segment_list );
		-- segments which are (regional) maxima are particulary intresting because we might want
		-- to lower or raise the terrain in these segments
		segment_list = find_flat_land.identify_local_highest_and_lowest_segment( heightmap, minp, maxp, segment, segment_list );


		-- lower the local mountain tops by 1, raise local holes by 1 up
		local i = 0;
		for az=minp.z,maxp.z do
		for ax=minp.x,maxp.x do
			i = i+1;
			local height = heightmap[i];
			heightmap2[ i ] = heightmap[i];
			local segment_id = segment_list[ segment[i] ].merged;
			if( not( segment_id )) then
				segment_id = segment[i];
			end
			-- cut mountaintops off and place glass one lower than where the mountaintop was
			if( segment_list[ segment_id ].is_local_highest ) then
				heightmap2[i] = heightmap2[i]-1;
				minetest.set_node( {x=ax, y=height, z=az}, {name="air", param2 = 0});
				minetest.set_node( {x=ax, y=height-1, z=az}, {name="default:glass", param2 = 0});
--				minetest.set_node( {x=ax, y=height, z=az}, {name="find_flat_land:segment", param2 = segment_id%256});
			-- fill local holes with obsidian_glass
			elseif( segment_list[ segment_id ].is_local_lowest ) then
				heightmap2[i] = heightmap2[i]+1;
				minetest.set_node( {x=ax, y=height, z=az}, {name="find_flat_land:segment", param2 = segment_id%256});
				minetest.set_node( {x=ax, y=height+1, z=az}, {name="default:obsidian_glass", param2 = 0});
			-- place a segment node for visualization
			else
				minetest.set_node( {x=ax, y=height, z=az}, {name="find_flat_land:segment", param2 = segment_id%256});
			end
		end
		end
	end


	-- analyze how many subsequent blocks have the same height in each row and column
	local same_height_count = find_flat_land.do_same_height_count( heightmap2, minp, maxp );

	-- use the information gained from do_same_height_count(..) to identify places of intrest 	
	-- search for flat land of 8 in x and 7 in z direction
	local buildplace_list = find_flat_land.search_for_flat_land( same_height_count, 8, 7, heightmap2, minp, maxp );
	-- place a meselamp to indicate where such places are located
	for nr, i in pairs( buildplace_list ) do
		minetest.set_node( {x=minp.x+(i%chunksize)-1, y=heightmap2[ i ], z=minp.z+math.floor(i/chunksize)}, {name="default:meselamp"});
	end
       	print( 'TIME ELAPSED: '..tostring( minetest.get_us_time() - t_last ) );
end);
