PaulWindowManager = {}
PaulWindowManager.__index = PaulWindowManager

-- Metadata
PaulWindowManager.name = "PaulWindowManager"
PaulWindowManager.version = "0.2"
PaulWindowManager.author = "Paul Krohn <pkrohn@daemonize.com>"
-- obj.homepage = "https://github.com/paul-krohn/paul-window-manager"
PaulWindowManager.license = "MIT - https://opensource.org/licenses/MIT"

PaulWindowManager.log = hs.logger.new('pwm', 'debug')

function PaulWindowManager:init()
  print("Initializing Paul's Window Manager")
end


function PaulWindowManager:new(win, useCurrentSize, screen)
  local self = setmetatable({}, PaulWindowManager)

  self.size = {x = 0, y = 0, h = 100, w = 100}

  self.margin = 10

  self.win = win
  self.frame = win:frame()
  local screen = screen or win:screen()
  self.max = screen:frame()
  self.menuBarOffset = win:screen():frame().y

  useCurrentSize = useCurrentSize or false
  self.log.df("use current size: %s", useCurrentSize)
  if useCurrentSize then
   self:guessSize()
  end

  return self

end


function PaulWindowManager:guessSize()

  self.log.df("the frame we are guessing from: x: %s w: %s y: %s h: %s", self.frame.x, self.frame.w, self.frame.y, self.frame.h)

  local abuts = {
    l = self.frame.x <= self.margin,
    r = self.frame.x + self.frame.w >= self.max.w - self.margin,
    t = self.frame.y <= self.menuBarOffset + self.margin,
    b = self.frame.y + self.frame.h >= self.max.h - self.margin
  }

  self.log.df("abutments: l: %s r: %s, t: %s, b: %s", abuts.l, abuts.r, abuts.t, abuts.b)

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

  self.log.df("we guessed/calculated: x: %s w: %s y: %s h: %s", self.size.x, self.size.w, self.size.y, self.size.h)
end

function PaulWindowManager:changeSize(hw, delta)

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
  self.log.df("%s: %s requested %s percent: %s, overage: %s", xy, self.size[xy], hw, requestedSideLength, overage)

end

function PaulWindowManager:move()

  self.log.d(string.format("window %s is going on screen %s", self.win:id(), self.win:screen():name()))
  self.log.d(string.format("screen max -- x: %s y: %s h: %s w: %s", self.max.x, self.max.y, self.max.h, self.max.w))

  local offsets = {left = self.margin, right = self.margin, top = self.margin, bottom = self.margin}

  if self.size.x >= 1 then
    offsets.left = 0.5 * self.margin
  end

  if self.size.x + self.size.w <= 99 then
    offsets.right = 0.5 * self.margin
  end

  if self.size.y >= 1 then
    offsets.top = 0.5 * self.margin
  end

  if self.size.y + self.size.h <= 99 then
    offsets.bottom = 0.5 * self.margin
  end

  self.log.df("moving to size: (%%) x: %s y: %s w: %s h: %s", self.size.x, self.size.y, self.size.w, self.size.h)
  self.log.df("margin offsets are: left: %s right: %s top: %s bottom: %s", offsets.left, offsets.right, offsets.top, offsets.bottom)

  self.frame.x = self.max.x + (self.max.w * self.size.x / 100) + offsets.left
  self.frame.w = (self.max.w * self.size.w / 100) - offsets.left - offsets.right
  self.frame.y = self.max.y + (self.max.h * self.size.y / 100) + offsets.top
  self.frame.h = (self.max.h * self.size.h / 100) - offsets.top - offsets.bottom

  self.log.df("moving frame to x: %s y: %s h: %s w: %s", self.frame.x, self.frame.y, self.frame.h, self.frame.w)
  self.win:setFrame(self.frame)
end

