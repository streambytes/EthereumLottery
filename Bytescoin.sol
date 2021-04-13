// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.0;

interface IERC20 {

    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

library SafeMath {
    function sub(uint a, uint b) internal pure returns (uint) {
      assert(b <= a);
      return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
      uint c = a + b;
      assert(c >= a);
      return c;
    }
}


contract ERC20 is IERC20 {

    string public constant name = "Bytescoin";
    string public constant symbol = "BYC";
    uint public constant decimals = 8;
    uint public constant initialSupply_ = 1312500 ; //Chosen by Fuliggine

    //event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    //event Transfer(address indexed from, address indexed to, uint tokens);


    mapping(address => uint) balances;

    mapping(address => mapping (address => uint)) allowed;
    
    mapping(address => uint) public players;

    using SafeMath for uint;
    
    uint totalSupply_;

    // Slot machine private variables
    uint private constant hBound = 1000 * (10 ** decimals);
    uint private pool;
    uint private constant columns = 3;
    uint[] private subdivisions;
    uint private constant subdiv = 9; // 9
    uint private hProb = 67;
    uint private lProb = 1;
    uint private mean = 0;
    uint private nonce;
    
    

    function create_subdiv() private view returns (uint[] memory) {
        uint curr_prob;
        uint[] memory sub_arr = new uint[](subdiv + 1);
        
        // lowest value
        sub_arr[0] = 100 - lProb;
        sub_arr[1] = 100 - lProb;

        for (uint i = 1; i < (subdiv); i++ ) {
            curr_prob =  i**2;
            sub_arr[i+1] = 100 - curr_prob;
        }

        return sub_arr;
    }

    constructor() public {
        totalSupply_ = initialSupply_ * (10 ** decimals);
        // Split totalSupply between owner and the contract
        balances[msg.sender] = totalSupply_ - (hBound / 2);
        balances[address(this)] = hBound / 2;
        pool = balances[address(this)];
        subdivisions = create_subdiv();
    }

    function totalSupply() public override view returns (uint) {
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns (uint) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint numTokens) public override returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address spender, uint numTokens) public override returns (bool) {
        allowed[msg.sender][spender] = numTokens;
        emit Approval(msg.sender, spender, numTokens);
        return true;
    }

    function allowance(address owner, address spender) public override view returns (uint) {
        return allowed[owner][spender];
    }

    function transferFrom(address owner, address buyer, uint numTokens) public override returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);
        
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }

    // Bet function -- some address sends tokens to the contract and we add them to the pool
    function bet(uint amount) public {
        pool += amount * 10 ** decimals;
        players[msg.sender] += amount * 10 ** decimals;
        transfer(address(this), amount * 10 ** decimals);
    }


    // RNG function -- generate random n number and get the average value
    function random() private returns (uint) {
        uint randomnumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % 101;
        nonce++;
        return randomnumber;
    }

    function play() public returns (string memory) {
        if (players[msg.sender] > 0) {
            uint amount = players[msg.sender];
            players[msg.sender] = 0;
            mean = 0;
            for (uint i = 0; i < columns; i++) {
                mean += random();
            }
            mean = mean / columns;
            
            if (win()) {
                prize(amount);
                return "You won!";
            }
            
            return "You lost!";
        }
        return "You have to bet first!";
    }
    
    // win function
    function win() private view returns (bool) {
        if (pool > hBound) {
            uint chance = 100 - hProb;
            return mean > chance;
        }

        uint x = uint((hBound - pool)/(100 * 10 ** decimals)); //Number from 0 to 8

        uint chance = subdivisions[subdiv - 1 - x];
        return mean > chance;
        
    }

    // prize function
    function prize(uint amount) private {
        pool -= amount;
        uint perc = (pool/100) * 20;
        pool -= perc;
        
        allowed[address(this)][msg.sender] = amount + perc;
        transferFrom(address(this), msg.sender, amount + perc);
    }
}
