// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.0;

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
    
    mapping(address => uint256) public players;

    using SafeMath for uint256;
    
    uint256 totalSupply_;

    // Slot machine private variables
    uint256 private constant hBound = 900 * (10 ** decimals);
    uint256 public pool;
    uint256 private constant columns = 1;
    uint256[] private subdivisions;
    uint256 private constant subdiv = 9;
    uint256 private hProb = 80;
    uint256 public prizeValue = 0;
    uint256 public mean = 0;
    uint256 public nonce;
    uint256 public globalRandom;
    
    
    

    function create_subdiv() private pure returns (uint256[] memory) {
        
        uint256 curr_prob;
        
        uint256[] memory sub_arr = new uint[](subdiv);

        for (uint i = 0; i < subdiv; i++ ) {
            curr_prob =  i**2;
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
        pool += amount * 10 ** decimals;
        players[msg.sender] += amount * 10 ** decimals;
        transfer(address(this), amount * 10 ** decimals);
    }


    // RNG function -- generate random n number and get the average value
    function random() public returns (uint256) {
        uint256 randomnumber = uint256(keccak256(abi.encodePacked(now, msg.sender, nonce))) % 101;
        nonce++;
        globalRandom = randomnumber;
        return randomnumber;
    }

    /*function a() public view returns (uint256) {
        return subdivisions[3];
    }*/

    

    function play() public {
        if (players[msg.sender] > 0) {
            uint256 amount = players[msg.sender];
            //players[msg.sender] = 0;
            mean = 0;
            for (uint i = 0; i < columns; i++) {
                mean += random();
            }
            //mean = mean / columns;
            
            if (win()) {
                prize(amount);
            } 
        }
        
    }
    // win function
    
    function win() private view returns (bool) {
        if (pool > hBound) {
            uint256 chance = 100 - hProb;
            return mean > chance;
        }

        uint256 x = uint256((hBound - pool)/100); //Number from 0 to 8

        uint256 chance = subdivisions[subdiv - 1 - x];
        return mean > chance;
        
    }

    // prize function

    function prize(uint256 amount) private {
        transfer(msg.sender, amount * 10 ** decimals);
        amount = amount * 10 ** decimals;
        pool -= amount;
        uint256 perc = (amount/100) * 20;
        pool -= perc;
        prizeValue = amount + perc;
    }
}
