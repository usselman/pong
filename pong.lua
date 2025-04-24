-- Valley Pong 
-- Author: Shirish Sarkar

-----------------------
-- GLOBAL VARIABLES --
-----------------------

player = {
  x = 2, y = 64,
  speed = 3.25,
  vel = 0,
  friction = 0.2
}

ai = {
  x = 125, y = 64,
  speed = 4,
  difficulty = 0.5
}

ball = {
  x = 64, y = 64,
  dx = 2, dy = 0,
  gravity = 0.01,
  rx = 0,  -- fractional remainder for x
  ry = 0   -- fractional remainder for y
}

ball_trail = {}

rally_count = 0
start_speed = 2.25
score = 0

--------------------------
-- POWERUP STATES
--------------------------
spawn_bubble_chance = 0.75

-- Existing multiplier powerup info (unchanged)
powerup_active = false
powerup_type   = 0  -- 1=extra balls, 2=x2 score, 3=freeze ai (existing logic)

powerup_timer  = 0
extra_balls = {}

-- Instead of a single bubble, we now have a table for multiple powerups.
max_powerups = 1   -- start with 1 and gradually increase up to 4.
powerups = {}      -- holds active powerup bubbles

-- Score threshold for spawning the next powerup.
next_powerup_score = 1

--------------------------
-- FREEZE AI LOGIC
--------------------------
ai_frozen_time = 0     -- frames left while AI is frozen
flash_time     = 0     -- frames for a short “screen flash”

--------------------------
-- SCREEN SHAKE & PARTICLE VARIABLES
--------------------------
screen_shake_time = 0       -- Duration (in frames) of the screen shake effect
screen_shake_magnitude = 0.01  -- Maximum pixel offset for shake
hit_particles = {}          -- Table to hold hit particles

--------------------------
-- SLOW POWERUP VARIABLES
--------------------------
slow_active = false    -- whether the slow powerup is active
slow_timer = 0         -- frames remaining for slow effect
slow_factor = 1        -- effective multiplier (1 normally, 0.5 while slowed)

--------------------------
-- SCORING MULTIPLIER  --
--------------------------
function base_score_multiplier()
  local mult = 1 + flr(score/50)
  return min(mult,10)
end

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
  
  -- Update the slow powerup effect.
  if slow_active then
    slow_timer -= 1
    if slow_timer <= 0 then
      slow_active = false
      slow_factor = 1
    else
      slow_factor = 0.5
    end
  else
    slow_factor = 1
  end

  if game_state == 0 then
    update_background()
    if btnp(5) then
      game_state = 1
      start_serve()
    end
  elseif game_state == 1 then
    update_background()
    update_player()
    update_ai_freeze()
    if serving then
      update_serve()
    else
      update_ball()          -- ball movement with pixel–by–pixel collision
      update_extra_balls()
      
      -- Update active powerup bubbles.
      update_powerups()
      
      -- Check for collisions: the ball collects powerups.
      for i = #powerups, 1, -1 do
        local p = powerups[i]
        if check_powerup_hit(ball.x, ball.y, p) then
          pop_powerup(p)
        end
      end
    end

    update_powerup()   -- existing multiplier powerup update
    update_trail()
    maybe_spawn_powerups()   -- spawn powerups if below max count

    if flash_time > 0 then
      flash_time -= 1
    end

  elseif game_state == 2 then
    game_state_pico = 1
    update_background()
    if btnp(5) then
      reset_game()
      game_state = 0
    end
  end

  update_hit_particles()
  if screen_shake_time > 0 then
    screen_shake_time -= 1
  end

  poke2(0x5f80, 0)
 poke2(0x5f82, score)
  poke2(0x5f84, game_state_pico)
end

-----------------------
-- DRAW FUNCTION    --
-----------------------
function _draw()
  -- Apply screen shake via random camera offset if active.
  if screen_shake_time > 0 then
    local shake_x = (flr(rnd(screen_shake_magnitude * 2 + 1)) - screen_shake_magnitude)/2
    local shake_y = (flr(rnd(screen_shake_magnitude * 2 + 1)) - screen_shake_magnitude)/2
    camera(shake_x, shake_y)
  else
    camera(0, 0)
  end

  cls()

  if game_state == 0 then
    draw_background()
    wave_print("s p a c e p a d d l e", 22, 36)
    print_centered("ARROWS TO MOVE", 56, 6)
    print_centered("PRESS X TO START", 66, 6)
    print_centered("VALLEY STUDIOS", 96, 7)
    print_centered("V1.0", 106, 6)
  elseif game_state == 1 then
    draw_background()
    draw_flash()
    draw_field()
    draw_paddles()
    draw_ball_trail()
    draw_hit_particles()
    draw_ball()
    draw_extra_balls()
    draw_powerups()
    draw_score()
    if serving then
      draw_serve_message()
    end
  elseif game_state == 2 then
    draw_background()
    print_centered("GAME OVER", 50, 7)
    print_centered("SCORE: " .. score, 60, 6)
    print_centered("PRESS X TO RESTART", 70, 6)
  end

  camera(0,0)
