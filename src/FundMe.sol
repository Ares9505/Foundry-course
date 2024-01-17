//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

error FundMe_NotOwner();

contract FundMe{
    //varibles de estado del contrato
    using PriceConverter for uint256;//para usar las funciones de la libreria PriceConverter para este tipo de variable
    
    address[] private s_funders;
    mapping(address funder => uint256 amountFunded) private s_addressToAumountFunded; //to track each fund by address
    address private immutable i_owner;
    uint256 public MINIMUM_USD = 5e18;
    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeed){
        //se llama al desplegar el contrato
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    modifier onlyOwner(){
        //require(msg.sender == i_owner,"Not the owner");
        if(msg.sender != i_owner){revert FundMe_NotOwner();}
        _;
    }
    
    function fundMe() payable public{
        require(msg.value.getConvertionRate(s_priceFeed) >= MINIMUM_USD, "didn't send enougth eth");
        s_funders.push(msg.sender);
        s_addressToAumountFunded[msg.sender] += msg.value; 
    }

    function withdraw() public {
        //poner en cero todos los 
        for(uint256 index = 0; index < s_funders.length; index++){
            s_addressToAumountFunded[s_funders[index]] = 0;
        }
        s_funders = new address[](0);
        //Formas de enviar crypto
        //transfer
        // payable(msg.sender).transfer(address(this).balance);// hace revert automaticamente
        // //send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send Failed"); //send solo hace revert si se usa require 
        //call (tambien permite llamar a cualquier funcion sin saber su ABI)
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "call");
    }


    function cheaperWithdraw() public{
        uint256 fundersLength = s_funders.length;   
        for(uint256 index = 0; index < fundersLength; index++){
            s_addressToAumountFunded[s_funders[index]] = 0;
        }
        s_funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "call");
    }

        function getVersion() view public returns(uint256){
        return s_priceFeed.version();
    }

    receive() external payable{
        fundMe();
    }

    fallback() external payable{
        fundMe();
    }

    /* View /pure functions*/
    //Se ponen private las variables de storage y se hacen funciones getter para las mismas
    //con el objetivo de que solo puedan ser llamadas por otras funciones y no por usuarios
    function getAddressToAmountFunded(
        address fundingAddress
        ) external view returns(uint256){
            return s_addressToAumountFunded[fundingAddress];
        }

    function getFunders(uint256 index) external view returns(address){
        return s_funders[index];
    }

    function getOwner() external view returns(address){
        return i_owner; 
    }
}


