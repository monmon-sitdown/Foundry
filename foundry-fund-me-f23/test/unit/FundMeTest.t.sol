//SPDX-License-Identifier:MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    /*
    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 6e18);
    }*/

    function testOwnerIsMsgSender() public view {
        //assertEq(fundMe.i_owner(), msg.sender);
        //assertEq(fundMe.i_owner(), address(this)); //改成传参数了之后要改回msg.sender
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFallsWithoutEnoughETH() public {
        vm.expectRevert();
        //uint256 cat = 1; Failed
        fundMe.fund(); //Not Enough eth so fail - revert - passed
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); //The next TX will be send by "user"
        fundMe.fund{value: SEND_VALUE}();

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        /*vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();*/

        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    } //PaulRBerg

    function testWithDrawWithASingleFunder() public funded {
        //Arrange
        uint256 startingOwnerBalace = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        /*uint256 gasStart = gasleft(); //1000
        vm.txGasPrice(GAS_PRICE); //200*/
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        /*uint256 gasEnd = gasleft();//1000 - 200 
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log(gasUsed)*/

        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalace,
            endingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        //Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            //vm.prank vm.deal fund the fundMe
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalace = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //ACT
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithDraw();
        vm.stopPrank();

        //assert
        assertEq(address(fundMe).balance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalace,
            fundMe.getOwner().balance
        );
    } //gas spent? Anvil set gas to 0

    function testWithdrawFromMultipleFunders() public funded {
        //Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            //vm.prank vm.deal fund the fundMe
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalace = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //ACT
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        //assert
        assertEq(address(fundMe).balance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalace,
            fundMe.getOwner().balance
        );
    } //gas spent? Anvil set gas to 0
}
