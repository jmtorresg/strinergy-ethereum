pragma solidity ^0.5;

// This simple ERC20 contract represents a tokenized energy project
// It has a fixed supply of tokens that are emitted on contract creation
// There will be one instance of this per energy project
contract AccessToken {
    string public constant name = "Strinergy Access Token";
    string public constant symbol = "SXA";
    uint8 public constant decimals = 18; // TBD depending on the unit we choose

    address payable _owner; // This address is payable because of the kill function
    uint256 _totalSupply;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    // Participant set operations
    mapping(address => uint) participantIndex;
    address[] participants;

    function addParticipant(address participant) private returns (uint) {
        uint index = participantIndex[participant];
        uint new_index = participants.length + 1;

        if(index == 0) {
            participants.push(participant);
            participantIndex[participant] = new_index;
            return new_index;
        }

        participants[index - 1] = participant;
        return index;
    }

    function removeParticipant(address participant) private {
        uint index = participantIndex[participant];
        if(index != 0) {
            participants[index - 1] = address(0x0);
        }
    }

    // ERC20 events

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);

    // Constructor

    constructor(uint256 totalSupply) public {
        _owner = msg.sender;
        _totalSupply = totalSupply;
        balances[_owner] = totalSupply;
    }

    // ERC20 functions

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender], "Insufficient funds");
        balances[msg.sender] = balances[msg.sender] - numTokens;
        balances[receiver] = balances[receiver] + numTokens;
        if(receiver != _owner) addParticipant(receiver);
        if(balances[msg.sender] == 0) removeParticipant(msg.sender);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[owner], "Insufficient funds in owner's account");
        require(numTokens <= allowed[owner][msg.sender], "Allowance too low");
        balances[owner] = balances[owner] - numTokens;
        allowed[owner][msg.sender] = allowed[owner][msg.sender] - numTokens;
        balances[receiver] = balances[receiver] + numTokens;
        if(receiver != _owner) addParticipant(receiver);
        if(balances[owner] == 0) removeParticipant(owner);
        emit Transfer(owner, receiver, numTokens);
        return true;
    }

    // Extended access extension functions
    function getParticipants() public view returns (address[] memory) {
        return participants;
    }

    function kill() public {
        require(msg.sender == _owner, "Only the owner of the contract can kill it");
        selfdestruct(_owner);
    }
}

// This is an ERC20-compatible contract whose tokens represent energy production
contract EnergyToken {
    string public constant name = "Strinergy Energy Token";
    string public constant symbol = "SXE";
    uint8 public constant decimals = 0; // TBD depending on the unit we choose

    address payable _owner;
    uint256 _totalSupply;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    // Energy token contract extensions
    mapping(address => bool) registeredProjects;
    mapping(address => bool) registeredMeterIds;
    mapping(address => address) meterProjects;
    mapping(address => uint256) projectBalances;

    // ERC20 events

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);

    // Constructor

    constructor() public {
        _owner = msg.sender;
        _totalSupply = 0;
    }

    // ERC20 functions

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender], "Insufficient funds");
        balances[msg.sender] = balances[msg.sender] - numTokens;
        balances[receiver] = balances[receiver] + numTokens;
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[owner], "Insufficient funds in owner's account");
        require(numTokens <= allowed[owner][msg.sender], "Allowance too low");
        balances[owner] = balances[owner] - numTokens;
        allowed[owner][msg.sender] = allowed[owner][msg.sender] - numTokens;
        balances[receiver] = balances[receiver] + numTokens;
        emit Transfer(owner, receiver, numTokens);
        return true;
    }

    // Energy token extension events
    event Production(address meter, address project, uint amount);
    event ProductionDistribution(address project, uint amount);
    event Debug(uint amount, address destination);

    // Energy token extension functions
    function registerProject(address project) public returns (bool) {
        require(msg.sender == _owner, "Only the owner of the contract can register new projects");
        registeredProjects[project] = true;
        return true;
    }

    function registerMeter(address meter, address project) public returns (bool) {
        require(msg.sender == _owner, "Sender is not the owner");
        require(registeredProjects[project], "Project is not registered");
        registeredMeterIds[meter] = true;
        meterProjects[meter] = project;
        return true;
    }

    function projectBalance(address project) public view returns (uint256) {
        return projectBalances[project];
    }

    // This function lets a production meter notify it has produced a certain amount of energy
    function productionNotify(uint amount) public returns (bool) {
        require(registeredMeterIds[msg.sender], "Meter is not registered");

        // Emit the energy tokens
        address project = meterProjects[msg.sender];
        projectBalances[project] = projectBalances[project] + amount;
        emit Production(msg.sender, project, amount);

        // Distribute them according to ownership
        AccessToken accessTokenContract = AccessToken(project);
        uint256 accessTokenSupply = accessTokenContract.totalSupply(); // TODO: read from access token contract
        address[] memory participants = accessTokenContract.getParticipants(); // TODO: read from access token contract
        uint256 energyPerAccessToken = 0;
        uint256 tokensToDistribute = 0;

        if(projectBalances[project] > accessTokenSupply) {
            tokensToDistribute = projectBalances[project] - (projectBalances[project] % accessTokenSupply);
            energyPerAccessToken = tokensToDistribute / accessTokenSupply;
        }

        // NOTE: the tokens that do not have "rightful" owners are burned when distribution happens
        if(tokensToDistribute > 0) {
            projectBalances[project] = projectBalances[project] - tokensToDistribute;

            uint256 currentParticipantShare;
            for(uint i = 0; i < participants.length; i++) {
                if(participants[i] == address(0x0)) continue;
                currentParticipantShare = accessTokenContract.balanceOf(participants[i]) * energyPerAccessToken;
                balances[participants[i]] = balances[participants[i]] + currentParticipantShare;
            }
            emit ProductionDistribution(project, tokensToDistribute);
        }

        return true;
    }

    function kill() public {
        require(msg.sender == _owner, "Only the owner of the contract can kill it");
        selfdestruct(_owner);
    }
}
