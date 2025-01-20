-- Valley Pong 
-- Author: Shirish Sarkar

-----------------------
-- GLOBAL VARIABLES --
-----------------------

player = {
  x=2, y=64,
  speed=3.25,
  vel=0,
  friction=0.2
}

ai = {
  x=125, y=64,
  speed=4,
  difficulty=0.5
}

ball = {
  x=64, y=64,
  dx=2, dy=0,
  gravity=0.01
}

ball_trail = {}

rally_count = 0
start_speed = 2.25
score = 0

--------------------------
-- POWERUP STATES
--------------------------
spawn_bubble_chance = 0.75

-- Existing multiplier powerup info
powerup_active = false
powerup_type   = 0  -- 1=extra balls, 2=x2 score, 3=freeze ai?? (we'll define new logic)

powerup_timer  = 0
extra_balls = {}

--------------------------
-- BUBBLE SPAWNER
--------------------------
bubble = {
  active=false,
  x=64, y=64,
  life=0,
  spr=1,    -- bubble sprite
  powerup_spr=0
}

-- Score thresholds for bubble spawns
next_powerup_score = 1

--------------------------
-- FREEZE AI LOGIC
--------------------------
ai_frozen_time = 0     -- frames left while AI is frozen
flash_time     = 0     -- frames for a short “screen flash”

--------------------------
-- SCORING MULTIPLIER  --
--------------------------
function base_score_multiplier()
  local mult = 1 + flr(score/50)
  return min(mult,10)
end

function total_score_multiplier()
  local base_mult = base_score_multiplier()
  if powerup_active and powerup_type==2 then
    -- if x2 powerup is active
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
  game_state=0
  music(1)
end

-----------------------
-- UPDATE FUNCTION  --
-----------------------
function _update()
  local game_state_pico=0
  if game_state==0 then
    update_background()
    if btnp(5) then
      game_state=1
      start_serve()
    end

  elseif game_state==1 then
    update_background()
    update_player()
    update_ai_freeze() -- handle AI freeze logic

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

    -- decrement flash_time if >0
    if flash_time>0 then
      flash_time-=1
    end

  elseif game_state==2 then
    game_state_pico=1
    update_background()
    if btnp(5) then
      reset_game()
      game_state=0
    end
  end

  poke4(0x5f80, score)
  poke2(0x5f84, game_state_pico)
end

-----------------------
-- DRAW FUNCTION    --
-----------------------
function _draw()
  cls()

  if game_state==0 then
    draw_background()
    wave_print("s p a c e p a d d l e", 22, 36)
    print_centered("ARROWS TO MOVE", 56, 6)
    print_centered("PRESS X TO START",66, 6)
    print_centered("VALLEY STUDIOS",96,7)
    print_centered("V0.4",106,6)

  elseif game_state==1 then
    draw_background()
    draw_flash()     -- if flash_time>0, show a quick screen overlay
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

  elseif game_state==2 then
    draw_background()
    print_centered("GAME OVER",50,7)
    print_centered("SCORE: "..score,60,6)
    print_centered("PRESS X TO RESTART",70,6)
  end
end

-------------------------------------
-- WAVE TYPING. --
-------------------------------------
function wave_print(text, x, y)
  local amplitude=2.5
  local speed=1
  for i=1,#text do
    local letter = sub(text,i,i)
    local t=time()*speed + i*0.1
    local wave_offset = sin(t)*amplitude
    local col=10 + flr((sin(t*0.5)+1)*2)
    if col>15 then col=15 end
    print(letter,x+(i-1)*4, y+wave_offset, col)
  end
end

-------------------------------------
-- UPDATE HELPERS: PLAYER, AI, BALL --
-------------------------------------
function update_player()
  local up=btn(0) or btn(2)
  local down=btn(1) or btn(3)
  if up then
    player.vel=-player.speed
  elseif down then
    player.vel=player.speed
  else
    player.vel*=player.friction
  end
  player.y+=player.vel
  player.y=mid(0,player.y,120)
end

-- Freeze AI for ai_frozen_time if >0
function update_ai_freeze()
  if ai_frozen_time>0 then
    ai_frozen_time-=1
    -- AI is frozen => do nothing
  else
    -- normal AI logic
    local ai_target_y=ball.y-4
    ai.y += (ai_target_y - ai.y)*ai.difficulty
    ai.y=mid(0,ai.y,120)
  end
end

function update_ball()
  -- Each frame, we want to move the ball from (ball.x, ball.y)
  -- to (ball.x + ball.dx, ball.y + ball.dy) in small increments.

  -- 1) Apply gravity to the velocity
  ball.dy += ball.gravity

  -- 2) Compute how far we want to move this frame
  local dx = ball.dx
  local dy = ball.dy

  -- 3) Determine how many sub-steps to take
  -- e.g. up to 4 sub-steps if distance is large
  local dist = sqrt(dx*dx + dy*dy)
  local steps = 1

  if dist > 4 then
    steps = ceil(dist / 4)
  end

  local step_x = dx / steps
  local step_y = dy / steps

  -- 4) Move the ball in multiple small steps
  for i=1,steps do
    ball.x += step_x
    ball.y += step_y

    -- Now check top/bottom bounce
    if ball.y < 0 then
      ball.y = 0
      ball.dy = -ball.dy * 0.95
      sfx(4)
    elseif ball.y > 127 then
      ball.y = 127
      ball.dy = -ball.dy * 0.95
      sfx(4)
    end

    -- Check collision with player side
    if ball.x < player.x + 2 then
      if is_colliding_with_paddle(player) then
        sfx(0)
        bounce_off_paddle(player)
        rally_count += 1
        scale_ball_speed()
        local mult = total_score_multiplier()
        score += mult
        check_score_for_bubble()
        -- Because we changed dx/dy in bounce_off_paddle(),
        -- re-calculate step_x/step_y so subsequent sub-steps move with new velocity
        dx = ball.dx
        dy = ball.dy
        dist = sqrt(dx*dx + dy*dy)
        if dist > 4 then
          steps = ceil(dist / 4)
        else
          steps = 1
        end
        step_x = dx / steps
        step_y = dy / steps
      elseif ball.x < -8 then
        music(2)
        game_state = 2
        return
      end
    end

    -- Check collision with AI side
    if ball.x + 2 > ai.x then
      if is_colliding_with_paddle(ai) then
        sfx(1)
        bounce_off_paddle(ai)
        rally_count += 1
        scale_ball_speed()
        dx = ball.dx
        dy = ball.dy
        dist = sqrt(dx*dx + dy*dy)
        if dist > 4 then
          steps = ceil(dist / 4)
        else
          steps = 1
        end
        step_x = dx / steps
        step_y = dy / steps
      elseif ball.x > 136 then
        sfx(3)
        local mult = total_score_multiplier()
        score += 3*mult
        rally_count = 0
        check_score_for_bubble()
        start_serve()
        return
      end
    end
  end

  -- Finally, add a new trail particle
  add(ball_trail, { x = ball.x, y = ball.y, life = 10 })
