stripExtension= /(.*)(?:\.[^/.]+)$/
module.exports= (filename)->
  return filename.replace(stripExtension,'$1')
