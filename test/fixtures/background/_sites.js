var foreground= __dirname+'/../foreground';
var map= {
  localhost: foreground
 ,'127.0.0.1': foreground
}

exports= module.exports= {
  lookup: function() {
      return map[this.host.name]
    }
  ,paths: [foreground]
}
