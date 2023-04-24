// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Obfuscated2 {
    //Fallback function called when tx data first 4 bytes doesnt match any function selector.
    //It is a function takes two inputs and performs the caltulation 18 * x * x + 32 * y + 24
    //It has its own custom ABI where tx data it accepts has a specific encoding
    //X and Y values have to be encoded as per descibed in ../encode.js

    // 0000000000000005         0000000000000000       000000000000000b        0000000000000000
    // ^8 bytes of x+5 in hex   ^padding               ^8 bytes of y+10 in hex ^padding
    fallback(bytes calldata data) external returns (bytes memory) {
        //get first 8 bytes of tx data and separate them into a new array
        bytes memory xBytes = new bytes(8);
        for (uint256 i = 0; i < 8; ++i) {
            xBytes[i] = data[i];
        }
        //convert to uint and decode it with the -5
        uint256 x = bytesToUint(xBytes) - 5;

        //first8 was x, next 8 bytes was padding, bytes 17-23 are value y.(24-32 are padding too)
        //separate 17th byte to 23rd byte in a new array
        bytes memory yBytes = new bytes(8);
        for (uint256 i = 0; i < 8; ++i) {
            yBytes[i] = data[i + 16];
        }
        //convert array to uint, decode with -10.
        uint256 y = bytesToUint(yBytes) - 10;

        return abi.encodePacked(18 * x * x + 32 * y + 24);
    }

    //Function that takes a bytes array of size 8, and transforms it into a uint.
    function bytesToUint(bytes memory b) public pure returns (uint256) {
        require(b.length == 8, "Invalid byte array length");
        uint256 number;
        for (uint256 i = 0; i < b.length; i++) {
            number = number + uint256(uint8(b[i])) * (2 ** (8 * (8 - (i + 1))));
            //In a sequence of 8 bytes ex: 0x0000000123456789
            //The formula gets each byte and transforms it into its numerical value
            //We are aware that in hex format each value can represent 16 different values from 0 to F.
            //But how do we calculate the value of each pair?

            //0x00-00-00-01-23-45-67-89

            //In decimal the weight of each value represents 10 times the weight of the previous one

            //In hex the weight of each value is 16 times the the weight of the previous one

            //   0x       1                   1                1               1
            //Where       ^Weight 16*16*16*x  ^Weight:16*16*x  ^Weight:16*x    ^Weight:x

            //Since each byte is composed by to hexadecimals,  each byte can represent 16*16, or 256 values(from 0 to
            // 255)
            //The 256 is better represented as 2**8.
            //   0x   01                              01                       01                  01
            //Where   ^Weight:(2**8)*(2**8)*(2**8)*x  ^Weight:(2**8)*(2**8)*x  ^Weight:(2**8)*x    ^Weight:x
            //or      ^2**24                           ^2**16                   ^2**8
            //         2**(8*3)                         2**(8*2)                2**(8*1)
            //We can see in the weight calculation  2**(8*(8-(i+1)) that the right part
            //knowing we have an array of length 8, we are calculating based on the byte position
            //the correct multiplication of 8 for that position.
        }
        return number;
    }
}
