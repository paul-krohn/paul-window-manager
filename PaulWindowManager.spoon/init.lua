pwm = {}
pwm.__index = pwm

-- Metadata
pwm.name = "PaulWindowsManager"
pwm.version = "0.1"
pwm.author = "Paul Krohn <pkrohn@daemonize.com>"
-- obj.homepage = "https://github.com/miromannino/miro-windows-management"
pwm.license = "MIT - https://opensource.org/licenses/MIT"

function pwm:init()
  print("Initializing Paul's Windows Manager")
end


return pwm
