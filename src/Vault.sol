// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title ETH Vault with pause + reentrancy protection
/// @notice Owner can pause/unpause. Users can deposit/withdraw ETH.

contract Vault {
    
    error NotOwner();
    error Paused();
    error ZeroAmount();
    error InsufficientBalance();

   
    address public owner;
    bool public paused;
    mapping(address => uint256) private _balances;

    // simple, gas-cheap reentrancy guard
    uint256 private _lock;

    
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event PausedSet(bool paused);

    
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }
    modifier whenNotPaused() {
        if (paused) revert Paused();
        _;
    }
    modifier nonReentrant() {
        if (_lock == 1) revert(); // generic revert, cheaper
        _lock = 1;
        _;
        _lock = 0;
    }

    
    constructor(address _owner) {
        owner = _owner;
    }

    
    function deposit() external payable whenNotPaused {
        if (msg.value == 0) revert ZeroAmount();
        _balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external whenNotPaused nonReentrant {
        if (amount == 0) revert ZeroAmount();
        uint256 bal = _balances[msg.sender];
        if (bal < amount) revert InsufficientBalance();

        // effects
        unchecked {
            _balances[msg.sender] = bal - amount;
        }

        // interaction
        (bool ok, ) = payable(msg.sender).call{value: amount}("");
        require(ok, "ETH transfer failed");
        emit Withdraw(msg.sender, amount);
    }

    // convenience
    function withdrawAll() external whenNotPaused nonReentrant {
        uint256 amt = _balances[msg.sender];
        if (amt == 0) revert InsufficientBalance();
        _balances[msg.sender] = 0;
        (bool ok, ) = payable(msg.sender).call{value: amt}("");
        require(ok, "ETH transfer failed");
        emit Withdraw(msg.sender, amt);
    }

    
    function pause() external onlyOwner {
        paused = true;
        emit PausedSet(true);
    }

    function unpause() external onlyOwner {
        paused = false;
        emit PausedSet(false);
    }

   
    function balanceOf(address user) external view returns (uint256) {
        return _balances[user];
    }

    function totalAssets() external view returns (uint256) {
        return address(this).balance;
    }

    // allow plain ETH sends to count as deposits when not paused
    receive() external payable {
        if (paused) revert Paused();
        _balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
}
