

    pragma solidity >=0.7.0 <0.9;

    contract TicketingSystem {
        
        address payable internal organizer;

        //* Publicly accessable variables 
        uint public ticketPrice;
        uint public visitorLimit;
        uint public eventStartTime;
        uint public eventFinishTime;
        
        //* Internal derived variables
        uint internal eventMinTime;
        uint internal expirationTime;

        //* Private visitor status counts
        uint private stayed;
        uint private attended;
        uint private notAttended;

        //* To Store wei
        mapping (address => uint256) private addressToHeldWei;

        //* Events
        event EventCancelled(string errorMessage);

        //* Status of the contract
        enum EventStatus {ONGOING, FINISHED, CANCELLED}
        EventStatus private statusOfEvent;

        //* Status of the visitors
        enum VisitorStatus {NOT_ATTENDED, ATTENDED, STAYED}
        VisitorStatus private statusOfVisitor;

        constructor(uint _ticketPrice, uint _visitorLimit, uint _eventStartTime, uint _eventFinishTime){
            organizer = payable(msg.sender);

            ticketPrice = _ticketPrice;
            visitorLimit = _visitorLimit;
            eventStartTime = _eventStartTime;
            eventFinishTime = _eventFinishTime;

            eventMinTime = eventStartTime + ((eventFinishTime - eventStartTime) * 30) / 100;
            expirationTime = eventFinishTime + 1 days; 

            statusOfEvent = EventStatus.ONGOING;
        }

        //* To Store Visitors
        struct Visitor{
            uint256 ID;
            address payable walletAddress;
            VisitorStatus status;
        }

        Visitor[] private visitors;

        // ************************
        // ****** MODIFIERS *******
        // ************************

        modifier statusCheck() {
            if (statusOfEvent == EventStatus.CANCELLED) {
                revert("The Event is Cancelled. You can not use this The Contract anymore");
            }
            else if (statusOfEvent == EventStatus.FINISHED){
                revert("The Event is Over. You can not use this The Contract anymore");
            }       
            _;
        }
        
        modifier checkSeats(){
            require(visitors.length < visitorLimit, "All tickets are taken");
            _;
        }

        modifier checkEventStartTime(){
            require(block.timestamp < eventStartTime, "The event is already started! You cannot buy tickets");
            _;
        }

        modifier onlyOrganizer(){
            require(msg.sender == organizer, "This function is Organizer Only!");
            _;
        }

        modifier onlyOracle(){
            require(msg.sender == oracleAddress, "This function is not open for everyone");
            _;
        }

        // *******************************
        // ****** HELPER FUNCTIONS *******
        // *******************************

        uint testFLAG = 0;
        function calculateRatios() private {
            testFLAG = visitors.length;
            for (uint i = 0; i < visitors.length; i++) {
                if (visitors[i].status == VisitorStatus.STAYED)
                    stayed++;
                else if(visitors[i].status == VisitorStatus.ATTENDED)
                    attended++;
                else 
                    notAttended++;
            }
        }

        function checkStayedOverAttendedRatio() private view returns(bool){
            if (stayed >= attended)
                return true;
            else 
                return false;
        }

        function checkAttendedOverNotAttended() private view returns(bool){
            if (attended + stayed >= notAttended)
                return true;
            else    
                return false;
        }

        function refundAllWei () private{
            for (uint i = 0; i < visitors.length; i++) {
                visitors[i].walletAddress.transfer(ticketPrice);
            }
        statusOfEvent = EventStatus.CANCELLED;
            emit EventCancelled("The event is cancelled");
        }

        function isCancelled() private view returns (bool){

            if (checkStayedOverAttendedRatio() && checkAttendedOverNotAttended()) {
                return false;
            }

            return true;
        }

        function checkNameSurnameEntrance(uint256 _userID) private view returns(uint){
            uint result = visitorLimit + 1;
            for(uint i = 0; i < visitors.length; i++) {
                if (keccak256(abi.encodePacked(visitors[i].ID)) == keccak256(abi.encodePacked(_userID))
                && visitors[i].status == VisitorStatus.NOT_ATTENDED) { 
                    result = i;
                    break;
                }
            }
            return result;
        }

        function checkNameSurnameExit(uint256 _userID) private view returns(uint){
            uint result = visitorLimit + 1;
            for(uint i = 0; i < visitors.length; i++) {
                if (keccak256(abi.encodePacked(visitors[i].ID)) == keccak256(abi.encodePacked(_userID))
                && visitors[i].status != VisitorStatus.STAYED) { 
                    result = i;
                    break;
                }
            }
            return result;
        }

        function checkAddress(address _visitorAddress) private view returns (bool) {
            bool result = true;
            for(uint i = 0; i < visitors.length; i++) {
                if (visitors[i].walletAddress == _visitorAddress) { 
                    result = false;
                    break;
                }
            }
            return result;
        }

        // *******************************
        // ****** PUBLIC FUNCTIONS *******
        // *******************************
        
        // Oracle Function
        function visitorLeaveCheck(uint256 _userID) public statusCheck() onlyOracle() returns(string memory){
            uint index = checkNameSurnameExit(_userID);
            require(index != visitorLimit + 1, "Invalid userID. Please try again!");
            if (eventMinTime < block.timestamp){
                visitors[index].status = VisitorStatus.STAYED;
            }

            return "The Visitor is marked as STAYED";
        }

        // Oracle Function
        function visitorEnterCheck(uint256 _userID) public statusCheck() onlyOracle() returns(string memory){
            uint index = checkNameSurnameEntrance(_userID);
            require(index != visitorLimit + 1, "-- The userID is not found on the list. --");
            visitors[index].status = VisitorStatus.ATTENDED;
            return "++ The userID is on the list. The Visitor is marked as ATTENDED ++";
        }
        
        function buyTicket () public payable statusCheck() checkSeats() checkEventStartTime() returns(uint) {
            require(msg.value == ticketPrice, "Wrong ticket price entered. Please check the value entered and try again.");
            require(checkAddress(msg.sender), "Only one ticket is allowed for per address");
            uint userID = uint(keccak256(abi.encodePacked(msg.sender)));
            visitors.push(Visitor(userID, payable(msg.sender), VisitorStatus.NOT_ATTENDED));
            addressToHeldWei[msg.sender] += msg.value;
            return userID;
        }

        function cancelEvent() public statusCheck() onlyOrganizer(){
            refundAllWei();
        }

        function contractExpiration() statusCheck() public{
            require(block.timestamp > expirationTime, "The Contract is not expired yet!");
            calculateRatios();
            if (isCancelled()){
                refundAllWei();
            }
            else{
                organizer.transfer(address(this).balance);
                statusOfEvent = EventStatus.FINISHED;
            }

        }

        // *******************************
        // ******* TEST FUNCTIONS ********
        // *******************************
        uint onlyOnceFlag = 0;
        
        modifier onlyOnce(){
            require(onlyOnceFlag == 0, "Oracle is already assigned.");
            onlyOnceFlag = 1;
            _;
        }
        
        address public oracleAddress;
        function assignOracle() public onlyOnce() {
            oracleAddress = msg.sender;
        }
    }

    