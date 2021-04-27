// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@rarible/lib-broken-line/contracts/LibBrokenLine.sol";

/**
  * balanceOf(address account) - текущий баланс (сумма всех локов) юзера
  * totalSupply() - общий баланс всех юзеров
  * createLock(uint value, uint slope, uint cliff) - сколько залочим, со скоростью разлока, сколько cliff длиной
  **/

contract Staking {
    using SafeMathUpgradeable for uint;
    using LibBrokenLine for BrokenLineDomain.BrokenLine;
    uint256 constant WEEK = 604800;                 //seconds one week
    uint256 constant STARTING_POINT_WEEK = 2676;    //starting point week (Staking Epoch begining)
    ERC20Upgradeable public token;
    address deposite;

    struct Lock {
        uint dt; //deposit time
        uint amount; //amount deposited
        uint et; //end time
    }

    mapping(address => BrokenLineDomain.BrokenLine) public userBalances;    //address - line
    BrokenLineDomain.BrokenLine public totalBalances;                       //total User Balance
    mapping (address => Lock) usersLock;                                     //idLock - Lock
    address[] usersAccounts;
    uint public idLock;

    constructor(ERC20Upgradeable _token, address _deposite) public {
        token = _token;
        deposite = _deposite;
        idLock = 1;
        //todo initialize totalBalances
    }

    function createLock(address account, uint amount, uint period, uint cliff) public returns (uint) {
        //todo проверки
        uint blockTime = roundTimestamp(block.timestamp);
        BrokenLineDomain.Line memory line = createLine(blockTime, amount, amount.div(period));
        idLock++;
        if (userBalances[account].initial.start == 0) {
            usersAccounts.push(account);
        }
        userBalances[account].add(line, cliff);
        totalBalances.add(line, cliff);
        usersLock[account] = Lock(blockTime, amount, blockTime + period);
        require(token.transferFrom(account, deposite, amount), "Transfer unsuccessfull");
        return idLock;

        // как меняется lock общий, когда юзер приходит/уходит/меняет
        // 1. нужно применить пропущенные изменения (окончания локов)
        // 2. если добавляем, то
    }

    function totalSupply() public returns (uint) {
        if (totalBalances.initial.start == 0) { //no lock
            return 0;
        }
        totalBalances.update(roundTimestamp(block.timestamp));
        return totalBalances.initial.bias;
    }

    function balanceOf(address account) public returns (uint) {
        if (userBalances[account].initial.start == 0) { //no lock
            return 0;
        }
        userBalances[account].update(roundTimestamp(block.timestamp));
        return userBalances[account].initial.bias;
    }

    function increaseUnlockTime(uint lockId, uint period) public {

    }

    function increaseLockedValue(uint lockId, uint period) public {

    }

    function withdraw() public {
        for (uint i = 0; i < usersAccounts.length; i++) {
            userBalances[usersAccounts[i]].update(roundTimestamp(block.timestamp));
            uint balanceDiff = usersLock[usersAccounts[i]].amount - userBalances[usersAccounts[i]].initial.bias;
            if (balanceDiff > 0) {
                require(token.transferFrom(address(this), usersAccounts[i], balanceDiff), "Transfer unsuccessfull");
            }
        }
    }

    function createLine(uint blockTime, uint amount, uint slope) internal pure returns (BrokenLineDomain.Line memory) {
        require(slope != 0, "require slope deposit time not equal 0");
        return BrokenLineDomain.Line(blockTime, amount, slope);
    }

    function roundTimestamp(uint ts) pure internal returns (uint) {
        return ts.div(WEEK).sub(STARTING_POINT_WEEK);
    }

}

