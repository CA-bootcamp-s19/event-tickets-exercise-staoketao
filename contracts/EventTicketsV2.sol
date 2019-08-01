pragma solidity ^0.5.0;

    /*
        The EventTicketsV2 contract keeps track of the details and ticket sales of multiple events.
     */
contract EventTicketsV2 {

    /*
        Define an public owner variable. Set it to the creator of the contract when it is initialized.
    */
    address public owner ;

    uint   PRICE_TICKET = 100 wei;

    /*
        Create a variable to keep track of the event ID numbers.
    */
    uint public idGenerator;

    /*
        Define an Event struct, similar to the V1 of this contract.
        The struct has 6 fields: description, website (URL), totalTickets, sales, buyers, and isOpen.
        Choose the appropriate variable type for each field.
        The "buyers" field should keep track of addresses and how many tickets each buyer purchases.
    */
    struct Event {
        string description;
        string URL;
        uint totalTickets;
        uint sales;
        mapping (address => uint) buyers;
        bool isOpen;

    }

    /*
        Create a mapping to keep track of the events.
        The mapping key is an integer, the value is an Event struct.
        Call the mapping "events".
    */
    mapping (uint => Event) events;



    event LogEventAdded(string desc, string url, uint ticketsAvailable, uint eventId);
    event LogBuyTickets(address buyer, uint eventId, uint numTickets);
    event LogGetRefund(address accountRefunded, uint eventId, uint numTickets);
    event LogEndSale(address owner, uint balance, uint eventId);


    constructor() public {
        owner= msg.sender;
    }

    /*
        Create a modifier that throws an error if the msg.sender is not the owner.
    */
    modifier isMsgSenderOwner() {
      require(msg.sender == owner);
      _;
    }

    /*
        Define a function called addEvent().
        This function takes 3 parameters, an event description, a URL, and a number of tickets.
        Only the contract owner should be able to call this function.
        In the function:
            - Set the description, URL and ticket number in a new event.
            - set the event to open
            - set an event ID
            - increment the ID
            - emit the appropriate event
            - return the event's ID
    */
    function addEvent(string memory description, string memory URL, uint totalTickets) public payable isMsgSenderOwner() returns (uint eventID)  {
      events[idGenerator].description = description;
      events[idGenerator].URL = URL;
      events[idGenerator].totalTickets = totalTickets;
      events[idGenerator].isOpen = true;
      emit LogEventAdded(description, URL, totalTickets, idGenerator);
      idGenerator +=1;

      return idGenerator-1;

    }

    /*
        Define a function called readEvent().
        This function takes one parameter, the event ID.
        The function returns information about the event this order:
            1. description
            2. URL
            3. ticket available
            4. sales
            5. isOpen
    */
    function readEvent(uint eventID) public view
        returns(string memory description, string memory website, uint ticketsAvailable, uint sales, bool isOpen) {
            return(events[eventID].description,events[eventID].URL, events[eventID].totalTickets-events[eventID].sales, events[eventID].sales, events[eventID].isOpen);

    }

    /*
        Define a function called buyTickets().
        This function allows users to buy tickets for a specific event.
        This function takes 2 parameters, an event ID and a number of tickets.
        The function checks:
            - that the event sales are open
            - that the transaction value is sufficient to purchase the number of tickets
            - that there are enough tickets available to complete the purchase
        The function:
            - increments the purchasers ticket count
            - increments the ticket sale count
            - refunds any surplus value sent
            - emits the appropriate event
    */
    function buyTickets(uint eventID, uint buyedTickets) public payable {
        require(events[eventID].isOpen == true);
        require(msg.value >= buyedTickets* PRICE_TICKET );
        require(events[eventID].totalTickets-events[eventID].sales >= buyedTickets);
        events[eventID].buyers[msg.sender]+=buyedTickets;
        events[eventID].sales += buyedTickets;
        uint totalPrice = buyedTickets * PRICE_TICKET;
        uint change = msg.value - totalPrice;
        msg.sender.transfer(change);
        emit LogBuyTickets(msg.sender, eventID, buyedTickets);
    }

    /*
        Define a function called getRefund().
        This function allows users to request a refund for a specific event.
        This function takes one parameter, the event ID.
        TODO:
            - check that a user has purchased tickets for the event
            - remove refunded tickets from the sold count
            - send appropriate value to the refund requester
            - emit the appropriate event
    */
    function getRefund(uint eventID) public payable {
        uint returnTickets= events[eventID].buyers[msg.sender];
        require(returnTickets > 0);
        events[eventID].sales-=returnTickets;
        events[eventID].buyers[msg.sender]=0;
        msg.sender.transfer(returnTickets * PRICE_TICKET);
        emit LogGetRefund(msg.sender, eventID, returnTickets);
    }

    /*
        Define a function called getBuyerNumberTickets()
        This function takes one parameter, an event ID
        This function returns a uint, the number of tickets that the msg.sender has purchased.
    */
    function getBuyerNumberTickets(uint eventID) public view
        returns(uint purchasedTickets) {

            return (events[eventID].buyers[msg.sender]);

    }

    /*
        Define a function called endSale()
        This function takes one parameter, the event ID
        Only the contract owner can call this function
        TODO:
            - close event sales
            - transfer the balance from those event sales to the contract owner
            - emit the appropriate event
    */
    function endSale(uint eventID) public payable isMsgSenderOwner {
        events[eventID].isOpen = false;
        uint balance = (events[eventID].sales * PRICE_TICKET);
        msg.sender.transfer(balance);
        emit LogEndSale(owner, balance, eventID);
    }


}

