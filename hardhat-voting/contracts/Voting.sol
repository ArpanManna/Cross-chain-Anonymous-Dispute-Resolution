// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {LinkTokenInterface} from "./LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";

contract Voting is CCIPReceiver, VRFConsumerBaseV2, ConfirmedOwner {
    address link;
    address router;
    string public latestMessageText;
    address public latestMessageSender;
    uint disputeId;
    VRFCoordinatorV2Interface COORDINATOR;
    uint256[] public requestIds;
    uint256 public lastRequestId;
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;
    uint totalDisputes = 0;

    struct Vote {
        address disputeRaiser;
        string reason;
        uint duration;
        uint totalVoters;
        uint votesA;
        uint votesB;
        mapping(address => uint) voting_ballot;
    }
    struct OnGoingDisputes {
        address disputeRaiser;
        string reason;
        uint duration;
        uint totalVoters;
        uint votesA;
        uint votesB;
    }

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */

    constructor(
        address _router,
        address _link
    ) CCIPReceiver(_router) VRFConsumerBaseV2(getCordinator(_router)) ConfirmedOwner(msg.sender) {
        link = _link;
        router = _router;
        COORDINATOR = VRFCoordinatorV2Interface(getCordinator(router));
        LinkTokenInterface(link).approve(router, type(uint256).max);
    }

    mapping(uint => Vote) public disputedProjects; // mapping of disputed project Id to Vote Details
    uint256 votingPeriodConstant = 1 hours;

    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    function initializeVoting(uint _disputeId, string memory _reason) public {
        require(disputedProjects[_disputeId].duration == 0, "Already Initialized!");
        disputedProjects[_disputeId].reason = _reason;
        disputedProjects[_disputeId].totalVoters = 100;
        disputedProjects[_disputeId].disputeRaiser = msg.sender;
        disputedProjects[_disputeId].duration = block.timestamp + votingPeriodConstant;
        totalDisputes++;
    }

    function checkVotingEligibility(uint _disputeId, uint _VRFdata) internal view returns (bool) {
        if (_VRFdata < disputedProjects[_disputeId].totalVoters) {
            return true;
        }
        return false;
    }

    function vote(
        uint _disputeId,
        uint _vote,
        uint64 sourceChainSelector,
        uint64 destinationChainSelector,
        address _receiver,
        uint _VRFdata
    ) public {
        string memory voteString;
        if (_vote == 1) {
            voteString = "A";
        } else if (_vote == 2) {
            voteString = "B";
        }

        if (sourceChainSelector == destinationChainSelector) {
            if (_vote == 1 && checkVotingEligibility(_disputeId, _VRFdata)) {
                disputedProjects[_disputeId].votesA += 1; // add vote in favor of A
            } else if (_vote == 2 && checkVotingEligibility(_disputeId, _VRFdata)) {
                disputedProjects[_disputeId].votesB += 1; // add vote in favor of B
            }
        } else if (sourceChainSelector != destinationChainSelector) {
            Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
                receiver: abi.encode(_receiver),
                data: abi.encode(_disputeId, voteString, _VRFdata),
                tokenAmounts: new Client.EVMTokenAmount[](0),
                feeToken: link,
                extraArgs: ""
            });
            IRouterClient(router).ccipSend(destinationChainSelector, message);
        }
        disputedProjects[_disputeId].voting_ballot[msg.sender] = _vote;
    }

    function _ccipReceive(Client.Any2EVMMessage memory message) internal override {
        (uint _disputeId, string memory _vote, uint randomness) = abi.decode(
            message.data,
            (uint, string, uint)
        );
        latestMessageSender = abi.decode(message.sender, (address));
        require(disputedProjects[_disputeId].duration != 0, "Voting Not Started Yet!");
        require(
            disputedProjects[_disputeId].duration > block.timestamp,
            "Voting for this project is Over!"
        );
        if (compare(_vote, "A")) {
            if (checkVotingEligibility(_disputeId, randomness)) {
                disputedProjects[_disputeId].votesA += 1; // add vote in favor of A
            }
        } else if (compare(_vote, "B")) {
            if (checkVotingEligibility(_disputeId, randomness)) {
                disputedProjects[_disputeId].votesB += 1; // add vote in favor of A
            }
        }
    }

    function getOngoingDisputes() public view returns (OnGoingDisputes[] memory) {
        uint ongoingDisputes = 0;
        for (uint i = 1; i <= totalDisputes; i++) {
            if (disputedProjects[i].duration < block.timestamp) {
                ongoingDisputes++;
            }
        }
        OnGoingDisputes[] memory disputes = new OnGoingDisputes[](ongoingDisputes);
        uint count = 0;
        for (uint i = 1; i <= totalDisputes; i++) {
            if (disputedProjects[i].duration < block.timestamp) {
                disputes[count].disputeRaiser = disputedProjects[i].disputeRaiser;
                disputes[count].reason = disputedProjects[i].reason;
                disputes[count].duration = disputedProjects[i].duration;
                disputes[count].totalVoters = disputedProjects[i].totalVoters;
                disputes[count].votesA = disputedProjects[i].votesA;
                disputes[count].votesB = disputedProjects[i].votesB;
                count++;
            }
        }
        return disputes;
    }

    function getVotingResult(uint _disputeId) public view returns (uint) {
        require(disputedProjects[_disputeId].duration != 0, "Voting not started yet");
        require(disputedProjects[_disputeId].duration < block.timestamp, "Voting not over yet!");
        if (disputedProjects[_disputeId].votesA == disputedProjects[_disputeId].votesB) return 0;
        return disputedProjects[_disputeId].votesA > disputedProjects[_disputeId].votesB ? 1 : 2;
    }

    function getVotingDetails(uint _disputeId) public view returns (uint, uint) {
        //Vote storage vote =  projects[projectId];
        return (disputedProjects[_disputeId].votesA, disputedProjects[_disputeId].votesB);
    }

    function compare(string memory str1, string memory str2) internal pure returns (bool) {
        return keccak256(abi.encodePacked(str1)) == keccak256(abi.encodePacked(str2));
    }

    function getCordinator(address _router) public pure returns (address coordinator) {
        if (_router == 0x554472a2720E5E7D5D3C817529aBA05EEd5F82D8) {
            // avalanche fuji
            return 0x2eD832Ba664535e5886b75D64C46EB9a228C2610;
        } else if (_router == 0x70499c328e1E2a3c41108bd3730F6670a44595D1) {
            // polygon mumbai
            return 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;
        } else if (_router == 0x9527E2d01A3064ef6b50c1Da1C0cC523803BCFF2) {
            // BNB chain
            return 0x6A2AAd07396B36Fe02a22b33cf443582f682c82f;
        } else if (_router == 0xD0daae2231E9CB96b94C8512223533293C3693Bf) {
            // sepolia
            return 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625;
        }
    }

    function getKeyHash(address _router) public pure returns (bytes32 keyHash) {
        if (_router == 0x554472a2720E5E7D5D3C817529aBA05EEd5F82D8) {
            return 0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61;
        } else if (_router == 0x70499c328e1E2a3c41108bd3730F6670a44595D1) {
            // polygon mumbai
            return 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;
        } else if (_router == 0x9527E2d01A3064ef6b50c1Da1C0cC523803BCFF2) {
            // BNB chain
            return 0xd4bb89654db74673a187bd804519e65e3f71a52bc55f11da7601a13dcf505314;
        } else if (_router == 0xD0daae2231E9CB96b94C8512223533293C3693Bf) {
            // sepolia
            return 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
        }
    }

    function getSubscriptionId(address _router) public pure returns (uint64 subscriptionId) {
        if (_router == 0x554472a2720E5E7D5D3C817529aBA05EEd5F82D8) {
            // avalanche fuji
            return 845;
        } else if (_router == 0x70499c328e1E2a3c41108bd3730F6670a44595D1) {
            // polygon mumbai
            return 6648;
        } else if (_router == 0x9527E2d01A3064ef6b50c1Da1C0cC523803BCFF2) {
            // BNB chain
            return 3250;
        } else if (_router == 0xD0daae2231E9CB96b94C8512223533293C3693Bf) {
            // sepolia
            return 7583;
        }
    }

    // Assumes the subscription is funded sufficiently.
    function requestRandomWords() external onlyOwner returns (uint256 requestId) {
        requestId = COORDINATOR.requestRandomWords(
            getKeyHash(router),
            getSubscriptionId(router),
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(_requestId, _randomWords);
    }

    function getRequestStatus(
        uint256 _requestId
    ) external view returns (bool fulfilled, uint256 randomWords) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords[0] % 100);
    }
}
