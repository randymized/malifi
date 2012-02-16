malifi = require('..')

describe 'Malifi', ->
    it 'should provide its version', ->
      malifi.version.should.match(/^\d+\.\d+\.\d+$/)