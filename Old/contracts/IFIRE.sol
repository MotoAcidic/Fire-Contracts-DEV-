/**
 * SPDX-License-Identifier: NO LICENSE
 */
pragma solidity ^0.6.0;

contract FIREData {
    /* Origin address */
    address public constant ORIGIN_ADDR = 0x9A6a414D6F3497c05E3b1De90520765fA1E07c03;

    /* Flush address */
    address payable public constant FLUSH_ADDR = 0xDEC9f2793e3c17cd26eeFb21C4762fA5128E0399;

    /* ERC20 constants */
    string public constant name = "FIRE Network";
    string public constant symbol = "FIRE";
    uint8 public constant decimals = 8;

    /* Embers per Satoshi = 10,000 * 1e8 / 1e8 = 1e4 */
    uint256 public constant EMBERS_PER_FIRE = 10 ** uint256(decimals); // 1e8
    //HEX
    uint256 public constant FIRE_PER_HEX = 1e4;
    uint256 public constant SATOSHIS_PER_HEX = 1e8;
    uint256 public constant EMBERS_PER_SATOSHI_HEX = EMBERS_PER_FIRE / SATOSHIS_PER_HEX * FIRE_PER_HEX;
    //Abet
    uint256 public constant FIRE_PER_ABET = 1e4;
    uint256 public constant SATOSHIS_PER_ABET = 1e8;
    uint256 public constant EMBERS_PER_SATOSHI_ABET = EMBERS_PER_FIRE / SATOSHIS_PER_ABET * FIRE_PER_ABET;
    //BECN
    uint256 public constant FIRE_PER_BECN = 1e4;
    uint256 public constant SATOSHIS_PER_BECN = 1e8;
    uint256 public constant EMBERS_PER_SATOSHI_BECN = EMBERS_PER_FIRE / SATOSHIS_PER_BECN * FIRE_PER_BECN;
    //XAP
    uint256 public constant FIRE_PER_XAP = 1e4;
    uint256 public constant SATOSHIS_PER_XAP = 1e8;
    uint256 public constant EMBERS_PER_SATOSHI_XAP = EMBERS_PER_FIRE / SATOSHIS_PER_XAP * FIRE_PER_XAP;
    //XXX
    uint256 public constant FIRE_PER_XXX = 1e4;
    uint256 public constant SATOSHIS_PER_XXX = 1e8;
    uint256 public constant EMBERS_PER_SATOSHI_XXX = EMBERS_PER_FIRE / SATOSHIS_PER_XXX * FIRE_PER_XXX;

    /* Total Satoshis from all COINS addresses in UTXO snapshot */
    uint256 public constant FULL_SATOSHIS_TOTAL_HEX = 1807766732160668;
    uint256 public constant FULL_SATOSHIS_TOTAL_ABET = 1807766732160668;
    uint256 public constant FULL_SATOSHIS_TOTAL_BECN = 1807766732160668;
    uint256 public constant FULL_SATOSHIS_TOTAL_XAP = 1807766732160668;
    uint256 public constant FULL_SATOSHIS_TOTAL_XXX = 1807766732160668;

    /* Total Satoshis from supported COINS addresses in UTXO snapshot after applying Silly Whale */
    uint256 public constant CLAIMABLE_SATOSHIS_TOTAL = 910087996911001;

    /* Number of claimable addresses in UTXO snapshot */
    uint256 public constant CLAIMABLE_HEX_ADDR_COUNT = 27997742;
    uint256 public constant CLAIMABLE_ABET_ADDR_COUNT = 27997742;
    uint256 public constant CLAIMABLE_BECN_ADDR_COUNT = 27997742;
    uint256 public constant CLAIMABLE_XAP_ADDR_COUNT = 27997742;
    uint256 public constant CLAIMABLE_XXX_ADDR_COUNT = 27997742;

    /* Largest address Satoshis balance in UTXO snapshot (sanity check) */
    uint256 public constant MAX_HEX_ADDR_BALANCE_SATOSHIS = 25550214098481;
    uint256 public constant MAX_ABET_ADDR_BALANCE_SATOSHIS = 25550214098481;
    uint256 public constant MAX_BECN_ADDR_BALANCE_SATOSHIS = 25550214098481;
    uint256 public constant MAX_XAP_ADDR_BALANCE_SATOSHIS = 25550214098481;
    uint256 public constant MAX_XXX_ADDR_BALANCE_SATOSHIS = 25550214098481;

    /* Time of contract launch (2019-12-03T00:00:00Z) */
    uint256 public constant LAUNCH_TIME = 1575331200;

    /* Size of a Embers or Shares uint */
    uint256 public constant EMBER_UINT_SIZE = 72;

    /* Size of a transform lobby entry index uint */
    uint256 public constant XF_LOBBY_ENTRY_INDEX_SIZE = 40;
    uint256 public constant XF_LOBBY_ENTRY_INDEX_MASK = (1 << XF_LOBBY_ENTRY_INDEX_SIZE) - 1;

    /* Seed for WAAS Lobby */
    uint256 public constant WAAS_LOBBY_SEED_FIRE = 1e9;
    uint256 public constant WAAS_LOBBY_SEED_EMBERS = WAAS_LOBBY_SEED_FIRE * EMBERS_PER_FIRE;

    /* Start of claim phase */
    uint256 public constant PRE_CLAIM_DAYS = 1;
    uint256 public constant CLAIM_PHASE_START_DAY = PRE_CLAIM_DAYS;

    /* Length of claim phase */
    uint256 public constant CLAIM_PHASE_WEEKS = 50;
    uint256 public constant CLAIM_PHASE_DAYS = CLAIM_PHASE_WEEKS * 7;

    /* End of claim phase */
    uint256 public constant CLAIM_PHASE_END_DAY = CLAIM_PHASE_START_DAY + CLAIM_PHASE_DAYS;

    /* Number of words to hold 1 bit for each transform lobby day */
    uint256 public constant XF_LOBBY_DAY_WORDS = (CLAIM_PHASE_END_DAY + 255) >> 8;

    /* BigPayDay */
    uint256 public constant BIG_PAY_DAY = CLAIM_PHASE_END_DAY + 1;

    /* Root hash of the UTXO Merkle tree */
    bytes32 public constant MERKLE_TREE_ROOT_HEX = 0x4e831acb4223b66de3b3d2e54a2edeefb0de3d7916e2886a4b134d9764d41bec;  //Block
    bytes32 public constant MERKLE_TREE_ROOT_ABET = 0x4e831acb4223b66de3b3d2e54a2edeefb0de3d7916e2886a4b134d9764d41bec; //Block
    bytes32 public constant MERKLE_TREE_ROOT_BECN = 0x4e831acb4223b66de3b3d2e54a2edeefb0de3d7916e2886a4b134d9764d41bec; //Block
    bytes32 public constant MERKLE_TREE_ROOT_XAP = 0x4e831acb4223b66de3b3d2e54a2edeefb0de3d7916e2886a4b134d9764d41bec;  //Block
    bytes32 public constant MERKLE_TREE_ROOT_XXX = 0x4e831acb4223b66de3b3d2e54a2edeefb0de3d7916e2886a4b134d9764d41bec;  //Block

    /* Size of a Satoshi claim uint in a Merkle leaf */
    uint256 public constant MERKLE_LEAF_SATOSHI_SIZE_HEX = 45;
    uint256 public constant MERKLE_LEAF_SATOSHI_SIZE_ABET = 45;
    uint256 public constant MERKLE_LEAF_SATOSHI_SIZE_BECN = 45;
    uint256 public constant MERKLE_LEAF_SATOSHI_SIZE_XAP = 45;
    uint256 public constant MERKLE_LEAF_SATOSHI_SIZE_XXX = 45;

    /* Zero-fill between HEX address and Satoshis in a Merkle leaf */
    uint256 public constant MERKLE_LEAF_FILL_SIZE_HEX = 256 - 160 - MERKLE_LEAF_SATOSHI_SIZE_HEX;
    uint256 public constant MERKLE_LEAF_FILL_BASE_HEX = (1 << MERKLE_LEAF_FILL_SIZE_HEX) - 1;
    uint256 public constant MERKLE_LEAF_FILL_MASK_HEX = MERKLE_LEAF_FILL_BASE_HEX << MERKLE_LEAF_SATOSHI_SIZE_HEX;
    /* Zero-fill between ABET address and Satoshis in a Merkle leaf */
    uint256 public constant MERKLE_LEAF_FILL_SIZE_ABET = 256 - 160 - MERKLE_LEAF_SATOSHI_SIZE_ABET;
    uint256 public constant MERKLE_LEAF_FILL_BASE_ABET = (1 << MERKLE_LEAF_FILL_SIZE_ABET) - 1;
    uint256 public constant MERKLE_LEAF_FILL_MASK_ABET = MERKLE_LEAF_FILL_BASE_ABET << MERKLE_LEAF_SATOSHI_SIZE_ABET;
    /* Zero-fill between BECN address and Satoshis in a Merkle leaf */
    uint256 public constant MERKLE_LEAF_FILL_SIZE_BECN = 256 - 160 - MERKLE_LEAF_SATOSHI_SIZE_BECN;
    uint256 public constant MERKLE_LEAF_FILL_BASE_BECN = (1 << MERKLE_LEAF_FILL_SIZE_BECN) - 1;
    uint256 public constant MERKLE_LEAF_FILL_MASK_BECN = MERKLE_LEAF_FILL_BASE_BECN << MERKLE_LEAF_SATOSHI_SIZE_BECN;
    /* Zero-fill between XAP address and Satoshis in a Merkle leaf */
    uint256 public constant MERKLE_LEAF_FILL_SIZE_XAP = 256 - 160 - MERKLE_LEAF_SATOSHI_SIZE_XAP;
    uint256 public constant MERKLE_LEAF_FILL_BASE_XAP = (1 << MERKLE_LEAF_FILL_SIZE_XAP) - 1;
    uint256 public constant MERKLE_LEAF_FILL_MASK_XAP = MERKLE_LEAF_FILL_BASE_XAP << MERKLE_LEAF_SATOSHI_SIZE_XAP;
    /* Zero-fill between XXX address and Satoshis in a Merkle leaf */
    uint256 public constant MERKLE_LEAF_FILL_SIZE_XXX = 256 - 160 - MERKLE_LEAF_SATOSHI_SIZE_XXX;
    uint256 public constant MERKLE_LEAF_FILL_BASE_XXX = (1 << MERKLE_LEAF_FILL_SIZE_XXX) - 1;
    uint256 public constant MERKLE_LEAF_FILL_MASK_XXX = MERKLE_LEAF_FILL_BASE_XXX << MERKLE_LEAF_SATOSHI_SIZE_XXX;

    /* Size of a Satoshi total uint */
    uint256 public constant SATOSHI_UINT_SIZE = 51;
    uint256 public constant SATOSHI_UINT_MASK = (1 << SATOSHI_UINT_SIZE) - 1;

    /* Percentage of total claimed Embers that will be auto-staked from a claim */
    uint256 public constant AUTO_STAKE_CLAIM_PERCENT = 90;

    /* Stake timing parameters */
    uint256 public constant MIN_STAKE_DAYS = 1;
    uint256 public constant MIN_AUTO_STAKE_DAYS = 350;

    uint256 public constant MAX_STAKE_DAYS = 5555; // Approx 15 years

    uint256 public constant EARLY_PENALTY_MIN_DAYS = 90;

    uint256 public constant LATE_PENALTY_GRACE_WEEKS = 2;
    uint256 public constant LATE_PENALTY_GRACE_DAYS = LATE_PENALTY_GRACE_WEEKS * 7;

    uint256 public constant LATE_PENALTY_SCALE_WEEKS = 100;
    uint256 public constant LATE_PENALTY_SCALE_DAYS = LATE_PENALTY_SCALE_WEEKS * 7;

    /* Stake shares Longer Pays Better bonus constants used by _stakeStartBonusEmbers() */
    uint256 public constant LPB_BONUS_PERCENT = 20;
    uint256 public constant LPB_BONUS_MAX_PERCENT = 200;
    uint256 public constant LPB = 364 * 100 / LPB_BONUS_PERCENT;
    uint256 public constant LPB_MAX_DAYS = LPB * LPB_BONUS_MAX_PERCENT / 100;

    /* Stake shares Bigger Pays Better bonus constants used by _stakeStartBonusEmbers() */
    uint256 public constant BPB_BONUS_PERCENT = 10;
    uint256 public constant BPB_MAX_FIRE = 150 * 1e6;
    uint256 public constant BPB_MAX_EMBERS = BPB_MAX_FIRE * EMBERS_PER_FIRE;
    uint256 public constant BPB = BPB_MAX_EMBERS * 100 / BPB_BONUS_PERCENT;

    /* Share rate is scaled to increase precision */
    uint256 public constant SHARE_RATE_SCALE = 1e5;

    /* Share rate max (after scaling) */
    uint256 public constant SHARE_RATE_UINT_SIZE = 40;
    uint256 public constant SHARE_RATE_MAX = (1 << SHARE_RATE_UINT_SIZE) - 1;

    /* Constants for preparing the claim message text */
    uint8 public constant ETH_ADDRESS_BYTE_LEN = 20;
    uint8 public constant ETH_ADDRESS_FIRE_LEN = ETH_ADDRESS_BYTE_LEN * 2;

    uint8 public constant CLAIM_PARAM_HASH_BYTE_LEN = 12;
    uint8 public constant CLAIM_PARAM_HASH_FIRE_LEN = CLAIM_PARAM_HASH_BYTE_LEN * 2;

    uint8 public constant HEX_SIG_PREFIX_LEN = 20;
    bytes24 public constant HEX_SIG_PREFIX_STR = "HEX Signed Message:\n";
    uint8 public constant ABET_SIG_PREFIX_LEN = 24;
    bytes24 public constant ABET_SIG_PREFIX_STR = "Altbet Signed Message:\n";
    uint8 public constant BECN_SIG_PREFIX_LEN = 24;
    bytes24 public constant BECN_SIG_PREFIX_STR = "Becn Signed Message:\n";
    uint8 public constant XAP_SIG_PREFIX_LEN = 24;
    bytes24 public constant XAP_SIG_PREFIX_STR = "Xap Signed Message:\n";
    uint8 public constant XXX_SIG_PREFIX_LEN = 24;
    bytes24 public constant XXX_SIG_PREFIX_STR = "Xxx Signed Message:\n";

    bytes public constant STD_CLAIM_PREFIX_STR = "Claim_FIRE_to_0x";
    bytes public constant OLD_CLAIM_PREFIX_STR = "Claim_BitcoinFIRE_to_0x";

    bytes16 public constant FIRE_DIGITS = "0123456789abcdef";

    /* Claim flags passed to hexAddressClaim()  */
    uint8 public constant CLAIM_FLAG_MSG_PREFIX_OLD = 1 << 0;
    uint8 public constant CLAIM_FLAG_HEX_ADDR_COMPRESSED = 1 << 1;
    uint8 public constant CLAIM_FLAG_HEX_ADDR_P2WPKH_IN_P2SH = 1 << 2;
    uint8 public constant CLAIM_FLAG_HEX_ADDR_BECH32 = 1 << 3;
    /* Claim flags passed to abetAddressClaim()  */
    uint8 public constant CLAIM_FLAG_ABET_ADDR_COMPRESSED = 1 << 1;
    uint8 public constant CLAIM_FLAG_ABET_ADDR_P2WPKH_IN_P2SH = 1 << 2;
    uint8 public constant CLAIM_FLAG_ABET_ADDR_BECH32 = 1 << 3;
    /* Claim flags passed to becnAddressClaim()  */
    uint8 public constant CLAIM_FLAG_BECN_ADDR_COMPRESSED = 1 << 1;
    uint8 public constant CLAIM_FLAG_BECN_ADDR_P2WPKH_IN_P2SH = 1 << 2;
    uint8 public constant CLAIM_FLAG_BECN_ADDR_BECH32 = 1 << 3;
    /* Claim flags passed to xapAddressClaim()  */
    uint8 public constant CLAIM_FLAG_XAP_ADDR_COMPRESSED = 1 << 1;
    uint8 public constant CLAIM_FLAG_XAP_ADDR_P2WPKH_IN_P2SH = 1 << 2;
    uint8 public constant CLAIM_FLAG_XAP_ADDR_BECH32 = 1 << 3;
    /* Claim flags passed to xxxAddressClaim()  */
    uint8 public constant CLAIM_FLAG_XXX_ADDR_COMPRESSED = 1 << 1;
    uint8 public constant CLAIM_FLAG_XXX_ADDR_P2WPKH_IN_P2SH = 1 << 2;
    uint8 public constant CLAIM_FLAG_XXX_ADDR_BECH32 = 1 << 3;

    uint8 public constant CLAIM_FLAG_ETH_ADDR_LOWERCASE = 1 << 4;
    
    /* Globals expanded for memory (except _latestStakeId) and compact for storage */
    struct GlobalsCache {
        // 1
        uint256 _lockedEmbersTotal;
        uint256 _nextStakeSharesTotal;
        uint256 _shareRate;
        uint256 _stakePenaltyTotal;
        // 2
        uint256 _dailyDataCount;
        uint256 _stakeSharesTotal;
        uint40 _latestStakeId;
        uint256 _unclaimedSatoshisTotal;
        uint256 _claimedSatoshisTotal;
        uint256 _claimedHexAddrCount;
        uint256 _claimedAbetAddrCount;
        uint256 _claimedBecnAddrCount;
        uint256 _claimedXapAddrCount;
        uint256 _claimedXxxAddrCount;
        //
        uint256 _currentDay;
    }

    struct GlobalsStore {
        // 1
        uint72 lockedEmbersTotal;
        uint72 nextStakeSharesTotal;
        uint40 shareRate;
        uint72 stakePenaltyTotal;
        // 2
        uint16 dailyDataCount;
        uint72 stakeSharesTotal;
        uint40 latestStakeId;
        uint128 claimStats;
    }

    GlobalsStore public globals;

    /* Claimed addresses */
    mapping(bytes20 => bool) public hexAddressClaims;
    mapping(bytes20 => bool) public abetAddressClaims;
    mapping(bytes20 => bool) public becnAddressClaims;
    mapping(bytes20 => bool) public xapAddressClaims;
    mapping(bytes20 => bool) public xxxAddressClaims;

    /* Daily data */
    struct DailyDataStore {
        uint72 dayPayoutTotal;
        uint72 dayStakeSharesTotal;
        uint56 dayUnclaimedSatoshisTotal;
    }

    mapping(uint256 => DailyDataStore) public dailyData;

    /* Stake expanded for memory (except _stakeId) and compact for storage */
    struct StakeCache {
        uint40 _stakeId;
        uint256 _stakedEmbers;
        uint256 _stakeShares;
        uint256 _lockedDay;
        uint256 _stakedDays;
        uint256 _unlockedDay;
        bool _isAutoStake;
    }

    struct StakeStore {
        uint40 stakeId;
        uint72 stakedEmbers;
        uint72 stakeShares;
        uint16 lockedDay;
        uint16 stakedDays;
        uint16 unlockedDay;
        bool isAutoStake;
    }

    mapping(address => StakeStore[]) public stakeLists;

    /* Temporary state for calculating daily rounds */
    struct DailyRoundState {
        uint256 _allocSupplyCached;
        uint256 _mintOriginBatch;
        uint256 _payoutTotal;
    }

    struct XfLobbyEntryStore {
        uint96 rawAmount;
        address referrerAddr;
    }

    struct XfLobbyQueueStore {
        uint40 headIndex;
        uint40 tailIndex;
        mapping(uint256 => XfLobbyEntryStore) entries;
    }

    mapping(uint256 => uint256) public xfLobby;
    mapping(uint256 => mapping(address => XfLobbyQueueStore)) public xfLobbyMembers;
}

