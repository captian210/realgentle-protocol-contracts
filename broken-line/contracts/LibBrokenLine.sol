// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/math/SignedSafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@rarible/lib-broken-line/contracts/LibIntMapping.sol";

/**
  * Line describes a linear function, how the user's voice decreases from point (start, bias) with speed slope
  * BrokenLine - a curve that describes the curve of the change in the sum of votes of several users
  * This curve starts with a line (Line) and then, at any time, the slope can be changed.
  * All slope changes are stored in slopeChanges. The slope can always be reduced only, it cannot increase,
  * because users can only run out of lockup periods.
  **/
contract BrokenLineDomain {

    struct Line {
        uint start;
        uint bias;
        uint slope;
    }

    struct LineData {       //all data about line
        Line line;
        uint cliff;
    }

    struct BrokenLine {
        mapping (uint => int) slopeChanges;         //change of slope applies to the next time point
        mapping (uint => LineData) initiatedLines;  //initiated (successfully added) Lines
        Line initial;
    }
}

library LibBrokenLine {
    using SignedSafeMathUpgradeable for int;
    using SafeMathUpgradeable for uint;
    using LibIntMapping for mapping (uint => int);

    /**
     *add Line, save data in LineData
     **/
    function add(BrokenLineDomain.BrokenLine storage brokenLine, uint id, BrokenLineDomain.Line memory line, uint cliff) internal {
        require(line.slope != 0, "Slope == 0, unacceptable value for slope");
        require(line.slope <= line.bias, "Slope > bias, unacceptable value for slope");
        require(brokenLine.initiatedLines[id].line.start == 0, "Line with given id is already exist");
        brokenLine.initiatedLines[id] = BrokenLineDomain.LineData(line, cliff);

        update(brokenLine, line.start);
        brokenLine.initial.bias = brokenLine.initial.bias.add(line.bias);
        uint period = line.bias.div(line.slope);
        if (cliff == 0) {
            brokenLine.initial.slope = brokenLine.initial.slope.add(line.slope);
        } else {
            uint cliffEnd = line.start.add(cliff).sub(1);
            brokenLine.slopeChanges.addToItem(cliffEnd, safeInt(line.slope));
            period = period.add(cliff);
        }

        int mod = safeInt(line.bias.mod(line.slope));
        uint256 endPeriod = line.start.add(period);
        uint256 endPeriodMinus1 = endPeriod.sub(1);
        brokenLine.slopeChanges.subFromItem(endPeriodMinus1, safeInt(line.slope).sub(mod));
        brokenLine.slopeChanges.subFromItem(endPeriod, mod);
    }

    /**
     *remove Line from BrokenLine, return line.bias, which actual now moment
     **/
    function remove(BrokenLineDomain.BrokenLine storage brokenLine, uint id, uint toTime) internal returns (uint) {
        BrokenLineDomain.LineData memory lineData = brokenLine.initiatedLines[id];
        BrokenLineDomain.Line memory line = lineData.line;
        require(line.bias != 0, "Line with given id already finished");

        update(brokenLine, toTime);
        //check time Line is over
        uint period = line.bias.div(line.slope);
        uint finishTime = line.start.add(period).add(lineData.cliff);
        if (toTime > finishTime) {
            line.bias = 0;
            return 0;
        }
        uint finishTimeMinusOne = finishTime.sub(1);
        int mod = safeInt(line.bias.mod(line.slope));
        uint nowBias = line.bias;
        uint cliffEnd =  line.start.add(lineData.cliff).sub(1);
        if (toTime <= cliffEnd) { //cliff works
            //in cliff finish time compensate change slope by oldLine.slope
            brokenLine.slopeChanges.subFromItem(cliffEnd, safeInt(line.slope));
            //in new Line finish point use oldLine.slope
            brokenLine.slopeChanges.addToItem(finishTimeMinusOne, safeInt(line.slope).sub(mod));
        } else if (toTime <= finishTimeMinusOne) { //slope works
            //now compensate change slope by oldLine.slope
            brokenLine.initial.slope = brokenLine.initial.slope.sub(line.slope);
            //in new Line finish point use oldLine.slope
            brokenLine.slopeChanges.addToItem(finishTimeMinusOne, safeInt(line.slope).sub(mod));
            nowBias = finishTime.sub(toTime).mul(line.slope).add(uint(mod));
        } else {  //tail works
            //now compensate change slope by tail
            brokenLine.initial.slope = brokenLine.initial.slope.sub(uint(mod));
            nowBias =uint(mod);
        }
        brokenLine.slopeChanges.addToItem(finishTime, mod);
        brokenLine.initial.bias = brokenLine.initial.bias.sub(nowBias);
        brokenLine.initiatedLines[id].line.bias = 0;
        return nowBias;
    }

    /**
     * Update initial Line by parameter toTime. CalculateВысчитывает и применяет все изменения из slopeChanges за этот период
     **/
    function update(BrokenLineDomain.BrokenLine storage brokenLine, uint toTime) internal {
        uint bias = brokenLine.initial.bias;
        uint slope = brokenLine.initial.slope;
        uint time = brokenLine.initial.start;
        require(toTime >= time, "can't update BrokenLine for past time");
        while (time < toTime) {
            bias = bias.sub(slope);
            int newSlope = safeInt(slope).add(brokenLine.slopeChanges[time]);
            require (newSlope >= 0, "slope < 0, something wrong with slope");
            slope = uint(newSlope);
            brokenLine.slopeChanges[time] = 0;
            time = time.add(1);
        }
        brokenLine.initial.start = toTime;
        brokenLine.initial.bias = bias;
        brokenLine.initial.slope = slope;
    }

    function safeInt(uint value) internal returns (int result) {
        result = int(value);
        require(value == uint(result), "int cast error");
    }
}