end

-------------------------------------
-- WAVE TYPING. --
-------------------------------------
function wave_print(text, x, y)
  local amplitude = 2.5
  local speed = 1
  for i = 1, #text do
    local letter = sub(text, i, i)
    local t = time() * speed + i * 0.1
    local wave_offset = sin(t) * amplitude
    local col = 10 + flr((sin(t * 0.5) + 1) * 2)
    if col > 15 then col = 15 end
    print(letter, x + (i - 1) * 4, y + wave_offset, col)
  end
end

-------------------------------------
-- UPDATE HELPERS: PLAYER, AI, BALL --
-------------------------------------
function update_player()
  local up = btn(0) or btn(2)
  local down = btn(1) or btn(3)
  if up then
    player.vel = -player.speed * slow_factor
  elseif down then
    player.vel = player.speed * slow_factor
  else
    player.vel *= player.friction
  end
  player.y += player.vel
  player.y = mid(0, player.y, 120)
end

function update_ai_freeze()
  if ai_frozen_time > 0 then
    ai_frozen_time -= 1
  else
    local ai_target_y = ball.y - 4
    ai.y += (ai_target_y - ai.y) * ai.difficulty * slow_factor
    ai.y = mid(0, ai.y, 120)
  end
end

------------------------------------------------------
-- NEW BALL UPDATE WITH Pixel-By-Pixel Collision Code --
------------------------------------------------------
function update_ball()
  -- 1) Apply gravity
  ball.dy += ball.gravity

  -- 2) Use slow_factor for ball movement.
  local effective_dx = ball.dx * slow_factor
  local effective_dy = ball.dy * slow_factor
  ball.rx += effective_dx
  ball.ry += effective_dy

  -- 3) Determine whole pixel movement using a custom round function.
  local moveX = round(ball.rx)
  local moveY = round(ball.ry)

  ball.rx -= moveX
  ball.ry -= moveY

  -- 4) Horizontal movement (pixel-by-pixel)
  local signX = moveX > 0 and 1 or (moveX < 0 and -1 or 0)
  for i = 1, abs(moveX) do
    local newX = ball.x + signX
    if signX < 0 then
      if collides_with_paddle(newX, ball.y, player) then
        sfx(0)
        bounce_off_paddle(player)
        rally_count += 1
        scale_ball_speed()
        score += total_score_multiplier()
        break
      elseif newX < -8 then
        music(2)
        game_state = 2
        return
      end
    elseif signX > 0 then
      if collides_with_paddle(newX, ball.y, ai) then
        sfx(1)
        bounce_off_paddle(ai)
        rally_count += 1
        scale_ball_speed()
        break
      elseif newX > 136 then
        sfx(3)
        score += 3 * total_score_multiplier()
        rally_count = 0
        start_serve()
        return
      end
    end
    ball.x = newX
  end

  -- 5) Vertical movement (pixel-by-pixel)
  local signY = moveY > 0 and 1 or (moveY < 0 and -1 or 0)
  for i = 1, abs(moveY) do
    local newY = ball.y + signY
    if newY < 0 then
      ball.y = 0
      ball.dy = -ball.dy * 0.95
      sfx(4)
      break
    elseif newY > 127 then
      ball.y = 127
      ball.dy = -ball.dy * 0.95
      sfx(4)
      break
    else
      ball.y = newY
    end
  end

  add(ball_trail, { x = ball.x, y = ball.y, life = 10 })
end

function round(n)
  if n < 0 then
    return -flr(-n + 0.5)
  else
    return flr(n + 0.5)
  end
end

function collides_with_paddle(x, y, pad)
  return (x + 2 > pad.x and x < pad.x + 2 and y + 2 > pad.y and y < pad.y + 12)
end

-------------------------------------
-- PADDLE Collision Response & Effects
-------------------------------------
function bounce_off_paddle(paddle)
  ball.dx = -ball.dx
  if paddle == player then
    local pad_mid = paddle.y + 6
    local offset = (ball.y - pad_mid) / 6
    ball.dy = (offset * 3) + (0.3 * ball.dy)
    ball.x = player.x + 3
  else
    local player_mid = player.y + 6
    if player_mid < 64 then
      ball.dy = abs(ball.dy) + rnd(0.5)
    else
      ball.dy = -abs(ball.dy) - rnd(0.5)
    end
    ball.x = ai.x - 3
  end
  screen_shake_time = 2  -- trigger screen shake
  spawn_hit_particles(ball.x + 1, ball.y + 1)
end

