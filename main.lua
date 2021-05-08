-- push is a library that will allow us to draw our game at a virtual
-- resolution, instead of however large our window is; used to provide
-- a more retro aesthetic


-- https://github.com/Ulydev/push
push = require 'push'
Class = require 'class'


require 'Paddle'

require 'Ball'


WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

PADDLE_SPEED = 200


function love.load()
    -- love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT,{
    --     fullscreen = false,
    --     resizable = false,
    --     vsync = true
    -- })
    math.randomseed(os.time())

    love.window.setTitle("my game")
    love.graphics.setDefaultFilter('nearest','nearest')

    smallFont = love.graphics.newFont('font.ttf',8)
    largeFont = love.graphics.newFont('font.ttf', 16)
    scoreFont = love.graphics.newFont('font.ttf', 32)
    love.graphics.setFont(smallFont)

    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = false,
        vsync = true
    })

    sounds = {
        ['paddle_hit'] = love.audio.newSource('sounds/paddle_hit.wav','static'),
        ['score'] = love.audio.newSource('sounds/score.wav','static'),
        ['wall_hit'] = love.audio.newSource('sounds/wall_hit.wav','static')
    }


    -- initialize score variables, used for rendering on the screen
    player1Score = 0
    player2Score = 0

    player1 = Paddle(10, 50, 5, 40)
    player2 = Paddle(VIRTUAL_WIDTH-10, VIRTUAL_HEIGHT-50, 5,40)


    ball = Ball(VIRTUAL_WIDTH/2-2, VIRTUAL_HEIGHT/2-2, 4,4)


    servingPlayer = 1

    winningPlayer = 0
    -- game state variable used to transition between different parts of the game
    -- (beginning, menus, main game, high score list, etc.)
    -- we will use this to determine behavior during render and update
    -- start = beginning of the game
    -- serve = waiting on key press to serve the ball
    -- play  = ball is in play
    -- done = game is over, with a victor, ready to restart
    gameState = 'start'


    -- a table we'll use to keep track of wwhich keys have been pressed this frame
    -- to get around the fact that LOVE's default callback wont let use
    -- test for input from within other functions
    love.keyboard.keysPressed = {}
end

function love.resize(w,h)
    push:resize(w,h)
end

function love.update(dt)
    if gameState == 'start' then
        -- pressing enter will begin the game
        if love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return') then
            gameState = 'serve'
        end
    elseif gameState == 'serve' then
        if love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return') then
            gameState = 'play'

            --before switching to play initialize ball's velocity based
            -- on player who last scored
            
            ball.dy = math.random(-50,50)
            if servingPlayer == 1 then
                ball.dx = math.random(140,200)
            else
                ball.dx = -math.random(140,200)
            end
        end
    elseif gameState == 'play' then
        print("ttt")
        -- detect ball collision with paddles, reversing dx if true around
        -- slightly increasing it, then altering the dy based on the positions
        -- at which it collided, then playing a sound effect

        if ball:collides(player1) then
            ball.dx = -ball.dx*1.03
            ball.x = player1.x+5

            -- formula for adjusting the angle of the ball when hit by the
            -- paddle; if the ball hits the paddle above itself
            -- midpoint, then the dy should be negative
            -- and scaled by how far above the midpoint in hits
            -- opposite true for below the midpoint
            -- only the dy should be positive

            if ball.y < player1.y + player1.height/2 then
                ball.dy = -math.random(50,100)*(player1.y+(player1.height/2)) / ball.y
            else
                ball.dy = math.random(50,100) * (player1.y+player1.height) / ball.y
            end

            sounds['paddle_hit']:play()
        end
        if ball:collides(player2) then
            ball.dx = -ball.dx*1.03
            ball.x = player2.x - 4

            if ball.y < player2.y + player2.height / 2 then
                ball.dy = -math.random(50, 100) * (player2.y + 
                    (player2.height / 2)) / ball.y
            else
                ball.dy = math.random(50, 100) * 
                    (player2.y + player2.height) / ball.y
            end

            sounds['paddle_hit']:play()
        end
        --detect upper and lower screen boundary collision, playing a sound effect and reversing dy if true

        if ball.y <= 0 then
            ball.y = 0
            ball.dy = -ball.dy
            sounds['wall_hit']:play()
        end

        if ball.y>=VIRTUAL_HEIGHT-4 then
            ball.y = VIRTUAL_HEIGHT-4
            ball.dy = -ball.dy
            sounds['wall_hit']:play()
        end

        -- if we reach the left or right corner, go back to serve
        -- and update the score and serving player
        if ball.x < 0 then
            servingPlayer = 1
            player2Score = player2Score +1
            sounds['score']:play()

            -- if we've reached a score of 10, the game is over;
            -- set the state to done so we can show victory message
            if player2Score == 10 then
                winningPlayer = 2
                gameState = 'done'
            else
                gameState = 'serve'
                ball:reset()
            end
        end
    
        if ball.x > VIRTUAL_WIDTH then
            servingPlayer = 2
            player1Score = player1Score +1
            sounds['score']:play()
            
            if player1Score ==3 then
                winningPlayer = 1
                gameState = 'done'
            else
                gameState = 'serve'
                ball:reset()
            end
        end

        ball:update(dt)
    elseif gameState == 'done' then
        -- game is simply in restart phase here, but will set the serving
        -- player to the opponent of whomever won for fairness!
        if love.keyboard.wasPressed('return') then
            gameState = 'serve'

            ball:reset()

            player1Score = 0
            player2Score = 0

            if winningPlayer == 1 then
                servingPlayer = 2
            else
                servingPlayer = 1
            end
        end

    end


    -- if we reach left or right endge of the screen, go back to start and update the score


    -- paddles can move no matter the state we're in

    -- player 1 movement
    if love.keyboard.isDown('w') then
        -- add negative paddle speed 
        player1.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('s') then
        player1.dy = PADDLE_SPEED
    else 
        player1.dy = 0
    end

    if love.keyboard.isDown('up') then
        player2.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('down') then
        player2.dy = PADDLE_SPEED
    else
        player2.dy = 0
    end

 

    player1:update(dt)
    player2:update(dt)




    -- clear the table for keys pressed, as the frame has ended
    love.keyboard.keysPressed = {}
