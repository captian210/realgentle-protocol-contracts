// SPDX-License-Identifier: MIT

pragma solidity >=0.6.9 <0.8.0;
pragma abicoder v2;

library LibOrderDataV1 {
    bytes4 constant public V1 = bytes4(keccak256("V1"));
    bytes4 constant public V2 = bytes4(keccak256("V2"));

    struct DataV1 {
        address benificiary;
        address[] origin;
        uint[] originFee;
    }

    struct DataV2 {
        address benificiary;
        address origin;
        uint originFee;
    }

    //todo think:  different metods return different poles of struct DataV1,
    function decodeOrderDataV1(bytes memory data) internal pure returns (DataV1 memory orderData) {
        orderData = abi.decode(data, (DataV1)); //todo transaction revert here
    }

    function decodeOrderDataV2(bytes memory data) internal pure returns (DataV2 memory orderData) {
        orderData = abi.decode(data, (DataV2));
    }
}
