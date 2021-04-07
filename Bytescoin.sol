// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}


contract ERC20 is IERC20 {

    string public constant name = "Bytescoin";
    string public constant symbol = "BYC";
    uint256 public constant decimals = 8;
    uint256 public constant initialSupply_ = 1312500 ; //Chosen by Fuliggine

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);


    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;

    using SafeMath for uint256;
    
    uint256 totalSupply_;

    // Slot machine private variables
    uint256 private constant hBound = 1000 * (10 ** decimals);
    uint256 private pool;
    uint256 private constant columns = 4;
    int private constant hProb = 65;
    uint8[] private subdivisions;
    uint8 private constant subdiv = 10;

    function create_subdiv() private returns (uint8[subdiv] memory) {
        
        int rate = -5;
        int curr_prob = hProb;
        
        uint[] memory sub_arr = new uint[](subdiv);

        for (int i = subdiv - 1; i >= 0; i-- ) {
            curr_prob = curr_prob * (1 + rate/100)**(i + 1);
            sub_arr[i] = 100 - curr_prob;
        }

        return sub_arr;

    }

    constructor() public {
        totalSupply_ = initialSupply_ * (10 ** decimals);
        // Split totalSupply between owner and the contract
        balances[msg.sender] = totalSupply_ - hBound;
        balances[address(this)] = hBound;
        pool = balances[address(this)];
        subdivisions = create_subdiv();
    }

    function totalSupply() public override view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address spender, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][spender] = numTokens;
        emit Approval(msg.sender, spender, numTokens);
        return true;
    }

    function allowance(address owner, address spender) public override view returns (uint) {
        return allowed[owner][spender];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);
        
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }

    // Bet function -- some address sends tokens to the contract and we add them to the pool

    function bet(uint256 amount) public {
        transfer(address(this), amount * 10 ** decimals);
        pool += amount * 10 ** decimals;
    }
    
    function viewpool() public view returns (uint256) {
        return pool;
    }

    // RNG function -- generate random n number and get the average value
    function random() private view returns (uint) {
        return uint(keccak256(block.timestamp, block.difficulty))%101;
    }

    function play() public view returns (uint256){
        uint256 mean = 0;
        for (uint i = 0; i < columns; i++) {
            mean += random();
        }
        mean = mean / columns;
        return mean;
    }

    function a() public view returns (uint8) {
        return subdivisions[0];
    }

    // win function

    // prize function
}