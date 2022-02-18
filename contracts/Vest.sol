//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Vest {
    address private owner;
    address public beneficiary;

    uint256 public tokenAmount; // total token amounts in 10**18 decimals
    uint256 public timePeriodToVest; // duration in unix time seconds
    uint256 public cliffPeriod; // time in unix time seconds
    uint256 public vestDuration;
    uint256 public start;
    uint256 public releasedTokens;

    bool public revocable;

    event Released(uint256 amount);

    constructor(
        address _owner,
        address _beneficiary,
        uint256 _tokenAmount,
        uint256 _vestDuration,
        uint256 _cliffPeriod,
        bool _revocable
    ) {
        owner = _owner;
        beneficiary = _beneficiary;
        tokenAmount = _tokenAmount;
        vestDuration = _vestDuration;
        cliffPeriod = block.timestamp + _cliffPeriod; // assume that starting time is on initial contract deploy
        start = block.timestamp;
        revocable = _revocable;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can perform this action");
        _;
    }

    function releaseToken(address _token) public onlyOwner {
        require(IERC20(_token).balanceOf(address(this)) > 0, "no more tokens available");
        
        uint256 amountToRelease = releaseableAmount(_token);
        releasedTokens += amountToRelease; // change state before transfer to prevent reentrancy

        (bool success) = IERC20(_token).transfer(beneficiary, amountToRelease);
        require(success);

        emit Released(amountToRelease);
    }

    function revoke(address _token) public onlyOwner {
        require(revocable);

        uint256 balance = IERC20(_token).balanceOf(address(this));
        uint256 unreleased = releaseableAmount(_token);
        uint256 refund = balance - unreleased;

        (bool success) = IERC20(_token).transfer(owner, refund);
        require(success);
    }

    ///////////////
    /// Helpers ///
    ///////////////

    function releaseableAmount(address _token) public view returns (uint256) {
        return vestedAmount(_token) - releasedTokens;
    }

    function vestedAmount(address _token) public view returns (uint256) {
        uint256 currentBalance = IERC20(_token).balanceOf(address(this));
        uint256 totalBalance = currentBalance + releasedTokens;

        if (block.timestamp < cliffPeriod) {
            return 0; // can't vest anything if it is before the cliff
        } else if (block.timestamp >= start + vestDuration ) { // if it is fully past the vesting period and nothing has been vested yet, then vest it all
            return totalBalance;
        } else {
            return totalBalance * ((block.timestamp - start) / vestDuration); // otherwise, vest it linearlly
        }
    }
}
