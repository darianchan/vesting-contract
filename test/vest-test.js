const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Vest", function () {
  let Vest;
  let vest;
  let accounts;

  beforeEach(async () => {
    accounts = await ethers.getSingers();
    Vest = await ethers.getContractFactory("Vest");
    vest = await Vest.deploy(accounts[0].address, accounts[1].address, 1000, )
  })

});
