local imageCache = {}

function ImageGetData(image)
    return imageCache[image]
end

function MakeNewImage(path)
    local image = love.graphics.newImage(path) -- load spritesheet
    local imagedata = love.image.newImageData(path) 
    imageCache[image] = imagedata
    return image
end