/**
 * @dev contract of the FIRE contract
 */
interface IFIREGlobalsAndUtility {
    /**
     * @dev PUBLIC FACING: Optionally update daily data for a smaller
     * range to reduce gas cost for a subsequent operation
     * @param beforeDay Only update days before this day number (optional; 0 for current day)
     */
    function dailyDataUpdate(uint256 beforeDay)
        external;
    /**
     * @dev PUBLIC FACING: External helper to return multiple values of daily data with
     * a single call. Ugly implementation due to limitations of the standard ABI encoder.
     * @param beginDay First day of data range
     * @param endDay Last day (non-inclusive) of data range
     * @return list Fixed array of packed values
     */
    function dailyDataRange(uint256 beginDay, uint256 endDay)
        external
        view
        returns (uint256[] memory list);
    /**
     * @dev PUBLIC FACING: External helper to return most global info with a single call.
     * Ugly implementation due to limitations of the standard ABI encoder.
     * @return Fixed array of values
     */
    function globalInfo()
        external
        view
        returns (uint256[13] memory);
    /**
     * @dev PUBLIC FACING: External helper for the current day number since launch time
     * @return Current day number (zero-based)
     */
    function currentDay()
        external
        view
        returns (uint256);
    /**
     * @dev PUBLIC FACING: ERC20 totalSupply() is the circulating supply and does not include any
     * staked Embers. allocatedSupply() includes both.
     * @return Allocated Supply in Embers
     */
    function allocatedSupply()
        external
        view
        returns (uint256);
} 

