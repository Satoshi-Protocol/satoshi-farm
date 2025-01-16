// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { Farm } from "./Farm.sol";

import { DEFAULT_NATIVE_ASSET_ADDRESS, FarmConfig, IFarm, WhitelistConfig } from "./interfaces/IFarm.sol";
import {
    ClaimAndStakeCrossChainParams,
    ClaimAndStakeParams,
    DepositParams,
    DepositWithProofParams,
    DstInfo,
    ExecuteClaimParams,
    IFarmManager,
    LZ_COMPOSE_OPT,
    LzConfig,
    RequestClaimParams,
    StakePendingClaimCrossChainParams,
    StakePendingClaimParams,
    WithdrawParams
} from "./interfaces/IFarmManager.sol";
import { IRewardToken } from "./interfaces/IRewardToken.sol";

import { IOAppComposer } from "./interfaces/layerzero/IOAppComposer.sol";
import { MessagingFee, SendParam } from "./interfaces/layerzero/IOFT.sol";
import { OFTComposeMsgCodec } from "./interfaces/layerzero/OFTComposeMsgCodec.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { BeaconProxy } from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import { IBeacon } from "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract FarmManager is IFarmManager, OwnableUpgradeable, PausableUpgradeable, UUPSUpgradeable, IOAppComposer {
    using SafeERC20 for IERC20;

    // IRewardToken public rewardToken;
    IBeacon public farmBeacon;
    IRewardToken public rewardToken;
    mapping(IFarm => bool) public validFarms;

    LzConfig public lzConfig;
    DstInfo public dstInfo;

    modifier onlyFarm(address addr) {
        IFarm farm = IFarm(addr);
        if (!isValidFarm(farm)) revert InvalidFarm(farm);
        _;
    }

    modifier onlyDstEidIsCurrentChain() {
        if (!_dstEidIsCurrentChain()) revert DstEidIsNotCurrentChain(dstInfo.dstEid, lzConfig.eid);
        _;
    }

    modifier onlyDstEidIsNotCurrentChain() {
        if (_dstEidIsCurrentChain()) revert DstEidIsCurrentChain(dstInfo.dstEid, lzConfig.eid);
        _;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner { }

    function initialize(
        IBeacon _farmBeacon,
        IRewardToken _rewardToken,
        DstInfo memory _dstInfo,
        LzConfig memory _lzConfig,
        FarmConfig memory _farmConfig
    )
        external
        initializer
    {
        _checkIsNotZeroAddress(address(_farmBeacon));
        _checkIsNotZeroAddress(address(_rewardToken));

        __Ownable_init(msg.sender);
        __Pausable_init();
        __UUPSUpgradeable_init();

        // if dstEid is current chain, create reward farm
        if (_dstInfo.dstEid == lzConfig.eid) {
            IFarm farm = _createFarm(IERC20(_rewardToken), _farmConfig);
            _dstInfo.dstRewardFarm = farm;
        } else if (_dstInfo.dstEid != 0) {
            _checkIsNotZeroAddress(address(_dstInfo.dstRewardFarm));
            _checkIsNotZero(uint256(_dstInfo.dstRewardManagerBytes32));
        } else {
            revert InvalidZeroDstEid();
        }

        farmBeacon = _farmBeacon;
        rewardToken = _rewardToken;
        dstInfo = _dstInfo;
        lzConfig = _lzConfig;

        emit DstInfoUpdated(_dstInfo);
        emit LzConfigUpdated(_lzConfig);
    }

    // --- onlyOwner functions ---
    function pause() external onlyOwner {
        _pause();
    }

    function resume() external onlyOwner {
        _unpause();
    }

    function updateLzConfig(LzConfig memory _lzConfig) external onlyOwner {
        lzConfig = _lzConfig;
        emit LzConfigUpdated(_lzConfig);
    }

    function updateDstInfo(DstInfo memory _dstInfo) external onlyOwner {
        _checkIsNotZero(uint256(_dstInfo.dstEid));
        _checkIsNotZero(uint256(_dstInfo.dstRewardManagerBytes32));
        _checkIsNotZeroAddress(address(_dstInfo.dstRewardFarm));

        dstInfo = _dstInfo;
        emit DstInfoUpdated(_dstInfo);
    }

    function updateFarmConfig(IFarm farm, FarmConfig memory farmConfig) external onlyOwner {
        farm.updateFarmConfig(farmConfig);
        emit FarmConfigUpdated(farm, farmConfig);
    }

    function updateWhitelistConfig(IFarm farm, WhitelistConfig memory whitelistConfig) external onlyOwner {
        farm.updateWhitelistConfig(whitelistConfig);
        emit WhitelistConfigUpdated(farm, whitelistConfig);
    }

    function createFarm(IERC20 underlyingAsset, FarmConfig memory farmConfig) external onlyOwner returns (address) {
        IFarm farm = _createFarm(underlyingAsset, farmConfig);
        return address(farm);
    }

    function depositNativeAssetWithProof(DepositWithProofParams memory depositWithProofParams)
        public
        payable
        whenNotPaused
    {
        (IFarm farm, uint256 amount, address receiver, bytes32[] memory merkleProof) = (
            depositWithProofParams.farm,
            depositWithProofParams.amount,
            depositWithProofParams.receiver,
            depositWithProofParams.merkleProof
        );

        _checkFarmIsValid(farm);

        if (msg.value < amount) revert InvalidAmount(msg.value, amount);

        farm.depositNativeAssetWithProof{ value: amount }(amount, msg.sender, receiver, merkleProof);

        emit DepositWithProof(farm, amount, msg.sender, receiver, merkleProof);
    }

    function depositNativeAssetWithProofBatch(DepositWithProofParams[] memory depositWithProofParamsArr)
        public
        payable
        whenNotPaused
    {
        uint256[] memory depositAmountArr = new uint256[](depositWithProofParamsArr.length);
        for (uint256 i = 0; i < depositWithProofParamsArr.length; i++) {
            depositAmountArr[i] = depositWithProofParamsArr[i].amount;
        }
        _checkTotalAmount(depositAmountArr, msg.value);

        for (uint256 i = 0; i < depositWithProofParamsArr.length; i++) {
            depositNativeAssetWithProof(depositWithProofParamsArr[i]);
        }
    }

    function depositERC20WithProof(DepositWithProofParams memory depositWithProofParams) public whenNotPaused {
        (IFarm farm, uint256 amount, address receiver, bytes32[] memory merkleProof) = (
            depositWithProofParams.farm,
            depositWithProofParams.amount,
            depositWithProofParams.receiver,
            depositWithProofParams.merkleProof
        );

        _checkFarmIsValid(farm);

        farm.depositERC20WithProof(amount, msg.sender, receiver, merkleProof);

        emit DepositWithProof(farm, amount, msg.sender, receiver, merkleProof);
    }

    function depositERC20WithProofBatch(DepositWithProofParams[] memory depositWithProofParamsArr)
        public
        whenNotPaused
    {
        for (uint256 i = 0; i < depositWithProofParamsArr.length; i++) {
            depositERC20WithProof(depositWithProofParamsArr[i]);
        }
    }

    function depositNativeAsset(DepositParams memory depositParams) public payable whenNotPaused {
        (IFarm farm, uint256 amount, address receiver) =
            (depositParams.farm, depositParams.amount, depositParams.receiver);

        _checkFarmIsValid(farm);

        if (msg.value < amount) revert InvalidAmount(msg.value, amount);

        farm.depositNativeAsset{ value: amount }(amount, msg.sender, receiver);

        emit Deposit(farm, amount, msg.sender, receiver);
    }

    function depositNativeAssetBatch(DepositParams[] memory depositParamsArr) public payable whenNotPaused {
        uint256[] memory depositAmountArr = new uint256[](depositParamsArr.length);
        for (uint256 i = 0; i < depositParamsArr.length; i++) {
            depositAmountArr[i] = depositParamsArr[i].amount;
        }

        _checkTotalAmount(depositAmountArr, msg.value);

        for (uint256 i = 0; i < depositParamsArr.length; i++) {
            depositNativeAsset(depositParamsArr[i]);
        }
    }

    function depositERC20(DepositParams memory depositParams) public whenNotPaused {
        (IFarm farm, uint256 amount, address receiver) =
            (depositParams.farm, depositParams.amount, depositParams.receiver);

        _checkFarmIsValid(farm);

        farm.depositERC20(amount, msg.sender, receiver);

        emit Deposit(farm, amount, msg.sender, receiver);
    }

    function depositERC20Batch(DepositParams[] memory depositParamsArr) public whenNotPaused {
        for (uint256 i = 0; i < depositParamsArr.length; i++) {
            depositERC20(depositParamsArr[i]);
        }
    }

    function withdraw(WithdrawParams memory withdrawParams) public whenNotPaused {
        (IFarm farm, uint256 amount, address receiver) =
            (withdrawParams.farm, withdrawParams.amount, withdrawParams.receiver);

        _checkFarmIsValid(farm);

        farm.withdraw(amount, msg.sender, receiver);
        emit Withdraw(farm, amount, msg.sender, receiver);
    }

    function withdrawBatch(WithdrawParams[] memory withdrawParamsArr) public whenNotPaused {
        for (uint256 i = 0; i < withdrawParamsArr.length; i++) {
            withdraw(withdrawParamsArr[i]);
        }
    }

    function requestClaim(RequestClaimParams memory requestClaimParams) public whenNotPaused {
        (IFarm farm, uint256 amount, address receiver) =
            (requestClaimParams.farm, requestClaimParams.amount, requestClaimParams.receiver);

        _checkFarmIsValid(farm);

        (uint256 claimAmt, uint256 claimableTime, bytes32 claimId) = farm.requestClaim(amount, msg.sender, receiver);
        emit ClaimRequested(farm, claimAmt, msg.sender, receiver, claimableTime, claimId);
    }

    function requestClaimBatch(RequestClaimParams[] memory requestClaimParamsArr) public whenNotPaused {
        for (uint256 i = 0; i < requestClaimParamsArr.length; i++) {
            requestClaim(requestClaimParamsArr[i]);
        }
    }

    function executeClaim(ExecuteClaimParams memory executeClaimParams) public whenNotPaused {
        (IFarm farm, uint256 amount, address owner, uint256 claimableTime, bytes32 claimId) = (
            executeClaimParams.farm,
            executeClaimParams.amount,
            executeClaimParams.owner,
            executeClaimParams.claimableTime,
            executeClaimParams.claimId
        );

        _checkFarmIsValid(farm);

        farm.executeClaim(amount, owner, msg.sender, claimableTime, claimId);
        emit ClaimExecuted(farm, amount, owner, msg.sender, claimableTime, claimId);
    }

    function executeClaimBatch(ExecuteClaimParams[] memory executeClaimParamsArr) public whenNotPaused {
        for (uint256 i = 0; i < executeClaimParamsArr.length; i++) {
            executeClaim(executeClaimParamsArr[i]);
        }
    }

    function stakePendingClaim(StakePendingClaimParams memory stakePendingClaimParams)
        public
        whenNotPaused
        onlyDstEidIsCurrentChain
    {
        (IFarm farm, uint256 amount, address receiver, uint256 claimableTime, bytes32 claimId) = (
            stakePendingClaimParams.farm,
            stakePendingClaimParams.amount,
            stakePendingClaimParams.receiver,
            stakePendingClaimParams.claimableTime,
            stakePendingClaimParams.claimId
        );
        _checkFarmIsValid(farm);

        farm.forceExecuteClaim(amount, msg.sender, receiver, claimableTime, claimId);

        DepositParams memory depositParams =
            DepositParams({ farm: dstInfo.dstRewardFarm, amount: amount, receiver: receiver });

        _stake(depositParams);

        emit PendingClaimStaked(farm, amount, msg.sender, receiver, claimableTime, claimId);
    }

    function stakePendingClaimBatch(StakePendingClaimParams[] memory stakePendingClaimParamsArr)
        public
        whenNotPaused
        onlyDstEidIsCurrentChain
    {
        for (uint256 i = 0; i < stakePendingClaimParamsArr.length; i++) {
            stakePendingClaim(stakePendingClaimParamsArr[i]);
        }
    }

    function stakePendingClaimCrossChain(StakePendingClaimCrossChainParams memory stakePendingClaimCrossChainParams)
        public
        payable
        whenNotPaused
        onlyDstEidIsNotCurrentChain
    {
        (
            IFarm farm,
            uint256 amount,
            address receiver,
            uint256 claimableTime,
            bytes32 claimId,
            bytes memory extraOptions
        ) = (
            stakePendingClaimCrossChainParams.farm,
            stakePendingClaimCrossChainParams.amount,
            stakePendingClaimCrossChainParams.receiver,
            stakePendingClaimCrossChainParams.claimableTime,
            stakePendingClaimCrossChainParams.claimId,
            stakePendingClaimCrossChainParams.extraOptions
        );
        _checkFarmIsValid(farm);

        farm.forceExecuteClaim(amount, msg.sender, receiver, claimableTime, claimId);

        _stakeCrossChain(receiver, amount, extraOptions, msg.value);

        emit PendingClaimStaked(farm, amount, msg.sender, receiver, claimableTime, claimId);
    }

    function stakePendingClaimCrossChainBatch(
        StakePendingClaimCrossChainParams[] memory stakePendingClaimCrossChainParamsArr
    )
        public
        payable
        whenNotPaused
        onlyDstEidIsNotCurrentChain
    {
        uint256[] memory feeAmountArr = new uint256[](stakePendingClaimCrossChainParamsArr.length);
        for (uint256 i = 0; i < stakePendingClaimCrossChainParamsArr.length; i++) {
            StakePendingClaimCrossChainParams memory stakePendingClaimCrossChainParams =
                stakePendingClaimCrossChainParamsArr[i];
            SendParam memory sendParam = formatLzDepositRewardSendParam(
                stakePendingClaimCrossChainParams.receiver,
                stakePendingClaimCrossChainParams.amount,
                stakePendingClaimCrossChainParams.extraOptions
            );
            MessagingFee memory expectFee = rewardToken.quoteSend(sendParam, false);
            feeAmountArr[i] = expectFee.nativeFee;
        }

        _checkTotalAmount(feeAmountArr, msg.value);

        for (uint256 i = 0; i < stakePendingClaimCrossChainParamsArr.length; i++) {
            stakePendingClaimCrossChain(stakePendingClaimCrossChainParamsArr[i]);
        }
    }

    function claimAndStake(ClaimAndStakeParams memory claimAndStakeParams)
        public
        whenNotPaused
        onlyDstEidIsCurrentChain
    {
        (IFarm farm, uint256 amount, address receiver) =
            (claimAndStakeParams.farm, claimAndStakeParams.amount, claimAndStakeParams.receiver);

        _checkFarmIsValid(farm);

        uint256 claimAndStakeAmt = farm.instantClaim(amount, msg.sender, address(this));

        DepositParams memory depositParams =
            DepositParams({ farm: dstInfo.dstRewardFarm, amount: amount, receiver: receiver });

        _stake(depositParams);

        emit ClaimAndStake(farm, claimAndStakeAmt, msg.sender, receiver);
    }

    function claimAndStakeBatch(ClaimAndStakeParams[] memory claimAndStakeParamsArr) public whenNotPaused {
        for (uint256 i = 0; i < claimAndStakeParamsArr.length; i++) {
            claimAndStake(claimAndStakeParamsArr[i]);
        }
    }

    function claimAndStakeCrossChain(ClaimAndStakeCrossChainParams memory claimAndStakeCrossChainParams)
        public
        payable
        whenNotPaused
        onlyDstEidIsNotCurrentChain
    {
        (IFarm farm, uint256 amount, address receiver, bytes memory extraOptions) = (
            claimAndStakeCrossChainParams.farm,
            claimAndStakeCrossChainParams.amount,
            claimAndStakeCrossChainParams.receiver,
            claimAndStakeCrossChainParams.extraOptions
        );

        _checkFarmIsValid(farm);

        uint256 claimAndStakeAmt = farm.instantClaim(amount, msg.sender, address(this));

        _stakeCrossChain(receiver, amount, extraOptions, msg.value);

        emit ClaimAndStake(farm, claimAndStakeAmt, msg.sender, receiver);
    }

    function claimAndStakeCrossChainBatch(ClaimAndStakeCrossChainParams[] memory claimAndStakeCrossChainParamsArr)
        public
        payable
        whenNotPaused
        onlyDstEidIsNotCurrentChain
    {
        uint256[] memory feeAmountArr = new uint256[](claimAndStakeCrossChainParamsArr.length);
        for (uint256 i = 0; i < claimAndStakeCrossChainParamsArr.length; i++) {
            ClaimAndStakeCrossChainParams memory claimAndStakeCrossChainParams = claimAndStakeCrossChainParamsArr[i];
            SendParam memory sendParam = formatLzDepositRewardSendParam(
                claimAndStakeCrossChainParams.receiver,
                claimAndStakeCrossChainParams.amount,
                claimAndStakeCrossChainParams.extraOptions
            );
            MessagingFee memory expectFee = rewardToken.quoteSend(sendParam, false);
            feeAmountArr[i] = expectFee.nativeFee;
        }

        _checkTotalAmount(feeAmountArr, msg.value);

        for (uint256 i = 0; i < claimAndStakeCrossChainParamsArr.length; i++) {
            claimAndStakeCrossChain(claimAndStakeCrossChainParamsArr[i]);
        }
    }

    function mintRewardCallback(address to, uint256 amount) external onlyFarm(msg.sender) {
        IFarm farm = IFarm(msg.sender);

        try rewardToken.mint(to, amount) { }
        catch {
            revert MintRewardTokenFailed(rewardToken, farm, amount);
        }
    }

    function transferCallback(IERC20 token, address from, uint256 amount) external onlyFarm(msg.sender) {
        IFarm farm = IFarm(msg.sender);

        uint256 balanceBefore = token.balanceOf(address(farm));
        token.safeTransferFrom(from, address(farm), amount);
        uint256 balanceAfter = token.balanceOf(address(farm));
        uint256 balanceDiff = balanceAfter - balanceBefore;
        if (balanceDiff != amount) revert AssetBalanceChangedUnexpectedly(token, farm, from, amount, balanceDiff);
    }

    // --- external view functions ---
    function totalShares(IFarm farm) external view returns (uint256) {
        return farm.totalShares();
    }

    function shares(IFarm farm, address addr) external view returns (uint256) {
        return farm.shares(addr);
    }

    function previewReward(IFarm farm, address addr) external view returns (uint256) {
        return farm.previewReward(addr);
    }

    function lastRewardPerToken(IFarm farm) external view returns (uint256) {
        return farm.lastRewardPerToken();
    }

    function lastUpdateTime(IFarm farm) external view returns (uint256) {
        return farm.lastUpdateTime();
    }

    function getLastUserRewardPerToken(IFarm farm, address addr) external view returns (uint256) {
        return farm.getLastUserRewardPerToken(addr);
    }

    function getPendingReward(IFarm farm, address addr) external view returns (uint256) {
        return farm.getPendingReward(addr);
    }

    function isDepositEnabled(IFarm farm) external view returns (bool) {
        return farm.isDepositEnabled();
    }

    function isClaimable(IFarm farm) external view returns (bool) {
        return farm.isClaimable();
    }

    function isValidFarm(IFarm farm) public view returns (bool) {
        return validFarms[farm];
    }

    /// @notice Handles incoming composed messages from LayerZero.
    /// @dev Decodes the message payload to perform a token swap.
    ///      This method expects the encoded compose message to contain the swap amount and recipient address.
    /// @param _oApp The address of the originating OApp.
    /// @param /*_guid*/ The globally unique identifier of the message (unused in this mock).
    /// @param _message The encoded message content in the format of the OFTComposeMsgCodec.
    /// @param /*Executor*/ Executor address (unused in this mock).
    /// @param /*Executor Data*/ Additional data for checking for a specific executor (unused in this mock).
    function lzCompose(
        address _oApp,
        bytes32, /*_guid*/
        bytes calldata _message,
        address, /*Executor*/
        bytes calldata /*Executor Data*/
    )
        external
        payable
        override
    {
        require(_oApp == address(rewardToken), "!oApp");
        require(msg.sender == lzConfig.endpoint, "!endpoint");
        // Extract the composed message from the delivered message using the MsgCodec
        (LZ_COMPOSE_OPT opt, bytes memory data) =
            abi.decode(OFTComposeMsgCodec.composeMsg(_message), (LZ_COMPOSE_OPT, bytes));
        if (opt == LZ_COMPOSE_OPT.DEPOSIT_REWARD_TOKEN) {
            uint256 _amountLD = OFTComposeMsgCodec.amountLD(_message);
            (DepositParams memory depositParams) = abi.decode(data, (DepositParams));
            require(_amountLD == depositParams.amount, "invalid receive amount");
            rewardToken.approve(address(depositParams.farm), depositParams.amount);
            depositERC20(depositParams);
        } else {
            revert("Invalid opt");
        }
    }

    function formatLzDepositRewardSendParam(
        address receiver,
        uint256 amount,
        bytes memory extraOptions
    )
        public
        view
        returns (SendParam memory sendParam)
    {
        bytes memory composeMsg = abi.encode(
            LZ_COMPOSE_OPT.DEPOSIT_REWARD_TOKEN, abi.encode(DepositParams(dstInfo.dstRewardFarm, amount, receiver))
        );

        sendParam = SendParam(
            dstInfo.dstEid,
            dstInfo.dstRewardManagerBytes32,
            amount,
            amount,
            extraOptions,
            composeMsg,
            "" // oftCmd
        );
    }

    // --- internal functions ---
    function _createFarm(IERC20 underlyingAsset, FarmConfig memory farmConfig) internal returns (IFarm) {
        bytes memory initData = abi.encodeCall(IFarm.initialize, (address(underlyingAsset), address(this), farmConfig));
        IFarm farm = IFarm(address(new BeaconProxy(address(farmBeacon), initData)));
        if (isValidFarm(farm)) revert FarmAlreadyExists(farm);

        validFarms[farm] = true;
        emit FarmCreated(farm, underlyingAsset, dstInfo.dstRewardFarm);
        return farm;
    }

    function _stake(DepositParams memory depositParams) internal {
        rewardToken.approve(address(dstInfo.dstRewardFarm), depositParams.amount);
        depositERC20(depositParams);
    }

    function _stakeCrossChain(address receiver, uint256 amount, bytes memory extraOptions, uint256 msgValue) internal {
        SendParam memory sendParam = formatLzDepositRewardSendParam(receiver, amount, extraOptions);
        MessagingFee memory expectFee = rewardToken.quoteSend(sendParam, false);
        if (msgValue < expectFee.nativeFee) revert InsufficientFee(expectFee.nativeFee, msgValue);

        rewardToken.send{ value: msgValue }(sendParam, expectFee, lzConfig.refundAddress);
    }

    function _checkFarmIsValid(IFarm farm) internal view {
        if (!isValidFarm(farm)) revert InvalidFarm(farm);
    }

    function _checkTotalAmount(uint256[] memory amountArr, uint256 msgValue) internal pure {
        uint256 totalAmount;
        for (uint256 i = 0; i < amountArr.length; i++) {
            totalAmount += amountArr[i];
        }

        if (msgValue != totalAmount) revert InvalidAmount(msgValue, totalAmount);
    }

    function _checkIsNotZero(uint256 value) internal pure {
        if (value == 0) revert InvalidZeroValue();
    }

    function _checkIsNotZeroAddress(address addr) internal pure {
        if (addr == address(0)) revert InvalidZeroAddress();
    }

    function _dstEidIsCurrentChain() internal view returns (bool) {
        return lzConfig.eid == dstInfo.dstEid;
    }
}
