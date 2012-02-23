var background= __dirname+'/../background';
var map= {
  localhost: background
 ,'127.0.0.1': background
}

exports= module.exports= {
  lookup: function() {
      return map[this.host.name]
    }
  ,paths: [background]
}
