pico-8 cartridge // http://www.pico-8.com
version 8
__lua__
--the harvest   stay calm through
--the dark woods after a long day
player = {}
cam_offset_x = 0
cam_offset_y = 0
cam_dx = 0
cam_dy = 0
cam_x = 0
cam_y = 0
beam1 = {}
beam2 = {}
beam_bound = {}
trees = {}
active_trees = {}
scarecrows = {}
crows = {}
active_crows = {}
objects = {}
lit_objects = {}
active_map = 1
transition_frame = 0
caught_frame = 0
caught_scarecrow = {}
map_bounds = {}
fright = 0.0
extra_fright = 0
heartbeat_counter = 0
active_text = {}
active_text.active = false
events = {}
win_game = 0

function spawn_house_scarecrows()
 wave_count += 1
 if wave_count > 3 then
  return
 end
 local goalx, act = {63, 103}, {0,200,0,200}
 init_scarecrow_path(3, 99, act, pick_value(goalx), 72, rnd(), 22)
 init_scarecrow_path(31, 134, act, pick_value(goalx), 72, rnd(), 18)
 init_scarecrow_path(84, 134, act, pick_value(goalx), 72, rnd(), 18)
 init_scarecrow_path(131, 134, act, pick_value(goalx), 72, rnd(), 18)
 init_scarecrow_path(194, 109, act, pick_value(goalx), 72, rnd(), 16)
end

