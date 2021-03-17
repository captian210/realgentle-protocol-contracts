// SPDX-License-Identifier: MIT

pragma solidity >=0.6.9 <0.8.0;
pragma experimental ABIEncoderV2;

import "../../../contracts/exchange/v2/LibFeeSide.sol";

contract LibFeeSideTest {
    function getFeeSideTest(bytes4 maker, bytes4 taker) external pure returns (LibFeeSide.FeeSide){
        return LibFeeSide.getFeeSide(maker, taker);
    }
}
