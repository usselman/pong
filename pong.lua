-- Valley Pong 
-- Author: Shirish Sarkar

-- Game variables
player = { x = 2, y = 64, speed = 4 }
ai = { x = 125, y = 64, speed = 4, difficulty = 0.5 }
ball = { x = 64, y = 64, dx = 2, dy = 2 }
score = 0

function _init()
    cls()
end

function _update()
    -- Player movement
    if btn(0) then player.y -= player.speed end -- Up
    if btn(1) then player.y += player.speed end -- Down

    -- Keep player paddle on screen
    player.y = mid(0, player.y, 120)

    -- AI movement (gets smarter over time)
    ai_target_y = ball.y - 4
    ai.y += (ai_target_y - ai.y) * ai.difficulty
    ai.y = mid(0, ai.y, 120)

    -- Update ball position
    ball.x += ball.dx
    ball.y += ball.dy

    -- Ball collision with top and bottom
    if ball.y < 0 or ball.y > 127 then
        ball.dy = -ball.dy
    end

    -- Ball collision with player paddle
    if ball.x < player.x + 2 and
       ball.y + 2 > player.y and
       ball.y < player.y + 16 then
        ball.dx = -ball.dx
        ball.x = player.x + 2
        score += 1
        -- Increase difficulty
        ai.difficulty = min(1, ai.difficulty + 0.02)
        ai.speed += 0.05
    end

    -- Ball collision with AI paddle
    if ball.x + 2 > ai.x and
       ball.y + 2 > ai.y and
       ball.y < ai.y + 16 then
        ball.dx = -ball.dx
        ball.x = ai.x - 2
    end

    -- Ball out of bounds (player misses)
    if ball.x < 0 then
        -- Reset ball
        ball.x = 64
        ball.y = 64
        ball.dx = 2
        ball.dy = 2
        -- Reset AI difficulty
        ai.difficulty = 0.25
        ai.speed = 1
        score = 0
    end

    -- Ball out of bounds (AI misses)
    if ball.x > 128 then
        ball.dx = -ball.dx
    end
end

function _draw()
    cls()
    -- Draw middle barrier
    rectfill(65, 0, 65, 128, 1);
    -- Draw screen barrier
    rect(0, 0, 127, 127, 1);
    -- Draw player paddle
    rectfill(player.x, player.y, player.x + 2, player.y + 12, 12);
    -- Draw AI paddle
    rectfill(ai.x, ai.y, ai.x + 2, ai.y + 12, 8);
    -- Draw ball
    rectfill(ball.x, ball.y, ball.x + 2, ball.y + 2, 10);
    -- Draw score
    print("Score: "..score, 54, 4, 7);
end
