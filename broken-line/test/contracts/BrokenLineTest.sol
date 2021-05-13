// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;
pragma abicoder v2;

import "../../contracts/LibBrokenLine.sol";

contract BrokenLineTest is BrokenLineDomain {
    using LibBrokenLine for BrokenLine;

    BrokenLine public brokenLine;
    event resultAddLine(uint result);
    event resultRemoveLine(uint result);

    function addTest(Line memory line, uint cliff) public {
        uint result = brokenLine.add(line, cliff);
        emit resultAddLine(result);
    }

    function update(uint timeTo) public {
        brokenLine.update(timeTo);
    }

    function getCurrent() view public returns (Line memory) {
        return brokenLine.initial;
    }

    function removeTest(uint id, uint toTime) public {
        uint result = brokenLine.remove(id, toTime);
        emit resultRemoveLine(result);
    }
}
