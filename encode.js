
function encode(a, b) {
    x = a + 5
    y = b + 10
  var intermediatePaddingX
      var intermediatePaddingY
    
     intermediatePaddingX = x.toString(16).padStart(16, "0").padEnd(32, "0")
    intermediatePaddingY = y.toString(16).padStart(16, "0").padEnd(32, "0")
    // This implements a very naive encoding of x and y
    
        
    return "0x" + intermediatePaddingX + intermediatePaddingY;
  }
  
  exports.encode = encode;