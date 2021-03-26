// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;
pragma abicoder v2;

import "@rarible/royalties/contracts/LibPart.sol";

interface IRoyaltiesProvider {
    function getRoyalties(
        address token,
        uint tokenId
    ) external returns (LibPart.Part[] memory);

    function setRoyaltiesByToken(address token, LibPart.Part[] memory royalties) external;

    function setRoyaltiesByTokenAndTokenId(address token, uint tokenId, LibPart.Part[] memory royalties) external;

}
