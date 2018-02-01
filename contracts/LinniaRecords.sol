pragma solidity ^0.4.18;

import "./Owned.sol";
import "./LinniaHub.sol";
import "./LinniaRoles.sol";
import "./LinniaHTH.sol";

contract LinniaRecords is Owned {
    struct FileRecord {
        address patient;
        uint sigCount;
        mapping (address => bool) signatures;
        // For now the record types are
        // 0 nil, 1 Blood Pressure, 2 A1C, 3 HDL, 4 Triglycerides, 5 Weight
        uint recordType;
        bytes32 ipfsHash; // ipfs hash of the encrypted file
        uint timestamp; // time the file is added
    }
    event RecordAdded(bytes32 indexed fileHash, address indexed patient);
    event RecordSigAdded(bytes32 indexed fileHash, address indexed doctor);

    LinniaHub public hub;
    // all linnia records
    // filehash => record mapping
    mapping(bytes32 => FileRecord) public records;
    // reverse mapping: ipfsHash => sha256 fileHash
    mapping(bytes32 => bytes32) public ipfsRecords;

    /* Modifiers */
    modifier onlyFromDoctor() {
        require(hub.rolesContract().roles(msg.sender) == LinniaRoles.Role.Doctor);
        _;
    }

    modifier onlyFromPatient() {
        require(hub.rolesContract().roles(msg.sender) == LinniaRoles.Role.Patient);
        _;
    }

    /* Constructor */
    function LinniaRecords(LinniaHub _hub, address initialAdmin)
        Owned(initialAdmin)
        public
    {
        hub = _hub;
    }

    /// Add metadata to a medical record uploaded to IPFS by the patient,
    /// without any doctor's signatures.
    /// @param fileHash the hash of the original unencrypted file
    /// @param recordType the type of the record
    /// @param ipfsHash the sha2-256 hash of the file on IPFS
    function addRecordByPatient(bytes32 fileHash,
        uint recordType, bytes32 ipfsHash)
        onlyFromPatient
        public
        returns (bool)
    {
        require(_addRecord(fileHash, msg.sender, recordType, ipfsHash));
        return true;
    }

    /// Add metadata to a medical record uploaded to IPFS by a doctor
    /// @param fileHash the hash of the original unencrypted file
    /// @param patient the address of the patient
    /// @param recordType the type of the record
    /// @param ipfsHash the sha2-256 hash of the file on IPFS
    function addRecordByDoctor(bytes32 fileHash,
        address patient, uint recordType, bytes32 ipfsHash)
        onlyFromDoctor
        public
        returns (bool)
    {
        // add the file first
        require(_addRecord(fileHash, patient, recordType, ipfsHash));
        // add doctor's sig to the file
        require(_addSig(fileHash, msg.sender));
        return true;
    }

    /// Add a doctor's signature to an existing file
    /// This function is only callable by a doctor
    /// @param fileHash the hash of the original file
    function addSigByDoctor(bytes32 fileHash)
        onlyFromDoctor
        public
        returns (bool)
    {
        require(_addSig(fileHash, msg.sender));
        return true;
    }

    /// Add a doctor's signature to an existing file.
    /// This function can be called by anyone. As long as the signatures are
    /// indeed from a doctor, the sig will be added to the file record
    /// @param fileHash the hash of the original file
    /// @param r signature: R
    /// @param s signature: S
    /// @param v signature: V
    function addSig(bytes32 fileHash, bytes32 r, bytes32 s, uint8 v)
        public
        returns (bool)
    {
        // recover the doctor's address from signature
        address doctor = recover(fileHash, r, s, v);
        // add sig
        require(_addSig(fileHash, doctor));
        return true;
    }

    function addRecordByAdmin(bytes32 fileHash,
        address patient, address doctor,
        uint recordType, bytes32 ipfsHash)
        onlyAdmin
        public
        returns (bool)
    {
        require(_addRecord(fileHash, patient, recordType, ipfsHash));
        if (doctor != 0) {
            require(_addSig(fileHash, doctor));
        }
        return true;
    }

    /* Private functions */
    function _addRecord(bytes32 fileHash, address patient,
        uint recordType, bytes32 ipfsHash)
        private
        returns (bool)
    {
        // validate input
        require(fileHash != 0 && recordType != 0 && ipfsHash != 0);
        // the file must be new
        require(records[fileHash].recordType == 0 &&
            ipfsRecords[ipfsHash] == 0);
        // verify patient role
        require(hub.rolesContract().roles(patient) == LinniaRoles.Role.Patient);
        // add record
        records[fileHash] = FileRecord({
            patient: patient,
            sigCount: 0,
            recordType: recordType,
            ipfsHash: ipfsHash,
            timestamp: block.timestamp
        });
        // add the reverse mapping
        ipfsRecords[ipfsHash] = fileHash;
        // emit event
        RecordAdded(fileHash, patient);
        return true;
    }

    function _addSig(bytes32 fileHash, address doctor)
        private
        returns (bool)
    {
        // the file must exist
        require(records[fileHash].recordType != 0);
        // verify doctor role
        require(hub.rolesContract().roles(doctor) == LinniaRoles.Role.Doctor);
        // the doctor must not have signed the file already
        require(!records[fileHash].signatures[doctor]);
        // add signature
        records[fileHash].sigCount++;
        records[fileHash].signatures[doctor] = true;
        // update HTH if possible
        LinniaHTH hthContract = hub.hthContract();
        if (address(hthContract) != 0) {
            require(hthContract.addPoints(patientOf(fileHash), 1));
        }
        // emit event
        RecordSigAdded(fileHash, doctor);
        return true;
    }

    /* Constant functions */
    function recover(bytes32 message, bytes32 r, bytes32 s, uint8 v)
        public pure returns (address)
    {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(prefix, message);
        return ecrecover(prefixedHash, v, r, s);
    }

    function patientOf(bytes32 fileHash)
        public view returns (address)
    {
        return records[fileHash].patient;
    }

    function sigExists(bytes32 fileHash, address doctor)
        public view returns (bool)
    {
        return records[fileHash].signatures[doctor];
    }
}