interface IFIREStakeableToken is IFIREGlobalsAndUtility {
    /**
     * @dev PUBLIC FACING: Open a stake.
     * @param newStakedEmbers Number of Embers to stake
     * @param newStakedDays Number of days to stake
     */
    function stakeStart(uint256 newStakedEmbers, uint256 newStakedDays)
        external;
    /**
     * @dev PUBLIC FACING: Unlocks a completed stake, distributing the proceeds of any penalty
     * immediately. The staker must still call stakeEnd() to retrieve their stake return (if any).
     * @param stakerAddr Address of staker
     * @param stakeIndex Index of stake within stake list
     * @param stakeIdParam The stake's id
     */
    function stakeGoodAccounting(address stakerAddr, uint256 stakeIndex, uint40 stakeIdParam)
        external;
    /**
     * @dev PUBLIC FACING: Closes a stake. The order of the stake list can change so
     * a stake id is used to reject stale indexes.
     * @param stakeIndex Index of stake within stake list
     * @param stakeIdParam The stake's id
     */
    function stakeEnd(uint256 stakeIndex, uint40 stakeIdParam)
        external;
    /**
     * @dev PUBLIC FACING: Return the current stake count for a staker address
     * @param stakerAddr Address of staker
     */
    function stakeCount(address stakerAddr)
        external
        view
        returns (uint256);
}

