-- Valley Pong 
-- Author: Shirish Sarkar

-----------------------
-- GLOBAL VARIABLES --
-----------------------
player = { x = 2,  y = 64, speed = 4 }
ai     = { x = 125, y = 64, speed = 4, difficulty = 0.5 }

ball = {
  x = 64,
  y = 64,
  dx = 2,         -- horizontal velocity
  dy = 0,         -- vertical velocity
  gravity = 0.01  -- "gravity" factor (pulls ball downward)
}

ball_trail = {}

-- We'll keep track of how many times the ball has bounced off a paddle:
rally_count = 0

-- Original starting speed for reference (used in speed scaling)
start_speed = 2.25

score = 0

--------------------------
-- SCORING MULTIPLIER  --
--------------------------
function score_multiplier()
  -- 0–49 => 1×, 50–99 => 2×, up to 10×
  -- floor(score/50) + 1, capped at 10
  local mult = 1 + flr(score / 50)
  return min(mult, 10)
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
-- game_state:
--   0 = start menu
--   1 = playing
--   2 = game over
game_state = 0

-- "Serve It Up!" pause
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
    -- START MENU
    update_background()
    if btnp(5) then
      game_state = 1
      start_serve()
    end
    
  elseif game_state == 1 then
    -- PLAYING
    update_background()
    update_player()
    update_ai()

    if serving then
      update_serve()
    else
      update_ball()
    end

    update_trail()
    
  elseif game_state == 2 then
    -- GAME OVER
    game_state_pico = 1
    update_background()
    if btnp(5) then
      reset_game()
      game_state = 0
    end
  end

  -- Poke the score & game state to memory for external reading
  poke4(0x5f80, score)
  poke2(0x5f84, game_state_pico)
end

-----------------------
-- DRAW FUNCTION    --
-----------------------
function _draw()
  cls()

  if game_state == 0 then
    -- START MENU
    draw_background()
    print_centered("space paddle", 36, 7)
    print_centered("ARROWS TO MOVE", 56, 6)
    print_centered("PRESS X TO START", 66, 6)
    print_centered("VALLEY STUDIOS", 96, 7)

  elseif game_state == 1 then
    -- PLAYING
    draw_background()
    draw_field()
    draw_paddles()
    draw_ball_trail()
    draw_ball()
    draw_score()

    if serving then
      draw_serve_message()
    end

  elseif game_state == 2 then
    -- GAME OVER
    draw_background()
    print_centered("GAME OVER", 50, 7)
    print_centered("SCORE: "..score, 60, 6)
    print_centered("PRESS X TO RESTART", 70, 6)
  end
end

-------------------------------------
-- UPDATE HELPERS: PLAYER, AI, BALL --
-------------------------------------

function update_player()
  -- Up: btn(0) or btn(2), Down: btn(1) or btn(3)
  if btn(0) or btn(2) then player.y -= player.speed end
  if btn(1) or btn(3) then player.y += player.speed end
  player.y = mid(0, player.y, 120)
end

function update_ai()
  -- Basic AI movement
  local ai_target_y = ball.y - 4
  ai.y += (ai_target_y - ai.y) * ai.difficulty
  ai.y = mid(0, ai.y, 120)
end

function update_ball()
  -- Gravity
  ball.dy += ball.gravity

  -- Move
  ball.x += ball.dx
  ball.y += ball.dy
  
  -- Top/bottom bounce
  if ball.y < 0 then
    ball.y = 0
    ball.dy = -ball.dy * 0.95
    sfx(4)
  elseif ball.y > 127 then
    ball.y = 127
    ball.dy = -ball.dy * 0.95
    sfx(4)
  end

  -- Player side
  if ball.x < player.x + 2 then
    if is_colliding_with_paddle(player) then
      sfx(0)
      bounce_off_paddle(player)
      rally_count += 1
      scale_ball_speed()       -- apply speed up
      local mult = score_multiplier()
      score += mult
    elseif ball.x < -8 then
      -- Player misses => game over
      music(2)
      game_state = 2
    end
  end

  -- AI side
  if ball.x + 2 > ai.x then
    if is_colliding_with_paddle(ai) then
      sfx(1)
      bounce_off_paddle(ai)
      rally_count += 1
      scale_ball_speed()
    elseif ball.x > 136 then
      -- AI misses => your gain
      sfx(3)
      local mult = score_multiplier()
      score += 3 * mult
      rally_count = 0
      start_serve()
    end
  end

  -- Add a new trail particle
  add(ball_trail, {
    x = ball.x,
    y = ball.y,
    life = 10
  })
end

