//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Vest {
    //address who created the vesting contract (i.e. SYN multisig)
    address private owner;

    //address who's receiving the vested tokens
    address public beneficiary;

    // this is the address of the ERC-20 token you'd like to distribute to the beneficiary of the vesting contract
    address public tokenToDistribute;

    //this is the length of the vesting contract in seconds (i.e. 1 month is 2419200 seconds)
    uint256 public vestDuration;

    //period beneficiary must wait until vesting begins
    uint256 public cliffPeriod; // time in unix time seconds

    //total number of tokens to emit to the beneficiary over the entire vest duration
    uint256 public numTokensToDistribute;
    
    //TODO: do you want Vest frequency? (i.e. pay out per day / week / month rather than seconds)
    
    //block timestamp of when the contract is deployed
    uint256 public start;

    //number of tokens that have been vested thus far
    uint256 public releasedTokens;


    // whether the vesting contract is cancellable after it has been deployed or not
    bool public revocable;

    //whether the vesting contract has received the initial token supply to disburse
    bool public active;

    //this event is emitted when tokens are vested
    event Released(uint256 amount, address beneficiary);

    //this event is emmitted when a vesting contract is seeded with tokens to vest
    event Activated(uint256 amount, address beneficiary);

    constructor(
        address _owner,
        address _beneficiary,
        address _tokenToDistribute,
        uint256 _vestDuration,
        uint256 _cliffPeriod,
        uint256 _numTokensToDistribute,
        bool _revocable
    ) {
        owner = _owner;
        beneficiary = _beneficiary;
        vestDuration = _vestDuration;
        cliffPeriod = _cliffPeriod; 
        numTokensToDistribute = _numTokensToDistribute;
        tokenToDistribute = _tokenToDistribute;
        revocable = _revocable;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can perform this action");
        _;
    }
      modifier onlyActive() {
        require(active == true, "only an active, seeded contract can perform this action");
        _;
    }

    function depositInitialTokens(uint _amount) public onlyOwner {
        (bool success) = IERC20(tokenToDistribute).transfer(address(this), _amount);
        require(success);
        
        active = true;
        start = block.timestamp;
        cliffPeriod = start + cliffPeriod;
    }

    function releaseToken() public onlyOwner onlyActive {
        require(IERC20(tokenToDistribute).balanceOf(address(this)) > 0, "no more tokens available to vest");
        
        uint256 amountToRelease = releaseableAmount(tokenToDistribute);
        releasedTokens += amountToRelease; // change state before transfer to prevent reentrancy

        (bool success) = IERC20(tokenToDistribute).transfer(beneficiary, amountToRelease);
        require(success);

        emit Released(amountToRelease, beneficiary);
    }

    function revoke() public onlyOwner {
        require(revocable);

        uint256 balance = IERC20(tokenToDistribute).balanceOf(address(this));
        uint256 unreleased = releaseableAmount(tokenToDistribute);
        uint256 refund = balance - unreleased;

        (bool success) = IERC20(tokenToDistribute).transfer(owner, refund);
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
            return totalBalance * ((block.timestamp - start) / vestDuration); // otherwise, vest it linearlly TODO: this doesn't work
        }
    }
}
