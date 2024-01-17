//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter{
    //todas las funciones deben ser internas
    function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint256){
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        //priceFeed.decimals(); devuelve 8 decimales y msg.value tiene 18 , para ponerlos en la misma escala se debe multiplicar este resultado por 10
        return uint256(answer * 1e10); //se hace type casting pq answer es de timpo int256

    }
    function getConvertionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
        ) internal view returns(uint256){
        //Convierte de ethereum a dolar
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }
    
}