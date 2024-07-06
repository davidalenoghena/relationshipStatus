// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract relStatus_Contract {
    enum RelStatus { Single, Pending, Relationship }

    struct Profile {
        uint256 id;
        address profileAddress;
        string name;
        RelStatus relStatus;
        address partner;
        string instID;
    }

    Profile[] public profiles;
    uint256 public profileCount = 0;
    //mapping(uint256 => Profile) public profiles;

    address public owner;

    constructor() {
        owner = msg.sender; //whosoever has connected their wallet
    }

    //check if the address exists
    function Search(address _profileAddress) public view returns (Profile memory) {
        //bool exists = false; //to enable the use of require
        uint256 profileId; //created to store the id from the for loop

        for (uint256 id = 0; id < profiles.length; id++) {
            if (profiles[id].profileAddress == _profileAddress) {
                //exists = true;
                profileId = id;
            }
            else {
                //exists = false;
                revert("Address does not exist"); 
            }
        }
        
        //require(exists == true, "Address does not exist");
        //if the address exists, return the details of the profile

        return profiles[profileId];
    }
    
    //returns the ID of an address
    function returnID(address _profileAddress) private view returns (uint256) {
        bool exists = addressExist(_profileAddress);
        require(exists == true, "Address does not exist");

        uint256 profileId;

        for (uint256 id = 0; id < profiles.length; id++) {
            if (profiles[id].profileAddress == _profileAddress) {
                profileId = id;
            }
        }
        return profileId;
    }

    //check if an address exists in the database
    function addressExist(address _profileAddress) public view returns (bool) {
        //loop through the database to check for the address
        for (uint256 id = 0; id < profiles.length; id++) {
            if (profiles[id].profileAddress == _profileAddress) {
                return true;
            }
        }

        return false;
    }

    //check if an instagram account exists in the database
    function instExist(string memory _instID) public view returns (bool) {
        //convert strings to hash to enable comparison between strings
        bytes32 convertedID = keccak256(abi.encodePacked(_instID));
        for (uint256 id = 0; id < profiles.length; id++) {
            bytes32 convertID = keccak256(abi.encodePacked(profiles[id].instID));
            //now compare the hashes
            if (convertID == convertedID) {
                return true;
            }
        }

        return false;
    }

    //check if an address has been connected as a partner already
    function partnerExist(address _partnerAddress) public view returns (bool) {
        for (uint256 id = 0; id < profiles.length; id++) {
            //if address(0) is the partner address, it does not count as a partner
            if (profiles[id].partner == address(0)) {
                return false;
            }
            if (profiles[id].partner == _partnerAddress) {
                return true;
            }
        }
        return false;
    }
    
    //create a profile
    function createProfile(string memory _name, address _partner, string memory _instID) public {
        //error-checks
        require(owner != _partner, "Your address and your partner's address cannot be the same"); //address of partner and owner shouldn't be the same
        require(instExist(_instID) == false, "This Instagram ID already exists"); //check if instagram id exists in the database
        require(addressExist(owner) == false, "Address already exists"); //check if address already exists
        
        //check if partner exists in the database
        if (addressExist(_partner)) {
            uint256 partnerId = returnID(_partner); //get id of partner to be able to check partner's partner
            //if partner exists and has added the owner as partner, then relationship is relationship           
            if (profiles[partnerId].partner == owner) {
                profiles.push(Profile(profileCount, owner, _name, RelStatus.Relationship, _partner, _instID));
            } 
            //if partner exists and has not added the owner as partner, then relationship is pending
            else {
                profiles.push(Profile(profileCount, owner, _name, RelStatus.Pending, _partner, _instID));
            }
        }
        //if partner does not exist yet in the database
        else {
            //if owner clicks on "no partner"
            if (_partner == address(0)) {
            //if no partner is added, default to address (0x000...)
            profiles.push(Profile(profileCount, owner, _name, RelStatus.Single, _partner, _instID));
            }
            //if partner does not exist yet in the database, then relationship status is pending and partner is the filled partner
            else {
                profiles.push(Profile(profileCount, owner, _name, RelStatus.Pending, _partner, _instID));
            }
        }      
        profileCount ++; //increment the product count
    }

    //fetch all the profiles
    function getProfiles() public view returns (Profile[] memory) {
        return profiles;
    }

    //connect to a partner already in the database
    function connectPartner(address _partner) public {
        uint256 ownerId = returnID(owner); //get the id of the owner to allow us access information about the profile
        uint256 partnerId = returnID(_partner); //get the id of the partner

        //if the partner is already in a relationship
        if (profiles[partnerId].relStatus == RelStatus.Relationship) {
            revert("Partner is with someone else already ;(");
        }
        //if the partner is not in a relationship (single or pending)
        else {
            //if the partner added is single
            if (profiles[partnerId].relStatus == RelStatus.Single) {
                profiles[ownerId].partner = _partner; //to change the partner of the owner to the address of the partner added
                profiles[ownerId].relStatus = RelStatus.Pending;
            }

            //if the partner added is pending (that is has already attempted to add the owner)
            else if (profiles[partnerId].relStatus == RelStatus.Pending) {
                //check if the partner the partner is attempting to connect to is same as the owner
                if (profiles[partnerId].partner == owner){
                    profiles[ownerId].partner = _partner;
                    profiles[ownerId].relStatus = RelStatus.Relationship;
                    profiles[partnerId].relStatus = RelStatus.Relationship;
                }
                //if the partner the partner added isn't for this owner
                else {
                    revert("Partner wants someone else ;(");
                }  
            }
        }
    }

    //disconnect from a partner (relationship or pending)
    function disconnectPartner() public {
        uint256 ownerId = returnID(owner);
        address partnerAddress = profiles[ownerId].partner;
        uint256 partnerId = returnID(partnerAddress);

        //if you've added the partner but the partner hasn't added you (pending)
        //added the or in case the partner is pending with someone else
        if (profiles[partnerId].relStatus == RelStatus.Single || profiles[partnerId].relStatus == RelStatus.Pending) {
            profiles[ownerId].partner = address(0);
            profiles[ownerId].relStatus = RelStatus.Single;
        }
        //if you and the partner has added each other
        if (profiles[partnerId].relStatus == RelStatus.Relationship && profiles[partnerId].partner == owner) {
            //change both owner and partner relationship status to single
            profiles[ownerId].partner = address(0);
            profiles[ownerId].relStatus = RelStatus.Single;

            profiles[partnerId].partner = address(0);
            profiles[partnerId].relStatus = RelStatus.Single;
        }           
    }

    //to delete the last profile added
    function deleteProfile() public {
        profiles.pop();
    }
}