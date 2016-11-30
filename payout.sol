pragma solidity ^0.4.0;

/// @title Payout to payees
contract Payout {
    
    // address of the party allowed to add or remove Payees
    address controller;

    // a map of address => number of shares
    mapping(address=>uint) shares;
   
    // an array of all of the payees
    // needed because mappings aren't iterable
    address[] payees;
    
    // address to store the last account we tried to send to if an error occurred
    address public error;

    // total number of shares in the contract. Stored so we don't have to recalculate 
    // for every payout
    uint total;

    function Payout(address director) {
        // give control of the contract to whichever address is specified
        controller = director;
        // initialize 0
        total = 0;
    }

    function addPayee(address payTo, uint payShares) {
        if(msg.sender != controller || payShares == 0) {
            throw;
        }

        // check the mapping for a balance because this is a faster operation
        // uninitialized = 0
        if(shares[payTo] > 0) {
            // subtract the old number of shares from the total so the count stays in sync
            uint prev = shares[payTo];
            // keep total shares in sync
            total = total - prev + payShares;
            // update the shares map with new value
            shares[payTo] = payShares;
            
        } else {
            // set the addres -> shares map
            shares[payTo] = payShares;
            // add the address to the list of addresses
            payees.push(payTo); 
            // keep total shares in sync
            total += payShares;
        }
   }

    function removePayee(address payTo) {
        if(msg.sender != controller) {
            throw;
        } 

        // check for a non 0 value in the map
        if(shares[payTo] > 0) {
            // null out the shares
            shares[payTo] = 0;
            // subtract the number of shares from the total
            total -= shares[payTo];
            // then remove the value from the array
            delete payees[payTo];
        } else {
            throw;
        }
        
    }

    function pay() payable returns (bool) {
        // calculate the value of one share, allowing the EVM to determine best type
        var shareVal = msg.value / total;
        address pay;
        uint s;
        for(uint i = 0; i < payees.length; i++) {
            pay = payees[i];
            s = shares[pay];
            // throw an error and undo all work if send to any address fails
            if(!pay.send(shareVal * s)) {
                // I'm not sure if this will roll back after an error or not
                error = pay;
                throw;
            }
        }
        return true;
    }
}
