-- Valley Pong 
-- Author: Shirish Sarkar

-----------------------
-- GLOBAL VARIABLES --
-----------------------

-- Player with momentum
player = {
  x = 2,
  y = 64,
  speed = 3.5,   -- how quickly velocity changes with up/down
  vel = 0,     -- current velocity
  friction = 0.4
}

-- AI settings
ai = {
  x = 125,
  y = 64,
  speed = 4,
  difficulty = 0.5
}

-- Main ball
ball = {
  x = 64,
  y = 64,
  dx = 2,
  dy = 0,
  gravity = 0.01
}

ball_trail = {}

-- Keep track of how many times the ball has bounced off a paddle:
rally_count = 0
start_speed = 2.25

score = 0

--------------------------
-- POWERUP STATES
--------------------------
spawn_bubble_chance = 0.75
powerup_active = false
powerup_type   = 0  -- 1=3 extra balls, 2=×2 score
powerup_timer  = 0  -- frames until powerup expires

--------------------------
-- EXTRA BALLS (POWERUP #1)
--------------------------
extra_balls = {}

--------------------------
-- BUBBLE SPAWNER
--------------------------
bubble = {
  active      = false,
  x           = 64,
  y           = 64,
  life        = 0,
  spr         = 1,  -- bubble is sprite #1
  powerup_spr = 0   -- which powerup inside? sprite #2 or #3
}

-- After your score passes next_powerup_score,
-- we do a 25% chance to spawn the bubble
next_powerup_score = 1

--------------------------
-- SCORING MULTIPLIER  --
--------------------------
function base_score_multiplier()
  -- 0–49 => 1×, 50–99 => 2×, up to 10×
  local mult = 1 + flr(score / 50)
  return min(mult, 10)
end

-- If the x2 powerup is active, we double the base multiplier
function total_score_multiplier()
  local base_mult = base_score_multiplier()
  if powerup_active and powerup_type == 2 then
    return base_mult * 2
  end
  return base_mult
end

--------------------------
-- PARALLAX BACKGROUND --
--------------------------
bg_layer1 = {}
bg_layer2 = {}
num_shapes_layer1 = 20
num_shapes_layer2 = 15

-----------------------
-- GAME STATE SYSTEM --
-----------------------
-- 0 = start menu
-- 1 = playing
-- 2 = game over
game_state = 0

serving = false
serve_timer = 0

-----------------------
-- INITIALIZATION    --
-----------------------
function _init()
  cls()
  init_background()
  game_state = 0
  music(1)
end

-----------------------
-- UPDATE FUNCTION  --
-----------------------
function _update()
  local game_state_pico = 0
  if game_state == 0 then
    update_background()
    if btnp(5) then
      game_state = 1
      start_serve()
    end

  elseif game_state == 1 then
    update_background()
    update_player()
    update_ai()

    if serving then
      update_serve()
    else
      update_ball()
      update_extra_balls() 
      update_bubble()   
    end

    update_powerup()
    update_trail()
    maybe_spawn_bubble()

  elseif game_state == 2 then
    game_state_pico = 1
    update_background()
    if btnp(5) then
      reset_game()
      game_state = 0
    end
  end

  -- GAME STATE AND SCORE STORAGE
  poke4(0x5f80, score)
  poke2(0x5f84, game_state_pico)
end

-----------------------
-- DRAW FUNCTION    --
-----------------------
function _draw()
  cls()

  if game_state == 0 then
    draw_background()
    --print_centered("space paddle", 36, 7)
    wave_print("s p a c e p a d d l e", 22, 36)
    print_centered("ARROWS TO MOVE", 56, 6)
    print_centered("PRESS X TO START", 66, 6)
    print_centered("VALLEY STUDIOS", 96, 7)
    print_centered("V0.2", 106, 6)

  elseif game_state == 1 then
    draw_background()
    draw_field()
    draw_paddles()
    draw_ball_trail()
    draw_ball()
    draw_extra_balls()
    draw_bubble()
    draw_score()

    if serving then
      draw_serve_message()
    end

  elseif game_state == 2 then
    draw_background()
    print_centered("GAME OVER", 50, 7)
    print_centered("SCORE: "..score, 60, 6)
    print_centered("PRESS X TO RESTART", 70, 6)
  end
end

-------------------------------------
-- WAVE TYPING. --
-------------------------------------

function wave_print(text, x, y)
  -- how strongly letters wave
  local amplitude = 2.5
  -- how quickly letters move
  local speed = 1

  for i=1,#text do
    local letter = sub(text, i, i)
    local t = time() * speed + i * 0.1
    -- wave offset: move the letter up/down with sine
    local wave_offset = sin(t) * amplitude

    -- color cycling: pick a color based on (time + i)
    local col = 10 + flr((sin(t * 0.5) + 1) * 2)
    -- clamp col to a valid range 7..13 or do a quick wrap:
    if col > 15 then col = 15 end

    -- Print the letter with wave offset
    print(letter, x + (i-1)*4, y + wave_offset, col)
  end
end


-------------------------------------
-- UPDATE HELPERS: PLAYER, AI, BALL --
-------------------------------------

-- Player momentum
function update_player()
  local up = btn(0) or btn(2)
  local down = btn(1) or btn(3)

  if up then
    player.vel = -player.speed
  elseif down then
    player.vel = player.speed
  else
    -- drift / friction
    player.vel *= player.friction
  end

  player.y += player.vel
  player.y = mid(0, player.y, 120)
end

function update_ai()
  local ai_target_y = ball.y - 4
  ai.y += (ai_target_y - ai.y)*ai.difficulty
  ai.y = mid(0, ai.y, 120)
end

function update_ball()
  -- Gravity
  ball.dy += ball.gravity
  ball.x += ball.dx
  ball.y += ball.dy

  -- top/bottom bounce
  if ball.y < 0 then
    ball.y = 0
    ball.dy = -ball.dy*0.95
    sfx(4)
  elseif ball.y>127 then
    ball.y = 127
    ball.dy = -ball.dy*0.95
    sfx(4)
  end

  -- Player side
  if ball.x < player.x+2 then
    if is_colliding_with_paddle(player) then
      sfx(0)
      bounce_off_paddle(player)
      rally_count += 1
      scale_ball_speed()

      local mult = total_score_multiplier()
      score += mult
      check_score_for_bubble()

    elseif ball.x < -8 then
      music(2)
      game_state = 2
    end
  end

  -- AI side
  if ball.x+2>ai.x then
    if is_colliding_with_paddle(ai) then
      sfx(1)
      bounce_off_paddle(ai)
      rally_count += 1
      scale_ball_speed()
    elseif ball.x>136 then
      sfx(3)
      local mult = total_score_multiplier()
      score += 3*mult
      rally_count=0
      check_score_for_bubble()
      start_serve()
    end
  end

  add(ball_trail, { x=ball.x, y=ball.y, life=10 })
end

-----------------------------------------
-- COLLISION & BOUNCE HELPER FUNCTIONS --
-----------------------------------------
function is_colliding_with_paddle(pad)
  return (
    (ball.x+2>pad.x) and
    (ball.x<pad.x+2) and
    (ball.y+2>pad.y) and
    (ball.y<pad.y+12)
  )
end

function bounce_off_paddle(paddle)
  ball.dx = -ball.dx

  if paddle==player then
    local pad_mid = paddle.y+6
    local offset = (ball.y - pad_mid)/6
    ball.dy = (offset*3)+(0.3*ball.dy)
    ball.x=player.x+3
  else
    local player_mid = player.y+6
    if player_mid<64 then
      ball.dy=abs(ball.dy)+rnd(0.5)
    else
      ball.dy=-abs(ball.dy)-rnd(0.5)
    end
    ball.x=ai.x-3
  end
end

function scale_ball_speed()
  local factor=1+(4*rally_count/100)
  if factor>5 then factor=5 end

  local old_spd=sqrt(ball.dx^2 + ball.dy^2)
  if old_spd>0 then
    local new_spd=start_speed*factor
    local sc=new_spd/old_spd
    ball.dx*=sc
    ball.dy*=sc
  end
end

---------------------------------
-- SERVE ("SERVE IT UP!") LOGIC --
---------------------------------
function start_serve()
  reset_ball()
  serving=true
  serve_timer=90
end

function update_serve()
  serve_timer-=1
  if serve_timer<=0 then
    serving=false
  end
end

function draw_serve_message()
  local t=flr(time()*30)
  local color=(t%30<15) and 10 or 9
  --print_centered("SERVE IT UP!", 50, color)
  wave_print("serve it up!", 42, 50)
end

---------------------------------
-- GAME RESET/INIT FUNCTIONS  --
---------------------------------
function reset_ball()
  ball.x=64
  ball.y=64
  ball.dx=2
  ball.dy=0
end

function reset_game()
  reset_ball()
  ai.difficulty=0.25
  ai.speed=1

  score=0
  serving=false
  serve_timer=0
  rally_count=0
  player.vel=0

  extra_balls={}
  bubble.active=false
  powerup_active=false
  powerup_type=0
  powerup_timer=0
  next_powerup_score=10

  ball_trail={}

  music(1)
end

----------------------
-- TRAIL MANAGEMENT --
----------------------
function update_trail()
  for i=#ball_trail,1,-1 do
    local p=ball_trail[i]
    p.life-=1
    if p.life<=0 then
      del(ball_trail, p)
    end
  end
end

function draw_ball_trail()
  for i=1,#ball_trail do
    local p=ball_trail[i]
    local c=7
    if p.life<=6 then c=6 end
    if p.life<=3 then c=5 end
    rectfill(p.x, p.y, p.x+1, p.y+1, c)
  end
end

------------------------------
-- EXTRA BALLS (POWERUP#1) --
------------------------------
function update_extra_balls()
  for i=#extra_balls,1,-1 do
    local eb=extra_balls[i]
    eb.dy+=ball.gravity
    eb.x+=eb.dx
    eb.y+=eb.dy
    eb.life-=1

    -- top/bottom bounce
    if eb.y<0 then
      eb.y=0
      eb.dy=-eb.dy*0.95
    elseif eb.y>127 then
      eb.y=127
      eb.dy=-eb.dy*0.95
    end

    -- remove if time gone
    if eb.life<=0 then
      del(extra_balls, eb)
    else
      -- collision with player's paddle => +1 ×mult
      if eb.x<player.x+2 then
        if (eb.x+2>player.x and eb.x<player.x+2 and eb.y+2>player.y and eb.y<player.y+12) then
          sfx(0)
          eb.dx=-eb.dx
          eb.dy=(eb.dy*0.9)+rnd(0.2)
          local mult=total_score_multiplier()
          score+=mult
          check_score_for_bubble()
        elseif eb.x<-8 then
          del(extra_balls, eb)
        end
      end

      -- collision with AI or pass AI => +3 ×mult if it passes
      if eb.x+2>ai.x then
        if (eb.x+2>ai.x and eb.x<ai.x+2 and eb.y+2>ai.y and eb.y<ai.y+12) then
          sfx(1)
          -- bounce
          eb.dx=-eb.dx
        elseif eb.x>136 then
          -- user gain +3 * mult
          local mult=total_score_multiplier()
          score += 3*mult
          del(extra_balls, eb)
        end
      end
    end
  end
end

function draw_extra_balls()
  for eb in all(extra_balls) do
    rectfill(eb.x, eb.y, eb.x+2, eb.y+2, 8) -- red
  end
end

------------------------------
-- POWERUP BUBBLE
------------------------------
function maybe_spawn_bubble()
  -- If bubble is already active, do nothing
  if bubble.active then return end

  -- If score >= next_powerup_score => 25% chance
  if score>=next_powerup_score then
    if rnd(1)<spawn_bubble_chance then
      spawn_bubble()
    else
      --next_powerup_score += 10*base_score_multiplier()
      next_powerup_score += 1
    end
  end
end

function spawn_bubble()
  bubble.active=true
  bubble.life=600  -- 10s
  bubble.spr=1

  -- random spawn in ±10px around center so it doesn't get auto-popped
  bubble.x=64 + rnd(20) - 10
  bubble.y=64 + rnd(20) - 10

  if rnd(1)<0.5 then
    bubble.powerup_spr=2  -- 3 extra balls
  else
    bubble.powerup_spr=3  -- x2 score for 10s
  end

  --next_powerup_score += 10*base_score_multiplier()
  next_powerup_score += 1
end

function update_bubble()
  if not bubble.active then return end

  bubble.life-=1

  -- gentle floating
  bubble.x += (rnd(5)-rnd(5))*0.2
  bubble.y += (rnd(5)-rnd(5))*0.2

  -- keep bubble in a region
  if bubble.y<20 then bubble.y=20 end
  if bubble.y>110 then bubble.y=110 end
  if bubble.x<50 then bubble.x=50 end
  if bubble.x>78 then bubble.x=78 end

  -- vanish if time is up
  if bubble.life<=0 then
    bubble.active=false
    return
  end

  -- collision with main ball?
  if check_bubble_hit(ball.x, ball.y) then
    pop_bubble()
    return
  end

  -- collision with any extra ball?
  for eb in all(extra_balls) do
    if check_bubble_hit(eb.x, eb.y) then
      pop_bubble()
      return
    end
  end
end

function draw_bubble()
  if not bubble.active then return end
  spr(bubble.spr, bubble.x-4, bubble.y-4)
  spr(bubble.powerup_spr, bubble.x-4, bubble.y-4)
end

function check_bubble_hit(bx, by)
  local dx=(bubble.x - (bx+1))
  local dy=(bubble.y - (by+1))
  local dist=sqrt(dx^2 + dy^2)
  return (dist<4)
end

function pop_bubble()
  sfx(2)
  bubble.active=false
  bubble.life=0
  spawn_powerup(bubble.powerup_spr)
end

function spawn_powerup(s)
  if s==2 then
    spawn_extra_balls()
  else
    powerup_active=true
    powerup_type=2
    powerup_timer=600
  end
end

function spawn_extra_balls()
  -- spawn them heading TOWARD the enemy
  -- i.e., positive dx
  for i=1,3 do
    add(extra_balls, {
      x=ball.x,
      y=ball.y,
      dx=(1 + rnd(2)),   -- ensures dx>0
      dy=rnd(1)-0.5,
      life=600,
    })
  end
end

function sgn(val)
  if val<0 then return -1 end
  return 1
end

function update_powerup()
  if powerup_active then
    powerup_timer-=1
    if powerup_timer<=0 then
      powerup_active=false
      powerup_type=0
    end
  end
end

function check_score_for_bubble()
  -- Additional logic optional if you want
end

------------------------------
-- DRAWING HELPER FUNCTIONS --
------------------------------
function draw_field()
  rectfill(65,0,65,128,1)
  rect(0,0,127,127,1)
end

function draw_paddles()
  rectfill(player.x, player.y, player.x+2, player.y+12, 12)
  rectfill(ai.x, ai.y, ai.x+2, ai.y+12, 8)
end

function draw_ball()
  rectfill(ball.x, ball.y, ball.x+2, ball.y+2, 10)
end

function draw_score()
  print("Score: "..score, 52, 4, 7)

  -- Subtle flashing base multiplier
  local base_mult = base_score_multiplier()
  local t = flr(time()*30)
  local color = (t%30<15) and 12 or 13
  print("(".."X"..base_mult..")", 60, 12, color)

  -- If powerup multiplier is active, show it
  if powerup_active and powerup_type==2 then
    local color2=(t%20<10) and 10 or 9
    print_centered("POWERUP x2!", 20, color2)
  end
end

--------------------------
-- BACKGROUND FUNCTIONS --
--------------------------
function init_background()
  for i=1,num_shapes_layer1 do
    add(bg_layer1, {
      x=rnd(128),
      y=rnd(128),
      speed=0.8,
      shape=flr(rnd(3)),
      color=5
    })
  end
  for i=1,num_shapes_layer2 do
    add(bg_layer2, {
      x=rnd(128),
      y=rnd(128),
      speed=1.5,
      shape=flr(rnd(3)),
      color=6
    })
  end
end

function update_background()
  for shape in all(bg_layer1) do
    shape.x-=shape.speed
    if shape.x<-8 then
      shape.x=128
      shape.y=rnd(128)
    end
  end
  for shape in all(bg_layer2) do
    shape.x-=shape.speed
    if shape.x<-8 then
      shape.x=128
      shape.y=rnd(128)
    end
  end
end

function draw_background()
  for shape in all(bg_layer1) do
    draw_shape(shape)
  end
  for shape in all(bg_layer2) do
    draw_shape(shape)
  end
end

function draw_shape(shp)
  color(shp.color)
  circfill(shp.x, shp.y, 1, shp.color)
end

--------------------------------
-- TEXT HELPER (CENTERED)     --
--------------------------------
function print_centered(str,y,col)
  col=col or 7
  local w=#str*4
  local x=64-(w/2)
  print(str,x,y,col)
end
