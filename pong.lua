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

-- define two layers of shapes
bg_layer1 = {}
bg_layer2 = {}

-- how many shapes in each layer
num_shapes_layer1 = 20
num_shapes_layer2 = 15

function init_background()
  -- generate layer1 shapes
  for i=1,num_shapes_layer1 do
    add(bg_layer1, {
      x = rnd(128),     -- random x between 0..127
      y = rnd(128),     -- random y
      speed = 0.8,      -- slower speed for far layer
      shape = flr(rnd(3)),
      color = 5         -- a subtle color
    })
  end
  
  -- generate layer2 shapes
  for i=1,num_shapes_layer2 do
    add(bg_layer2, {
      x = rnd(128),
      y = rnd(128),
      speed = 1.5,      -- slightly faster for near layer
      shape = flr(rnd(3)),
      color = 6         -- a slightly brighter color
    })
  end
end

function update_background()
  -- update layer1
  for shape in all(bg_layer1) do
    shape.x -= shape.speed
    -- if shape goes off-screen to the left, reset on the right
    if shape.x < -8 then
      shape.x = 128
      shape.y = rnd(128)
    end
  end
  
  -- update layer2
  for shape in all(bg_layer2) do
    shape.x -= shape.speed
    if shape.x < -8 then
      shape.x = 128
      shape.y = rnd(128)
    end
  end
end

function draw_background()
  -- draw layer1 first (farther)
  for shape in all(bg_layer1) do
    draw_shape(shape)
  end
  
  -- draw layer2 (nearer)
  for shape in all(bg_layer2) do
    draw_shape(shape)
  end
end

-- draws a generic shape based on its "shape" field
function draw_shape(shp)
  color(shp.color)
  if shp.shape == 0 then
    -- circle
    circfill(shp.x, shp.y, 1, shp.color)
  elseif shp.shape == 1 then
    -- rectangle
    circfill(shp.x, shp.y, 1, shp.color)
  else
    -- optionally: more shapes, triangles, etc.
    circfill(shp.x, shp.y, 1, shp.color)
  end
end

-----------------------
-- INITIALIZATION   --
-----------------------
function _init()
  cls()
  init_background()
end

-----------------------
-- UPDATE FUNCTION --
-----------------------
function _update()
  update_background()
  update_player()
  update_ai()
  update_ball()
  update_trail()
end

-----------------------
-- DRAW FUNCTION   --
-----------------------
function _draw()
  cls()
  draw_background()
  draw_field()
  draw_paddles()
  draw_ball_trail()
  draw_ball()
  draw_score()
end

-------------------------------------
-- UPDATE HELPERS: PLAYER, AI, BALL --
-------------------------------------

function update_player()
  if btn(0) then player.y -= player.speed end -- Up
  if btn(1) then player.y += player.speed end -- Down
  -- Keep player paddle on screen
  player.y = mid(0, player.y, 120)
end

function update_ai()
  -- AI movement (gets smarter over time):
  -- The AI paddle's vertical target is near the ball's y
  local ai_target_y = ball.y - 4
  ai.y += (ai_target_y - ai.y) * ai.difficulty
  ai.y = mid(0, ai.y, 120)
end