function pick_value(values)
 return values[rand_int(#values) + 1]
end

function init_lit_objects()
 init_window(60, 33, 20, 97, 8, 7)
 init_window(77, 50, 37, 114, 6, 8)
 init_window(118, 48, 78, 112, 4, 8)
 init_window(134, 50, 94, 114, 6, 8)
end

function init_window(x, y, sx, sy, w, h)
 window = {}
 window.x = x
 window.y = y
 window.draw_type = 4
 window.sx = sx
 window.sy = sy
 window.width = w
 window.height = h
 add(lit_objects, window)
end

function draw_lit_object(li)
 set_palette(li)
 sspr(li.sx, li.sy, li.width, li.height, li.x, li.y)
end

function heartbeat()
 if fright + extra_fright == 0 or (caught_frame > 0 and caught_frame < 60) then
  return
 end
 heartbeat_counter += 1
 target = -30*fright + 40
 if extra_fright > 0 then
  target = max(10, target - 10)
  extra_fright -= 1
 end
 if heartbeat_counter > target then
  sound = 8
  for s in all(scarecrows) do
   if s.active then
    sound = 2
    if in_light(s) then
     sound = 9
     break
    end
   end
   if in_light(s) then
    sound = 2
   end
  end
  sfx(sound)
  heartbeat_counter = 0
 end
end

function init_objects(n)
 objects = {}
 if n == 1 then
  init_cart(78, 45, false)
  init_branch_v(265, 104)
  init_branch_v(272, 95)
  init_branch_h(411, 95)
  init_sack(672, 42, false)
  init_bucket(1028, 24, false, false)
  init_cart(1441, 58, true)
  init_branch_h(1346, 104)
 elseif n == 2 then
  init_cart(147, 66, false)
  init_rock(84, 114)
  init_sack(271, 86, true, false)
  init_bucket(294, 117, false, false)
  init_rock(292, 7)
  init_sack(374, 170, false, false)
  init_rock(370, 177)
  init_branch_v(307, 28)
  init_branch_v(355, 198)
 elseif n == 3 then
  init_sack(22, 198, true, true)
  init_rock(100, 237)
  init_rock(106, 215)
  init_cart(420, 135, false)
 elseif n == 4 then
  init_branch_h(67, 1034)
  init_bucket(19, 1008, false, true)
  init_sack(7, 1006, false, true)
  init_branch_v(128, 998)
  init_cart(59, 21, true)
  init_sack(54, 633, false, false)
 else
  init_cart(148, 72, false)
  init_branch_h(36, 47)
  init_branch_v(18, 40)
  init_rock(19, 101)
  --lumber
  init_branch_h(172, 56)
  --well
  init_object(137, 133, 107, 1, 2, {-3, 4, -4, 0}, false)
 end
end

function init_branch_v(x, y)
 init_object(108, x, y, 1, 2, {-2, 3, -14, -1}, rand_boolean())
end

function init_branch_h(x, y)
 init_object(122, x, y, 2, 1, {-7, 8, -4, -1}, rand_boolean())
end

function init_rock(x, y)
 col = {-3, 4, -6, 0}
 s = 106
 if rnd() < 0.333 then
  s = 90
  col[3] = -4
 else
  s += rand_int(2)
 end
 init_object(s, x, y, 1, 1, col, rand_boolean())
end

function init_bucket(x, y, flipped, tipped)
 s = 87
 if tipped then
  s = 88
 end
 init_object(s, x, y, 1, 1, {-3,3,-4,0}, flipped)
end

function init_sack(x, y, flipped, hoe)
 s = 46
 if hoe then
  s = 62
 end
 init_object(s, x, y, 2, 1, {-6,7,-5,0}, flipped)
end

function init_cart(x, y, flipped)
 init_object(14, x, y, 2, 2, {-7,8,-9,0}, flipped)
end

function init_object(sprite, x, y, width, height, col, flipped)
 object = {}
 object.x = x
 object.y = y
 object.draw_type = 3
 object.sprite = sprite
 object.height = height
 object.width = width
 object.col = col
 object.flipped = flipped
 add(objects, object)
end

function draw_object(o)
 set_palette(o)
 spr(o.sprite, o.x - o.width*4 + 1, o.y - o.height*8 + 1, o.width, o.height, o.flipped)
end

function init_crows(n)
 active_crows = {}
 for place in all(crows[n]) do
  init_random_crow(place[1], place[2], 0.75)
 end
 
 --special crows
 if n == 1 then
  init_crow(819, 90, 1, 0)
  init_crow(843, 90, 0, 0)
 elseif n == 2 then
  init_random_crow(400, 74, 0.667)
  init_random_crow(377, 133, 0.667)
  init_random_crow(84, 110, 0.333)
 elseif n == 3 then
  init_random_crow(211, 68, 0.5)
  init_random_crow(271, 119, 0.5)
  init_random_crow(313, 159, 0.5)
  init_random_crow(294, 77, 0.5)
  init_random_crow(284, 78, 0.5)
 end
end

function init_random_crow(x, y, spawn_threshold)
 init_crow(x, y, rand_int(2), spawn_threshold)
end

function init_crow(x, y, dir, spawn_threshold)
 if rnd() > spawn_threshold then
  crow = {}
  crow.draw_type = 2
  crow.dir = dir
  crow.x = x
  crow.y = y
  crow.flying = false
  crow.frame = rand_int(53)
  add(active_crows, crow)
 end
end

function update_crow(crow)
 if on_screen(crow.x, crow.y) then
  if crow.flying then
   crow.y -= 0.5 + rnd()
   crow.x += 4*crow.dir - 2
   crow.frame += 1
   crow.frame %= 12
   if crow.y <= 0 then
    del(active_crows, crow)
   end
  else
   if distance_to(crow) < 16 and rnd() > 0.5 then
    crow.flying = true
    crow.dir = rand_int(2)
    crow.frame = 0
    sfx(7)
    if rnd() > 0.75 then
     sfx(6)
    end
   end
   crow.frame += 0.5 + rnd()
   if flr(crow.frame) == 42 and rnd() > 0.5 then
    crow.frame = 50
   end
   crow.frame %= 53
  end
 end
end

function distance_to(entity)
 --using manhattan distance, because euclidean overflows...
 --use a (very) approximate correction to help diagonals
 local x_dist = abs(player.x - entity.x)
 local y_dist = abs(player.y - 2 - entity.y)
 if y_dist ~= 0 and x_dist/y_dist > 0.7 and x_dist/y_dist < 1.428 then
  return .74 * (x_dist + y_dist)
 end
 return x_dist + y_dist
end

function draw_crow(crow)
 local n = 103
 local frame = crow.frame
 if crow.flying then
  char_palette()
  if frame < 3 then
   n = 119
  elseif frame >= 6 and frame < 9 then
   n = 121
  else
   n = 120
  end
 else
  set_palette(crow)
  if (frame >= 24 and frame < 30) or (frame >= 45 and frame < 50) then
   n = 104
  elseif (frame >= 42 and frame < 45) or frame >= 50 then
   n = 105
  end
 end
 spr(n, crow.x - 4, crow.y - 7, 1, 1, crow.dir == 0)
end

function interaction_events()
 if active_map == 1 then
  if not log_chopped and within_bounds(player.x, player.y, {43, 44, 25, 39}) then
   player.chop_counter = 45
   sfx(5)
  end
 elseif active_map == 3 then
  if fence_chopped < 4 and within_bounds(player.x, player.y, {91, 92, 115, 123}) then
   player.chop_counter = 45
   sfx(5)
  end
 elseif active_map == 5 then
   --house event: celar
   if within_bounds(player.x, player.y, {34, 36, 58, 63}) then
    if celar_chopped then
     if not got_key then
      sfx(12)
      init_text("got the spare key", 45)
      got_key = true
     end
    else
     player.chop_counter = 45
     sfx(5)
    end
   end

   --house event: door left
   if within_bounds(player.x, player.y, {60, 65, 69, 70}) then
    try_door(true)
   end

   --house event: door right
   if within_bounds(player.x, player.y, {101, 106, 67, 68}) then
    try_door(false)
   end
 end
end

function try_door(left)
 if got_key then
  if (left_door and left) or (not left_door and not left) then
   win_game = 1
   sfx(14)
  else
   init_text("jammed!", 15)
   sfx(13)
  end
 else
  init_text("locked! key's in the celar", 30)
  sfx(15)
 end
end

function chop_event()
 if active_map == 1 then
  sfx(3)  
  if scare_crows() then
   sfx(7)
  end
  init_text("i should get goin'...", 90)
  log_chopped = true
 elseif active_map == 3 then

  fence_chopped += 1
  if fence_chopped == 4 then
   sfx(4)
   mset(73, 13, 143)
   mset(73, 14, 159)
   mset(73, 15, 175)
  else
   sfx(3)
  end
 elseif active_map == 5 then
  --house event
  if not celar_chopped then
   if rnd() < 0.25 then
    sfx(11)
    mset(5, 22, 172)
    mset(5, 23, 188)
    celar_chopped = true
   else
    sfx(10)
   end
   if scare_crows() then
    sfx(7)
   end
  end
 end
end

function scare_crows()
 local crows_scared = false
 for crow in all(active_crows) do
   if on_screen(crow.x, crow.y) and distance_to(crow) < 48 then
    crows_scared = true
    crow.flying = true
    crow.frame = 0
   end
  end
 return crows_scared
end

function add_event(e)
 add(events, e)
end

function init_events(n)
 events = {}
 if n == 1 then
  add_event({
   bounds = {199,200,0,135},
   text = "sure is dark tonight",
   time = 90,
   scare = 0
  })
  add_event({
   bounds = {327,328,0,135},
   text = "glad i brought the flashlight",
   time = 90,
   scare = 0
  })
  add_event({
   bounds = {560,700,0,70},
   text = "pumpkins're comin' in nicely",
   time = 120,
   scare = 0
  })
  add_event({
   bounds = {794,852,70,135},
   text = "scarecrow's not doin' much...",
   time = 90,
   scare = 0
  })
  add_event({
   bounds = {1100,1101,0,135},
   text = "who put that right in the path?",
   time = 90,
   scare = 0
  })
  add_event({
   bounds = {1229,1230,0,135},
   text = "what was--",
   time = 45,
   scare = 0.12
  })
  add_event({
   bounds = {1286,1287,0,135},
   text = "somethin' followin'",
   time = 90,
   scare = 0.03
  })
  add_event({
   bounds = {1500,1501,0,135},
   text = "hurry, hurry, hurry",
   time = 90,
   scare = 0.1
  })
 elseif n == 2 then
  add_event({
   bounds = {10,11,0,199},
   text = "am i goin' crazy?",
   time = 90,
   scare = 0
  })
  add_event({
   bounds = {180,181,0,199},
   text = "just gotta get home",
   time = 90,
   scare = 0
  })
  add_event({
   bounds = {307,308,93,104},
   text = "err...",
   time = 90,
   scare = 0.125
  })

 elseif n == 3 then
  add_event({
   bounds = {20,21,189,239},
   text = "stay--",
   time = 30,
   scare = 0
  })
  add_event({
   bounds = {35,100,170,171},
   text = "stay calm",
   time = 60,
   scare = 0
  })
  add_event({
   bounds = {35,100,75,76},
   text = "blocked!",
   time = 60,
   scare = 0.1
  })
  add_event({
   bounds = {220,261,77,160},
   text = "keep movin'",
   time = 60,
   scare = 0.05
  })

 elseif n == 4 then
  add_event({
   bounds = {70,80,1000,1100},
   text = "into the woods...",
   time = 60,
   scare = 0.0
  })
  add_event({
   bounds = {0,150,720,725},
   text = "i know yer somewhere!",
   time = 60,
   scare = 0.1
  })
  add_event({
   bounds = {0,150,240,250},
   text = "don't stop! almost home!",
   time = 45,
   scare = 0.05
  })
 end
end

function within_bounds(x, y, bounds)
 return x >= bounds[1] and x <= bounds[2] and y >= bounds[3] and y <= bounds[4]
end

function update_events()
 for event in all(events) do
  if within_bounds(player.x, player.y, event.bounds) then
   fright = min(1.0, fright + event.scare)
   init_text(event.text, event.time)
   del(events, event)
  end
 end

 --special events
 if active_map == 3 then
  if not scarecrows_spawned and within_bounds(player.x, player.y, {34, 92, 0, 120}) then
   local bot_row_act = {34, 92, 0, 120}
   init_scarecrow_path(46, 217, bot_row_act, 46, 129, 2, 8)
   init_scarecrow_path(68, 217, bot_row_act, 68, 129, 2, 8)
   init_scarecrow_path(90, 217, bot_row_act, 90, 129, 2, 8)
   add_event({
    bounds = {35,100,149,150},
    text = "no! the corn field, only chance",
    time = 120,
    scare = 0.1
   })
   scarecrows_spawned = true
  end
 end
end

function init_text(text, time)
 active_text.text = text
 active_text.index = 0
 active_text.countdown = time
 active_text.offsets = {}
 for i = 1,#text do
  active_text.offsets[i] = 0
 end
 active_text.active = true
end

function _init()
 --player state
 player.x = 38
 player.y = 40

 player.direction = 1
 --collision box: {xmin, xmax, ymin, ymax}
 player.col = {-3,4,-5,0}
 player.frame = 0
 player.swing_counter = 0
 player.chop_counter = 0
 player.resolve = 3
 player.moving = false

 --input state
 arrow_hold_count = 0
 hold_direction = false

 --map bounds
 add(map_bounds, {208, 16})
 add(map_bounds, {60, 24})
 add(map_bounds, {54, 29})
 add(map_bounds, {20, 134})
 add(map_bounds, {24, 16})

 --world objects
 for i = 1,5 do
  tree_map_list, crow_map_list = init_map_lists(i)
  add(trees, tree_map_list)
  add(crows, crow_map_list)
 end

 init_map(active_map)
end

function init_map_lists(map_n)
 local tree_map_list, crow_map_list = {}, {}
 for i=0,map_bounds[map_n][1] - 1 do
  for j=0,map_bounds[map_n][2] - 1 do
   local map_flags = fget(mget(cell_to_map_n(i, j, map_n)))
   if band(map_flags, 0x2) == 2 then
    add(tree_map_list, {i, j, rand_boolean()})
   end
   if band(map_flags, 0x4) == 4 then
    add(crow_map_list, {i*8 + 4, j*8})
   end
  end
 end
 return tree_map_list, crow_map_list
end

--[[
 scarecrow types:
  1 - teleporting
  2 - approaching
  3 - continuous
  4 - stationary
]]--
function init_scarecrow(x, y, type, base_wait)
 scarecrow = {}
 scarecrow.draw_type = 1
 scarecrow.direction = 3
 scarecrow.x = x
 scarecrow.y = y
 scarecrow.type = type
 scarecrow.col = {-3,3,-5,0}
 scarecrow.act = {0,0,0,0}
 scarecrow.active = false
 scarecrow.frame = 0
 scarecrow.wait_counter = 0
 scarecrow.recover_frame = 0
 scarecrow.recover_x = 0
 scarecrow.recover_y = 0
 scarecrow.base_wait = base_wait
 return scarecrow
end

function init_scarecrow_jump(x, y, act, time)
 local s = init_scarecrow(x, y, 1, time)
 s.act = act
 add(scarecrows, s)
end

function init_scarecrow_approaching(x, y, act)
 local s = init_scarecrow(x, y, 2, 4 + rand_int(3))
 s.act = act
 add(scarecrows, s)
end

function init_scarecrow_path(x, y, act, wx, wy, group, wait)
 local s = init_scarecrow(x, y, 3, wait)
 s.act = act
 s.wx = wx
 s.wy = wy
 s.group = group
 add(scarecrows, s)
end

function init_scarecrow_still(x, y)
 local s = init_scarecrow(x, y, 4, 1)
 s.active = true
 add(scarecrows, s)
end

function update_scarecrow(scarecrow)
 scarecrow.frame = (scarecrow.frame + rnd(.1) + .1) % 2

 --handle getting swung at
 if scarecrow.recover_frame > 0 then
  scarecrow.recover_frame -= 1
  if scarecrow.recover_frame == 23 then
   scarecrow.x = scarecrow.recover_x
   scarecrow.y = scarecrow.recover_y
  end
  return
 elseif scarecrow.type == 3 then
  for other in all(scarecrows) do
   if other.type == 3 then
    if other.group == scarecrow.group and (in_light(other) or other.recover_frame > 0) then
     return
    end
   end
  end
 end

 if player.swing_counter > 0 then
  return
 end

 if not scarecrow.active then
  --activate scarecrow if player moves within activation rectangle
  if within_bounds(player.x, player.y, scarecrow.act) then
   scarecrow.active = true
  end
 elseif not in_light(scarecrow) and transition_frame + caught_frame == 0 then
  if scarecrow.wait_counter > 0 then
   scarecrow.wait_counter -= 1
  else
   if scarecrow.type == 1 then --teleporting
    local dx, dy = player.x - scarecrow.x, player.y - scarecrow.y
    local new_x, new_y = valid_teleport_position(scarecrow, scarecrow.x + flr(dx/3), scarecrow.y + flr(dy/3), dx, dy)
    if not in_light_coords(new_x, new_y) then
     scarecrow.x, scarecrow.y = new_x, new_y
     scarecrow.wait_counter = rnd(5) + scarecrow.base_wait
    end
   elseif scarecrow.type == 2 then --approaching
    local dx, dy, new_x, new_y = player.x - scarecrow.x, player.y - scarecrow.y, scarecrow.x, scarecrow.y
    if abs(dx) >= abs(dy) then
     new_x += 2*sgn(dx)
     if in_collision(scarecrow, new_x, new_y) and abs(dy) > 0.5 then
      new_x = scarecrow.x
      new_y += 2*sgn(dy)
     end
    else
     new_y += 2*sgn(dy)
     if in_collision(scarecrow, new_x, new_y) and abs(dx) > 0.5 then
      new_y = scarecrow.y
      new_x += 2*sgn(dx)
     end
    end
    if not in_light_coords(new_x, new_y) and not in_collision(scarecrow, new_x, new_y) then
     scarecrow.x, scarecrow.y = new_x, new_y
     scarecrow.wait_counter = flr(rnd(4) + 2)
    end
   elseif scarecrow.type == 3 then --steady
    --move in direction of waypoint
    local dx, dy = scarecrow.wx - scarecrow.x, scarecrow.wy - scarecrow.y
    if dx ~= 0 then
     dx /= abs(dx)
    end
    if dy ~= 0 then
     dy /= abs(dy)
    end
    local new_x, new_y = scarecrow.x + dx, scarecrow.y + dy
    if not move_scarecrow_to(scarecrow, new_x, new_y) then
     if not move_scarecrow_to(scarecrow, scarecrow.x, new_y) then
      move_scarecrow_to(scarecrow, new_x, scarecrow.y)
     end
    end
   end
  end
  --update direction
  scarecrow.direction = determine_scarecrow_direction(scarecrow)
 end
end

function move_scarecrow_to(scarecrow, x, y)
 if not in_collision(scarecrow, x, y) then
  scarecrow.x, scarecrow.y = x, y
  scarecrow.wait_counter = rnd(5) + scarecrow.base_wait
  return true
 end
 return false
end

function valid_teleport_position(scarecrow, new_x, new_y, dx, dy)
 if in_collision(scarecrow, new_x, new_y) then
  local offset = 1
  while true do
   local x1, y1, x2, y2 = new_x + sgn(dx)*offset, new_y + sgn(dy)*offset, new_x - sgn(dx)*offset, new_y - sgn(dy)*offset
   if not in_collision(scarecrow, x1, new_y) then
    return x1, new_y
   elseif not in_collision(scarecrow, new_x, y1) then
    return new_x, y1
   elseif not in_collision(scarecrow, x2, new_y) then
    return x2, new_y
   elseif not in_collision(scarecrow, new_x, y2) then
    return new_x, y2
   end
   offset += 1
  end
 end
 return new_x, new_y
end

function determine_scarecrow_direction(scarecrow)
 local dx_to_farmer, dy_to_farmer = player.x - scarecrow.x, player.y - scarecrow.y
 if abs(dy_to_farmer) > abs(dx_to_farmer) then
  if dy_to_farmer > 0 then
   return 3
  else
   return 2
  end
 elseif dx_to_farmer < 0 then
  return 0
 end
 return 1
end

function opposite_direction(d)
 if d%2 == 1 then
  return d - 1
 end
 return d + 1
end

function update_caught()
 --handle tie of getting caught and exiting map, tie goes to the player
 --handle caught while chopping, wait until chop finishes
 if transition_frame + player.swing_counter + player.chop_counter > 0 then
  return
 end

 if caught_frame == 0 then
  --check for player caught
  for scarecrow in all(scarecrows) do
   --note: using manhattan distance, since euclidean may overflow
   if scarecrow.recover_frame == 0 and distance_to(scarecrow) <= 15 then
    player.resolve -= 1
    extra_fright = 90

    --two possiblities: either swing axe or get caught
    if player.resolve > 0 then
     player.direction = opposite_direction(determine_scarecrow_direction(scarecrow))
     player.swing_counter = 15
     scarecrow.recover_frame = 30

     local dx, dy = 0, 0
     if player.direction == 0 then
      dx = -10
     elseif player.direction == 1 then
      dx = 10
     elseif player.direction == 2 then
      dy = -10
     else
      dy = 10
     end
     if scarecrow.type <= 2 then
      scarecrow.recover_x, scarecrow.recover_y = valid_teleport_position(scarecrow, scarecrow.x + dx, scarecrow.y + dy, dx, dy)
     else
      scarecrow.recover_x, scarecrow.recover_y  = scarecrow.x, scarecrow.y
     end

     --axe swing and miss
     sfx(0)
    else
     --initialize darkness start and end points
     caught_points = {}
     for i = 1,10 do
      new_point = {}
      new_point.sx = scarecrow.x + rand_int(5) - 2
      new_point.sy = scarecrow.y + rand_int(6) - 10
      new_point.ex = player.x + rand_int(6) - 2
      new_point.ey = player.y + rand_int(8) - 8
      new_point.completion = 0
      new_point.color = rand_int(4)
      if new_point.color == 0 then
       new_point.color = 5
      elseif new_point.color > 1 then
       new_point.color = 0
      end
      add(caught_points, new_point)
     end
     caught_frame = 72
     --caught sound
     sfx(1)
    end
   end
  end
 elseif caught_frame > 0 then
  if caught_frame > 60 then
   --update scarecrow darkness
   for point in all(caught_points) do
    if point.completion < 1 and rnd() > 0.75 then
     --point.completion = min(point.completion + .15, 1)
     point.completion = min(point.completion + rnd(.4) + .1, 1)
    end
   end
   caught_frame -= 1
  elseif caught_frame > 1 then
   --decrement counter
   caught_frame -= 1
  else
   --reset current map
   reset_player_position()
   active_text.active = false
   init_map(active_map)
   caught_frame = 0
  end
 end
end

function reset_player_position()
 if active_map == 1 then
  player.x = 34
  player.y = 63
  player.direction = 1
 elseif active_map == 2 then
  player.x = 3
  player.y = 97
  player.direction = 1
 elseif active_map == 3 then
  player.x = 3
  player.y = 209
  player.direction = 1
 elseif active_map == 4 then
  player.x = 5
  player.y = 1049
  player.direction = 1
 else
  player.x = 120
  player.y = 134
  player.direction = 2
 end
end

function draw_caught(n)
 for point in all(caught_points) do
  --linear interpolation
  local endx = point.sx + point.completion*(point.ex - point.sx)
  local endy = point.sy + point.completion*(point.ey - point.sy)
  line(point.sx, point.sy, endx, endy, point.color)
 end
end

function in_light(n)
 if n.draw_type == 3 then
  return in_light_coords(flr(n.x), flr(n.y + n.col[3]/2))
 end
 return in_light_coords(flr(n.x), flr(n.y))
end

function in_light_coords(x, y)
 if player.direction <= 1 then
  if within_bounds(x, y, {beam_bound[1], beam_bound[2], beam1.m*x + beam1.b, beam2.m*x + beam2.b}) then
   return true
  end
 else
  if within_bounds(x, y, {(y - beam1.b)/beam1.m, (y-beam2.b)/beam2.m, beam_bound[1], beam_bound[2]}) then
   return true
  end
 end
 return false
end

function set_palette(c)
 char_palette()
 if not (in_light(c) or c.draw_type == 4) then
  dark_palette()
 end
 if transition_frame > 0 then
  transition_palette()
 end
end

function draw_scarecrow(scarecrow)
 if scarecrow.recover_frame > 0 then
  char_palette()
  for c = 1,15 do
   pal(c, 0)
  end
 else
  set_palette(scarecrow)
 end

 if scarecrow.recover_frame <= 28 and scarecrow.recover_frame > 23 then
  circfill(scarecrow.x - 1, scarecrow.y - 9, scarecrow.recover_frame - 24, 0)
  circfill(scarecrow.recover_x - 1, scarecrow.recover_y - 9, abs(scarecrow.recover_frame - 28), 0)
 else
  local sprite = 0
  if scarecrow.direction == 0 then
   sprite = 4
  elseif scarecrow.direction == 2 then
   sprite = 36
  elseif scarecrow.direction == 3 then
   sprite = 32
  end
  spr(sprite + 2*flr(scarecrow.frame), scarecrow.x - 7, scarecrow.y - 15, 2, 2)
  if scarecrow.recover_frame < 24 and scarecrow.recover_frame > 0 and scarecrow.recover_frame % 2 == 0 and transition_frame == 0 then
   for i = 1,3 do
    pal()
    pset(scarecrow.x - 8 + rand_int(15), scarecrow.y - 15 + rand_int(13), 1)
   end
  end
 end
end

function _update()
 if win_game > 0 then
  win_game += 1
  return
 end

 event_timer += 1
 if active_map == 5 and event_timer  % 300 == 150 then
  spawn_house_scarecrows()
 end

 --update player catching scarecrow
 update_caught()

 if transition_frame + caught_frame == 0 then
  heartbeat()

  --regular update
  if player.swing_counter + player.chop_counter == 0 then
   hold_direction = btn(5)

   if btnp(4) then
    interaction_events()
   end

   local dx,dy = 0,0
   local btn_pressed = false
   if btn(2) then
    dy += movement_key(2, -.75)
    btn_pressed = true
   elseif btn(3) then
    dy += movement_key(3, .75)
    btn_pressed = true
   end

   if btn(1) then
    dx += movement_key(1, .75)
    btn_pressed = true
   elseif btn(0) then
    dx += movement_key(0, -.75)
    btn_pressed = true
   end

   if not btn_pressed then
    player.frame = 0
    arrow_hold_count = 0
   end

   if dx ~= 0 or dy ~= 0 then
    player.moving = true
    local frame_increase = 0.12

    if dx ~= 0 and dy ~= 0 then
     dx /= 1.414
     dy /= 1.414
    end

    if hold_direction then
     dx *= .667
     dy *= .667
     frame_increase *= .667
    end
    local newx, newy = player.x + dx, player.y + dy
    local collision = false
    if dx ~= 0 and dy ~= 0 then
     if in_collision(player, newx, player.y) then
      newx = player.x
      collision = true
     end
     if in_collision(player, newx, newy) then
      newy = player.y
     else
      collision = false
     end
    elseif in_collision(player, newx, newy) then
     collision = true
    end
    if collision then
     player.frame = 0
     player.moving = false
    else
     player.frame += frame_increase
     player.frame %= 4
     player.x, player.y = newx, newy
    end
    --see if player stepped into a new area
    update_map()
   else
    player.moving = false
   end

  --axe swing reaction update
  else
   player.moving = false
   player.swing_counter = max (0, player.swing_counter - 1)
   player.chop_counter = max(0, player.chop_counter - 1)
  end

  --update flashlight beams
  local px, py = flr(player.x), flr(player.y)
  if player.direction == 1 then
   beam_bound[1] = px + 4
   beam_bound[2] = px + 44
   beam1.m = -.75
   beam1.b = py - 6 - beam1.m*(beam_bound[1])
   beam2.m = .75
   beam2.b = py - 6 - beam2.m*(beam_bound[1])
   --special case offsets
   if is_stepping_left() then
    beam1.b += 1
    beam2.b += 1
   elseif is_stepping_right() then
    beam1.b += 1 - beam1.m
    beam2.b += 1 - beam2.m
    beam_bound[1] += 1
    beam_bound[2] += 1
   end
  elseif player.direction == 0 then
   beam_bound[2] = px - 3
   beam_bound[1] = px - 43
   beam1.m = .75
   beam1.b = py - 5 - beam1.m*(beam_bound[2])
   beam2.m = -.75
   beam2.b = py - 5 - beam2.m*(beam_bound[2])
   if is_stepping_left() then
    beam1.b += 1
    beam2.b += 1
   elseif is_stepping_right() then
    beam1.b += 1 + beam1.m
    beam2.b += 1 + beam2.m
    beam_bound[1] -= 1
    beam_bound[2] -= 1
   end
  elseif player.direction == 2 then
   beam_bound[2] = py - 6
   beam_bound[1] = py - 46
   beam1.m = 1.333
   beam1.b = beam_bound[2] - beam1.m*(px - 3)
   beam2.m = -1.333
   beam2.b = beam_bound[2] - beam2.m*(px - 3)
   if is_stepping_left() then
    beam1.b += 1
    beam2.b += 1
    beam_bound[1] += 1
    beam_bound[2] += 1
   elseif is_stepping_right() then
    beam1.b -= beam1.m
    beam2.b -= beam2.m
   end
  else
   beam_bound[1] = py - 3
   beam_bound[2] = py + 37
   beam1.m = -1.333
   beam1.b = beam_bound[1] - beam1.m*(px + 4)
   beam2.m = 1.333
   beam2.b = beam_bound[1] - beam2.m*(px + 4)
   if is_stepping_left() then
    beam1.b += beam1.m
    beam2.b += beam2.m
   end
  end
 elseif transition_frame > 0 then
  if transition_frame == 30 then
   player.x, player.y = next_x, next_y
   init_map(next_map)
  end
  transition_frame -= 1
 else
  heartbeat()
 end

 --chop events
 if player.chop_counter == 24 then
  chop_event()
 end

 --scarecrow movement
 foreach(scarecrows, update_scarecrow)

 --crow movement
 foreach(active_crows, update_crow)

 --update world animations
 foreach(active_trees, update_tree)

 --update environmental events
 update_events()

 --update text
 update_text()
end

function _draw()
 cls()

 if win_game > 30 then
  if win_game > 60 then
   print("home safe", 46, 64, 7)
  end
  return
 end

 --"gameover" black screen
 if caught_frame > 0 and caught_frame <= 60 then
  return
 end

 local transition_phase = flr(transition_frame/15)
 if transition_phase == 2 or transition_phase == 1 then
  return
 end
 pal()

 update_camera()
 camera(cam_x, cam_y)

 dark_palette()
 if transition_frame > 0 then
  transition_palette()
 end

 draw_map()

 if transition_frame == 0 then
  pal()

  --draw_darkness()
  draw_flashlight()
  pal()
 end

 draw_characters()

 if caught_frame > 0 then
  draw_caught()
 end

 palt(0,false)
 palt(11,true)
 foreach(active_trees, draw_tree)
 pal()

 --text
 draw_text()
end

function update_text()
 if active_text.active then
  local text_length = #(active_text.text)
  if active_text.index < text_length then
   active_text.index += 1
  elseif active_text.countdown > 0 then
   active_text.countdown -= 1
  else
   local done = true
   for i = 1,text_length do
    if active_text.offsets[i] == 0 then
     if rnd(fright) < .1 then
      active_text.offsets[i] += 0.5 + fright/2
     end
     done = false
    elseif active_text.offsets[i] < 13 then
     active_text.offsets[i] += 0.5  + fright/2
     done = false
    end
   end
   if done then
    active_text.active = false
   end
  end
 end
end

function draw_text()
 camera()
 rectfill(0, 114, 127, 127, 0)

 if active_text.active then
  local display_text = sub(active_text.text, 1, active_text.index)
  local cursor = 64 - 2*#display_text
  for i = 1,#display_text do
   local offset = active_text.offsets[i]
   local color = 7
   if offset >= 10 then
    color = 1
   elseif offset >= 7 then
    color = 13
   elseif offset >= 4 then
    color = 6
   end
   if offset < 13 then
    print(sub(display_text,i,i), cursor, 116 + active_text.offsets[i], color)
   end
   cursor += 4
  end
 end
end

function add_to_characters(c)
 add(characters, c)
end

function draw_characters()
 characters = {}
 foreach(scarecrows, add_to_characters)
 foreach(active_crows, add_to_characters)
 foreach(objects, add_to_characters)
 foreach(lit_objects, add_to_characters)

 --order characters back to front (rendering order)
 for i = 2,#characters do
  local j = i
  while j > 1 and in_front_of(characters[j - 1], characters[j]) do
   characters[j], characters[j-1] = characters[j - 1], characters[j]
   j -= 1
  end
 end

 local farmer_drawn = false
 for i = 1,#characters do
  if not farmer_drawn and in_front_of(characters[i], player) then
   char_palette()
   draw_farmer()
   farmer_drawn = true
  end

  if characters[i].draw_type == 1 then
   draw_scarecrow(characters[i])
  elseif characters[i].draw_type == 2 then
   draw_crow(characters[i])
  elseif characters[i].draw_type == 3 then
   draw_object(characters[i])
  else
   draw_lit_object(characters[i])
  end
 end
 if not farmer_drawn then
  char_palette()
  draw_farmer()
 end
 pal()
end

function char_palette()
 pal()
 palt(0,false)
 palt(11,true)
end

function in_front_of(a, b)
 local ax, ay, bx, by = flr(a.x), flr(a.y), flr(b.x), flr(b.y)
 if ay == by then
  return ax < bx
 end
 return ay > by
end

function update_map()
 if active_map == 1 then
  if player.x >= 1665 and player.y >= 51 and player.y < 69 then
   next_x, next_y = 3, player.y + 33
   transition()
  end
 elseif active_map == 2 then
  if player.x >= 481 and player.y >= 91 and player.y < 102 then
   next_x, next_y = 3, player.y + 112
   transition()
  end
 elseif active_map == 3 then
  if player.x >= 434 and player.y >= 147 and player.y <= 157 then
   next_x, next_y = 3, player.y + 896
   transition()
  end
 elseif active_map == 4 then
  if player.x >= 83 and player.x < 148 and player.y < 6 then
   next_x, next_y = player.x - 8, 134
   transition()
  end
 end
end

function transition()
 transition_frame = 60
 next_map = active_map + 1
end

function init_map(n)
 player.resolve = 3
 active_map = n
 extra_fright = 0
 heartbeat_counter = 0
 fill_active_trees(n)
 init_scarecrows(n)
 init_objects(n)
 init_events(n)
 init_crows(n)
 if active_map == 5 then
  init_lit_objects()
 end

 --starting fright level
 fright = n*0.25 - 0.25

 --special event flags
 log_chopped = false
 scarecrows_spawned = false
 fence_chopped = 0
 mset(73, 13, 142)
 mset(73, 14, 158)
 mset(73, 15, 85)
 celar_chopped = false
 mset(5, 22, 224)
 mset(5, 23, 240)

 --ending flags
 event_timer = 0
 got_key = false
 wave_count = 0
 left_door = rand_boolean()
end

function init_scarecrows(n)
 scarecrows = {}
 if n == 1 then
  init_scarecrow_jump(1143, 36, {1229, 1261, 0, 135}, 10)
  init_scarecrow_jump(1396, 20, {1344, 1351, 0, 135}, 10)

  --fenced scarecrow
  init_scarecrow_still(827, 108)

 elseif n == 2 then
  init_scarecrow_jump(356, 99, {307, 315, 69, 127}, 5)

 elseif n == 3 then
  local top_row_act = {34, 92, 0, 120}
  init_scarecrow_path(46, 20, top_row_act, 46, 110, 1, 8)
  init_scarecrow_path(68, 20, top_row_act, 68, 110, 1, 8)
  init_scarecrow_path(90, 20, top_row_act, 90, 110, 1, 8)

  local config1 = rand_boolean()
  local config2 = rand_boolean()
  if config1 then
   init_scarecrow_approaching(273, 118, {211, 219, 117, 120})
  else
   init_scarecrow_approaching(217, 118, {155, 164, 117, 120})
  end
  if config2 then
   init_scarecrow_approaching(160, 160, {155, 163, 117, 120})
  else
   init_scarecrow_approaching(217, 160, {155, 163, 157, 160})
  end

  if not config1 and config2 then
   init_scarecrow_approaching(273, 78, {211, 219, 77, 81})
   init_scarecrow_approaching(244, 198, {265, 280, 194, 200})
   init_scarecrow_approaching(328, 138, {345, 360, 156, 161})
  else
   init_scarecrow_approaching(216, 78, {164, 219, 37, 120})
   init_scarecrow_approaching(328, 194, {323, 331, 157, 160})
   init_scarecrow_approaching(310, 118, {267, 275, 117, 120})
  end

  init_scarecrow_approaching(160, 56, {155, 163, 77, 81})
  init_scarecrow_approaching(300, 158, {267, 331, 157, 160})

  if rand_boolean() then
   init_scarecrow_approaching(300, 78, {267, 331, 77, 80})
  else
   init_scarecrow_approaching(300, 38, {267, 331, 37, 40})
  end
  if rand_boolean() then
   init_scarecrow_approaching(366, 118, {323, 331, 117, 120})
  else
   init_scarecrow_approaching(244, 160, {208, 282, 157, 160})
  end

 elseif n == 4 then
  init_scarecrow_jump(82 + rand_int(54), 438, {74, 148, 372, 386}, 15)
  init_scarecrow_jump(82 + rand_int(54), 198, {74, 148, 180, 198}, 10)
  init_scarecrow_jump(82 + rand_int(54), 78, {74, 148, 70, 126}, 10)

  init_scarecrow_still(39, 999)
 end
end

function fill_active_trees(n)
 active_trees = {}
 for tree_params in all(trees[n]) do
  add(active_trees, create_tree(tree_params))
 end
end

function create_tree(params)
 local tree = {}
 tree.cell_x, tree.cell_y, tree.flipped = params[1], params[2], params[3]
 tree.branch_state = {}
 tree.branch_timer = {}
 for i = 1,5 do
  add(tree.branch_state, rand_int(2))
  add(tree.branch_timer, rand_int(90) + 30)
 end
 return tree
end

function on_screen(x, y)
 return within_bounds(x, y, {cam_x - 16, cam_x + 144, cam_y, cam_y + 152})
end

function update_tree(tree)
 --make sure tree is on screen
 local tx, ty = tree.cell_x*8, tree.cell_y*8
 if on_screen(tx, ty) then
  for i = 1,5 do
   tree.branch_timer[i] -= 1
   if tree.branch_timer[i] < 1 then
    tree.branch_state[i] = 1 - tree.branch_state[i]
    tree.branch_timer[i] = rand_int(90) + 30
   end
  end
 end
end

function flip_single_sprite(n, x, y, flipped)
 spr(n, x, y, 1, 1, flipped)
end

function draw_tree(tree)
 local tx, ty = tree.cell_x*8, tree.cell_y*8
 if on_screen(tx, ty) then
  local flipped = tree.flipped
  local flipped_dir = 1
  if flipped then
   flipped_dir = -1
  end
  local branch_state = tree.branch_state
  ty -= 8
  flip_single_sprite(109 + branch_state[1], tx, ty, flipped)
  ty -= 8
  flip_single_sprite(93, tx, ty, flipped)
  tx -= flipped_dir*8
  flip_single_sprite(92 - branch_state[2], tx, ty, flipped)
  tx += flipped_dir*16
  flip_single_sprite(94 + branch_state[3], tx, ty, flipped)
  ty -= 8
  flip_single_sprite(78 + branch_state[4], tx, ty, flipped)
  tx -= flipped_dir*8
  flip_single_sprite(77, tx, ty, flipped)
  tx -= flipped_dir*8
  flip_single_sprite(76 - branch_state[5], tx, ty, flipped)
 end
end

function rand_boolean()
 return rand_int(2) == 1
end

function rand_int(n)
 return flr(rnd(n))
end

function movement_key(dir, change)
 if not hold_direction then
  player.direction = dir
 end
 arrow_hold_count += 1
 if arrow_hold_count > 3 then
  return change
 end
 return 0
end

function px_to_cell(p)
 return flr(p/8)
end

function cell_to_map(cx, cy)
 return cell_to_map_n(cx, cy, active_map)
end

function cell_to_map_n(cx, cy, map_n)
 if map_n == 1 then
  if cx >= 16 and cx < 64 then
   cx %= 8
   cx += 8
  elseif cx >= 100 and cx < 107 and cy >= 10 and cy < 86 then
   cx -= 68
   cy += 14
  elseif cx >= 64 then
   cx %= 16
   cx += 16
  end
 elseif map_n == 2 then
  if cx < 32 then
   cx %= 8
   cx += 120
  end
 elseif map_n == 3 then
  if cx < 21 then
   cx += 61
  elseif cx < 42 then
   cx %= 7
   cx += 75
  else
   cx += 40
  end
 elseif map_n == 4 then
  cx += 94
  if cy > 108 then
   cy -= 105
  elseif cy > 18 then
   cy -= 19
   cy %= 15
   cy += 4
  end
 else
  cy += 16
 end
 return cx, cy
end

function px_to_map(px, py)
 return cell_to_map(px_to_cell(px), px_to_cell(py))
end

function draw_map()
 if active_map == 1 then
  --start section
  map(0,0,0,0,16,16)

  --repeated forest
  for i = 0,5 do
   map(8, 0, 128 + i*64, 0, 8, 16)
  end

  --start pumpkin farms
  for i = 0,8 do
   map(16, 0, 512 + i*128, 0, 16, 16)
  end

  --insert tiny scarecrow corral
  map(32, 24, 800, 80, 7, 6)

 elseif active_map == 2 then
  --path
  for i = 0,3 do
   map(120, 0, i*64, 0, 8, 24)
  end

  --corn field
  map(32,0,256,0,28,24)

 elseif active_map == 3 then
  --start section
  map(61,0,0,0,21,29)

  --repeated corn rows
  for i = 0,2 do
   map(75,0,168 + i*56,0,7,29)
  end

  --end section
  map(82,0,336,0,12,29)
 elseif active_map == 4 then
  --map top
  map(94,0,0,0,20,19)

  --repeated section
  for i = 0,5 do
   map(94,4,0,152 + i*120,20,15)
  end

  --map bottom
  map(94,4,0,872,20,29)
 else
  map(0,16,0,0,24,16)
 end
end

function in_collision(obj, x, y)
 return environment_collision(obj, x, y) or all_object_collision(obj, x, y)
end

function all_object_collision(obj, x, y)
 local temp_obj = {}
 temp_obj.col, temp_obj.x, temp_obj.y = obj.col, x, y

 --player collision
 if obj != player and object_collision(temp_obj, player) then
  return true
 end

 --scarecrow collision
 for scarecrow in all(scarecrows) do
  if obj != scarecrow and object_collision(temp_obj, scarecrow) then
   return true
  end
 end

 --object collision
 for object in all(objects) do
  if object_collision(temp_obj, object) then
   return true
  end
 end

 return false
end

function object_collision(obj1, obj2)
 return obj1.x+obj1.col[1] < obj2.x+obj2.col[2]
    and obj1.x+obj1.col[2] > obj2.x+obj2.col[1]
    and obj2.y+obj2.col[4] > obj1.y+obj1.col[3]
    and obj2.y+obj2.col[3] < obj1.y+obj1.col[4]
end

function environment_collision(entity, x, y)
 local x1, x2, y1, y2 = x + entity.col[1], x + entity.col[2], y + entity.col[3], y + entity.col[4]
 return environment_collision_pixel(x1, y1) or
 environment_collision_pixel(x1, y2) or
 environment_collision_pixel(x2, y1) or
 environment_collision_pixel(x2, y2) or
 x1 < 0 or
 y1 < 0 or
 x2 > map_bounds[active_map][1]*8 + 7 or
 y2 > map_bounds[active_map][2]*8 + 7
end

function environment_collision_pixel(x, y)
 local flags = fget(mget(px_to_map(x, y)))
 return band(flags, 0x1) == 1 or (band(flags, 0x8) ~= 0 and y%8 < 6)
end

function update_camera()
 local min_map_x, min_map_y, max_map_x, max_map_y, x_target, y_target, max_offset, max_vel = 0, 0, map_bounds[active_map][1]*8 - 128, map_bounds[active_map][2]*8 - 114, 0, 0, flr(fright*32), flr(fright*4 + 0.5)

 if player.direction == 0 then
  x_target = -max_offset
 elseif player.direction == 1 then
  x_target = max_offset
 else
  y_target = (player.direction*2 - 5)*max_offset
 end

 if hold_direction then
  x_target, y_target = flr(x_target/2), flr(y_target/2) 
 end

 local x_err, y_err = x_target - cam_offset_x, y_target - cam_offset_y
 if x_err ~= 0 then
  cam_dx = mid(.075*x_err + sgn(x_err)*1, -max_vel, max_vel)
 else
  cam_dx = 0
 end
 if abs(cam_dx) > 0 and abs(cam_dx) < 1 then
  cam_dx = sgn(cam_dx)
 end
 cam_offset_x = flr(mid(cam_offset_x + cam_dx, -max_offset, max_offset) + 0.5)

 if y_err ~= 0 then
  cam_dy = mid(.075*y_err + sgn(y_err), -max_vel, max_vel)
 else
  cam_dy = 0
 end
 if abs(cam_dy) > 0 and abs(cam_dy) < 1 then
  cam_dy = sgn(cam_dy)
 end
 cam_offset_y = flr(mid(cam_offset_y + cam_dy, -max_offset, max_offset) + 0.5)

 cam_x = mid(flr(player.x)-64 + cam_offset_x, min_map_x, max_map_x)
 cam_y = mid(flr(player.y)-61 + cam_offset_y, min_map_y, max_map_y)

 --chop screen shake
 if player.chop_counter > 16 and player.chop_counter <= 24 then
  cam_x += sin(player.chop_counter/8 - 2)
 end
end

function is_stepping_left()
 return player.moving and flr(player.frame) == 0
end

function is_stepping_right()
 return player.moving and flr(player.frame) == 2
end

function dark_palette()
 for i = 0,15 do
  pal(i, dark_color(i))
 end
end

function transition_palette()
 for i = 0,15 do
  pal(i, transition_color(i))
 end
end

function dark_color(i)
 if light_color(i) then
  return 2
 elseif medium_color(i) then
  return 1
 end
 return 0
end

function transition_color(i)
 if light_color(i) or medium_color(i) then
  return 1
 end
 return 0
end

function light_color(i)
 return i == 7 or i == 10 or i == 11 or i == 15
end

function medium_color(i)
 return i == 6 or i == 9 or i == 12 or i == 14
end

function recolor_pixel(i, j)
 pset(i, j, pget(i, j))
end

function draw_flashlight()
 --populate lit map cell edges
 local cells_beam1, cells_beam2 = {}, {}
 for i = beam_bound[1], beam_bound[2] do
  if player.direction <= 1 then
   cx_beam1, cy_beam1, cy_beam2 = px_to_cell(i), px_to_cell(beam1.m*i + beam1.b), px_to_cell(beam2.m*i + beam2.b)
   cx_beam2 = cx_beam1
  else
   cx_beam1, cy_beam1, cx_beam2 = px_to_cell((i - beam1.b)/beam1.m), px_to_cell(i), px_to_cell((i - beam2.b)/beam2.m)
   cy_beam2 = cy_beam1
  end
  if #cells_beam1 == 0 then
   add(cells_beam1, {cx_beam1, cy_beam1})
  else
   if cells_beam1[#cells_beam1][1] ~= cx_beam1 or cells_beam1[#cells_beam1][2] ~= cy_beam1 then
    add(cells_beam1, {cx_beam1, cy_beam1})
   end
  end
  if #cells_beam2 == 0 then
   add(cells_beam2, {cx_beam2, cy_beam2})
  else
   if cells_beam2[#cells_beam2][1] ~= cx_beam2 or cells_beam2[#cells_beam2][2] ~= cy_beam2 then
    add(cells_beam2, {cx_beam2, cy_beam2})
   end
  end
 end

 --fill in center cells
 local cells_center, prev_val = {}, -1
 for cell in all(cells_beam1) do
  if player.direction <= 1 then
   if cell[1] ~= prev_val then
    local y_bound = find_cell_y(cells_beam2, cell[1])
    for i = cell[2] + 1, y_bound - 1 do
     add(cells_center, {cell[1],i})
    end
    prev_val = cell[1]
   end
  else
   if cell[2] ~= prev_val then
    local x_bound = find_cell_x(cells_beam2, cell[2])
    for i = cell[1] + 1, x_bound - 1 do
     add(cells_center, {i,cell[2]})
    end
    prev_val = cell[2]
   end
  end
 end

 --render lit map cells
 foreach(cells_beam1, draw_single_cell)
 foreach(cells_beam2, draw_single_cell)
 foreach(cells_center, draw_single_cell)

 --add shadows
 dark_palette()
 --top beam
 local cells_handled = {}
 shadow_cell(cells_beam1, beam1, player.direction ~= 2, cells_handled)
 shadow_cell(cells_beam2, beam2, player.direction == 3, cells_handled)

 --far edge
 for cell in all(cells_center) do
  if not (contains(cell, cells_beam1) or contains(cell, cells_beam2)) then
   local check_bound, check_cell, start_i, start_j = beam_bound[2], cell[1], cell[1]*8, cell[2]*8
   local end_i, end_j = start_i + 7, start_j + 7
   if player.direction == 1 then
    start_i = check_bound + 1
   elseif player.direction == 0 then
    check_bound = beam_bound[1]
    end_i = check_bound - 1
   elseif player.direction == 2 then
    check_bound = beam_bound[1]
    check_cell = cell[2]
    end_j = check_bound - 1
   else
    check_cell = cell[2]
    start_j = check_bound + 1
   end
   if check_cell == px_to_cell(check_bound) then
    for i = start_i, end_i do
     for j = start_j, end_j do
      recolor_pixel(i, j)
     end
    end
   end
  end
 end
end

function shadow_cell(cells, beam, above, cells_handled)
 for cell in all(cells) do
 local cell_x, cell_y = cell[1], cell[2]
 local start_i, start_j = cell_x*8, cell_y*8
 local end_i, end_j, b1, b2 = start_i + 7, start_j + 7, px_to_cell(beam_bound[1]), px_to_cell(beam_bound[2])

  if player.direction <= 1 and cell_x == b1 then
   if not contains(cell, cells_handled) then
    for i = start_i, beam_bound[1]-1 do
     for j = start_j, end_j do
      recolor_pixel(i, j)
     end
    end
    add(cells_handled, cell)
   end
   start_i = beam_bound[1]
  elseif player.direction > 1 and cell_y == b1 then
   if not contains(cell, cells_handled) then
    for i = start_i, end_i do
     for j = start_j, beam_bound[1]-1 do
      recolor_pixel(i, j)
     end
    end
    add(cells_handled, cell)
   end
   start_j = beam_bound[1]
  end

  if player.direction <= 1 and cell_x == b2 then
   if not contains(cell, cells_handled) then
    for i = beam_bound[2] + 1, end_i do
     for j = start_j, end_j do
      recolor_pixel(i, j)
     end
    end
    add(cells_handled, cell)
   end
   end_i = beam_bound[2]
  elseif player.direction > 1 and cell_y == b2 then
   if not contains(cell, cells_handled) then
    for i = start_i, end_i do
     for j = beam_bound[2] + 1, end_j do
      recolor_pixel(i, j)
     end
    end
    add(cells_handled, cell)
   end
   end_j = beam_bound[2]
  end

  for i = start_i, end_i do
   for j = start_j, end_j do
    local border = beam.m*i + beam.b
    if (above and j <= border) or (not above and j >= border) then
     recolor_pixel(i, j)
    end
   end
  end
 end
end

function contains(cell, cells)
 for c in all(cells) do
  if c[1] == cell[1] and c[2] == cell[2] then
   return true
  end
 end
 return false
end

function find_cell_y(cells, x)
 for cell in all(cells) do
  if cell[1] == x then
   return cell[2]
  end
 end
end

function find_cell_x(cells, y)
 for cell in all(cells) do
  if cell[2] == y then
   return cell[1]
  end
 end
end

function draw_single_cell(cell)
 local mx, my = cell_to_map(cell[1], cell[2])
 map(mx, my, cell[1]*8, cell[2]*8, 1, 1)
end

function draw_darkness()
 for i = cam_x, cam_x + 127 do
  for j = cam_y, cam_y + 127 do
   px_color = pget(i,j)
   if px_color == 10 or px_color == 11 then
    if rnd() > .25 then
     px_color = 2
    else
     px_color = 0
    end
   elseif px_color == 9 or px_color == 6 then
    if rnd() > .25 then
     px_color = 1
    else
     px_color = 0
    end
   else
    px_color = 0
   end
   pset(i,j,px_color)
  end
 end
end

function draw_farmer()
 local n = 9
 if player.direction == 0 then
  n += 3
 elseif player.direction == 1 then
  n += 35
 elseif player.direction == 2 then
  n += 32
 end

 --regular walking
 if player.swing_counter + player.chop_counter == 0 then
  if player.moving then
   if flr(player.frame) == 0 then
    n -= 1
   elseif flr(player.frame) == 2 then
    n += 1
   end
  end

 --adjust for axe swing
 elseif player.chop_counter > 0 then
  n = 167
  if mid_chop() then
   n = 168
  elseif end_chop() then
   n = 170
  elseif player.chop_counter <= 10 then
   n = 44
  end
 else
  n += 119
  if mid_swing() then
   n += 1
   if player.direction == 0 then
    n += 1
   end
  elseif player.swing_counter > 0 and player.swing_counter <= 7 then
   n += 2
   if player.direction < 2 then
    n += 1
   end
  end
 end

 spr(n, player.x - 3, player.y - 15, 1, 2)
 --special case: sideways swing extends to extra sprites
 if player.direction < 2 and mid_swing() then
  if player.direction == 0 then
   spr(n+15, player.x - 11, player.y - 7)
  else
   spr(n+1, player.x + 5, player.y - 15, 1, 2)
  end
 end

 --sepcial case: sideways chop extends to extra sprites
 if mid_chop() then
  spr(169, player.x + 5, player.y - 15, 1, 2)
 elseif end_chop() then
  spr(187, player.x + 5, player.y - 7)
 end
end

function mid_chop()
 return player.chop_counter > 24 and player.chop_counter <= 27
end

function end_chop()
 return player.chop_counter > 10 and player.chop_counter <= 24
end

function mid_swing()
 return player.swing_counter > 7 and player.swing_counter <= 10
end

__gfx__
bbbbbb000bbbbbbbbbbbbb000bbbbbbbbbbbbb0000bbbbbbbbbbbb000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb0dd60bbbbbbbbbbb0dd60bbbbbbbbbbb06dd0bbbbbbbbbbb06dd0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbb0ddd0bbbbbbbbbbb0ddd0bbbbbbbbb0ddd0bbbbbbbbbbb0ddd0bbbbbbbbbbbbbbbbbb00bbbbbbbbbbbbbbbbbbbbbb00bbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb0dd450bbbbbbbbbb0dd450bbbbbbbbb054dd0bbbbbbbbbb054dd0bbbbbbbbb00bbbbb0220bbbbb00bbbbb00bbbbbb0220bbbb00bbbbbbbbbbbbbbbbbbbb
0000005440000000000000544000000000000044500000000000004450000000bb0220bbb022440bbb0220bbb0220bbbb044420bb0220bbbbbb0000bbbbbbbbb
22246d5256dd422222246d5256dd422222246d5256dd422222246d5256dd42220022440b004ff40bb022440b044420bbbb0f440b044420bbbb0d444000bbbbbb
004dd0d56d0dd400004dd0d56d0dd400004dd0d56d0dd400004dd0d56006d400d04ff40bd00f70bbb04ff40bb0f440bbbb07f0bbb0f440bbb0d5222444000bbb
bb0d0dd5dd00d0bbb0d00dd5dd0d00bbbb0d0dd5dd00d0bbb0d00d55dd0d00bb500f70bb5028e20b0b0f70bbb07f0bbbbb08820bb07f0bbb0d000115224440bb
bbb00d125d0b0bbbbb0b0d125d00bbbbbbb00d125d0b0bbbbb0b0d12dd00bbbb402e820b482282805028e20bb01e20bb0002e80bbb0e20bb49f9f0001152d0bb
bbbb0d525d60bbbbbbb0dd5256d0bbbbbbbb0d525d60bbbbbbbb0d5216d0bbbb4e28228040522520522282800548e20b5492820bb008e20b4f11f9f90002d400
bbb0615215d0bbbbbb06d5521d0bbbbbbbb0615215d0bbbbbbb061525d0bbbbb9855202090c550f0402255f0b042820bdaf8850b0502850b11dd1ffff9f40044
bbb0d502510bbbbbb0d05002150bbbbbbbb0d502510bbbbbbb0dd502550bbbbb405d55a050dc1d5a9055d05aba980d0b00010c0baf885d0b555dd1f9fff00b00
bb0d0002050bbbbbbb0b0b0250bbbbbbbb0d0002050bbbbbbbb00002050bbbbb50d1cd0b50c11c0050dc1d00b021cd0bbb01d0bb0001cc0b5515d1499f9f9000
bbb0bb02050bbbbbbbbbbb050bbbbbbbbbb0bb02050bbbbbbbbbbb0250bbbbbb00d11c0b00d11d0b50c11d0bb02cd10bbbb01d0bbb011d0b1555500222244999
bbbbbb0200bbbbbbbbbbbb020bbbbbbbbbbbbb0200bbbbbbbbbbbb020bbbbbbbb0401c0bb040040b00d1040bbb0c010bbb05440bb01001d001500bb000d00444
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb040bbbbbbbbbb040b0bbb044550bbbbbbbbb05500440b00bbbbbb00bb000
bbbbbbb060bbbbbbbbbbbbb060bbbbbbbbbbbbb060bbbbbbbbbbbbb060bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000020bbbbbb
bbbbbb06d0bbbbbbbbbbbb06d0bbbbbbbbbbbb06d0bbbbbbbbbbbb06d0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb099402220bbbbb
bbbbb0dddd0bbbbbbbbbb0dddd0bbbbbbbbbb05dd50bbbbbbbbbb05dd50bbbbbbbbbbbbbbbb00bbbbbbbbbbbbbbbbbbbbbb00bbbbbbbbbbbb0f999400000bbbb
bbbbb054450bbbbbbbbbb054450bbbbbbb00b05dd50b00bbbb00005dd50b00bbbbb00bbbbb0220bbbbb00bbbbbbb00bbbb0220bbbbbb00bbb0ff9f909f9f00bb
00000004400000000000000440000000004d00055000d400004d50055000d400bb0220bbb042220bbb0220bbbbb0220bb024440bbbb0220bb0f9f49099f9f0bb
2244dd5256dd44222244dd525ddd442222225dd256d522222222ddd52dd52222b0422200b0442200b042220bbb024440b044f0bbbb0244400f9f9940499f9f0b
000dd0d5dd0dd0000006d0d56d0dd00000000055dd0000000000005d6d000000b0442205bb022005b044220bbb044f0bbb0f70bbbb044f0b09f994010499f90b
bbb000d55d000bbbbbb000d55d000bbbbbbbb05dd50bbbbbbbbbb05dd50bbbbbbb022005b0288205bb0220b0bbb0f00bb02880bbbbb0f70bb099494049499990
bbbb065215d0bbbbbbbb06521dd0bbbbbbbbb05d1510bbbbbbbb055d1510bbbbb0222202b8222224b0282205bb028050b08e2000bb02e0bbbbbbbb020000bbbb
bbbb0d5255d0bbbbbbbb0d5255d0bbbbbbbb05ddd510bbbbbbb055ddd10bbbbbb2288225b252228202288225b02e2045b0082045b028200bbbbbb00044400bbb
bbbb0d52150bbbbbbbb0d5125d0bbbbbbbb055d5d10bbbbbbb055dd5d10bbbbbb2552202a255550802225028b0082040b0508f05b082045abbbb0044000090bb
bbbbb052510bbbbbbbb00552510bbbbbbbbb00d5d50bbbbbbbb00d55d0bbbbbba85d550405dccd04b055d502b0d088f0b0c040b0b0d0f050bb00d4009f9ff0bb
bbbb055250bbbbbbbb05515250bbbbbbbbbb0d5dd0bbbbbbbbb0dd5dd0bbbbbb05ddcd04b0d11d04b0dcdd04b0cc0040bb0410bbb004100bb0dd001294f9f0bb
bbb0551250bbbbbbbbb000520bbbbbbbbbb0dd12d0bbbbbbbb0dd10d0bbbbbbbb0d11c00b0c11c00b0c11d04b0d11040b0d10bbbb040c0bb055d0110499f9f0b
bbbb00020bbbbbbbbbbbbb020bbbbbbbbb0d00020bbbbbbbbbb000020bbbbbbbb0401c0bb040040bb0c104000d10010bb04450bbb010d0bbb055d0210499f90b
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb040bbbbbbbbbb040bbbb04400550bbbbbbbbb055440bbb0d022044499990
5444d5555444d53b9335b3439335b3439335b3435441f1555441f15500000080000000080000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
4445554444455133393339333933393339333933441f4144441f414400008800000000000008000000008000bbbbbbbbbbbb0bbbbbbbbbbbbbbbbbbbbbbbbbbb
5554444d5554533333b135531351355313513333552f414d112f414d00089980000080000008800000089800bbbbb000bbbbb01bbbbbbb00bbbbbbbb00b11bbb
55444455554445b39435545555445455554451b3552f4112442f41550008a80000089800000980000089a800bbbbbbb0bb0bbbb001bbb1b000b11bbbbb0b01bb
445d4445445d5b34335d4445445d4445445d4b34442911241129114500055000000150000005500000055000b00bbbbbbbb0bbbbb00b10bbbb0bb0bbbbb0bb0b
4555555445554133b33555544555555445555533452121114521215400024000000240000004400000024000bbb0bbbbbb101bbbbb001bbbbbb0bb0bbbbb0bbb
4445544444444535343554444445544444455135441421444414214400124100001241000012410000124100bb0011bbbb0b001bbbb110bb0bbb0bbb00bbb0bb
5d4444555d445343331444555d4444555d4443435d1411555d14115500011000000110000001100000011000000b0000b00bb0000bb10000b0bbb0bbbbbbbbbb
9335b3339354d5559314d5555444d5555444d53b5411f1555411f155b00000bbbbbbbbbb93111133bbbbbbbbb0bbbbb0b0bbbbb000b00bbbbbb0bbbbbbbbbbbb
3933345339545544395445444454454444545133441f4144441f414406ddd60bbbb0000b31499413bbbbbbbbbbbbbb0bbbbbbb0bb0001b1bbb0bb110bb00bbbb
3333953933b5444d33b5444d4555444d45555333552f414d112f414d0711160bb0066760319f4519bbb000bbbbbbbb0bbbb001bbbb000001111000bb10bbb1bb
94533393943544559431454554444545544445b3552f4112442f415506776d0b0d6670d093115213bb0dd50bbbbb01bbb0000000b0b10bb0bbb0bbbbb110000b
33453533331d4445335d55545554555455545b34442f4124112f41450666dd0b0dd670d131454441b05dd6d0bb1000000bbb0bb00b010b0bbbbb001bbbb0bbb0
b3333354b3355554b33b51b5b95b51b5b91b41334529411145294154b16dd11105dd60d1224442540555dd5000bb0bbbbbb00bbb01b000bbbbbbbbb0bbbb01bb
34349333343554443433933b3433933b3433933b4429414444294144b1dd51110115dd511452442104415541bb00bbbbbb00bbbbb00000bbbbbbbbbbbbbbbb0b
33493343331444553349334333493343334933435d1221555d122155b011111bb111111145211543bbb4414bb0bbbbbbbbbbbbbbb0000bbbbbbbbbbbbbbbbbb0
4444d4445444d4555544d44444444444444444d4444d44445411f155bbbbbbbbbbbbbbbbbbbbbbbbb0000bbbbbbb00bbbbbbb4bbbb000bbbbb000bbb91225333
54455554444555444554554444d4444494d444449444444d441f4144bbbbbbbbbbbbbbbbbbbbbbbb055d50bbbb005d0bbbbbb4bbbb000bb1bb000bbb15421453
4555945d545559949455455d444494559144941591449454552f414dbbbbbbbbbbbbbbbbbbbbbbbb5505d50bb05d6d50bbbbb14bbb000b1bbb000bb114522539
5554494555554433441555554454a1b13b5da1b13b54a1b5552f4155bbbbbbbbbbbbbbbbbbbbbbbb50600d0bb0d6dd50bb4b5b4bbb00001bbb00001b91442193
5512434555514b94941d555545b1b351b1b10351b0b1b31b44291145bbbb00bbbbbb00bbbbbbbbbb0dddd00bb0ddd1d0bb141b44bb00010bbb00010b31442133
555142355555b2244155595544133113355331133553315445212154bbb11bbbbb111bbbbb11100b05d5dd50b05d5110bbb14b41bb0001bbbb0001bbb1444254
555511b5b35b311215334495445133b1315133b1315133b444142144bb110bbbbbb00bbbbbb00b0b055555d005551110bbbb141bbb0000bbbb0000bb34145423
3b49333bd5355351535594414d19351b3311351b331931545d141155bbb0bbbbbbb0bbbbbbb0bbbb4111144401511244b4bbb4bbbb0000bbbb0000bb33144213
3354d1355535bb35b55524214453b1a1315931a1315331a45441f155bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb14b544b93144133bbbbbbbb93144423
5b555515555355533b555215445139313513393135113935441f4144bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb14411b39124133bbbbbbbb39314425
5399455d594242513135555d45b5b31391b1b31391b1b314112f414dbbbbbbbbbbbbbbbbbbbbbbbbbbbbb44bbbbbbbbbbb141bbb33144139bbbbbbbb33314421
5344945599444425155b5555531331513313315133133154442f4112b111bbbbbbbbbbbbbbbbbbbb22bbb1144bbbbb44bb42bbbb93144413bbbbbbbb94515442
524444159449442155539455455135133151351331513315112f4124bb111bbbb1111bbbbbbbbbbb112bbb41144b2b11bb421bbb31454441bbbbbbbb33414942
5524215559494215545d42154455315131553151315531b545294111bbb111bbbb11110bbb11111bbb1b421bb14442bbb4f91bbb22444254bbbbbbbbb3319f94
45511554551111554455115444513155554131d54551315544294144bbb0000bbbb00bbbb1111bbbbbbb11bb4b111442b111bbbb14524421bbbbbbbb343419f9
4d4544444d4554444d445544d445555444555554544555545d122155bb0bbbbbbb0bbbbbbbbbbbbb4bbbbbbb1bbb4111bbbbbbbb45211543bbbbbbbb33493112
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb931441339335b3339335b3339335b3335411f1555411f155
bbbbbbbbbbbbbbbbbbbbbbbbbb00bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000000b39124133393334533933345339333453441f4144441f4144
0bb00bbbbbbbbbbbbbbbbbbbb0d50bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb051151503314414d3333953953339539533395395501114d5501114d
d00220bbbbb00bbbbbb00b0bbb0220bbbbbbbbbbbbb00bbbbb000bbbbbbbbbbbbbbbbbbb0d555dd0931444153353315155441393535333935501411255014112
5022440bbb0220bbbb0220d0b044420bbbbbbbbbbb0220bbb02000bbbbbbbbbbbbbbbbbbd55d556d3145444114334445445d4433333b35334401412444014124
204ff40bb044220bb0442255002f440bbbbbbbbbb044420bb000450bbbbbbbbbbbbbbbbb56d55d55224442544515555445555554433533544501411145012111
200f70bbb04ff40bb04ff404040ff0bbbbbbbbbbbb0f440b0044550bbbbbbbbbbbbbbbbb10000001145244214445544444455443344553334401214444012414
4022e80bbb0f70bbbb0f70044e82880bbbbbbb0b0007f0bb440000bbbbbbbbbbbbbbbbbbb22bb22b452115455d4444555d4441551d4441535d0141555d011215
f82e820bb002280bb082204000e8820bbbbbb0500202280ba20280bbbbbbbbbbbbbbbbbbb425524b9335b3315444d5555444d5335444d5555551115555551221
9e88000bb040800bb0288ef0b002220bbbbb05444fe8880bb08e80bbbbbbbbbbbbbbbbbb041001403933444d44455544444555533b1555444551d15545555115
4000550bb00f00bbb0000090bbb0550bbbbb0d500502820bbb0220bbbbbbbbbbbbbbbbbb016676d0333444555554441d551444399333141d5551515d5555555d
00dc1d0bb0004000b05d5040bb01dc0bbbbbb00bbbb0550bbb0550bbbbbbbbbbbbbbbbbb01dd6dd0945d1b45511b3b93945b3393345333935551115555555155
b0c11c0bb010040db0d1cd0bbb01c0bbbbbbbbbbbbb1cd0bbb0cd00bbbbbbbbbbbbbbbbb05dddd50334535333345b533334535333345353344514155445d5555
b0d11d0bb0d10dd0b0d11c0bbbb01d0bbbbbbbbbbb0cd10bb0cd1100bbbbbbbbbbbbbbbb055ddd50b3333354b3333354b3333354b33333544551215445555515
b040040bb040100bb0401c0bbb05440bbbbbbbbbbb0c0010b0c00150bbbbbbbbbbbbbbbb015555503434933334349333343493333434933355514154555551d1
bbbbbbbbbbbb040bbbbb040bbbbbbbbbbbbbbbbbb04405500440050bbbbbbbbbbbbbbbbbb011510b334933433349334333493343334933435d4111555d451111
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb9335b3333102411200611d1354114121
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0dd0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb39333453312018503071061344191114
bbb00bb0bbbbbbbb00b00bbbbbb000bbbbbbbbbbbbbbbbbbbbbbbbbbb05400bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33339539330280093077760b5529411d
bb022005bb000bbb500220bbbb00dd0bbbb00bbbbbbbbbbbbbb000bbbb0040bbbbb00bbbbbbbbbbbbbbb00bbbbbbbbbb945333939450039390666d03552f4112
b0422205b00220bb5502240bb005400bbb0220bbbbbbbbbbbb00220bb0020f0bbb0220bbbbbbbbbbbbb0220bbbbbbbbb334535333345353330d6d513442f4124
b0442204b022240b4004440bb020040bb024440bd0bbbbbbb0024400b0240e40b024440bbb0bbbbbbb024420bbbbbbbbb3333300b3333354b11d511445294111
bb022004b0020020000220bbbb0f00f0b044f0bb0d0bbbbbbb044f40bb0f280bb044f0bbb050bbbbbb044f0bbbbbbbbb34340051343493333311113344294144
b028820eb22882202028820bb0882e04bb0f7000450bbbbbbbb0ff04b02880bbbb0f70b004450bbbbbb0ff0bbbbbbbbb3300510133493343334933435d122155
b02222280282220b0282220bb0288200b08820f4000bbbbbbb082080b02220bbb0882004400d0bbbbb0220bbbbbbbbbb005100019335b3339335b3339335b333
b05222840255220b0025520bb022e00bb028ee00bbbbbbbbbb028e0bb0220bbbb028eef00bb00bbbbb02820bbbbbbbbb51000001393334531011001010110033
b0555500b05d550bb05dd50bb0550bbbb02220bbbbbbbbbbbb0220bbb0550bbbb022200bbbbbbbbbbb020e000bbbbbbb0000005033339530555555555555550b
b0dccd0bb0ddcd0bb0d1cd0bb0cd10bbb0550bbbbbbbbbbbbb0550bbb0cd10bbb0550bbbbbbbbbbbbb0550f44000bbbb0000d511945333055555555555555503
b0d11d0bb0d11c0bb0d11c0bbb0c10bbb0cc10bbbbbbbbbbb0cd10bbbb0c10bbb0cc10bbbbbbbbbbb0cd100004450bbb006d55113345305555d555d555d55503
b0c11c0bb0401c0bb040140bb0d10bbbb0d110bbbbbbbbbb00d1110bb0d10bbbb0d110bbbbbbbbbb00d1110bb0550bbb6d555111b3333055dd555555dd55dd50
b040040bbbbb040bbbbb020bb04450bb0d10010bbbbbbbbb0410010bb04450bb0d10010bbbbbbbbb0410010bb0d0bbbb055110003434905555dd55d5551155d0
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb04400550bbbbbbbbb0400550bbbbbbbb04400550bbbbbbbbb0400550bbbbbbbb3010002033493055d555dd55dd55dd55
9335b0555555555d19f5d5dd5d55df905111111155dd55dd55dd55dd55dd555555dd55dd55dd55dd55d55551155555dd55dd55d50335b3339335b3339335b333
3933305555555dd1977719911991777901111111dd55dd55dd551155d555dd555555dd55dd55dd55dd555d55dd55dd555555dd55093334533933345339333453
3333905555555d19ffff19a11991ffff90511151555d55d5555115d555dd15dd55dd55d555dd55dd55dd55dd55dd555555d555dd53339539333395300333953b
9453305555555197777719911a91777779011111d555dd555d55dd55dd55d5555155dd555d5555155d555555dd55dd55dd551d55d05333939453330550533393
33453055555d1977777719a119a1777777905511551d55dd55dd55dd55dd55d555dd555d55dd555d55dd55dd55dd55dd555d55dd504535333345305511053533
b333305555519fffffff1a911a91fffffff90511dd55dd55dd55dd55dd55dd55dd555115dd55dd55d555d155555111555d55d551dd333354b333055511103354
343490555d197777777719a11aa177777777905155d55551555155dd555d55dd55dd555d555d55dd55dd55dd55dd51dd55dd55d5550493333430555511110333
33493055d197777777771aa11a91777777777901dd55dd55dd551555555551155d55dd55dd551d55dd55d555dd55dd55dd55dd55d50933433305555511511043
9335b05519fffffffffd55ddd55d5fffffffff9051dd55dd55dd55d555dd511155dd55dd55d555dd555d55dd55dd55dd511155dd5153b3339055555511111103
393330d1977777777777777777777777777777795555555555555555555555555555555555555555555555555555555555555555555034530555555511111110
33339019fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff195395555555511111111
945331555ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd5533935555555551115111
33453533159999955999999999999995599999999999999514444445544444444444444554444444444444415999999999999999951335335555555511111111
b33333541d9ffff5d9ffffff99fffff5d9ff99fffff9ff9519999995d901111011100195d999999999999991d999fffff9f9fff9951333545555555511111111
343493331df77775df77777777777775df7777777777777519f9f995d9517fff7fff15f5d99fff9999f9ff91df77777777777777751493335555555511111111
334933431df77775df55555555555575df777777777777751f777775df5f11111111f575df77777777777771df77777777777777751933435555555511511151
9335b3331dfffff5df517fff7fff15f5dffffffffffffff51ffffff5df1f12222221f1f5dfff00111100fff1dffffffffffffffff515b3335555555511111111
393334531df77775df5f11111111f575df777777777777751f777775dfdf12222221fd75df70009a99000771df7777777777777775133453555555d105111111
333395391dfffff5df1f12222221f1f5dff0011111100ff51f777775dfd7122422217d75df70009aa9000771dfff0011111100fff51395395555dd1990111111
945333931df77775dfdf12222221fd75df000a91199000751ffffff5dfdf124424217df5dff0009aa9000ff1df7000aa11990007751333935555519779055111
334535331df77775dfd7122422217d75df0009a11a9000751f777775dfd712449421fd75df70009aaa000771df70009911a9000775153533555d197777905111
b33333531dfffff5dfdf124424217df5df0009911aa000f51f777775dfdf124440417d75df70009aa9000771dff0009a11aa000ff513335455519ffffff90111
343493001df77775dfd712494421fd75df000aa11a9000751ffffff5dfd7144440417df5dff00099a9000ff1df7000aa11a90007751493335519777777779011
334300511df77775dfdf142440417d75df0009a119a000751f777775dfd7124444417d75df70001111000771df700099119a0007751933435197777777777901
9300d5001dfffff5dfd7144440417df5df000991199000f51ffffff5dfd712444241fdf5dffffffffffffff1dff0009a1199000ff515b333933551511555b333
00d511511df77775dfd7129444417d75df000111111000751f777775dfd7124442417d75df77777777777771df70001111110007751334533931515515531453
d511d5001dfffff5dfd712444491fdf5dffffffffffffff51ffffff5dfdf14494441fdf5dffffffffffffff1dffffffffffffffff51395393331131551151539
116d10111df77775dfd7124444417d75df777777777777751ffffff5dfdf14444221fdf5dffffffffffffff1df77777777777777751333939451555145551393
6d1155111dfffff5dfdf14444441fdf5dffffffffffffff51ffffff5dfdf12442221fdf5dffffffffffffff1dffffffffffffffff51535333343551551553533
115551501dfffff5dfdf14444421fdf5dffffffffffffff51333333013115551515551301333333333333331dffffffffffffffff5133354b333115551513354
111100001d1111f5dfdf12444421fdf5dffffffffffffff51334933393355515551153333434933b34349331dffffffffffffffff51493333434551314149333
3311122100d55d10133333333333333013333333333333333349334333b1151551551b3933493343334933401333333333333333300933433349154533493343
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101000000000000000000000000000001010000050000000000000101010101010100000000000000000501010101010101000000000000030005
0000000000000000000003000000010100000000000000000000000000000100000000000000000000000000000001010000000000000000000000000100040400000000000404040404040404000000000000000004040404040400040000000001000000000000000000000100000001010101010108080808080101000000
__map__
7d5050505050507d5050505050505050505160616240606162406061624151419c505050505050505050505050505050505050505050516673747474747474756641505141505050505050505050505050505050507d50505050505050505050505051415050507d5050505050505050504500000000000040405340408c5052
505050507d5050505050507d5050505050517071724070717240707172415141505050508d8a8c50505050505050507d5050505050505166404040404040404066415051415050505050505050507d50505050505050505050505050505050505050514150507d5050505050507d50505066000000000000529c509d9b9d5050
59505050505050508d8a8d5050505050505160616240606162406061624151415050509a9b9b9c5050507d50505050505050505050505166636464646464646566415051415050505042434343434343434343434343434344507d5050505043434340404343437d505050505050505050660000000000005050505050508a8d
507d505042446f509d9c9c505050507d50517071724070717240707172415141505050504243434343434343434343434343434344505166737474747474747566415051415050505051457676767676767676767676764641505050505050457656404055764650507d50505050505050660000000000005050505050509d9c
8d50595051417f505050505050505050505253535353535353535353535451415050507d5145767676767676767676767676764641505166636464646464646566415051415050505051664040404040404040404040406641505050505050664040404040406650505050505050505950660000000000005050505050505050
9c6f6f5052545059505050507d505050505050505050505050505050505051415050505051454040404040404040404040404066415051667374747474747475664150514150505050516663646464654040636464646566415050505050506663646464646566505050508a8d505050506600000000000050507d5050505050
597f7f42434343434343434450504243434343434343434343434343434340405050505051666061624040606162404060616266415051666364646464646465664150514150505050516673747474754040737474747566415050505050506673747474747566505050509d9c5050508a660000000000005050505050505050
5050505140404040404040404343404040404040404040404040404040404040507d505051667071724040707172404070717266417d51667374747474747475664150514150505050516663646464654040636464646566415050505050506663646464646566508a8b8d507d5050509d660000000000005050505050505050
505050525353535353534040404040405353535353535353535353535353535350505050516640404040404040404040404040664150515576767676764040406641505141505050505166737474747540407374747475664150505050505066737474747475668a40419d5050508a8c50660000000000005050505050595050
508a8c5050505050505052535353535450505050505050507d5050505050505050505050516640406061624040606161624040664150525353535353536464656641505141505050505166404040404040404040404040664150505050505066636464646465669c9b9c5050509a9b9c50660000000000005050505050505050
9a9b9c505050505050505050505050505050505050505050505050505050507d44505042555640407071724040707171724040555644505050507d50507474756641505141505050505166636464646540406364646465664150505050505066737474747475665050507d505050505050660000000000004343434343434343
8c5050505050595050505050505050505050508a8b8c505050505050505050504043434040404040404040404040404040404040404043434343434343646465664150514150505050516673747474754040737474747566415050508a8d50664040404040406650505050505050507d50660000000000004040404040404040
9c505950505050505050505050507d505059509d9b9c50505050507d5050505053535340404040404040404040404040404040404040535353535353537474756641505141505050505166636464646540406364646465664150509a9b9c50666364646464656650505950505050505050660000000000005353535353535353
7d505050507d50505050505050505050505050505050505050505050505050505050505255464040606161624040606162404045565450507d505050506464656641505141505042438e567374747475404073747474756641505050505050667374747474756650505050508a8b8c5950660000000000005050505050505050
507d50505050505050505950505050507d505050508a8d50505050505050507d5050505051664040707171724040707172404066417d505050505050507474756641505140434340409e4040404040404040404040404066415050505050506663646464646566505050508a40419d507d660000000000005050505050505050
8c8b8d8a8b8c507d50508b8c8d7d8b8c50508d509a9b9c508d8c7d8c8b8d505050507d505166404040404040404040404040406641505050508a8c50504040406641505140535353535546636464646540406364646465664150505050507d66737474747475665050509a9c9b9c505050660000000000005050595050505050
8c5050505050505050505050505050509a9c509a9b9b9c9b00000000000000005050505051666061624040606162404060616266415050509a9b9c505064646566415051415050505051667374747475404073747474756641507d5050505066636464646465668a8d505050507d505050660000000000005050505050505050
9c8a8c50505950cecf507d50505050505050508a8c50505000000000000000005050505051667071724040707172404070717266417d505050505050507474756641505141505050505166636464646540406364646465664150505050505066737474747475669b9c507d505050505050660000000000005050505050505050
8a40548a8c50cededfcf50505050507d50509a9b9c50595000000000000000007d50505051664040404040404040404040404066415050505050505950646465664150514150505050516673747474754040737474747555564343434343506640404040404066507d5050505050505050660000000000007d50505050505050
9b9c9a9b9cbddeeeefdfbebebebebebebebf5050505050500000000000000000505050505155767676767676767676767676765641505050505050505074747566415051415050505051664040404040404040404040404040404053535350557656404055765650505050505050505050660000000000005050508a8c505050
5050505950c0c1c2c3c4c5c6c7c8c9cacbcccd506f7d5050000000000000000050505950525353535353535353535353535353535450507d50505050506464656641505141505050505166636464646540406364646465455653545050505053535340405353535050505050505050508a6600000000000050509a9c9d505050
6f59505050d0d1d2d3d4d5d6d7d8d9dadbdcdd507f50596f00000000000000005050505050507d5050505050505050507d505050505050505050505050747475664150514150505050516673747474754040737474747566415050505050505050505141505050505050507d5050505050660000000000005050505050507d50
7f50505050e0e1e2e3e4e5e6e7e8e9eaebeced6f4243447f0000000000000000505050505050505050505050507d505050505050505050508b8c8a8c8b76767656415051415050505051666364646465404063646464656641507d5050505050505051415050505050505050505050595066000000000000507d505050505050
7d50505050f0f1f2f3f4f5f6f7f8f9fafbfcfd7f514041500000000000000000507d505050505050507d505050505050505050507d505042404040409b535353535450514150505050516673747474754040737474747566415050505050505050505141505050508b8a8d505050505050660000000000008c508b8c8a8b8b43
5050505050adae5050505050feff50505050505051404044000000000000000042434343434344000000000000000000000000000000000000000000005050505050505141505050505166404040404040404040404040664150505059505050505051415050509a9b9b9c507d50505050660000000000000000000000000000
505050505050505050505050505050505050505051404041000000000000000051457676764641000000000000000000000000000000000000000000004343434343434041505050505155767676767676767676767676564150505050504343434340415050505050505050505050508a660000000000000000000000000000
505950505050505050505050505050505050505052535354000000000000000051664040406641000000000000000000000000000000000000000000005353535353535354505050505253535353535353535353535353535450505050505353535353545050505050507d505050505050660000000000000000000000000000
505050505050505050505050505050505050505050505050000000000000000051664040406641000000000000000000000000000000000000000000005050505050505050505050507d5050505050507d505050505050507d50507d505050505050505050505050505050505050505050660000000000000000000000000000
505050505050505050505050505050505050505050505050000000000000000051557676765641000000000000000000000000000000000000000000005050507d5050505050505050507d505050505050505050507d505050505050507d5050505050505050507d50505050507d505050660000000000000000000000000000
5050504244505050505050505050505050505050507d50500000000000000000525353535353540000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7d50505141505050505050505050505050504243434343430000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
505050514150507d505050505050505050505140404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00010000136201362013630136301363013640136401364010640106301063010630106201e6201e6101e6101c6101b6101a61019610186101761015610146101361011610106100f6100d6100c6100b61009610
00020000396303961039620396103962039610396203962039630396203963039620396303965039630396403963039640396503964039630396300e7300d7300c7500a7500a7500875008740067400573004730
010200000312007140021200111005100051000810003100071000311007140081700514003130021200111001110011000110001100011000110001100011000110001100011000110001100011000110001100
000200001d6701e6601d6501c6501a64021640176301f630136301b6200e620166200962011610066100561004610036100000000000000000000000000000000000000000000000000000000000000000000000
000200001d6701e6601d6501c6501a64021640176301f63013630136201f6601d640186301e6200d660166400b6300a6201162008610066100461003610026100360002600016000560005600036000160001600
00010000156201562015630156301663017640186401a6401b6401c6301d6301e6301f62020620216202261023610246102561026610266102661026610146001360011600106000f6000d6000c6000b60009600
000100002827024270282702426028260242502825024240282302422028220242202822024220282202422028220242202722023220262202222025210212102421021210242102121024210212102421021210
000200001761017620176201763018630186401864018630186201861018610186101862018620186301862018620186101861017600176001761017610176101762017620176101661016610176101760017600
000200000311007120021100111005100051000810003100071000311007120081300512003120021100111001100011000110001100011000110001100011000110001100011000110001100011000110001100
000200000314007160021300111005100051000810003100071000312007150081700515003130021200111001110011000110001100011000110001100011000110001100011000110001100011000110001100
000200003c6203c6303c6403c5703c5603c6403c6303c6203b61039610386103a6003960037600356000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
000200002f630316403c5603c560336402d640266301f63013630136201f6701d660186501e64016630166300f6200a6200962008610066100461003610026100360002600016000560005600036000160001600
0003000028630296202a6102b6102c6102d6202d6302d6202d6100050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
000300000967009670096500964009630096200962009610086100860007600076000760006600056000660000600006000060000600006000060000600006000060000600006000060000600006000060000600
000300001c6301a6401b6102f6402e610006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
000300002f6302e6102d6102d6102d6302b6102b6102b6002d6002d6202d6102b6102a61027620276102761026600006000060000600006000060000600006000060000600006000060000600006000060000600
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344

