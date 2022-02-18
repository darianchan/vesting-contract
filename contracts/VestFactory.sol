//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import './Vest.sol';

contract VestFactory {
    address private owner;
    Vest[] public vestingContracts;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can perform this action");
        _;
    }

    function createVestingContract(
        address _owner,
        address _beneficiary,
        uint256 _tokenAmount,
        uint256 _timePeriodToVest,
        uint256 _vestDuration,
        uint256 _cliffPeriod,
        bool _revocable
    ) public onlyOwner {
        Vest vestingContract = new Vest(
            _owner,
            _beneficiary,
            _tokenAmount,
            _timePeriodToVest,
            _vestDuration,
            _cliffPeriod,
            _revocable
        );
        vestingContracts.push(vestingContract);
    }
}