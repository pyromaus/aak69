//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
// add parametric package/container insurance

contract RotterEngine {
    // using Chainlink for Chainlink.Request;
    struct Shipper {
        uint shipperID;
        address shipperAddy;
    }
    struct Container {
        uint containerID;
        uint shipperID;
        uint grossWeight;
        Coordinates origin;
        uint originTimestamp;
        Coordinates latestLoc;
        uint latestTimestamp;
        bool active;
        // address receiver;    for insurance products paying out to the receiver of goods
    }

    struct TrackingSnapshot {
        uint containerID;
        uint currentTimestamp;
        Coordinates currentLoc;
    }

    // this struct in mock and the live versions, a uint should be fed to the contract, not a string
    // 52.115421, 4.280247 = 052 115421 004 280247

    struct Coordinates {
        string latitude;
        string longitude;
    }
    mapping(address => Shipper) public shippers;
    mapping(uint => address) public shipperIdToAddress;
    uint[] public shipperIndex;
    mapping(address => mapping(uint => Container)) public containers;
    mapping(uint => address) public containerIdToOwner;
    mapping(address => uint[]) public containerIndex;

    address owner;
    bytes32 chainlinkJobId;
    bytes32 public reqId;
    uint oraclePayment;
    address link;
    address oracle;
    bool public active;

    uint public SEQ_shipperID = 0;
    uint public SEQ_containerID = 0;

    modifier OnlyOwner() {
        if (msg.sender != owner) {
            revert RotterEngine__NotOwner();
        }
        _;
    }
    modifier ContractActive() {
        if (!active) {
            revert RotterEngine__NotActive();
        }
        _;
    }
    modifier AdminCall() {
        if (msg.sender != owner) {
            address _shipper = msg.sender;
        }
        _;
    }

    error RotterEngine__NotOwner();
    error RotterEngine__NotActive();

    constructor(address _link, address _oracle) payable {
        // setChainlinkToken(_link);
        link = _link;
        oracle = _oracle;
        // setChainlinkOracle(_oracle);
        chainlinkJobId = "xxxxxxxxxxxxxxx";
        owner = msg.sender;
        active = true;
    }

    function newShipper(address _shipper) public OnlyOwner returns (uint) {
        SEQ_shipperID++;
        shippers[_shipper] = Shipper(SEQ_shipperID, _shipper);
        shipperIdToAddress[SEQ_shipperID] = _shipper;
        shipperIndex.push(SEQ_shipperID);
        return SEQ_shipperID;
    }

    function user_newShipper() public returns (uint) {
        SEQ_shipperID++;
        shippers[msg.sender] = Shipper(SEQ_shipperID, msg.sender);
        shipperIdToAddress[SEQ_shipperID] = msg.sender;
        shipperIndex.push(SEQ_shipperID);
        return SEQ_shipperID;
    }

    function addContainer(
        address _shipper,
        Coordinates memory _coords,
        uint _gWeight
    ) public OnlyOwner returns (uint) {
        SEQ_containerID++;
        containers[_shipper][SEQ_containerID] = Container(
            SEQ_containerID,
            shippers[_shipper].shipperID,
            _gWeight,
            _coords,
            block.timestamp,
            _coords,
            block.timestamp,
            true
        );
        containerIdToOwner[SEQ_containerID] = _shipper;
        containerIndex[_shipper].push(SEQ_containerID);
        return SEQ_containerID;
    }

    function user_addContainer(
        Coordinates memory _coords,
        uint _gWeight
    ) public returns (uint) {
        SEQ_containerID++;
        containers[msg.sender][SEQ_containerID] = Container(
            SEQ_containerID,
            shippers[msg.sender].shipperID,
            _gWeight,
            _coords,
            block.timestamp,
            _coords,
            block.timestamp,
            true
        );
        containerIdToOwner[SEQ_containerID] = msg.sender;
        containerIndex[msg.sender].push(SEQ_containerID);
        return SEQ_containerID;
    }

    // this will call an oracle to get the container's latest coordinates
    function trackContainer(
        // address _shipper,
        uint _containerID,
        //string memory _lat,
        //string memory _long
    ) public OnlyOwner ContractActive returns (Coordinates memory) {
        fetchNewTestCoords(
            getContainerOwner(_containerID),
            _containerID,
            _lat,
            _long
        );
        Coordinates memory freshCoords = containers[
            getContainerOwner(_containerID)
        ][_containerID].latestLoc;
        return freshCoords;
    }

    function user_trackContainer(
        uint _containerID,
        string memory _lat,
        string memory _long
    ) public ContractActive returns (Coordinates memory) {
        fetchNewTestCoords(msg.sender, _containerID, _lat, _long);
        Coordinates memory freshCoords = containers[msg.sender][_containerID]
            .latestLoc;
        return freshCoords;
    }

    // internally feed the contract new container coordinates for testing purposes
    function fetchNewTestCoords(
        address _shipper,
        uint _containerID,
        string memory _lat,
        string memory _long
    ) internal {
        containers[_shipper][_containerID].latestLoc.latitude = _lat;
        containers[_shipper][_containerID].latestLoc.longitude = _long;
    }

    function modifyGrossWeight(
        // need to require that the container exists.
        // address _shipper,
        uint _containerID,
        uint newWeight
    ) public OnlyOwner ContractActive returns (uint) {
        containers[getContainerOwner(_containerID)][_containerID]
            .grossWeight = newWeight;
        return newWeight;
    }

    function user_modifyGrossWeight(
        // need to add a check whether its their container to change
        uint _containerID,
        uint newWeight
    ) public ContractActive returns (uint) {
        containers[msg.sender][_containerID].grossWeight = newWeight;
        return newWeight;
    }

    function getLatestCoordinates(
        // address _shipper,
        uint _containerID
    ) public view OnlyOwner returns (Coordinates memory) {
        return
            containers[getContainerOwner(_containerID)][_containerID].latestLoc;
    }

    function user_getLatestCoordinates(
        uint _containerID
    ) public view returns (Coordinates memory) {
        return containers[msg.sender][_containerID].latestLoc;
    }

    // does msg.sender matter if it's a view function?

    function getLatestSnapshot(
        // address _shipper,
        uint _containerID
    ) public view OnlyOwner returns (TrackingSnapshot memory) {
        TrackingSnapshot memory latest;
        latest.containerID = _containerID;
        latest.currentTimestamp = block.timestamp;
        latest.currentLoc = containers[getContainerOwner(_containerID)][
            _containerID
        ].latestLoc;
        return latest;
    }

    function user_getLatestSnapshot(
        uint _containerID
    ) public view returns (TrackingSnapshot memory) {
        TrackingSnapshot memory latest;
        latest.containerID = _containerID;
        latest.currentTimestamp = block.timestamp;
        latest.currentLoc = containers[msg.sender][_containerID].latestLoc;
        return latest;
    }

    function concludeContainer(
        // address _shipper,
        uint _containerID
    ) public OnlyOwner ContractActive returns (bool) {
        containers[getContainerOwner(_containerID)][_containerID]
            .active = false;
        return true;
    }

    function reactivateContainer(
        // address _shipper,
        uint _containerID
    ) public OnlyOwner returns (bool) {
        containers[getContainerOwner(_containerID)][_containerID].active = true;
        return true;
    }

    function getContainerOwner(
        uint _containerID
    ) public view returns (address) {
        return containerIdToOwner[_containerID];
    }

    function getShipperAddressById(
        uint _shipperId
    ) public view returns (address) {
        return shipperIdToAddress[_shipperId];
    }

    // 52.115421, 4.280247 = 052 115421 004 280247

    // function convertUintResponseToCoordStruct(
    //     uint _coordsFromOracle
    // ) internal returns (Coordinates memory) {
    //     string memory latitude;
    //     string memory longitude;
}

// anyone can track the package with the advantage of
// having tracking without anyone knowing that youre tracking it
// cos its just a view function, theres no URL being visited and
// thereby tracked/pinged to the feds

// when you log on to any package tracking service on Web2, in the best
// case, they know somebody triggered a tracking info fetch at a known
// point in time (in the worst case, they identified the person) cos
// their server gets a ping when someone connects and loads the page etc.
// this can potentially put the package under greater scrutiny
//
// with this smart contract, the tracking info is written on-chain.
// the only pinging being done here is by the party updating the
// coordinates. the end-user calls a view function to see the latest
// coordinates, which doesn't leave a trace that anyone called anything

// check if the view function callers are invisible when they do it

// bro sell this to the DNM
// theres a massive upside to this
// millions of volume per site

// i have like 50 mil
// i have like 50 mil bro
// i have like 50 mill bro
// i have like 50 mill bro
// i rly dont care about the cash