function scale_ball_speed()
  local factor = 1 + (4 * rally_count / 100)
  if factor > 5 then factor = 5 end
  local old_spd = sqrt(ball.dx^2 + ball.dy^2)
  if old_spd > 0 then
    local new_spd = start_speed * factor
    local sc = new_spd / old_spd
    ball.dx *= sc
    ball.dy *= sc
  end
end

---------------------------------
-- SERVE ("SERVE IT UP!") LOGIC --
---------------------------------
function start_serve()
  reset_ball()
  serving = true
  serve_timer = 90
end

function update_serve()
  serve_timer -= 1
  if serve_timer <= 0 then
    serving = false
  end
end

function draw_serve_message()
  wave_print("serve it up!", 42, 50)
end

---------------------------------
-- GAME RESET/INIT FUNCTIONS  --
---------------------------------
function reset_ball()
  ball.x = 64
  ball.y = 64
  ball.dx = 2
  ball.dy = 0
  ball.rx = 0
  ball.ry = 0
end

function reset_game()
  reset_ball()
  ai.difficulty = 0.25
  ai.speed = 1

  score = 0
  serving = false
  serve_timer = 0
  rally_count = 0
  player.vel = 0

  extra_balls = {}
  powerups = {}
  max_powerups = 1
  powerup_active = false
  powerup_type = 0
  powerup_timer = 0
  next_powerup_score = 10

  ball_trail = {}
  ai_frozen_time = 0
  flash_time = 0
  slow_active = false
  slow_timer = 0
  slow_factor = 1

  music(1)
end

----------------------
-- TRAIL MANAGEMENT --
----------------------
function update_trail()
  for i = #ball_trail, 1, -1 do
    local p = ball_trail[i]
    p.life -= 1
    if p.life <= 0 then
      del(ball_trail, p)
    end
  end
end

function draw_ball_trail()
  for i = 1, #ball_trail do
    local p = ball_trail[i]
    local c = 7
    if p.life <= 6 then c = 6 end
    if p.life <= 3 then c = 5 end
    rectfill(p.x, p.y, p.x + 1, p.y + 1, c)
  end
end

------------------------------
-- HIT PARTICLE FUNCTIONS --
------------------------------
function spawn_hit_particles(x, y)
  local count = 4
  for i = 1, count do
    local angle = rnd(1)
    local speed = 1 + rnd(1)
    add(hit_particles, {
      x = x,
      y = y,
      dx = cos(angle) * speed,
      dy = sin(angle) * speed,
      life = 10,
      color = 7
    })
  end
end

function update_hit_particles()
  for i = #hit_particles, 1, -1 do
    local p = hit_particles[i]
    p.x += p.dx
    p.y += p.dy
    p.dx *= 0.95
    p.dy *= 0.95
    p.life -= 1
    if p.life <= 0 then
      del(hit_particles, p)
    end
  end
end

function draw_hit_particles()
  for p in all(hit_particles) do
    circfill(p.x, p.y, 1, p.color)
  end
end

