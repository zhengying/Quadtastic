local inspect = require("lib/inspect")

unpack = unpack or table.unpack

if os.getenv("DEBUG") then
  require("lib/lovedebug/lovedebug")
  require("debugconfig")
end

local imgui = require("imgui")

local Button = require("Button")
local Inputfield = require("Inputfield")
local Label = require("Label")
local gui_state
local state = {
  filepath = "", -- the path to the file that we want to edit
  image = nil, -- the loaded image
}

-- Scaling factor
local scale = 2

function love.load()
  love.graphics.setDefaultFilter("nearest", "nearest")

  font = love.graphics.newFont("res/m5x7.ttf", 16)
  love.graphics.setFont(font)

  stylesprite = love.graphics.newImage("res/style.png")

  love.keyboard.setKeyRepeat(true)
  gui_state = imgui.init_state()
  gui_state.style.font = font
end

local count = 0
function love.draw()
  imgui.begin_frame(gui_state)
  love.graphics.scale(scale, scale)

  love.graphics.clear(203, 222, 227)
  Label.draw(gui_state, 2, 2, nil, nil, "File:")
  state.filepath = Inputfield.draw(gui_state, 30, 2, 160, nil, state.filepath)

  local pressed, active = Button.draw(gui_state, 200, 2, nil, nil, "Doggo!!")
  if pressed then 
    success, more = pcall(love.graphics.newImage, state.filepath)
    if success then
      state.image = more
    else
      print(more)
    end
  end
  if state.image then
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.draw(state.image, 2, 32)
  end

  imgui.end_frame(gui_state)
end

local function unproject(x, y)
  return x / scale, y / scale
end

function love.mousepressed(x, y, button)
  x, y = unproject(x, y)
  imgui.mousepressed(gui_state, x, y, button)
end

function love.mousereleased(x, y, button)
  x, y = unproject(x, y)
  imgui.mousereleased(gui_state, x, y, button)
end

function love.mousemoved(x, y, dx, dy)
  x ,  y = unproject(x ,  y)
  dx, dy = unproject(dx, dy)
  imgui.mousemoved(gui_state, x, y, dx, dy)
end

function love.wheelmoved(x, y)
  imgui.wheelmoved(gui_state, x, y)
end

function love.keypressed(key, scancode, isrepeat)
  imgui.keypressed(gui_state, key, scancode, isrepeat)
end

function love.keyreleased(key, scancode)
  imgui.keyreleased(gui_state, key, scancode, isrepeat)
end

function love.textinput(text)
  imgui.textinput(gui_state, text)
end

function love.update(dt)
  imgui.update(state, dt)
end
