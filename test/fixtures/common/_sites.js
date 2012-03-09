var background= __dirname+'/../background';
var sample= __dirname+'/../sample.com';
var map= {
  localhost: background
 ,'127.0.0.1': background
 ,'sample.com': sample
}

exports= module.exports= {
  lookup: function() {
      return map[this.host.name]
    }
  ,paths: [background,sample]
}