-----------------------------------------
-- COLLISION & BOUNCE HELPER FUNCTIONS --
-----------------------------------------
-- Tighter bounding-box collision check
function is_colliding_with_paddle(pad)
  return (
    (ball.x + 2 > pad.x) and
    (ball.x < pad.x + 2) and
    (ball.y + 2 > pad.y) and
    (ball.y < pad.y + 12)
  )
end

function bounce_off_paddle(paddle)
  -- Reverse X direction
  ball.dx = -ball.dx
  
  if paddle == player then
    -- Standard bounce logic
    local pad_mid = paddle.y + 6
    local offset = (ball.y - pad_mid) / 6
    ball.dy = (offset * 3) + (0.3 * ball.dy)
    ball.x = player.x + 3
  else
    -- AI aims far away from player's Y
    local player_mid = player.y + 6
    if (player_mid < 64) then
      -- Player is high => send ball downward
      ball.dy = abs(ball.dy) + rnd(0.5)
    else
      -- Player is low => send ball upward
      ball.dy = -abs(ball.dy) - rnd(0.5)
    end
    ball.x = ai.x - 3
  end
end

-- Speed up the ball after each rally, up to 5× original speed by 100 rallies
function scale_ball_speed()
  -- rally_count from 0..100 => factor from 1..5
  local factor = 1 + (4 * rally_count / 100)
  if factor > 5 then
    factor = 5
  end

  -- Current direction
  local old_spd = sqrt(ball.dx^2 + ball.dy^2)
  if old_spd > 0 then
    local new_spd = start_speed * factor
    -- Scale dx,dy proportionally
    local scale = new_spd / old_spd
    ball.dx *= scale
    ball.dy *= scale
  end
end

function reset_difficulty()
  ai.difficulty = 0.25
  ai.speed      = 1
end

---------------------------------
-- SERVE ("SERVE IT UP!") LOGIC --
---------------------------------
function start_serve()
  reset_ball()
  --reset_difficulty()
  serving = true
  serve_timer = 90   -- ~1.5 seconds at 60fps
end

function update_serve()
  serve_timer -= 1
  if serve_timer <= 0 then
    serving = false
  end
end

function draw_serve_message()
  local t = flr(time()*30)
  local color
  if (t % 30) < 15 then
    color = 10
  else
    color = 9
  end
  print_centered("SERVE IT UP!", 50, color)
end

---------------------------------
-- GAME RESET/INIT FUNCTIONS  --
---------------------------------
function reset_ball()
  ball.x = 64
  ball.y = 64
  ball.dx = 2
  ball.dy = 0
  --rally_count = 0
end

function reset_game()
  reset_ball()
  reset_difficulty()
  score = 0
  serving = false
  serve_timer = 0
  rally_count = 0
  music(1)
end

----------------------
-- TRAIL MANAGEMENT --
----------------------
function update_trail()
  for i=#ball_trail,1,-1 do
    local p = ball_trail[i]
    p.life -= 1
    if p.life <= 0 then
      del(ball_trail, p)
    end
  end
end

function draw_ball_trail()
  for i=1,#ball_trail do
    local p = ball_trail[i]
    local c = 7
    if p.life <= 6 then c = 6 end
    if p.life <= 3 then c = 5 end
    rectfill(p.x, p.y, p.x+1, p.y+1, c)
  end
end

------------------------------
-- DRAWING HELPER FUNCTIONS --
------------------------------
function draw_field()
  rectfill(65, 0, 65, 128, 1)
  rect(0, 0, 127, 127, 1)
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
end

--------------------------
-- BACKGROUND FUNCTIONS --
--------------------------
function init_background()
  for i=1,num_shapes_layer1 do
    add(bg_layer1, {
      x = rnd(128),
      y = rnd(128),
      speed = 0.8,
      shape = flr(rnd(3)),
      color = 5
    })
  end
  
  for i=1,num_shapes_layer2 do
    add(bg_layer2, {
      x = rnd(128),
      y = rnd(128),
      speed = 1.5,
      shape = flr(rnd(3)),
      color = 6
    })
  end
end

function update_background()
  for shape in all(bg_layer1) do
    shape.x -= shape.speed
    if shape.x < -8 then
      shape.x = 128
      shape.y = rnd(128)
    end
  end
  for shape in all(bg_layer2) do
    shape.x -= shape.speed
    if shape.x < -8 then
      shape.x = 128
      shape.y = rnd(128)
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
function print_centered(str, y, col)
  col = col or 7
  local w = #str * 4
  local x = 64 - (w / 2)
  print(str, x, y, col)
end