function PaulWindowManager:bindKeys(args)
  local sizes = args.sizes or {}
  local deltas = args.deltas or {}
  local stack = args.stack or {}
  local appDefaults = args.appDefaults or {}
  local next = args.next or {}
  local mic = args.mic or {}

  for _, mapping in pairs(sizes) do
    self.log.df("the mapping is mash: %s, key: %s, size: %s", mapping.mash, mapping.key, mapping.size.w)
    hs.hotkey.bind(mapping.mash, mapping.key, function()
      local pwm = self:new(hs.window.focusedWindow())

      pwm.size.h = mapping.size.h or 100
      pwm.size.w = mapping.size.w or 100
      pwm.size.x = mapping.size.x or 0
      pwm.size.y = mapping.size.y or 0

      pwm:move()
    end)
  end
  for _, mapping in pairs(deltas) do
    self.log.df("the mapping is mash: %s, key: %s", mapping.mash, mapping.key)
    hs.hotkey.bind(mapping.mash, mapping.key, function()
      local pwm = self:new(hs.window.focusedWindow(), true)
      pwm:changeSize(mapping.hw, mapping.delta)
      pwm:move()
    end)
  end

  for _, mapping in pairs(stack) do
    self.log.df("mapping stacker, the mash is ", mapping.mash)
    hs.hotkey.bind(mapping.mash, mapping.key, function()
      local win = hs.window.focusedWindow()
      self:stackWindows(win)
    end)
  end
  if appDefaults and appDefaults.positions and appDefaults.mash and appDefaults.key then
    hs.hotkey.bind(appDefaults.mash, appDefaults.key, self:appDefaultPositions(appDefaults.positions))
  end

  for _, mapping in pairs(next) do
    hs.hotkey.bind(mapping.mash, mapping.key, self:moveWindowtoNextScreen())
  end

  for _, mapping in pairs(mic) do
    self.log.df("mapping %s + %s to mic toggle", table.concat(mapping.mash, "+"), mapping.key)
    hs.hotkey.bind(mapping.mash, mapping.key, self:micMuteToggle(mapping.mic))
  end
end

function PaulWindowManager:appDefaultPositions(appPositions)
  function theCallback()
    for appName, position in pairs(appPositions) do
      thisApp = hs.application.get(appName)
      if thisApp == nil then
        self.log.df("skipping nil app: %s", appName)
      else
        for title, appWindow in pairs(thisApp:allWindows()) do
          local pwm = PaulWindowManager:new(appWindow)

          pwm.size.h = position.h or 100
          pwm.size.w = position.w or 100
          pwm.size.x = position.x or 0
          pwm.size.y = position.y or 0

          pwm:move()

        end
      end
    end
  end
  return theCallback
end

function PaulWindowManager:stackWindows(win)
  -- find all windows in the app of the frontmost window
  -- make all the windows in the app the same size
  local f = win:frame()
  local app = win:application()
  local windows = app:allWindows()
  for i, window in ipairs(windows) do
    window:setFrame(f)
  end
end

function PaulWindowManager:moveWindowtoNextScreen()
  self.log.vf("creating a function for moving a window to the next screen")
  return function()
    local win = hs.window.focusedWindow()
    local scr = win:screen()
    local nextScreen = scr:next()
    self.log.df("moving window" .. win:id() .. " to screen, " .. nextScreen:name())
    self.max = nextScreen:frame()
    pwm = PaulWindowManager:new(win, false, nextScreen)
    win:moveToScreen(nextScreen)
    if nextScreen:fullFrame().h < scr:fullFrame().h or nextScreen:fullFrame().w < scr:fullFrame().w then
      -- next screen is smaller; make it full screen.
      pwm.size = { h = 100, w = 100, x = 0, y = 0 }
    end
    pwm:move()
  end
end

function PaulWindowManager:micMuteToggle(micName)
  return function()
    local currentMic = hs.audiodevice.defaultInputDevice()
    if micName then
      currentMic = hs.audiodevice.findDeviceByName(micName)
    end

    currentMic:setMuted(not currentMic:muted())
    local verb = currentMic:muted() and " " or " un-"
    hs.alert.show(currentMic:name() .. verb .. "muted")

  end
end

return PaulWindowManager
