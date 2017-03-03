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
local Frame = require("Frame")
local Layout = require("Layout")
local Scrollpane = require("Scrollpane")

-- Make the state variables local unless we are in debug mode
if not _DEBUG then
  local gui_state
  local state
end

local transform = require('Quadtastic/transform')

-- Cover love transformation functions
do
  local lg = love.graphics
  lg.translate = transform.translate
  lg.rotate = transform.rotate
  lg.scale = transform.scale
  lg.shear = transform.shear
  lg.origin = transform.origin
  lg.push = transform.push
  lg.pop = transform.pop
end

-- Scaling factor
local scale = 2

local set_opened_file = function(state, filename_or_data, filepath)
  success, more = pcall(love.graphics.newImage, filename_or_data)
  if success then
    state.image = more
    state.filepath = filepath or filename_or_data
  else
    print(more)
  end
end

local reset_view = function(state)
  state.scrollpane_state = Scrollpane.init_scrollpane_state()
  state.display.zoom = 1
  if state.image then
    Scrollpane.set_focus(state.scrollpane_state, {
      x = 0, y = 0, 
      w = state.image:getWidth(), h = state.image:getHeight()
    })
  end
end

function love.load()
  -- Initialize the state
  state = {
    filepath = "res/style.png", -- the path to the file that we want to edit
    image = nil, -- the loaded image
    display = {
      zoom = 1, -- additional zoom factor for the displayed image
    },
    scrollpane_state = nil,
  }

  love.window.setMode(800, 600, {resizable=true, minwidth=400, minheight=300})

  love.graphics.setDefaultFilter("nearest", "nearest")

  font = love.graphics.newFont("res/m5x7.ttf", 16)
  love.graphics.setFont(font)

  local stylesprite = love.graphics.newImage("res/style.png")

  backgroundcanvas = love.graphics.newCanvas(8, 8)
  do
    -- Create a canvas with the background texture on it
    backgroundquad = love.graphics.newQuad(48, 16, 8, 8, 128, 128)
    backgroundcanvas:setWrap("repeat", "repeat")
    backgroundcanvas:renderTo(function()
      love.graphics.draw(stylesprite, backgroundquad)
    end)
  end

  love.keyboard.setKeyRepeat(true)
  gui_state = imgui.init_state(transform)
  gui_state.style.font = font
  gui_state.style.stylesheet = stylesprite
end

local count = 0
function love.draw()
  imgui.begin_frame(gui_state)
  love.graphics.scale(scale, scale)

  love.graphics.clear(203, 222, 227)
  local w, h = gui_state.transform.unproject_dimensions(
    love.graphics.getWidth(), love.graphics.getHeight()
  )
  Layout.start(gui_state, 2, 2, w - 4, h - 4)

    Layout.start(gui_state)
      Label.draw(gui_state, nil, nil, nil, nil, "File:")
      Layout.next(gui_state, "-", 2)

      state.filepath = Inputfield.draw(gui_state, nil, nil, 160, nil, state.filepath)
      Layout.next(gui_state, "-", 2)

      local pressed, active = Button.draw(gui_state, nil, nil, nil, nil, "Doggo!!")
      if pressed then 
        set_opened_file(state, state.filepath)
        reset_view(state)
      end
    Layout.finish(gui_state, "-")

    Layout.next(gui_state, "|", 2)

    Frame.start(gui_state, nil, nil, nil, gui_state.layout.max_h - 30)
    if state.image then
      state.scrollpane_state = Scrollpane.start(gui_state, nil, nil, nil, 
        nil, state.scrollpane_state
      )
        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.scale(state.display.zoom, state.display.zoom)

        -- Draw background pattern
        local img_w, img_h = state.image:getDimensions()
        backgroundquad = love.graphics.newQuad(0, 0, img_w, img_h, 8, 8)
        love.graphics.draw(backgroundcanvas, backgroundquad)

        love.graphics.draw(state.image)
        -- Draw a bright pixel where the mouse is
        love.graphics.setColor(255, 255, 255, 255)
        do
          local mx, my = gui_state.transform.unproject(gui_state.mouse.x, gui_state.mouse.y)
          mx, my = math.floor(mx - .5), math.floor(my - .5)
          love.graphics.rectangle("fill", mx, my, 1, 1)
        end

        gui_state.layout.adv_x = img_w * state.display.zoom
        gui_state.layout.adv_y = img_h * state.display.zoom
      Scrollpane.finish(gui_state, state.scrollpane_state)
    else
      -- Put a label in the center of the frame
      local y = gui_state.layout.max_h / 2 - gui_state.style.font:getHeight()
      Label.draw(gui_state, nil, y, gui_state.layout.max_w, nil,
                 "no image :(", {alignment = ":"})
    end
    Frame.finish(gui_state)

    Layout.next(gui_state, "|", 2)

    Layout.start(gui_state)
      do
        local pressed = Button.draw(gui_state, nil, nil, 13, 14, "+")
        if pressed then
          state.display.zoom = math.min(12, state.display.zoom + 1)
        end
      end
      Layout.next(gui_state, "-")
      do
        local pressed = Button.draw(gui_state, nil, nil, 13, 14, "-")
        if pressed then
          state.display.zoom = math.max(1, state.display.zoom - 1)
        end
      end
    Layout.finish(gui_state, "-")

  Layout.finish(gui_state, "|")

  imgui.end_frame(gui_state)
end

function love.filedropped(file)
  -- The love filesystem blocks access to all files outside certain directories
  -- so we need a little workaround to use the dropped file.

  if file:open('r') then
    local data = file:read()
    file:close()
    success, data = pcall(function() 
      return love.image.newImageData(
        love.filesystem.newFileData(data, 'img', 'file'))
    end)
    if success and data then
      set_opened_file(state, data, file:getFilename())
      reset_view(state)
    end
  end
end

function love.mousepressed(x, y, button)
  x, y = x, y
  imgui.mousepressed(gui_state, x, y, button)
end

function love.mousereleased(x, y, button)
  x, y = x, y
  imgui.mousereleased(gui_state, x, y, button)
end

function love.mousemoved(x, y, dx, dy)
  x ,  y = x ,  y
  dx, dy = dx, dy
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
