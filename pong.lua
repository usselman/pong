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

score = 0

-- The ball's trail particles
ball_trail = {}

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

-- When the ball resets, we show "SERVE IT UP!" for 2 seconds
-- serving = true means we're in the "serve" pause
-- serve_timer counts down frames (2s ~ 120 frames at 60fps)
serving = false
serve_timer = 0

-----------------------
-- INITIALIZATION    --
-----------------------
function _init()
  cls()
  init_background()
  game_state = 0

  music(1) -- Example: start some music if you want
end

-----------------------
-- UPDATE FUNCTION  --
-----------------------
function _update()
  if game_state == 0 then
    -----------------------
    -- START MENU (state=0)
    -----------------------
    update_background()
    -- Press X (btn(5)) to start the game
    if btnp(5) then
      game_state = 1
      start_serve()
    end
    
  elseif game_state == 1 then
    ---------------------
    -- PLAYING (state=1)
    ---------------------
    update_background()
    update_player()
    update_ai()

    -- If we are in "serve" mode, the ball is paused except for the 2s timer
    if serving then
      update_serve()
    else
      update_ball()
    end

    update_trail()
    
  elseif game_state == 2 then
    ------------------------
    -- GAME OVER (state=2)
    ------------------------
    update_background()
    -- Press X (btn(5)) to reset and go back to start menu
    if btnp(5) then
      reset_game()
      game_state = 0
    end
  end
end

-----------------------
-- DRAW FUNCTION    --
-----------------------
function _draw()
  cls()

  if game_state == 0 then
    -----------------------
    -- START MENU
    -----------------------
    draw_background()
    -- Draw "SPACE" sprite letters (example near the top)
    draw_space_title(32, 20) 
    -- print_centered("VALLEY PONG", 48, 7)
    print_centered("PRESS X TO START", 62, 6)

  elseif game_state == 1 then
    -----------------------
    -- PLAYING
    -----------------------
    draw_background()
    draw_field()
    draw_paddles()
    draw_ball_trail()
    draw_ball()
    draw_score()

    -- If serving, draw "SERVE IT UP!" in flashing color
    if serving then
      draw_serve_message()
    end

  elseif game_state == 2 then
    -----------------------
    -- GAME OVER
    -----------------------
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
  if btn(0) then player.y -= player.speed end -- Up
  if btn(1) then player.y += player.speed end -- Down
  player.y = mid(0, player.y, 120)
end

function update_ai()
  -- AI movement (gets smarter over time):
  local ai_target_y = ball.y - 4
  ai.y += (ai_target_y - ai.y) * ai.difficulty
  ai.y = mid(0, ai.y, 120)
end

function update_ball()
  ball.dy += ball.gravity
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
      increase_difficulty()
      score += 1
    elseif ball.x < -8 then
      -- Player misses => Game Over
      sfx(2)
      game_state = 2
    end
  end

  -- AI side
  if ball.x + 2 > ai.x then
    if is_colliding_with_paddle(ai) then
      sfx(1)
      bounce_off_paddle(ai)
    elseif ball.x > 136 then
      -- AI misses => You beat AI => +5 (or +10, per your preference)
      sfx(3)
      -- Instead of game over, we keep playing but reset ball
      score += 5
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
function is_colliding_with_paddle(paddle)
  return (ball.y + 2 > paddle.y and ball.y < paddle.y + 12)
end

function bounce_off_paddle(paddle)
  ball.dx = -ball.dx
  
  if paddle == player then
    local paddle_mid = paddle.y + 6
    local offset = (ball.y - paddle_mid) / 6
    ball.dy = (offset * 3) + (0.3 * ball.dy)
    ball.x = player.x + 3
  else
    -- AI aiming logic
    local player_mid = player.y + 6
    if (player_mid < 64) then
      ball.dy = abs(ball.dy) + rnd(0.5)
    else
      ball.dy = -abs(ball.dy) - rnd(0.5)
    end
    ball.x = ai.x - 3
  end
end

function increase_difficulty()
  ai.difficulty = min(1, ai.difficulty + 0.02)
  ai.speed      = min(4, ai.speed + 0.05)
end

function reset_difficulty()
    ai.difficulty = 0.25
    ai.speed      = 1
end

---------------------------------
-- SERVE ("SERVE IT UP!") LOGIC --
---------------------------------
-- Called whenever a new round starts.
function start_serve()
  reset_ball()
  reset_difficulty()
  serving = true
  serve_timer = 90   -- ~2 seconds at 60fps
end

function update_serve()
  -- While serving, the ball is effectively paused
  serve_timer -= 1
  if serve_timer <= 0 then
    serving = false
  end
end

function draw_serve_message()
  -- Flashing color: let’s pick color based on frame count
  -- e.g., two colors toggling every 15 frames
  local t = flr(time()*30)
  local color
  if (t % 30) < 15 then
    color = 10  -- e.g., bright green
  else
    color = 9   -- e.g., bright red
  end
  
  -- Print "SERVE IT UP!" in the center
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
end

function reset_game()
  reset_ball()
  reset_difficulty()
  score = 0
  serving = false
  serve_timer = 0
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
  rectfill(65, 0, 65, 128, 1)    -- middle barrier
  rect(0, 0, 127, 127, 1)        -- outer screen border
end

function draw_paddles()
  rectfill(player.x, player.y, player.x + 2, player.y + 12, 12)
  rectfill(ai.x, ai.y, ai.x + 2, ai.y + 12, 8)
end

function draw_ball()
  rectfill(ball.x, ball.y, ball.x + 2, ball.y + 2, 10)
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
  local w = #str * 4   -- each character ~4px wide in Pico-8's font
  local x = 64 - (w / 2)
  print(str, x, y, col)
end

------------------------------------
-- DRAW "SPACE" FROM SPRITES     --
------------------------------------
-- We have 6 sprite indices for each letter: top half, bottom half.
-- According to your info:
-- S: top=1, bot=17
-- P: top=2, bot=18
-- A: top=3, bot=19
-- C: top=4, bot=20
-- E: top=5, bot=21
-- We'll place them horizontally in a row.
function draw_space_title(x, y)
  local letters = {
    { top=1,  bot=17 },  -- S
    { top=2,  bot=18 },  -- P
    { top=3,  bot=19 },  -- A
    { top=4,  bot=20 },  -- C
    { top=5,  bot=21 },  -- E
  }

  local cursor_x = x
  for l in all(letters) do
    -- Draw top half at (cursor_x, y)
    spr(l.top, cursor_x, y)
    -- Draw bottom half at (cursor_x, y+8)
    spr(l.bot, cursor_x, y+8)

    -- Move cursor to the right (8 pixels wide each letter)
    cursor_x += 8
  end
end