end

function love.keypressed(key)
    -- keys can be accessed by string name
    if key == 'escape' then
        love.event.quit()
    end
    love.keyboard.keysPressed[key] = true
end

--[[
    Caled after update by LOVE2D, used to draw anything to the screen,
    updated or otherwise.
]]


function love.draw()
    -- begin rendering at virtual resolution
    push:apply('start')

    love.graphics.clear(0.3, 0.2, 0.1, 1.0)


    if gameState == 'start' then
        love.graphics.setFont(smallFont)
        love.graphics.printf("Welcome to Pong!", 0,10, VIRTUAL_WIDTH,'center')
        love.graphics.printf("Press enter to begin!", 0, 20, VIRTUAL_WIDTH,'center')
    elseif gameState == 'serve' then
        -- UI messages
        love.graphics.setFont(smallFont)
        love.graphics.printf('Player ' .. tostring(servingPlayer) .. "'s serve!", 0 ,10, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Press Enter to serve!', 0, 20, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'play' then
        -- no UI messaged to display in play
    elseif gameState == 'done' then
        -- UI messages
        love.graphics.setFont(largeFont)
        love.graphics.printf('Player ' .. tostring(winningPlayer) .. ' wins!', 0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(smallFont)
        love.graphics.printf("Press Enter to restart!", 0, 30, VIRTUAL_WIDTH, 'center')
    end

    displayScore()

    player1:render()
    player2:render()
    ball:render()

    displayFps()
    -- -- first paddle
    -- love.graphics.rectangle('fill', 10, player1Y, 5,20)
    -- -- second paddle
    -- love.graphics.rectangle('fill', VIRTUAL_WIDTH-10, player2Y, 5, 20)
    -- -- ball
    -- love.graphics.rectangle('fill', ballX, ballY, 4,4)

    -- end rendering at virtual resolution
    push:apply('end')
end

function displayFps()
    fps = love.timer.getFPS()

    love.graphics.setFont(smallFont)
    love.graphics.setColor(1, 0.2, 0.2, 1.0)
    love.graphics.print(tostring(fps), 10,10)
    love.graphics.setColor(1,1,1, 1.0)
end

function displayScore()
    love.graphics.setFont(scoreFont)
    love.graphics.print(tostring(player1Score), VIRTUAL_WIDTH/2-50, VIRTUAL_HEIGHT/3)
    love.graphics.print(tostring(player2Score), VIRTUAL_WIDTH/2+30, VIRTUAL_HEIGHT/3)
end


function love.keyboard.wasPressed(key)
    if love.keyboard.keysPressed[key] then
        return true
    else
        return false
    end
end