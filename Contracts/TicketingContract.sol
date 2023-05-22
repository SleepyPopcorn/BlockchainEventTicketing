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

    event eventCancelled(string errorMessage);

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

}