// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.22 <0.9.0;

contract MultiSig{
    
    address mainOwner;
    address[] walletOwners;
    uint transferId=0;
    uint limit;


    constructor(){
        mainOwner = msg.sender;
        walletOwners.push(mainOwner);
     
   
    }

    mapping(address => uint) balance;
    mapping(address => mapping(uint => bool)) approvals;


    struct Transfer{
        address sender;
        address payable receiver;
        uint amount;
        uint id;   // Id of the Transfer
        uint approval;        
        uint timeOfTransaction;
    }
    
    Transfer[] transferRequest;
    
    event walletOwnerAdded(address addedBy, address ownerAdded, uint timeofTransaction);
    event walletOwnerRemoved(address removedBy, address ownerremoved, uint timeofTransaction);
    event fundsDeposited(address sender, uint amount , uint timeofTransaction);
    event fundsWithDrawn(address sender, uint amount , uint timeofTransaction);
    event transferCreated(address sender, address receiver, uint amount, uint id, uint approvals, uint timeofTransaction);
    event transferCancelled(address sender, address receiver, uint amount, uint id, uint approvals, uint timeofTransaction);
    event transferApproved(address sender, address receiver, uint amount, uint id, uint approvals, uint timeofTransaction);
    event transferexecuted(address sender, address receiver, uint amount, uint id, uint approvals, uint timeofTransaction);


    modifier onlyOwner(){ // To ensure only wallet owners can call the function
    
       bool isOwner = false;

       for(uint i=0; i<walletOwners.length; i++){
           if(walletOwners[i]==msg.sender){
           isOwner=true;
           break;
           }
       }
       require(isOwner==true, "only wallet owners can call this function");     
       _;

    }


    function getWalletOwners() public view returns(address[] memory) {
          
          return walletOwners;
    }

    function addWalletOwner(address owner) public onlyOwner  {

       for(uint i=0; i<walletOwners.length; i++){

           if(walletOwners[i]==owner){
               revert("Cannot add duplicate owners");
           }
       }
        walletOwners.push(owner);
        emit walletOwnerAdded(msg.sender, owner , block.timestamp);
    }

    function removeWalletOwners(address owner) public onlyOwner  {

      
      bool hasBeenfound =  false;
      uint OwnerIndex;

      for(uint i=0; i<walletOwners.length; i++){

          if(walletOwners[i] == owner){
          
          hasBeenfound = true;
          OwnerIndex = i;
          break;
          
          }

      }
      require(hasBeenfound == true, "Wallet owner not detected");

      walletOwners[OwnerIndex] = walletOwners[walletOwners.length-1];
      walletOwners.pop();

      emit walletOwnerRemoved(msg.sender, owner , block.timestamp);
    }

    function Deposit() public payable onlyOwner{
        
       require(msg.value>0, "Cannot deposit a value 0");

       balance[msg.sender] = msg.value;

       emit fundsDeposited(msg.sender,msg.value,block.timestamp);

    } 

    function withdraw(uint amount) public onlyOwner{

        require(balance[msg.sender]>=amount, "You have not deposited this much of amount int the wallet");
        balance[msg.sender]-=amount;
        payable(msg.sender).transfer(amount);

        emit fundsWithDrawn(msg.sender,amount,block.timestamp);
    }

    function createTransferRequest(address payable receiver, uint amount) public onlyOwner{

        require(balance[msg.sender]>=amount, "Insufficient Funds");
        
        for(uint i=0; i< transferRequest.length; i++){
             
             require(walletOwners[i]!=msg.sender,"Cannot tranfer to yourself ");
        }

        balance[msg.sender]-=amount;
        transferRequest.push(Transfer(msg.sender, receiver, amount, transferId, 0 , block.timestamp));
        transferId++;

        emit transferCreated(msg.sender, receiver, amount , transferId, 0, block.timestamp);
    }

    function cancelTransfer(uint _id) public onlyOwner{
        
        bool hasBeenfound = false;
        uint transferIndex = 0;

        for(uint i=0; i< transferRequest.length; i++){

             if(transferRequest[i].id==_id){
                 hasBeenfound = true;
                 break;
             }
             transferIndex++;
        }
        require(hasBeenfound,"Transfer id not found");
        require(msg.sender == transferRequest[transferIndex].sender,"Only the creator can cancel");

        balance[msg.sender] += transferRequest[transferIndex].amount;
        transferRequest[transferIndex] = transferRequest[transferRequest.length - 1];
        emit transferCancelled(msg.sender, transferRequest[transferIndex].receiver, transferRequest[transferIndex].amount, transferRequest[transferIndex].id, transferRequest[transferIndex].approval, transferRequest[transferIndex].timeOfTransaction);

        transferRequest.pop();
        
        
    }
    function getBalance() public view returns(uint){

        return balance[msg.sender];
    }

      function getContractBalance() public view returns(uint){

        return address(this).balance;
    }


    function getTransferRequests() public view returns(Transfer[] memory){
        return transferRequest;
    }

    function getApprovals(uint id) public view returns(bool){
        return approvals[msg.sender][id];
    } 
    
    function getLimit() public view returns(uint){
        return limit;
    }
    
    function getNumOfApprovals(uint _id) public view returns(bool){
        return approvals[msg.sender][_id];
    }

    function approveTransfer(uint _id) public onlyOwner{
  
        bool hasBeenfound = false;
        uint transferIndex = 0;

        for(uint i=0; i< transferRequest.length; i++){

             if(transferRequest[i].id==_id){
                 hasBeenfound = true;
                 break;
             }
             transferIndex++;
        }
        require(hasBeenfound);
        require(transferRequest[transferIndex].sender != msg.sender, "cannot apporove your transfer request");
        require(approvals[msg.sender][_id] == false, "Cannot appoved twice");

        transferRequest[transferIndex].approval +=1;
        approvals[msg.sender][_id] = true;
        
        emit transferApproved (msg.sender, transferRequest[transferIndex].receiver, transferRequest[transferIndex].amount, transferRequest[transferIndex].id, transferRequest[transferIndex].approval, transferRequest[transferIndex].timeOfTransaction);
        limit = walletOwners.length;
        if(transferRequest[transferIndex].approval == limit){

            transferFunds(transferIndex);
        }
        
    }

    function transferFunds(uint id) private{
             
        balance[transferRequest[id].receiver] += transferRequest[id].amount;

        transferRequest[id].receiver.transfer(transferRequest[id].amount);
    

        transferRequest[id] = transferRequest[transferRequest.length-1];
        emit transferexecuted (msg.sender, transferRequest[id].receiver, transferRequest[id].amount, transferRequest[id].id, transferRequest[id].approval, transferRequest[id].timeOfTransaction);
        transferRequest.pop();

    }

}