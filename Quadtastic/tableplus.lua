local table = table

-- Returns table[key][...]
-- That is, get(t, k1, k2, k3) is another way to write t[k1][k2][k3]
-- but there is no built-in way in Lua to do this in an automated way
function table.get(tab, key, ...)
  if tab == nil then return nil
  elseif select("#", ...) == 0 then
    return tab[key]
  else
    -- apply recursively
    return table.get(tab[key], ...)
  end
end

-- Sets table[key][...] to value
-- That is, _set(t, v, k1, k2, k3) is another way to write t[k1][k2][k3] = v
-- but there is no built-in way in Lua to do this in an automated way
function table.set(tab, value, key, ...)
  if value == nil then return
  elseif select("#", ...) == 0 then
    tab[key] = value
  else
    -- apply recursively
    table.set(tab[key], value, ...)
  end
end

-- Tries to find the list of keys that point to a specific value.
-- Performs a depth-first-search through the given table.
-- Therefore matching items that are nested deeper in the table might be
-- returned even though matching items on higher levels exist.
function table.find_key(tab, value)
  for k,v in pairs(tab) do
    if v == value then return k
    elseif type(v) == "table" then -- search recursively
      -- Return a list of keys
      local result = {table.find_key(v, value)}
      if #result > 0 then return k, unpack(result) end
    end
  end
  return nil
end

function table.keys(tab)
  local keys = {}
  for k, _ in pairs(tab) do
    table.insert(keys, k)
  end
  return keys
end

function table.values(tab)
  local values = {}
  for _, v in pairs(tab) do
    table.insert(values, v)
  end
  return values
end

return table