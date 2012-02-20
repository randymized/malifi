var site= __dirname+'/../site';
var map= {
  localhost: site
 ,'127.0.0.1': site
}

exports= module.exports= {
  lookup: function() {
      return map[this.host.name]
    }
  ,paths: [site]
}
