// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { PRBTest } from "@prb/test/PRBTest.sol";
import { console2 } from "forge-std/console2.sol";
import { StdCheats } from "forge-std/StdCheats.sol";
import "../src/Obfuscated.sol";
import "forge-std/console.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

/// @dev See the "Writing Tests" section in the Foundry Book if this is your first time with Forge.
/// https://book.getfoundry.sh/forge/writing-tests
contract FooTest is PRBTest, StdCheats {
    Obfuscated2 public contractObf;

    function setUp() public {
        contractObf = new Obfuscated2();
    }

    function test_Example() external {
        //bytes in position 7 and 23 are the last two bytes of each input
        //this generates the byte array:
        //0x00000000000000050000000000000000000000000000000b0000000000000000
        //which is the example of inputs x=0, y=1
        bytes memory callDatasNEW = new bytes(32);
        for (uint8 i = 0; i < 32; ++i) {
            if (i == 23) {
                callDatasNEW[i] = 0x0b;
            } else if (i == 7) {
                callDatasNEW[i] = 0x05;
            } else {
                callDatasNEW[i] = 0x00;
            }
        }

        //tx data should look like this:
        //The first 8 bytes represent the x value + 5, and they are padded 8 bytes to the right.
        //After the first 16 bytes comes the 8 bytes that represent value y + 10, with 8 bytes padded on the right
        // too.abi

        // This is the tx data for the x and y values [0, 1]
        //0x00000000000000050000000000000000000000000000000b0000000000000000
        // This is the tx data for the x and y values [72191321, 312]
        //0x00000000044d8d5e000000000000000000000000000001420000000000000000
        (bool success, bytes memory returnData) = address(contractObf).call(callDatasNEW);
        uint256 number = abi.decode(returnData, (uint256));
        assertEq(56, number);
    }
}
