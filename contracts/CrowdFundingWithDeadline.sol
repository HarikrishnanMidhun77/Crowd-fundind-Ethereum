pragma solidity >=0.4.21 <0.7.0;


contract CrowdFundingWithDeadline {
    enum State {Ongoing, Failed, Succeeded, Paidout}

    string public name;
    uint256 public targetAmount;
    uint256 public fundingDeadline;
    address payable public beneficiary;
    State public state;
    mapping(address => uint256) public amounts;
    bool public collected;
    uint256 public totalCollected;

    modifier inState(State expectedState) {
        require(state == expectedState, "Invalid State");
        _;
    }

    constructor(
        string memory contractName,
        // uint256 targetAmountEth,
        uint256 targetAmountWei,
        uint256 durationInMin,
        address beneficiaryAddress
    ) public {
        name = contractName;
        targetAmount = targetAmountWei; //targetAmountEth * 1 ether;
        fundingDeadline = currentTime() + durationInMin * 1 minutes;
        beneficiary = address(uint160(beneficiaryAddress));
        state = State.Ongoing;
    }

    function contribute() public payable inState(State.Ongoing) {
        require(beforeDeadline(), "No contributions after deadline!");
        totalCollected += msg.value;
        amounts[msg.sender] += msg.value;

        if (totalCollected >= targetAmount) {
            collected = true;
        }
    }

    function beforeDeadline() public view returns (bool) {
        return currentTime() < fundingDeadline;
    }

    function finishCrowdFunding() public inState(State.Ongoing) {
        require(
            !beforeDeadline(),
            "cannot finish campaign before the deadline!"
        );
        if (!collected) {
            state = State.Failed;
        } else {
            state = State.Succeeded;
        }
    }

    function collect() public payable inState(State.Succeeded) {
        if (beneficiary.send(totalCollected)) {
            state = State.Paidout;
        } else {
            state = State.Failed;
        }
    }

    function withdraw() public payable inState(State.Failed) {
        require(amounts[msg.sender] > 0, "No contributions");
        uint256 contributed = amounts[msg.sender];
        amounts[msg.sender] = 0;

        if (!msg.sender.send(contributed)) {
            amounts[msg.sender] = contributed;
        }
    }

    function currentTime() internal view returns (uint256) {
        return now;
    }
}
