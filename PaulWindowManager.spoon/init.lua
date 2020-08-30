screenDimensionFigurer = {}
screenDimensionFigurer.__index = screenDimensionFigurer

-- Metadata
screenDimensionFigurer.name = "PaulWindowsManager"
screenDimensionFigurer.version = "0.1"
screenDimensionFigurer.author = "Paul Krohn <pkrohn@daemonize.com>"
-- obj.homepage = "https://github.com/miromannino/miro-windows-management"
screenDimensionFigurer.license = "MIT - https://opensource.org/licenses/MIT"

function screenDimensionFigurer:init()
  print("Initializing Paul's Windows Manager")
end


function screenDimensionFigurer:new(win, useCurrentSize)
  local self = setmetatable({}, screenDimensionFigurer)

  self.size = {x = 0, y = 0, h = 100, w = 100}

  self.margin = 10

  self.win = win
  self.frame = win:frame()
  local screen = win:screen()
  self.max = screen:frame()
  self.menuBarOffset = win:screen():frame().y

  useCurrentSize = useCurrentSize or false
  print(string.format("use current size: %s", useCurrentSize))
  if useCurrentSize then
   self:guessSize()
  end

  return self

end


function screenDimensionFigurer:guessSize()

  -- print(string.format("the frame we are guessing from: x: %s w: %s y: %s h: %s", self.frame.x, self.frame.w, self.frame.y, self.frame.h))

  local abuts = {
    l = self.frame.x <= self.margin,
    r = self.frame.x + self.frame.w >= self.max.w - self.margin,
    t = self.frame.y <= self.menuBarOffset + self.margin,
    b = self.frame.y + self.frame.h >= self.max.h - self.margin
  }

  -- print(string.format("abutments: l: %s r: %s, t: %s, b: %s", abuts.l, abuts.r, abuts.t, abuts.b))

  if abuts.l and abuts.r then
    self.size.x = 0
    self.size.w = 100
  elseif abuts.l and not abuts.r then
    self.size.x = 0
    self.size.w = (self.frame.w + self.margin * 1.5) / self.max.w * 100
  elseif not abuts.l and abuts.r then
    self.size.x = (self.frame.x - self.margin * 0.5) / self.max.w * 100
    self.size.w = (self.frame.w + self.margin) / self.max.w * 100
  else  -- abuts neither is the remaining case
    self.size.x = (self.frame.x - self.margin * 0.5) / self.max.w * 100
    self.size.w = (self.frame.w + self.margin) / self.max.w * 100
  end

  if abuts.t and abuts.b then
    self.size.y = 0
    self.size.h = 100
  elseif abuts.t and not abuts.b then
    self.size.y = 0
    self.size.h = (self.frame.h + self.margin * 1.5) / self.max.h * 100
  elseif not abuts.t and abuts.b then
    self.size.y = (self.frame.y - self.menuBarOffset - self.margin * 0.5) / self.max.h * 100
    self.size.h = (self.frame.h + self.margin) / self.max.h * 100
  else
    self.size.y = (self.frame.y - self.menuBarOffset - self.margin * 0.5) / self.max.h * 100
    self.size.h = (self.frame.h + self.margin) / self.max.h * 100
  end

  print(string.format("we guessed/calculated: x: %s w: %s y: %s h: %s", self.size.x, self.size.w, self.size.y, self.size.h))
end

function screenDimensionFigurer:changeSize(hw, delta)
  -- self:guessSize()
  xy = 'x'
  if  hw == 'h' then
    xy = 'y'
  end
  requestedSideLength = self.size[hw] + delta
  overage = self.size[xy] + self.size[hw] + delta - 100
  if overage < 0 then
    overage = 0
  end
  self.size[xy] = self.size[xy] - overage
  self.size[hw] = self.size[hw] + delta + overage
  if self.size[hw] >= 100 then
    self.size[xy] = 0
    self.size[hw] = 100
  end
  print(string.format("%s: %s requested %s percent: %s, overage: %s", xy, self.size[xy], hw, requestedSideLength, overage))

end

function screenDimensionFigurer.move(self)

  local offsets = {left = self.margin, right = self.margin, top = self.margin, bottom = self.margin}
  if self.size.x ~= 0 then
    offsets.left = 0.5 * self.margin
  end

  if self.size.x + self.size.w <= 99 then
    offsets.right = 0.5 * self.margin
  end

  if self.size.y ~= 0 then
    offsets.top = 0.5 * self.margin
  end

  if self.size.y + self.size.h <= 99 then
    offsets.bottom = 0.5 * self.margin
  end

  print(string.format("moving to size: (%%) x: %s y: %s w: %s h: %s", self.size.x, self.size.y, self.size.w, self.size.h))

  self.frame.x = (self.max.w * self.size.x / 100) + offsets.left
  self.frame.w = (self.max.w * self.size.w / 100) - offsets.left - offsets.right
  self.frame.y = (self.max.h * self.size.y / 100) + offsets.top + self.menuBarOffset
  self.frame.h = (self.max.h * self.size.h / 100) - offsets.top - offsets.bottom

  self.win:setFrame(self.frame)
end

function screenDimensionFigurer:bindSizes(mappings)
  for _, mapping in pairs(mappings) do
    print(string.format("the mapping is mash: %s, key: %s, size: %s", mapping.mash, mapping.key, mapping.size.w))
    hs.hotkey.bind(mapping.mash, mapping.key, function()
      local sdf = self:new(hs.window.focusedWindow())

      sdf.size.h = mapping.size.h or 100
      sdf.size.w = mapping.size.w or 100
      sdf.size.x = mapping.size.x or 0
      sdf.size.y = mapping.size.y or 0

      sdf:move()
    end)
  end
end

function screenDimensionFigurer:bindChangeSizes(mappings)
  for _, mapping in pairs(mappings) do
    print(string.format("the mapping is mash: %s, key: %s", mapping.mash, mapping.key))
    hs.hotkey.bind(mapping.mash, mapping.key, function()
      local sdf = self:new(hs.window.focusedWindow(), true)
      sdf:changeSize(mapping.hw, mapping.delta)
      sdf:move()
    end)
  end
end

return screenDimensionFigurer
