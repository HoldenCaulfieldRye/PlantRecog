var assert = require("assert")

// Sample Test 1: A failing test
describe('Array', function(){
  describe('#indexOf()', function(){
    it('should return -1 when the value is not present', function(){
      [1,2,3].indexOf(5).should.equal(-1);
      [1,2,3].indexOf(0).should.equal(-1);
    })
  })
})

// Sample Test 2: A passing test
describe('Array', function(){
  describe('#indexOf()', function(){
    it('should return -1 when the value is not present', function(){
      assert.equal(-1, [1,2,3].indexOf(5));
      assert.equal(-1, [1,2,3].indexOf(0));
    })
  })
})


describe('GraphicServer', function(){
  describe('#graphic_config()', function(){
    it('should not return Invalid Config File error', function(){
      assert.not.equal({}, graphic_config('../env/graphic_dev_env.conf'));
    })
  })
})
