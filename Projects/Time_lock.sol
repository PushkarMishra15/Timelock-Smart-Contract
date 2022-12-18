// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.22 <0.9.0;

contract timelock{
     
     uint public duration = 10 seconds;
     uint public end;
     address public manager;
     address payable public contract_address;

     receive() external payable{
    
     }

     constructor(){
         manager = msg.sender;
         contract_address=payable(address(this)); 
     }
    function deposit(uint _amount) public payable { 
       
        contract_address.transfer(_amount);
    }
     
     function getBalance() public view returns(uint){
         return address(this).balance ;
     }

}