function update_ball()
  -----------------------
  -- GRAVITY & MOTION --
  -----------------------
  -- Add gravity to vertical velocity
  ball.dy += ball.gravity
  
  -- Update the ball position
  ball.x += ball.dx
  ball.y += ball.dy
  
  -------------------------------
  -- COLLISION: TOP/BOTTOM    --
  -------------------------------
  if ball.y < 0 then
    ball.y = 0
    ball.dy = -ball.dy * 0.95
  elseif ball.y > 127 then
    ball.y = 127
    ball.dy = -ball.dy * 0.95
  end

  -------------------------------
  -- COLLISION: PLAYER PADDLE --
  -------------------------------
  if ball.x < player.x + 2 then
    if is_colliding_with_paddle(player) then
      sfx(0)
      bounce_off_paddle(player)
      increase_difficulty()
      score += 1
    elseif ball.x < -8 then
      -- Ball out of bounds (player misses)
      sfx(2)
      reset_ball()
      reset_difficulty()
      score = 0
    end
  end

  ---------------------------
  -- COLLISION: AI PADDLE --
  ---------------------------
  if ball.x + 2 > ai.x then
    if is_colliding_with_paddle(ai) then
      sfx(1)
      bounce_off_paddle(ai)
    elseif ball.x > 136 then
      -- AI misses, you beat the AI => +10 points
      sfx(2)
      reset_ball()
      reset_difficulty()
      score += 10
    end
  end

  ----------------
  -- TRAIL INFO --
  ----------------
  -- Add a new trail particle at the ball’s current position
  add(ball_trail, {
    x = ball.x,
    y = ball.y,
    life = 10 -- frames before it disappears
  })
end

-----------------------------------------
-- COLLISION & BOUNCE HELPER FUNCTIONS --
-----------------------------------------
function is_colliding_with_paddle(paddle)
  -- Check if the ball's vertical range overlaps with the paddle's
  return (ball.y + 2 > paddle.y and ball.y < paddle.y + 12)
end

function bounce_off_paddle(paddle)
  -- Reverse the horizontal direction
  ball.dx = -ball.dx
  
  if paddle == player then
    -- Standard bounce for the player
    local paddle_mid = paddle.y + 6
    local offset = (ball.y - paddle_mid) / 6
    ball.dy = (offset * 3) + (0.3 * ball.dy)
    ball.x = player.x + 3
    
  else
    -- Specialized bounce logic for the AI:
    -- The AI tries to bounce the ball *away* from the player's position.
    -- We'll check whether the player's paddle is in the top or bottom half of the screen.
    local player_mid = player.y + 6

    -- Simple approach: if the player is above the center,
    -- the AI aims the ball downward; otherwise, aims upward.
    if (player_mid < 64) then
      -- Player is mostly in upper half => aim ball downward
      ball.dy =  abs(ball.dy) + rnd(0.5)
    else
      -- Player is mostly in lower half => aim ball upward
      ball.dy = -abs(ball.dy) - rnd(0.5)
    end

    -- Move ball slightly away from AI’s paddle so it doesn't get stuck
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

function reset_ball()
  ball.x = 64
  ball.y = 64
  ball.dx = 2
  ball.dy = 0
end

----------------------
-- TRAIL MANAGEMENT --
----------------------
function update_trail()
  -- Update each particle’s life.
  -- Remove it if it runs out of life.
  for i=#ball_trail,1,-1 do
    local p = ball_trail[i]
    p.life -= 1
    if p.life <= 0 then
      del(ball_trail, p)
    end
  end
end

function draw_ball_trail()
  -- Draw from oldest to newest for a nice fade effect
  for i=1,#ball_trail do
    local p = ball_trail[i]
    -- Simple fade by color shift
    local c = 7
    if p.life <= 6 then c = 6 end
    if p.life <= 3 then c = 5 end

    -- Draw a tiny rectangle to represent a particle
    rectfill(p.x, p.y, p.x+1, p.y+1, c)
  end
end

---------------------------
-- DRAW HELPER FUNCTIONS --
---------------------------
function draw_field()
  -- Middle barrier
  rectfill(65, 0, 65, 128, 1)
  -- Outer screen border
  rect(0, 0, 127, 127, 1)
end

function draw_paddles()
  -- Player paddle
  rectfill(player.x, player.y, player.x + 2, player.y + 12, 12)
  -- AI paddle
  rectfill(ai.x, ai.y, ai.x + 2, ai.y + 12, 8)
end

function draw_ball()
  rectfill(ball.x, ball.y, ball.x + 2, ball.y + 2, 10)
end

function draw_score()
  print("Score: "..score, 52, 4, 7)
end
