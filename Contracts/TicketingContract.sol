pragma solidity >=0.7.0 <0.9;

contract TicketingSystem {
    address payable internal organizer;

    uint public ticketPrice;
    uint public visitorLimit;
    uint public eventStartTime;
    uint public eventFinishTime;
    
    uint internal eventMinTime;
    uint internal expirationTime;

    mapping (address => uint256) public addressToHeldWei;

    event EventCancelled(string errorMessage);

    constructor(uint _ticketPrice, uint _visitorLimit, uint _eventStartTime, uint _eventFinishTime){
        organizer = payable(msg.sender);

        ticketPrice = _ticketPrice;
        visitorLimit = _visitorLimit;
        eventStartTime = _eventStartTime;
        eventFinishTime = _eventFinishTime;

        eventMinTime = ((eventFinishTime - eventStartTime) * 30) / 100;
        expirationTime = eventFinishTime + 1 days;
    }

    struct Visitor{
        string name;
        string surname;
        address payable wallet;
    }

    Visitor[] public visitors;

    

    // organizer name check function 
    // also count when the visitor attend (inside of this function)


    // when visitor leave he needs to *** Check oracle then decide***

    // while checking leaving ppl check ratio of stayed/attended
    modifier checkSeats() {
        require(visitors.length < visitorLimit);
        _;
    }

    modifier checkTime() {
        require(block.timestamp < eventStartTime);
        _;
    }

    function buyTicket (string memory _name, string memory _surname) public payable checkSeats() checkTime() {
        require(msg.value == ticketPrice, "Wrong ticket price entered. Please check the value entered and try again.");
        visitors.push(Visitor(_name, _surname, payable(msg.sender)));
        addressToHeldWei[msg.sender] += msg.value;
    }

    modifier onlyOrganizer {
        require(msg.sender == organizer);
        _;
    }

    function refundAllWei () private {
        for (uint i = 0; i < visitors.length; i++) {
            visitors[i].wallet.transfer(ticketPrice);
        }
        emit EventCancelled("The event is cancelled");
    }

    function cancelEvent() public onlyOrganizer(){
        refundAllWei();
    }

    function isCancelled() private returns (bool) {

    }

    function contractExpiration() public { // think how to call this.
        require(block.timestamp > expirationTime, "The Contract is not expired yet!");
        if (isCancelled()){
            refundAllWei();
        }
        else{
            organizer.transfer(address(this).balance);
        }

    }
}