interface IFIREUTXOClaimValidation is IFIREStakeableToken {
    /*
     * @dev PUBLIC FACING: Verify a ABET address and balance are unclaimed and part of the Merkle tree
     * @param hexAddr Hex address (binary; no base58-check encoding)
     * @param abetAddr Altbet address (binary; no base58-check encoding)
     * @param becnAddr Becn address (binary; no base58-check encoding)
     * @param xapAddr Xap address (binary; no base58-check encoding)
     * @param xxxAddr Xxx address (binary; no base58-check encoding)
     * @param rawSatoshis Raw ABET address balance in Satoshis
     * @param proof Merkle tree proof
     * @return True if can be claimed
     */
    function hexAddressIsClaimable(bytes20 hexAddr, uint256 rawSatoshis, bytes32[] calldata proof)
        external
        view
        returns (bool);
    function abetAddressIsClaimable(bytes20 abetAddr, uint256 rawSatoshis, bytes32[] calldata proof)
        external
        view
        returns (bool);
    function becnAddressIsClaimable(bytes20 becnAddr, uint256 rawSatoshis, bytes32[] calldata proof)
        external
        view
        returns (bool);
    function xapAddressIsClaimable(bytes20 xapAddr, uint256 rawSatoshis, bytes32[] calldata proof)
        external
        view
        returns (bool);
    function xxxAddressIsClaimable(bytes20 xxxAddr, uint256 rawSatoshis, bytes32[] calldata proof)
        external
        view
        returns (bool);
    /*
     * @dev PUBLIC FACING: Verify a ABET address and balance are part of the Merkle tree
     * @param hexAddr Hex address (binary; no base58-check encoding)
     * @param abetAddr Altbet address (binary; no base58-check encoding)
     * @param becnAddr Becn address (binary; no base58-check encoding)
     * @param xapAddr Xap address (binary; no base58-check encoding)
     * @param xxxAddr Xxx address (binary; no base58-check encoding)
     * @param rawSatoshis Raw ABET address balance in Satoshis
     * @param proof Merkle tree proof
     * @return True if valid
     */
    function hexAddressIsValid(bytes20 hexAddr, uint256 rawSatoshis, bytes32[] calldata proof)
        external
        pure
        returns (bool);
    function abetAddressIsValid(bytes20 abetAddr, uint256 rawSatoshis, bytes32[] calldata proof)
        external
        pure
        returns (bool);
    function becnAddressIsValid(bytes20 becnAddr, uint256 rawSatoshis, bytes32[] calldata proof)
        external
        pure
        returns (bool);
    function xapAddressIsValid(bytes20 xapAddr, uint256 rawSatoshis, bytes32[] calldata proof)
        external
        pure
        returns (bool);
    function xxxAddressIsValid(bytes20 xxxAddr, uint256 rawSatoshis, bytes32[] calldata proof)
        external
        pure
        returns (bool);
    /**
     * @dev PUBLIC FACING: Verify a Merkle proof using the UTXO Merkle tree
     * @param merkleLeaf_hex Leaf asserted to be present in the Merkle tree
     * @param merkleLeaf_abet Leaf asserted to be present in the Merkle tree
     * @param merkleLeaf_becn Leaf asserted to be present in the Merkle tree
     * @param merkleLeaf_xap Leaf asserted to be present in the Merkle tree
     * @param merkleLeaf_xxx Leaf asserted to be present in the Merkle tree
     * @param proof Generated Merkle tree proof
     * @return True if valid
     */
    function merkleProofIsValid(
        bytes32 merkleLeaf_hex, 
        bytes32 merkleLeaf_abet, 
        bytes32 merkleLeaf_becn, 
        bytes32 merkleLeaf_xap, 
        bytes32 merkleLeaf_xxx, 
        bytes32[] calldata proof)
        external
        pure
        returns (bool);
    /**
     * @dev PUBLIC FACING: Verify that a Bitcoin signature matches the claim message containing
     * the Ethereum address and claim param hash
     * @param claimToAddr Eth address within the signed claim message
     * @param claimParamHash Param hash within the signed claim message
     * @param pubKeyX First  half of uncompressed ECDSA public key
     * @param pubKeyY Second half of uncompressed ECDSA public key
     * @param claimFlags Claim flags specifying address and message formats
     * @param v v parameter of ECDSA signature
     * @param r r parameter of ECDSA signature
     * @param s s parameter of ECDSA signature
     * @return True if matching
     */
    function claimMessageMatchesSignature(
        address claimToAddr,
        bytes32 claimParamHash,
        bytes32 pubKeyX,
        bytes32 pubKeyY,
        uint8 claimFlags,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        pure
        returns (bool);
    /**
     * @dev PUBLIC FACING: Derive an Ethereum address from an ECDSA public key
     * @param pubKeyX First  half of uncompressed ECDSA public key
     * @param pubKeyY Second half of uncompressed ECDSA public key
     * @return Derived Eth address
     */
    function pubKeyToEthAddress(bytes32 pubKeyX, bytes32 pubKeyY)
        external
        pure
        returns (address);
    /**
     * @dev PUBLIC FACING: Derive a Bitcoin address from an ECDSA public key
     * @param pubKeyX First  half of uncompressed ECDSA public key
     * @param pubKeyY Second half of uncompressed ECDSA public key
     * @param claimFlags Claim flags specifying address and message formats
     * @return Derived Bitcoin address (binary; no base58-check encoding)
     */
    function pubKeyToHexAddress(bytes32 pubKeyX, bytes32 pubKeyY, uint8 claimFlags)
        external
        pure
        returns (bytes20);
    function pubKeyToAbetAddress(bytes32 pubKeyX, bytes32 pubKeyY, uint8 claimFlags)
        external
        pure
        returns (bytes20);
    function pubKeyToBecnAddress(bytes32 pubKeyX, bytes32 pubKeyY, uint8 claimFlags)
        external
        pure
        returns (bytes20);
    function pubKeyToXapAddress(bytes32 pubKeyX, bytes32 pubKeyY, uint8 claimFlags)
        external
        pure
        returns (bytes20);
    function pubKeyToXxxAddress(bytes32 pubKeyX, bytes32 pubKeyY, uint8 claimFlags)
        external
        pure
        returns (bytes20);
}

interface IFIREUTXORedeemableToken is IFIREUTXOClaimValidation {
    /**
     * @dev PUBLIC FACING: Claim a ABET address and its Satoshi balance in Embers
     * crediting the appropriate amount to a specified Eth address. Bitcoin ECDSA
     * signature must be from that ABET address and must match the claim message
     * for the Eth address.
     * @param rawSatoshis Raw ABET address balance in Satoshis
     * @param proof Merkle tree proof
     * @param claimToAddr Destination Eth address to credit Embers to
     * @param pubKeyX First  half of uncompressed ECDSA public key for the ABET address
     * @param pubKeyY Second half of uncompressed ECDSA public key for the ABET address
     * @param claimFlags Claim flags specifying address and message formats
     * @param v v parameter of ECDSA signature
     * @param r r parameter of ECDSA signature
     * @param s s parameter of ECDSA signature
     * @param autoStakeDays Number of days to auto-stake, subject to minimum auto-stake days
     * @param referrerAddr Eth address of referring user (optional; 0x0 for no referrer)
     * @return Total number of Embers credited, if successful
     */
    function hexAddressClaim(
        uint256 rawSatoshis,
        bytes32[] calldata proof,
        address claimToAddr,
        bytes32 pubKeyX,
        bytes32 pubKeyY,
        uint8 claimFlags,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 autoStakeDays,
        address referrerAddr
    )
        external
        returns (uint256);
    function abetAddressClaim(
        uint256 rawSatoshis,
        bytes32[] calldata proof,
        address claimToAddr,
        bytes32 pubKeyX,
        bytes32 pubKeyY,
        uint8 claimFlags,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 autoStakeDays,
        address referrerAddr
    )
        external
        returns (uint256);
    function becnAddressClaim(
        uint256 rawSatoshis,
        bytes32[] calldata proof,
        address claimToAddr,
        bytes32 pubKeyX,
        bytes32 pubKeyY,
        uint8 claimFlags,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 autoStakeDays,
        address referrerAddr
    )
        external
        returns (uint256);
    function xapAddressClaim(
        uint256 rawSatoshis,
        bytes32[] calldata proof,
        address claimToAddr,
        bytes32 pubKeyX,
        bytes32 pubKeyY,
        uint8 claimFlags,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 autoStakeDays,
        address referrerAddr
    )
        external
        returns (uint256);
    function xxxAddressClaim(
        uint256 rawSatoshis,
        bytes32[] calldata proof,
        address claimToAddr,
        bytes32 pubKeyX,
        bytes32 pubKeyY,
        uint8 claimFlags,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 autoStakeDays,
        address referrerAddr
    )
        external
        returns (uint256);
    
}

interface IFIRETransformableToken is IFIREUTXORedeemableToken {
    /**
     * @dev PUBLIC FACING: Enter the tranform lobby for the current round
     * @param referrerAddr Eth address of referring user (optional; 0x0 for no referrer)
     */
    function xfLobbyEnter(address referrerAddr)
        external
        payable;
    /**
     * @dev PUBLIC FACING: Leave the transform lobby after the round is complete
     * @param enterDay Day number when the member entered
     * @param count Number of queued-enters to exit (optional; 0 for all)
     */
    function xfLobbyExit(uint256 enterDay, uint256 count)
        external;
    /**
     * @dev PUBLIC FACING: Release any value that has been sent to the contract
     */
    function xfLobbyFlush()
        external;
    /**
     * @dev PUBLIC FACING: External helper to return multiple values of xfLobby[] with
     * a single call
     * @param beginDay First day of data range
     * @param endDay Last day (non-inclusive) of data range
     * @return list Fixed array of values
     */
    function xfLobbyRange(uint256 beginDay, uint256 endDay)
        external
        view
        returns (uint256[] memory list);
    /**
     * @dev PUBLIC FACING: Return a current lobby member queue entry.
     * Only needed due to limitations of the standard ABI encoder.
     * @param memberAddr Eth address of the lobby member
     * @param entryId 49 bit compound value. Top 9 bits: enterDay, Bottom 40 bits: entryIndex
     * @return rawAmount uint256 Raw amount that was entered with
     * @return referrerAddr address Referring Eth addr (optional; 0x0 for no referrer)
     */
    function xfLobbyEntry(address memberAddr, uint256 entryId)
        external
        view
        returns (uint256 rawAmount, address referrerAddr);
    /**
     * @dev PUBLIC FACING: Return the lobby days that a user is in with a single call
     * @param memberAddr Eth address of the user
     * @return words Bit vector of lobby day numbers
     */
    function xfLobbyPendingDays(address memberAddr)
        external
        view
        returns (uint256[(1 + (50 * 7) + 255) >> 8] memory words);
}

interface IFIRE is IFIRETransformableToken {}