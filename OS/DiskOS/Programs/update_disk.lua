local source = select(1,...)

if not source or source == "-?" then
  printUsage(
    "update_disk <disk>","Updates an outdated LIKO-12 disk"
  )
  return
end


local term = require("terminal")
local eapi = require("Editors")

if source then source = term.resolve(source)..".lk12" else source = eapi.filePath end
if not fs.exists(source) then color(8) print("File doesn't exists") return 1 end
if fs.isDirectory(source) then color(8) print("Couldn't load a directory !") return 1 end

local saveData = fs.read(source)..";"
if not saveData:sub(0,5) == "LK12;" then color(8) print("This is not a valid LK12 file !!") return 1 end

--LK12;OSData;OSName;DataType;Version;Compression;CompressLevel; data"
--local header = "LK12;OSData;DiskOS;DiskGame;V"..saveVer..";"..sw.."x"..sh..";C:"

local nextarg = saveData:gmatch("(.-);")
nextarg() --Skip LK12;

local filetype = nextarg()
if not filetype then color(8) print("Invalid Data !") 1 return end
if filetype ~= "OSData" then
  color(8) print("Can't update '"..filetype.."' files !") return 1
end

local osname = nextarg()
if not osname then color(8) print("Invalid Data !") return 1 end
if osname ~= "DiskOS" then color(8) print("Can't update files from '"..osname.."' OS !") return 1 end

local datatype = nextarg()
if not datatype then color(8) print("Invalid Data !") return 1 end
if datatype ~= "DiskGame" then color(8) print("Can't update '"..datatype.."' from '"..osname.."' OS !") return 1 end

local dataver = nextarg()
if not dataver then color(8) print("Invalid Data !") return 1 end
dataver = tonumber(string.match(dataver,"V(%d+)"))
if not dataver then color(8) print("Invalid Data !") return 1 end
if dataver == _DiskVer then color(8) print("Disk is already up to date !") return 0 end
if dataver > 1 then color(8) print("Can't update disks newer than V1, provided: V"..dataver) return 1 end
if dataver < 1 then color(8) print("Can't update disks older than V1, provided: V"..dataver) return 1 end

local sw, sh = screenSize()

local datares = nextarg()
if not datares then color(8) print("Invalid Data !") return 1 end
local dataw, datah = string.match(datares,"(%d+)x(%d+)")
if not (dataw and datah) then color(8) print("Invalid Data !") return 1 end dataw, datah = tonumber(dataw), tonumber(datah)
if dataw ~= sw or datah ~= sh then color(8) print("This disk is made for GPUs with "..dataw.."x"..datah.." resolution, current GPU is "..sw.."x"..sh) return 1 end

local compress = nextarg()
if not compress then color(8) print("Invalid Data !") return 1 end
compress = string.match(compress,"C:(.+)")
if not compress then color(8) print("Invalid Data !") return 1 end

local clevel = nextarg()
if not clevel then color(8) print("Invalid Data !") return 1 end
clevel = string.match(clevel,"CLvl:(.+)")
if not clevel then color(8) print("Invalid Data !") return 1 end clevel = tonumber(clevel)

--local data = saveData:sub(datasum+1,-1)
local data = ""
for d in nextarg do data = data..d..";" end

if compress ~= "none" then --Decompress
  data = math.decompress(data,compress,clevel)
end

eapi.filePath = source
eapi:clearData()

if dataver == 1 then
  local chunk = loadstring(data)
  setfenv(chunk,{})
  data = chunk()
  for k, id in ipairs(eapi.saveid) do
    if id ~= -1 and data[tostring(id)] and eapi.leditors[k].import then
      if id == "spritesheet" then
        local d = data[id]:gsub("\n","")
        local w,h,imgdata = string.match(d,"LK12;GPUIMG;(%d+)x(%d+);(.+)")
        imgdata = imgdata:sub(0,w*h)
        imgdata = "LK12;GPUIMG;"..w.."x"..h..";"..imgdata..";0;"
        eapi.leditors[k]:import(imgdata)
      else
        if id == "luacode" then data[id] = data[id]:sub(2,-1) end
        eapi.leditors[k]:import(data[tostring(id)])
      end
    end
  end
end

term.execute("save")

color(11) print("Updated to Disk V".._DiskVer.." Successfully")
