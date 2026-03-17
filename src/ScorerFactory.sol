// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Scorer} from "./Scorer.sol";

contract ScorerFactory {
    event ScorerCreated(address indexed scorer, uint8 wCode, uint8 wClarity, uint8 wTime);
    
    function createScorer(
        uint8 wCode,
        uint8 wClarity,
        uint8 wTime
    ) external returns (address scorerAddress) {
        require(wCode + wClarity + wTime == 100, "Weights must sum to 100");
        
        CustomScorer scorer = new CustomScorer(wCode, wClarity, wTime);
        scorerAddress = address(scorer);
        
        emit ScorerCreated(scorerAddress, wCode, wClarity, wTime);
        return scorerAddress;
    }
}

contract CustomScorer is Scorer {
    constructor(uint8 _wCode, uint8 _wClarity, uint8 _wTime) 
        Scorer(_wCode, _wClarity, _wTime) 
    {}
}
