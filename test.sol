// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract ChcolateShop {

    uint256 private quantity;
    int256[] private transactions;

    // this function allows gavin to buy n chocolates
    function buyChocolates(uint n) public {
        unchecked {
            quantity = quantity + n;
            transactions.push(int256(n));
        }
    }

    // this function allows gavin to sell n chocolates
    function sellChocolates(uint n) public {
        if (n > quantity) {
            revert();
        }
        unchecked {
            quantity = quantity - n;
            transactions.push() = - int256(n);
        }

    }

    // this function returns total chocolates present in bag
    function chocolatesInBag() public view returns(uint256){
        return quantity;
    }

    // this function returns the nth transaction
    function showTransaction(uint n) public  view returns(int256) {
        return transactions[n - 1];
    }

    //this function returns the total number of transactions
    function numberOfTransactions() public view returns(uint256) {
        return transactions.length;
    }

}