// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract EthVault {
    // atur jumlah hari dalam 1 bulan
    uint256 public constant MONTH = 30 days;
    
    // varible
    struct DepositInfo {
        uint256 amount;
        uint256 start;
        uint256 lockPeriod; // 0 = flexible, >0 = locked
        bool withdrawn;
    }
    // declarasi vault
    mapping(address => DepositInfo[]) public deposits;

    event Deposited(address indexed user, uint256 amount, uint256 lockPeriod);
    event Withdrawn(address indexed user, uint256 amount);

    // fungsi deposit ke vault
    // @param waktu yang dipilih untuk lock 

     function deposit(uint8 monthsLock) external payable {
        require(msg.value > 0, "Amount must be > 0");
        require(monthsLock <= 3, "Max lock is 3 months");

        uint256 lock = monthsLock * MONTH; // 0 = flexible

        deposits[msg.sender].push(
            DepositInfo({
                amount: msg.value,
                start: block.timestamp,
                lockPeriod: lock,
                withdrawn: false
            })
        );

        emit Deposited(msg.sender, msg.value, lock);
    }

    // fungsi witdraw 

    function withdraw(uint256 depositIndex) external {
        DepositInfo storage dep = deposits[msg.sender][depositIndex];
        require(!dep.withdrawn, "Already withdrawn");
        if (dep.lockPeriod > 0) {
            require(
                block.timestamp >= dep.start + dep.lockPeriod,
                "Lock period not over"
            );
        }
        dep.withdrawn = true;
        (bool sent, ) = msg.sender.call{value: dep.amount}("");
        require(sent, "Withdraw failed");

        emit Withdrawn(msg.sender, dep.amount);
    }

     // Lihat jumlah deposit user
    function getDepositCount(address user) external view returns (uint256) {
        return deposits[user].length;
    }

    // Lihat detail deposit user
    function getDeposit(address user, uint256 index)
        external
        view
        returns (uint256 amount, uint256 start, uint256 lockPeriod, bool withdrawn)
    {
        DepositInfo storage dep = deposits[user][index];
        return (dep.amount, dep.start, dep.lockPeriod, dep.withdrawn);
    }
}