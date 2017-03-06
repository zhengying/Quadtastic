local Rectangle = require("Rectangle")
local renderutils = require("Renderutils")
local imgui = require("imgui")
local Text = require("Text")

local Inputfield = {}

local transform = require("transform")

local quads = {
  ul = love.graphics.newQuad( 0, 16, 3, 3, 128, 128),
   l = love.graphics.newQuad( 0, 19, 3, 1, 128, 128),
  ll = love.graphics.newQuad( 0, 29, 3, 3, 128, 128),
   b = love.graphics.newQuad( 3, 29, 1, 3, 128, 128),
  lr = love.graphics.newQuad(29, 29, 3, 3, 128, 128),
   r = love.graphics.newQuad(29, 19, 3, 1, 128, 128),
  ur = love.graphics.newQuad(29, 16, 3, 3, 128, 128),
   t = love.graphics.newQuad( 3, 16, 1, 3, 128, 128),
   c = love.graphics.newQuad( 3, 19, 1, 1, 128, 128),
}

Inputfield.draw = function(state, x, y, w, h, content)
  x = x or state.layout.next_x
  y = y or state.layout.next_y

  local margin_x = 4
  local textwidth = state.style.font and state.style.font:getWidth(content)
  w = w or math.max(32, 2*margin_x + (textwidth or 32))
  h = h or 18

  state.layout.adv_x = w
  state.layout.adv_y = h

  -- Draw border
  love.graphics.setColor(255, 255, 255, 255)
  renderutils.draw_border(state.style.stylesheet, quads, x, y, w, h, 3)

  -- Push state
  love.graphics.push("all")

  -- Restrict printing to the encolsed area
  do
    local abs_x, abs_y = state.transform:project(x + 2, y + 2)
    local abs_w, abs_h = state.transform:project_dimensions(w - 4, h - 4)
    love.graphics.setScissor(abs_x, abs_y, abs_w, abs_h)
  end

  -- Print label
  local margin_y = (h - 16) / 2

  -- Move text start to the left if text width is larger than field width
  local text_x = x + margin_x
  if textwidth + 20 > w - 6 then
    text_x = text_x - (textwidth + 20 - (w-6))
  end

  love.graphics.print(content, text_x, y + margin_y)

  -- Highlight if mouse is over button
  if state and state.mouse and
    imgui.is_mouse_in_rect(state, x, y, w, h)
  then
    love.graphics.setColor(255, 255, 255, 70)
    love.graphics.rectangle("fill", x + 2, y + 2, w - 4, h - 4)
  end

  if state and state.mouse and state.mouse.buttons[1] then
    local mx, my = state.mouse.buttons[1].at_x, state.mouse.buttons[1].at_y
    -- This widget has the keyboard focus if the last LMB click was inside this
    -- widget
    if imgui.is_mouse_in_rect(state, x, y, w, h, mx, my) then
      -- If the LMB was pressed in the last frame, set the cursor position
      if state.mouse.buttons[1].presses > 0 then
        -- Set the cursor position
        -- NYI
      end

      -- Change the cursor position based on special key presses
      if imgui.was_key_pressed(state, "left") then
        state.input_field.cursor_pos = math.max(0, state.input_field.cursor_pos - 1)
      end
      if imgui.was_key_pressed(state, "right") then
        state.input_field.cursor_pos = math.min(#content, state.input_field.cursor_pos + 1)
      end
      if imgui.was_key_pressed(state, "home") then
        state.input_field.cursor_pos = 0
      end
      if imgui.was_key_pressed(state, "end") then
        state.input_field.cursor_pos = #content
      end

      -- Remove character to the left of the cursor
      if imgui.was_key_pressed(state, "backspace") then
        if state.input_field.cursor_pos > 0 then
          content = string.sub(content, 1 , state.input_field.cursor_pos - 1) ..
                    string.sub(content, state.input_field.cursor_pos + 1, -1)
          -- Reduce cursor position by 1
          state.input_field.cursor_pos = math.max(0, state.input_field.cursor_pos - 1)
        end
      end
      -- Remove character to the right of the cursor
      if imgui.was_key_pressed(state, "delete") then
        if state.input_field.cursor_pos < #content then
          content = string.sub(content, 1 , state.input_field.cursor_pos) ..
                    string.sub(content, state.input_field.cursor_pos + 2, -1)
          -- The cursor position does not change in this case
        end
      end

      -- Display the cursor
      state.input_field.cursor_dt = state.input_field.cursor_dt + state.dt
      if state.input_field.cursor_dt > 1 then
        state.input_field.cursor_dt = state.input_field.cursor_dt - 1
      end
      if state.input_field.cursor_dt > .5 then
        local width = Text.min_width(state, string.sub(
          content, 1, state.input_field.cursor_pos))
        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.line(text_x + width, y + 4, text_x + width, y + h - 4)
      end

      local newtext = state.keyboard.text or ""
      content = string.sub(content, 1 , state.input_field.cursor_pos) ..
                newtext .. 
                string.sub(content, state.input_field.cursor_pos + 1, -1)
      -- Advance the cursor position by the lenght of the added text
      state.input_field.cursor_pos = math.min(#content, state.input_field.cursor_pos + #newtext)

    end
  end
  -- Restore state
  love.graphics.pop()
  return content
end

return Inputfield