pragma solidity ^0.4.0;

/// @title Payout to payees
contract Payout {
    
    // address of the party allowed to add or remove Payees
    address controller;

    struct ShareHolder {
        uint shareCount;
        uint arrIndex;
    }
    // a map of address => number of shares
    mapping(address=>ShareHolder) shares;
   
    // an array of all of the payees
    // needed because mappings aren't iterable
    address[] payees;
    
    // address to store the last account we tried to send to if an error occurred
    address public error;

    // total number of shares in the contract. Stored so we don't have to recalculate 
    // for every payout
    uint total;

    modifier onlyController(){
        if(msg.sender != controller) throw;
        _;
    }

    function Payout(address director){
        // give control of the contract to whichever address is specified
        controller = director;
        // initialize 0
        total = 0;
    }

    function removeFromPayeesArr(uint index)
    // replaces an item in the payees array and then updates its index in the shares 
    // map
    internal
    returns (bool)
    {
        // set the item at index equal to the last item and delete the last item
        uint last = payees.length - 1;
        if(last == index) {
            // if we are deleting the last item, we can just delete it 
            delete payees[last];
            return true;
        } else {
           // set the index equal to the last address to maintain a continuous array
           payees[index] = payees[last];
           // now delete the last item
           delete payees[last];
           // update the index of the moved item in the shares map
           address toUpdate = payees[index];
           shares[toUpdate].arrIndex = index;
           return true;
        }
    }

    function addPayee(address payTo, uint payShares) 
    onlyController
    {
        // check the mapping for a balance because this is a faster operation
        // uninitialized = 0
        if(shares[payTo].shareCount > 0) {
            // subtract the old number of shares from the total so the count stays in sync
            uint prev = shares[payTo].shareCount;
            // keep total shares in sync
            total = total - prev + payShares;
            // update the shares map with new value
            shares[payTo].shareCount = payShares;
            
        } else {
            // set the address -> shares map
            shares[payTo].shareCount = payShares;
            // add the address to the list of addresses
            payees.push(payTo); 
            // set the index
            shares[payTo].arrIndex = payees.length - 1;
            // keep total shares in sync
            total += payShares;
        }
   }

    function removePayee(address payTo) 
    onlyController
    {
        // check for a non 0 value in the map
        if(shares[payTo] > 0) {
            // null out the shares
            shares[payTo].shareCount = 0;
            // subtract the number of shares from the total
            total -= shares[payTo].shareCount;
            // then remove the value from the array
            removeFromPayeesArr(shares[payTo].arrIndex);
        } else {
            throw;
        }
        
    }

    function pay() 
    payable 
    returns (bool) 
    {
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
