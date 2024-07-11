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
        bool isPaused;
    }

    struct Interest{
        uint256 amount;
        uint256 lastUpdate;
    }

    enum TransactionType{ WITHDRAWAL, DEPOSIT, INTEREST }

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
        require(!users[msg.sender].isPaused, "Your account is locked");
        _;
    }

    modifier calculateInterest(){
        uint daysDiference = (block.timestamp - interests[msg.sender].lastUpdate) / secondsInDay;
        uint earnedInterest = ((users[msg.sender].balance * currentInterest) / 100) * daysDiference;
        interests[msg.sender].amount += earnedInterest;
        interests[msg.sender].lastUpdate = block.timestamp;
        _;
    }

    function changeInterest(uint8 newInterest) public isAdmin {
        currentInterest = newInterest;
    }

    
    function pauseWallet(address _userAddress, bool pauseStatus) public isAdmin {
        users[_userAddress].isPaused = pauseStatus;
    }    


    function getTransactionHistory() public view returns (TransactionHistory[] memory) {
        return transactionHistory[msg.sender];
    }

    function deposit() public payable isUserEnableToWithdrawalAndDeposit() calculateInterest {
        require(msg.value > 0, "Please provide non-zero amount");

        users[msg.sender].balance += msg.value;

        TransactionHistory memory newHistory = TransactionHistory(msg.value, TransactionType.DEPOSIT);

        transactionHistory[msg.sender].push(newHistory);

        emit Deposit(msg.sender, "Amount deposited succuessfully");
    }

    function withdrawal(uint256 _amount) public isUserEnableToWithdrawalAndDeposit calculateInterest {
        require(_amount > 0, "Please provide non-zero amount");
        require(users[msg.sender].balance >= _amount, "Insufficient amount");

        users[msg.sender].balance -= _amount;

        // Transfer Ether to the user
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Transfer failed.");

        TransactionHistory memory newHistory = TransactionHistory(_amount, TransactionType.WITHDRAWAL);
        
        transactionHistory[msg.sender].push(newHistory);

        emit Withdrawal(msg.sender, "Amount withdrawal successfully");
    }

    function checkBalance() public view returns(uint256) {   
        return users[msg.sender].balance;
    }

    function checkEarnedInterest() public isUserEnableToWithdrawalAndDeposit calculateInterest  returns (uint256) {
        return interests[msg.sender].amount;
    }

    function withdrawInterest(uint256 amount) public isUserEnableToWithdrawalAndDeposit calculateInterest {
        require(amount > 0, "Transfer amount should be greater than zero");
        require(interests[msg.sender].amount >= amount, "Insufficent balance");

        interests[msg.sender].amount -= amount;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer Failed");

        TransactionHistory memory newTransaction = TransactionHistory(amount, TransactionType.INTEREST);
        transactionHistory[msg.sender].push(newTransaction);

        emit Withdrawal(msg.sender, "Transfer successfull");
    }

}