end


function is_colliding_with_paddle(pad)
  return (
    (ball.x+2>pad.x) and
    (ball.x<pad.x+2) and
    (ball.y+2>pad.y) and
    (ball.y<pad.y+12)
  )
end

function bounce_off_paddle(paddle)
  ball.dx=-ball.dx
  if paddle==player then
    local pad_mid=paddle.y+6
    local offset=(ball.y - pad_mid)/6
    ball.dy=(offset*3)+(0.3*ball.dy)
    ball.x=player.x+3
  else
    local player_mid=player.y+6
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
  ai_frozen_time=0
  flash_time=0

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
      del(ball_trail,p)
    end
  end
end

function draw_ball_trail()
  for i=1,#ball_trail do
    local p=ball_trail[i]
    local c=7
    if p.life<=6 then c=6 end
    if p.life<=3 then c=5 end
    rectfill(p.x,p.y,p.x+1,p.y+1,c)
  end
end

------------------------------
-- EXTRA BALLS (POWERUP#2) --
------------------------------
function update_extra_balls()
  for i=#extra_balls,1,-1 do
    local eb=extra_balls[i]
    eb.dy+=ball.gravity
    eb.x+=eb.dx
    eb.y+=eb.dy
    eb.life-=1

    if eb.y<0 then
      eb.y=0
      eb.dy=-eb.dy*0.95
    elseif eb.y>127 then
      eb.y=127
      eb.dy=-eb.dy*0.95
    end

    if eb.life<=0 then
      del(extra_balls,eb)
    else
      -- collision with player
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

      -- collision or pass AI
      if eb.x+2>ai.x then
        if (eb.x+2>ai.x and eb.x<ai.x+2 and eb.y+2>ai.y and eb.y<ai.y+12) then
          sfx(1)
          eb.dx=-eb.dx
        elseif eb.x>136 then
          local mult=total_score_multiplier()
          score+=3*mult
          del(extra_balls, eb)
        end
      end
    end
  end
end

function draw_extra_balls()
  for eb in all(extra_balls) do
    rectfill(eb.x, eb.y, eb.x+2, eb.y+2, 8)
  end
end

------------------------------
-- POWERUP BUBBLE
------------------------------
function maybe_spawn_bubble()
  if bubble.active then return end
  if score>=next_powerup_score then
    if rnd(1)<spawn_bubble_chance then
      spawn_bubble()
    else
      next_powerup_score+=1
    end
  end
end

function spawn_bubble()
  bubble.active=true
  bubble.life=600
  bubble.spr=1

  bubble.x=64 + rnd(20)-10
  bubble.y=64 + rnd(20)-10

  -- 3 powerups => ~33% each
  local r=rnd(1)
  if r<0.33 then
    bubble.powerup_spr=2  -- 3 extra balls
  elseif r<0.66 then
    bubble.powerup_spr=3  -- x2 score
  else
    bubble.powerup_spr=4  -- freeze AI new
  end

  next_powerup_score+=1
end

function update_bubble()
  if not bubble.active then return end
  bubble.life-=1

  bubble.x+=(rnd(5)-rnd(5))*0.2
  bubble.y+=(rnd(5)-rnd(5))*0.2

  if bubble.y<20 then bubble.y=20 end
  if bubble.y>110 then bubble.y=110 end
  if bubble.x<50 then bubble.x=50 end
  if bubble.x>78 then bubble.x=78 end

  if bubble.life<=0 then
    bubble.active=false
    return
  end

  -- check collisions
  if check_bubble_hit(ball.x,ball.y) then
    pop_bubble()
    return
  end
  for eb in all(extra_balls) do
    if check_bubble_hit(eb.x,eb.y) then
      pop_bubble()
      return
    end
  end
end

function draw_bubble()
  if not bubble.active then return end
  spr(bubble.spr,bubble.x-4,bubble.y-4)
  spr(bubble.powerup_spr,bubble.x-4,bubble.y-4)
end

function check_bubble_hit(bx,by)
  local dx=(bubble.x-(bx+1))
  local dy=(bubble.y-(by+1))
  local dist=sqrt(dx^2+dy^2)
  return(dist<4)
end

function pop_bubble()
  sfx(2)
  bubble.active=false
  bubble.life=0
  spawn_powerup(bubble.powerup_spr)
end

--------------------------------
-- NEW POWERUP #4 LOGIC
--------------------------------
function spawn_powerup(s)
  if s==2 then
    -- #2 => spawn 3 extra red balls
    spawn_extra_balls()
  elseif s==3 then
    -- #3 => x2 multiplier
    powerup_active=true
    powerup_type=2
    powerup_timer=600
  elseif s==4 then
    -- #4 => freeze AI for 10s
    sfx(8)            -- play your sfx(8)
    flash_time=6     -- screen flash for ~10 frames
    ai_frozen_time=300-- freeze 5s
  end
end

function spawn_extra_balls()
  for i=1,3 do
    add(extra_balls,{
      x=ball.x,y=ball.y,
      dx=(1+rnd(2)),
      dy=rnd(1)-0.5,
      life=600
    })
  end
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

------------------------------
-- FLASHING THE SCREEN
------------------------------
function draw_flash()
  if flash_time>0 then
    -- fill the screen with a bright color
    local c=12
    rectfill(0,0,127,127,c)
  end
end

function check_score_for_bubble()
end

------------------------------
-- DRAWING HELPER FUNCTIONS --
------------------------------
function draw_field()
  rectfill(65,0,65,128,1)
  rect(0,0,127,127,1)
end

function draw_paddles()
  -- If AI is frozen, let's blink its color
  if ai_frozen_time>0 then
    local t=flr(time()*10)
    local c=(t%2==0) and 7 or 14 -- blink white/pink
    -- Draw AI with blinking color
    rectfill(ai.x, ai.y, ai.x+2, ai.y+12, c)
  else
    -- normal color for AI
    rectfill(ai.x, ai.y, ai.x+2, ai.y+12, 8)
  end

  -- Player is unaffected
  rectfill(player.x, player.y, player.x+2, player.y+12, 12)
end

function draw_ball()
  rectfill(ball.x, ball.y, ball.x+2, ball.y+2, 10)
end

function draw_score()
  print("Score: "..score,52,4,7)

  local base_mult=base_score_multiplier()
  local t=flr(time()*30)
  local color=(t%30<15) and 12 or 13
  print("(".."X"..base_mult..")",60,12,color)

  if powerup_active and powerup_type==2 then
    local color2=(t%20<10) and 10 or 9
    print_centered("POWERUP x2!",20,color2)
  end
end

--------------------------
-- BACKGROUND FUNCTIONS --
--------------------------
function init_background()
  for i=1,num_shapes_layer1 do
    add(bg_layer1,{
      x=rnd(128),y=rnd(128),
      speed=0.8,
      shape=flr(rnd(3)),
      color=5
    })
  end
  for i=1,num_shapes_layer2 do
    add(bg_layer2,{
      x=rnd(128),y=rnd(128),
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
  circfill(shp.x,shp.y,1,shp.color)
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
