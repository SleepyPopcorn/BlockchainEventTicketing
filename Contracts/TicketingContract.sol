pragma solidity >=0.7.0 <0.9;

contract TicketingSystem {

    address payable internal organizer;

    uint public ticketPrice;
    uint public eventStartTime;
    uint public eventFinishTime;
    uint public visitorLimit;

    uint internal eventMinTime;
    uint internal expirationTime;

    mapping (address => uint256) public addressToHeldWei;

    event eventCancelled(string errorMessage);

    constructor(uint _ticketPrice, uint _visitorLimit, uint _eventStartTime, uint _eventFinishTime, uint _expirationTime){
        organizer = payable(msg.sender);

        ticketPrice = _ticketPrice;
        visitorLimit = _visitorLimit;
        eventStartTime = _eventStartTime;
        eventFinishTime = _eventFinishTime;
        expirationTime = _expirationTime;

        eventMinTime = ( (eventFinishTime - eventStartTime) * 30) / 100;
        expirationTime = eventFinishTime + 1 days;
    }

    struct Visitor{
        string name;
        string surname;
        address payable wallet;
    }

    Visitor[] public visitors;

    modifier checkSeats(){
        require(visitors.length < visitorLimit);
        _;
    }

    modifier checkTime(){
        require(block.timestamp < eventStartTime);
        _;
    }

    

}