//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 constant FUND_AMOUNT = 0.1 ether;
    uint256 constant STARTING_BALANCE = 100 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumUSDisFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMessageSender() public {
        console.log("owner: %s", address(fundMe.getOwner()));
        console.log("sender: %s", msg.sender);
        assertEq(msg.sender, fundMe.getOwner());
    }

    function testIsGetVersionAccurate() public {
        assertEq(fundMe.getVersion(), 4);
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER);
        fundMe.fund{value: FUND_AMOUNT}();
        assertEq(fundMe.getAddressToAmountFunded(USER), FUND_AMOUNT);
    }

    function testAddFunderToArrayOfFundees() public {
        vm.prank(USER);
        fundMe.fund{value: FUND_AMOUNT}();
        assertEq(fundMe.getFunder(0), USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: FUND_AMOUNT}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        uint256 balanceOfOwnerBeforeWithdraw = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        uint256 gaStart = gasleft();
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gaStart - gasEnd) * tx.gasprice;
        console.log(gasUsed);

        assertEq(
            fundMe.getOwner().balance,
            startingFundMeBalance + balanceOfOwnerBeforeWithdraw
        );
        assertEq(address(fundMe).balance, 0);
    }

    function testWithdrawWithMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), FUND_AMOUNT);
            fundMe.fund{value: FUND_AMOUNT}();
        }

        uint256 balanceOfOwnerBeforeWithdraw = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        assertEq(
            fundMe.getOwner().balance,
            startingFundMeBalance + balanceOfOwnerBeforeWithdraw
        );
        assertEq(address(fundMe).balance, 0);
    }

    function testCheapWithdrawWithMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), FUND_AMOUNT);
            fundMe.fund{value: FUND_AMOUNT}();
        }

        uint256 balanceOfOwnerBeforeWithdraw = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.cheapWithdraw();
        assertEq(
            fundMe.getOwner().balance,
            startingFundMeBalance + balanceOfOwnerBeforeWithdraw
        );
        assertEq(address(fundMe).balance, 0);
    }
}
