foreground= __dirname+'/../foreground';
map=
  localhost: foreground
  '127.0.0.1': foreground

exports= module.exports=
  lookup: ()->
    return map[this.host.name]
  paths: [foreground]
