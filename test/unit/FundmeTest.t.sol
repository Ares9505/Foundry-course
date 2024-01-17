//SPDX-License-Identifier:MIT

pragma solidity ^0.8.18;

import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {Test, console} from "forge-std/Test.sol";

// contract FundMeTest is Test {
//     uint256 number = 1;

//     function setUp() external {
//         number = 2;
//     }

//     function testDemo() public {
//         console.log(number);
//         assertEq(number, 2);
//     }
// }

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user"); //se crea un usuario para cada vez q se quiera trabajar con el 
    uint256 constant SEND_VALUE = 0.1 ether; //100000000000000000
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 public constant gasPrice = 1;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER,STARTING_BALANCE); //para cambiar el balance de una cuenta 
    }

    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testDemo() public {
        console.log(msg.sender);
        console.log(fundMe.getOwner());
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionisAccuarate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert();//Se espera que el codigo siguiente haga un revert
        fundMe.fundMe();//debe hacer revert pues no se transfiere ningun dinero
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER);//Pone a USER como msg.sender de la proxima transaccion 
        fundMe.fundMe{value: SEND_VALUE}();
        console.log(USER.balance);//asi puedo ver el balance de la cuenta
        assertEq(fundMe.getAddressToAmountFunded(USER), SEND_VALUE);
    }

    modifier funded(){
        vm.prank(USER);
        fundMe.fundMe{value: SEND_VALUE}();
        _;
    }

    function testAddsFunderToArrayOfFunders() public funded{
        address funder = fundMe.getFunders(0);
        assertEq(funder,USER);
    }

    function checkOnlyOwnerCanWithDraw() public funded {
        vm.prank(USER);//ignora lo q no es una llamada a una funcion payable
        vm.expectRevert();
        fundMe.withdraw();     
    }

    function testWithdrawWithASingleFunder() public funded{
        //Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        assertEq(address(fundMe).balance,0);
        assertEq(startingFundMeBalance + startingOwnerBalance,
        endingOwnerBalance);
    }

    function testWithdrawFromMultipleFunder() public {
        //Arrange
        uint160 numberOfFunders = 10;
        uint160 starting_index = 1;// El tipo de las direcciones es 160
        //la direccion no se emoieza en 9 pues a veces se hace revert usando la direccion 0;
        //Act
        for (uint160 i = starting_index; i < (numberOfFunders); ++i ){
            hoax(address(i), SEND_VALUE);// address(<somedirection>)  se pueden crear direcciones dummy con variables de tipo uint160
            fundMe.fundMe{value: SEND_VALUE}();
        }
        uint256 startOwnerBalance = fundMe.getOwner().balance;
        uint256 startFundMeBalanace = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();
        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        assertEq(address(fundMe).balance, 0);
        assertEq(startFundMeBalanace + startOwnerBalance, endingOwnerBalance);

    }

    function testGasSpendedByWithdraw() public funded{
        uint256 gasStart = gasleft();//cuando se envía gas se envia mas de lo q se espera usar
        vm.txGasPrice(gasPrice);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart- gasEnd) * gasPrice;
        console.log(gasUsed);
    }

        function testCheaperWithdrawFromMultipleFunder() public {
        //Arrange
        uint160 numberOfFunders = 10;
        uint160 starting_index = 1;// El tipo de las direcciones es 160
        //la direccion no se emoieza en 9 pues a veces se hace revert usando la direccion 0;
        //Act
        for (uint160 i = starting_index; i < (numberOfFunders); ++i ){
            hoax(address(i), SEND_VALUE);// address(<somedirection>)  se pueden crear direcciones dummy con variables de tipo uint160
            fundMe.fundMe{value: SEND_VALUE}();
        }
        uint256 startOwnerBalance = fundMe.getOwner().balance;
        uint256 startFundMeBalanace = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();
        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        assertEq(address(fundMe).balance, 0);
        assertEq(startFundMeBalanace + startOwnerBalance, endingOwnerBalance);
    }

}