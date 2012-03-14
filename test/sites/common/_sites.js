var background= __dirname+'/../background';
var example= __dirname+'/../example.com';
var map= {
  localhost: background
 ,'127.0.0.1': background
 ,'example.com': example
}

exports= module.exports= {
  lookup: function() {
      return map[this.host.name]
    }
  ,paths: [background,example]
}
