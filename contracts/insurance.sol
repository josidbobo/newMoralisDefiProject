// SPDX-License-Identifier: MIT

 pragma solidity = 0.8.9;

 contract InsureBlocks {
    // State variables
     address mainAccount;
     bool locked;
     address owner;

    // Modifier to prevent zero addresses
     modifier noZeroAddress(){
         require(msg.sender != address(0), "Addresss Zero cannot call this function");
         _;
     }

    // Modifier to prevent re-entrancy attack
     modifier noReentrancy() {
         require(locked == false, "Can't call this function because it's locked");
         locked = true;
         _;
         locked = false;
     }

     modifier onlyOwner() {
         require(msg.sender == owner, "Only owner can call this function");
         _;
     }

     struct Insurance{    
         address owner;
         uint insuranceId;
         string insuranceName;
         uint amount;
         uint userInsuranceCount;
         address beneficiary;
         uint amountForBeneficiary;
         bool isApproved;
        }

//==============Mappings=================================
     mapping(uint => Insurance) portfolios;

     mapping (address => mapping(uint => Insurance)) userInsurances;
     
     mapping (address => uint) portfolioCountOfEachUser;
     mapping (address => bool) public isInsuree;
     mapping (address => bytes32) public passwordHash;

     uint public userCount;   // Keep count of number of users
     uint public count;     // Keep count of total portfolio

    event InsuranceMade(address indexed owner, uint _amountInsured, string typeOfInsurance, uint iD);
    event InsuranceDeposit(address indexed owner, uint _amountDeposited);
    event AuthorizedToWithdraw(address indexed owner, address indexed beneficiary, uint amountAuthorised, uint iD);
    event ClaimMade(address indexed owner, address indexed beneficiary, uint amount, uint id);

    constructor () {
        mainAccount = address(this);
        owner = msg.sender;
    }
    

    // /// @notice Convert dollar amount to wei
    // function priceConvert(uint _price) public view returns(uint){
    //     uint amount = (_price * 10 ** 26) / uint(getLatestPrice());
    //     return amount; 

    //     /*  Exchangeprice =  10 ** 18wei
    //        __price =  x   */     
    // }

    /// @dev function to create a portfolio; password only needed for the first instance after which its input becomes an empty string from frontend
    /// @param _amount wei value of amount, typeOfInsurance name of the insurance, _beneficiary default beneficiary to automatically claim, _maxAmountForBenef specifies how much of the portfolio is for the beneficiary of which both can change
     function insure(uint _amount, string memory typeOfInsurance, address _beneficiary, uint _maxAmountForBenef, string memory _password) public payable noZeroAddress{
         require(insuranceDeposit(_amount), "Could not send the Insured amount");

            if(!isInsuree[msg.sender]){
                bytes32 hashedPassword = hashPassword(_password);
                passwordHash[msg.sender] = hashedPassword;
                userCount++;
                isInsuree[msg.sender] = true;
            }

        portfolioCountOfEachUser[msg.sender]++;
        userInsurances[msg.sender][portfolioCountOfEachUser[msg.sender]] = Insurance(msg.sender, portfolioCountOfEachUser[msg.sender], typeOfInsurance, _amount, 0, _beneficiary, _maxAmountForBenef, false);

        count++;
        portfolios[count] = Insurance(msg.sender, count, typeOfInsurance, _amount, portfolioCountOfEachUser[msg.sender], _beneficiary, 0, false);
        
        emit InsuranceMade(msg.sender, _amount, typeOfInsurance, count);
     }

    /// @dev To hash String password and store it in bytes32
      function hashPassword (string memory a1) public pure returns (bytes32){
        return keccak256(abi.encode(a1));
    }
    /// @dev To check if the inputed password is correct  
     function stringsEqual (bytes32 _hashedPassword, string memory a2)public pure returns (bool){
        return _hashedPassword == keccak256(abi.encode(a2)) ? true : false;
    }

    function claim(uint id, uint _amount) public returns (bool){
       uint userPortId = portfolios[id].userInsuranceCount;
        Insurance storage _port = userInsurances[msg.sender][userPortId];
        require(_amount <= _port.amount, "Cannot claim above portfolio size");

        require(_port.isApproved, "You have not been permitted to withdraw yet");
        require(msg.sender == _port.beneficiary, "You are not a beneficiary to this portfolio");
        require(_amount <= _port.amountForBeneficiary, "Amount is more than approved for beneficiary");
             (bool success, ) = payable(msg.sender).call{value: _amount}("");
             require(success, "Transfer to beneficiary failed!");
             _port.amount -= _amount;
             if(success){
                emit ClaimMade(_port.owner, msg.sender, _amount, id);
                return true;
        } else {
            return false;
        }
         
    }

    /// @dev To deposit into the smart contract
    function insuranceDeposit(uint amount) payable noZeroAddress noReentrancy public returns (bool) {
        (bool success, ) = payable(mainAccount).call{value: amount}(""); 
        require(success, "Transfer Unsuccessful");
        if(success){
            emit InsuranceDeposit(msg.sender, amount);
            return true;
            } 
            else{
                return false;
            }
    }
    /// @dev Functional to facilitate a smart contract eth deposit
    receive() external payable {}

    /// @dev To change the withdrawal status of the beneficiary, that is pause or unpause withdrawal 
    function toggleAuthorisation(string memory _password, uint iD) payable public {
        require(msg.sender == userInsurances[msg.sender][iD].owner, "Not Owner of the Portfolio");
        bytes32 passCode = passwordHash[msg.sender];
        require(stringsEqual(passCode, _password), "Wrong Password!");

        if(!userInsurances[msg.sender][iD].isApproved){
            userInsurances[msg.sender][iD].isApproved = true;
        }else{
            userInsurances[msg.sender][iD].isApproved = false;
        }
    } 
    /// @dev Return the beneficiary address from the id of the portfolios
    function getBeneficiary(uint iD) public view returns(address){
        require(msg.sender == userInsurances[msg.sender][iD].owner, "Not Owner of the Portfolio");
        return userInsurances[msg.sender][iD].beneficiary;
    }

    function changeBeneficiaryAmount(uint iD, uint __amount, string memory _pass) public returns(bool){
        require(msg.sender == userInsurances[msg.sender][iD].owner, "Not Owner of the Portfolio");
        require(__amount <= userInsurances[msg.sender][iD].amount);
        bytes32 passCode = passwordHash[msg.sender];
        require(stringsEqual(passCode, _pass), "Wrong Password!");

        userInsurances[msg.sender][iD].amountForBeneficiary = __amount;
        return true;
    }

    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    function changeBeneficiary(uint iD, address _newBeneficiary) public {
        require(msg.sender == userInsurances[msg.sender][iD].owner, "Not Owner of the Portfolio");
        userInsurances[msg.sender][iD].beneficiary = _newBeneficiary;
    }

      function changePassword(string memory _pass, string memory newPass) public returns (bool) {
        bytes32 passCode = passwordHash[msg.sender];
        require(stringsEqual(passCode, _pass), "Wrong Password!");
        bytes32 _newPassWord = hashPassword(newPass);
        passwordHash[msg.sender] = _newPassWord;
        return true;
    }

    function topUpPortfolio(uint iD, uint _amount) public payable noReentrancy noZeroAddress{
        require(msg.sender == userInsurances[msg.sender][iD].owner, "Not the owner of the portfolio");
        Insurance storage _insureMe = userInsurances[msg.sender][iD];

        (bool success, ) = payable(mainAccount).call{value: _amount}("");
        require(success, "Transfer failed!");

        _insureMe.amount += _amount;
    }

    function transferBalance(uint amount, address payee) public payable onlyOwner noZeroAddress noReentrancy{
        require(amount <= getContractBalance(), "Amount greater than contract Balance");

        (bool success, ) = payable(payee).call{value: amount}("");
        require(success, "Transfer failed");
    }

 }
