var malifi = require('../');

describe('Malifi', function(){
  it('should provide its version', function() {
    malifi.version.should.match(/^\d+\.\d+\.\d+$/);
  });
});
