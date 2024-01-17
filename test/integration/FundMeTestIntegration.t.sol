//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {Test, console} from "forge-std/Test.sol";
import {FundFundMe, WithdrawFundMe } from "../../script/Interacctions.s.sol";

contract interactionsTest is Test{
    FundMe fundMe;
    address USER = makeAddr("user"); //se crea un usuario para cada vez q se quiera trabajar con su address 
    uint256 constant SEND_VALUE = 0.1 ether; //100000000000000000
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 public constant gasPrice = 1;


    function setUp() external {
        DeployFundMe deployer = new DeployFundMe();
        fundMe = deployer.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testUserCanFundAndOwnerWithdraw() public {
        FundFundMe fundFundMe = new FundFundMe();
        fundFundMe.fundFundMe(address(fundMe));

        WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
        withdrawFundMe.withdrawFundMe(address(fundMe));

        assert(address(fundMe).balance == 0);
    }

}
