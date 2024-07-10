// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract DecentralizedBank {   
    event Deposit(address indexed to, string msg);
    event Withdrawal(address indexed to, string msg);
    event InterestWithdrawal(address indexed to, string msg);

    address owner;

    uint secondsInDay = 86400;

    uint8 private currentInterest = 2;

    constructor(){
        owner = msg.sender;
    }

    struct User {
        uint256 balance;
        uint256 interest;
        bool isPaused;
    }

    struct Interest{
        uint256 amount;
        uint256 lastUpdate;
    }

    enum TransactionType{ WITHDRAWAL, DEPOSIT }

    struct TransactionHistory{
        uint256 amount;
        TransactionType mode;
    }

    mapping(address => User) public users;
    mapping(address => Interest) public interests;
    mapping(address => TransactionHistory[]) public transactionHistory;

    modifier isAdmin() {
        require(msg.sender == owner, "You don't have permission to perform this operation");
        _;
    }

    modifier isUserEnableToWithdrawalAndDeposit(){
        require(!users[msg.sender].isPaused, "Your transactions permission is locked");
        _;
    }

    function changeInterest(uint8 newInterest) public isAdmin() {
        currentInterest = newInterest;
    }

    
    function pauseWallet(address _userAddress, bool pauseStatus) public isAdmin() {
        users[_userAddress].isPaused = pauseStatus;
    }    


    function getTransactionHistory() public view returns (TransactionHistory[] memory) {
        return transactionHistory[msg.sender];
    }

    function deposit() public payable {
        require(msg.value > 0, "Please provide non-zero amount");

        users[msg.sender].balance += msg.value;

        TransactionHistory memory newHistory = TransactionHistory(msg.value, TransactionType.DEPOSIT);

        transactionHistory[msg.sender].push(newHistory);

        emit Deposit(msg.sender, "Amount deposited succuessfully");
    }

    function withdrawal() public payable {
        require(msg.value > 0, "Please provide non-zero amount");

        users[msg.sender].balance -= msg.value;

        TransactionHistory memory newHistory = TransactionHistory(msg.value, TransactionType.WITHDRAWAL);
        
        transactionHistory[msg.sender].push(newHistory);

        emit Withdrawal(msg.sender, "Amount withdrawal successfully");
    }

    function checkBalance() public view returns(uint256) {   
        return users[msg.sender].balance;
    }

}