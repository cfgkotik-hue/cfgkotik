 -- Speed/Fly/Noclip/InfiniteJump
  local LP = game:GetService("Players").LocalPlayer
  local UIS = game:GetService("UserInputService")
  local Settings = getgenv().Settings

  local Movement = {
      Speed = (function() -- speed logic end)(),
      Fly = (function() -- fly logic end)(),
      Jump = (function() -- jump power logic end)(),
      InfiniteJump = (function() -- infinite jump logic end)(),
      Noclip = (function() -- noclip logic end)(),
  }

  return Movemen