------------------------------
-- EXTRA BALLS (POWERUP#2) --
------------------------------
function update_extra_balls()
  for i = #extra_balls, 1, -1 do
    local eb = extra_balls[i]
    eb.dy += ball.gravity
    eb.x += eb.dx * slow_factor
    eb.y += eb.dy * slow_factor
    eb.life -= 1

    if eb.y < 0 then
      eb.y = 0
      eb.dy = -eb.dy * 0.95
    elseif eb.y > 127 then
      eb.y = 127
      eb.dy = -eb.dy * 0.95
    end

    if eb.life <= 0 then
      del(extra_balls, eb)
    else
      if eb.x < player.x + 2 then
        if (eb.x + 2 > player.x and eb.x < player.x + 2 and eb.y + 2 > player.y and eb.y < player.y + 12) then
          sfx(0)
          eb.dx = -eb.dx
          eb.dy = (eb.dy * 0.9) + rnd(0.2)
          score += total_score_multiplier()
          check_score_for_bubble()
        elseif eb.x < -8 then
          del(extra_balls, eb)
        end
      end

      if eb.x + 2 > ai.x then
        if (eb.x + 2 > ai.x and eb.x < ai.x + 2 and eb.y + 2 > ai.y and eb.y < ai.y + 12) then
          sfx(1)
          eb.dx = -eb.dx
        elseif eb.x > 136 then
          score += 3 * total_score_multiplier()
          del(extra_balls, eb)
        end
      end
    end
  end
end

function draw_extra_balls()
  for eb in all(extra_balls) do
    rectfill(eb.x, eb.y, eb.x + 2, eb.y + 2, 8)
  end
end

------------------------------
-- POWERUP BUBBLE (MULTIPLE) --
------------------------------
function maybe_spawn_powerups()
  if #powerups < max_powerups and score >= next_powerup_score then
    if rnd(1) < spawn_bubble_chance then
      spawn_powerup_bubble()
    else
      next_powerup_score += 1
    end
    if max_powerups < 4 then
      max_powerups += 1
    end
  end
end

function spawn_powerup_bubble()
  local p = {}
  p.active = true
  p.life = 600
  p.spr = 1
  if #powerups == 0 then
    p.x = 64 + rnd(20) - 10
    p.y = 64 + rnd(20) - 10
  else
    p.x = 16 + rnd(96)
    p.y = 16 + rnd(96)
  end
  local r = rnd(1)
  if r < 0.25 then
    p.powerup_spr = 2  -- spawn extra balls powerup
  elseif r < 0.5 then
    p.powerup_spr = 3  -- x2 score multiplier
  elseif r < 0.75 then
    p.powerup_spr = 4  -- freeze AI
  else
    p.powerup_spr = 5  -- slow (halves movement speeds)
  end
  add(powerups, p)
  next_powerup_score += 1
end

function update_powerups()
  for i = #powerups, 1, -1 do
    local p = powerups[i]
    p.life -= 1
    p.x += (rnd(5) - rnd(5)) * 0.2
    p.y += (rnd(5) - rnd(5)) * 0.2
    if p.x < 0 then p.x = 0 end
    if p.x > 127 then p.x = 127 end
    if p.y < 0 then p.y = 0 end
    if p.y > 127 then p.y = 127 end
    if p.life <= 0 then
      del(powerups, p)
    end
  end
end

function draw_powerups()
  for p in all(powerups) do
    spr(p.spr, p.x - 4, p.y - 4)
    spr(p.powerup_spr, p.x - 4, p.y - 4)
  end
end

function check_powerup_hit(bx, by, p)
  local dx = p.x - (bx + 1)
  local dy = p.y - (by + 1)
  local dist = sqrt(dx^2 + dy^2)
  return (dist < 4)
end

function pop_powerup(p)
  sfx(2)
  spawn_powerup(p.powerup_spr)
  del(powerups, p)
end

------------------------------
-- NEW POWERUP EFFECTS --
------------------------------
function spawn_powerup(s)
  if s == 2 then
    spawn_extra_balls()
  elseif s == 3 then
    powerup_active = true
    powerup_type = 2
    powerup_timer = 600
  elseif s == 4 then
    sfx(8)
    flash_time = 6
    ai_frozen_time = 300
  elseif s == 5 then
    sfx(8)
    flash_time = 6
    slow_active = true
    slow_timer = 300
  end
end

function spawn_extra_balls()
  for i = 1, 3 do
    add(extra_balls, {
      x = ball.x, y = ball.y,
      dx = (1 + rnd(2)),
      dy = rnd(1) - 0.5,
      life = 600
    })
  end
end

function update_powerup()
  if powerup_active then
    powerup_timer -= 1
    if powerup_timer <= 0 then
      powerup_active = false
      powerup_type = 0
    end
  end
end

------------------------------
-- FLASHING THE SCREEN
------------------------------
function draw_flash()
  if flash_time > 0 then
    local c = 12
    rectfill(0, 0, 127, 127, c)
  end
end

function check_score_for_bubble()
  -- (empty for now)
end

------------------------------
-- DRAWING HELPER FUNCTIONS --
------------------------------
function draw_field()
  rectfill(65, 0, 65, 128, 1)
  rect(0, 0, 127, 127, 1)
end

function draw_paddles()
  if ai_frozen_time > 0 then
    local t = flr(time() * 10)
    local c = (t % 2 == 0) and 7 or 14
    rectfill(ai.x, ai.y, ai.x + 2, ai.y + 12, c)
  else
    rectfill(ai.x, ai.y, ai.x + 2, ai.y + 12, 8)
  end
  rectfill(player.x, player.y, player.x + 2, player.y + 12, 12)
end

function draw_ball()
  rectfill(ball.x, ball.y, ball.x + 2, ball.y + 2, 10)
end

function draw_score()
  print("Score: " .. score, 52, 4, 7)
  local base_mult = base_score_multiplier()
  local t = flr(time() * 30)
  local color = (t % 30 < 15) and 12 or 13
  print("(" .. "X" .. base_mult .. ")", 60, 12, color)
  if powerup_active and powerup_type == 2 then
    local color2 = (t % 20 < 10) and 10 or 9
    print_centered("POWERUP x2!", 20, color2)
  end
end

--------------------------
-- BACKGROUND FUNCTIONS --
--------------------------
function init_background()
  for i = 1, num_shapes_layer1 do
    add(bg_layer1, {
      x = rnd(128), y = rnd(128),
      speed = 0.8,
      shape = flr(rnd(3)),
      color = 5
    })
  end
  for i = 1, num_shapes_layer2 do
    add(bg_layer2, {
      x = rnd(128), y = rnd(128),
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
