// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { Farm } from "./Farm.sol";

import { DEFAULT_NATIVE_ASSET_ADDRESS, FarmConfig, IFarm, WhitelistConfig } from "./interfaces/IFarm.sol";
import {
    ClaimAndStakeParams,
    DepositParams,
    DepositWhitelistParams,
    ExecuteClaimParams,
    IFarmManager,
    LZ_COMPOSE_OPT,
    LzConfig,
    RequestClaimParams,
    RewardInfo,
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
    mapping(IFarm => bool) public validFarms;

    LzConfig public lzConfig;
    RewardInfo public rewardInfo;

    modifier onlyFarm(address addr) {
        IFarm farm = IFarm(addr);
        if (!isValidFarm(farm)) revert InvalidFarm(farm);
        _;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner { }

    function initialize(
        IBeacon _farmBeacon,
        RewardInfo memory _rewardInfo,
        LzConfig memory _lzConfig,
        FarmConfig memory _farmConfig
    )
        external
        initializer
    {
        _checkIsNotZeroAddress(address(_farmBeacon));
        _checkIsNotZeroAddress(address(_rewardInfo.rewardToken));

        __Ownable_init(msg.sender);
        __Pausable_init();
        __UUPSUpgradeable_init();

        // if dstEid is 0, create farm for rewardToken initially
        if (_rewardInfo.dstEid == lzConfig.eid) {
            IFarm farm = _createFarm(IERC20(_rewardInfo.rewardToken), _farmConfig);
            _rewardInfo.dstRewardFarm = farm;
        } else if (_rewardInfo.dstEid != 0) {
            _checkIsNotZeroAddress(address(_rewardInfo.dstRewardFarm));
        } else {
            revert("Invalid dstEid");
        }

        farmBeacon = _farmBeacon;
        rewardInfo = _rewardInfo;
        lzConfig = _lzConfig;

        emit RewardInfoUpdated(_rewardInfo);
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

    function updateRewardInfo(RewardInfo memory _rewardInfo) external onlyOwner {
        rewardInfo = _rewardInfo;
        emit RewardInfoUpdated(_rewardInfo);
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

    function depositNativeAssetWithProof(DepositWhitelistParams memory depositParams) public payable whenNotPaused {
        (IFarm farm, uint256 amount, address receiver, bytes32[] memory merkleProof) =
            (depositParams.farm, depositParams.amount, depositParams.receiver, depositParams.merkleProof);

        _checkFarmIsValid(farm);

        if (msg.value < amount) revert InvalidAmount(msg.value, amount);

        farm.depositNativeAssetWithProof{ value: amount }(amount, msg.sender, receiver, merkleProof);

        emit DepositWithProof(farm, amount, msg.sender, receiver, merkleProof);
    }

    function depositNativeAssetWithProofBatch(DepositWhitelistParams[] memory depositParams)
        public
        payable
        whenNotPaused
    {
        uint256[] memory depositAmountArr = new uint256[](depositParams.length);
        for (uint256 i = 0; i < depositParams.length; i++) {
            depositAmountArr[i] = depositParams[i].amount;
        }
        _checkTotalAmount(depositAmountArr, msg.value);

        for (uint256 i = 0; i < depositParams.length; i++) {
            depositNativeAssetWithProof(depositParams[i]);
        }
    }

    function depositERC20WithProof(DepositWhitelistParams memory depositParams) public whenNotPaused {
        (IFarm farm, uint256 amount, address receiver, bytes32[] memory merkleProof) =
            (depositParams.farm, depositParams.amount, depositParams.receiver, depositParams.merkleProof);

        _checkFarmIsValid(farm);

        farm.depositERC20WithProof(amount, msg.sender, receiver, merkleProof);

        emit DepositWithProof(farm, amount, msg.sender, receiver, merkleProof);
    }

    function depositERC20WithProofBatch(DepositWhitelistParams[] memory depositParams) public whenNotPaused {
        for (uint256 i = 0; i < depositParams.length; i++) {
            depositERC20WithProof(depositParams[i]);
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

    function depositNativeAssetBatch(DepositParams[] memory depositParams) public payable whenNotPaused {
        uint256[] memory depositAmountArr = new uint256[](depositParams.length);
        for (uint256 i = 0; i < depositParams.length; i++) {
            depositAmountArr[i] = depositParams[i].amount;
        }

        _checkTotalAmount(depositAmountArr, msg.value);

        for (uint256 i = 0; i < depositParams.length; i++) {
            depositNativeAsset(depositParams[i]);
        }
    }

    function depositERC20(DepositParams memory depositParams) public whenNotPaused {
        (IFarm farm, uint256 amount, address receiver) =
            (depositParams.farm, depositParams.amount, depositParams.receiver);

        _checkFarmIsValid(farm);

        farm.depositERC20(amount, msg.sender, receiver);

        emit Deposit(farm, amount, msg.sender, receiver);
    }

    function depositERC20Batch(DepositParams[] memory depositParams) public whenNotPaused {
        for (uint256 i = 0; i < depositParams.length; i++) {
            depositERC20(depositParams[i]);
        }
    }

    function withdraw(WithdrawParams memory withdrawParams) public whenNotPaused {
        (IFarm farm, uint256 amount, address receiver) =
            (withdrawParams.farm, withdrawParams.amount, withdrawParams.receiver);

        _checkFarmIsValid(farm);

        farm.withdraw(amount, msg.sender, receiver);
        emit Withdraw(farm, amount, msg.sender, receiver);
    }

    function withdrawBatch(WithdrawParams[] memory withdrawParams) public whenNotPaused {
        for (uint256 i = 0; i < withdrawParams.length; i++) {
            withdraw(withdrawParams[i]);
        }
    }

    function requestClaim(RequestClaimParams memory requestClaimParams) public whenNotPaused {
        (IFarm farm, uint256 amount, address receiver) =
            (requestClaimParams.farm, requestClaimParams.amount, requestClaimParams.receiver);

        _checkFarmIsValid(farm);

        (uint256 claimAmt, uint256 claimableTime, bytes32 claimId) = farm.requestClaim(amount, msg.sender, receiver);
        emit ClaimRequested(farm, claimAmt, msg.sender, receiver, claimableTime, claimId);
    }

    function requestClaimBatch(RequestClaimParams[] memory requestClaimParams) public whenNotPaused {
        for (uint256 i = 0; i < requestClaimParams.length; i++) {
            requestClaim(requestClaimParams[i]);
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

    function executeClaimBatch(ExecuteClaimParams[] memory executeClaimParams) public whenNotPaused {
        for (uint256 i = 0; i < executeClaimParams.length; i++) {
            executeClaim(executeClaimParams[i]);
        }
    }

    function _isStakeConfigValid() internal view returns (bool) {
        return rewardInfo.dstRewardFarm != IFarm(address(0)) && rewardInfo.rewardToken != IRewardToken(address(0));
    }

    function stakePendingClaim(StakePendingClaimParams memory stakePendingClaimParams) public whenNotPaused {
        require(_isStakeConfigValid(), "Invalid stake config");
        (IFarm farm, uint256 amount, address receiver, uint256 claimableTime, bytes32 claimId) = (
            stakePendingClaimParams.farm,
            stakePendingClaimParams.amount,
            stakePendingClaimParams.receiver,
            stakePendingClaimParams.claimableTime,
            stakePendingClaimParams.claimId
        );
        _checkFarmIsValid(farm);
        //TODO: check reward farm chain is native

        farm.forceExecuteClaim(amount, msg.sender, receiver, claimableTime, claimId);

        DepositParams memory depositParams =
            DepositParams({ farm: rewardInfo.dstRewardFarm, amount: amount, receiver: receiver });

        rewardInfo.rewardToken.approve(address(rewardInfo.dstRewardFarm), amount);
        depositERC20(depositParams);

        emit PendingClaimStaked(farm, amount, msg.sender, receiver, claimableTime, claimId);
    }

    function stakePendingClaimCrossChain(
        StakePendingClaimParams memory stakePendingClaimParams,
        MessagingFee calldata fee,
        bytes memory extraOptions
    )
        public
        payable
        whenNotPaused
    {
        (IFarm farm, uint256 amount, address receiver, uint256 claimableTime, bytes32 claimId) = (
            stakePendingClaimParams.farm,
            stakePendingClaimParams.amount,
            stakePendingClaimParams.receiver,
            stakePendingClaimParams.claimableTime,
            stakePendingClaimParams.claimId
        );
        _checkFarmIsValid(farm);
        //TODO: check reward farm chain is not native

        farm.forceExecuteClaim(amount, msg.sender, receiver, claimableTime, claimId);

        SendParam memory sendParam = formatLzDepositRewardSendParam(receiver, amount, extraOptions);
        MessagingFee memory expectFee = rewardInfo.rewardToken.quoteSend(sendParam, false);
        require(expectFee.nativeFee == msg.value, "Invalid fee");

        rewardInfo.rewardToken.send{ value: msg.value }(sendParam, fee, lzConfig.refundAddress);

        emit PendingClaimStaked(farm, amount, msg.sender, receiver, claimableTime, claimId);
    }

    function claimAndStake(
        ClaimAndStakeParams memory claimAndStakeParams,
        MessagingFee calldata fee,
        bytes memory extraOptions
    )
        public
        payable
        whenNotPaused
    {
        require(_isStakeConfigValid(), "Invalid stake config");
        // TODO: check claimAndStake enabled?
        (IFarm farm, uint256 amount, address receiver) =
            (claimAndStakeParams.farm, claimAndStakeParams.amount, claimAndStakeParams.receiver);

        _checkFarmIsValid(farm);

        uint256 claimAndStakeAmt = farm.instantClaim(amount, msg.sender, address(this));

        _stake(claimAndStakeAmt, receiver, fee, extraOptions);

        emit ClaimAndStake(farm, claimAndStakeAmt, msg.sender, receiver);
    }

    function mintRewardCallback(address to, uint256 amount) external onlyFarm(msg.sender) {
        IFarm farm = IFarm(msg.sender);

        try rewardInfo.rewardToken.mint(to, amount) { }
        catch {
            revert MintRewardTokenFailed(rewardInfo.rewardToken, farm, amount);
        }
    }

    function _stake(
        address receiver,
        uint256 amount,
        MessagingFee calldata fee,
        bytes memory extraOptions
    )
        internal
        onlyFarm(msg.sender)
    {
        if (isRewardFarmNative()) {
            DepositParams memory depositParams =
                DepositParams({ farm: rewardInfo.dstRewardFarm, amount: amount, receiver: receiver });
            rewardInfo.rewardToken.approve(address(rewardInfo.dstRewardFarm), amount);
            depositERC20(depositParams);
        } else {
            SendParam memory sendParam = formatLzDepositRewardSendParam(receiver, amount, extraOptions);
            MessagingFee memory expectFee = rewardInfo.rewardToken.quoteSend(sendParam, false);
            require(expectFee.nativeFee == msg.value, "Invalid fee");
            rewardInfo.rewardToken.send{ value: msg.value }(sendParam, fee, lzConfig.refundAddress);
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

    // --- internal functions ---
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

    function _checkIsNotZeroAddress(address addr) internal pure {
        if (addr == address(0)) revert InvalidZeroAddress();
    }

    function _stake(uint256 amount, address receiver, MessagingFee calldata fee, bytes memory extraOptions) internal {
        if (isRewardFarmNative()) {
            DepositParams memory depositParams =
                DepositParams({ farm: rewardInfo.dstRewardFarm, amount: amount, receiver: receiver });

            rewardInfo.rewardToken.approve(address(rewardInfo.dstRewardFarm), amount);
            depositERC20(depositParams);
        } else {
            SendParam memory sendParam = formatLzDepositRewardSendParam(receiver, amount, extraOptions);
            MessagingFee memory expectFee = rewardInfo.rewardToken.quoteSend(sendParam, false);
            require(expectFee.nativeFee == msg.value, "Invalid fee");

            rewardInfo.rewardToken.send{ value: msg.value }(sendParam, fee, lzConfig.refundAddress);
        }
    }

    function _createFarm(IERC20 underlyingAsset, FarmConfig memory farmConfig) internal returns (IFarm) {
        bytes memory initData = abi.encodeCall(IFarm.initialize, (address(underlyingAsset), address(this), farmConfig));
        IFarm farm = IFarm(address(new BeaconProxy(address(farmBeacon), initData)));
        if (isValidFarm(farm)) revert FarmAlreadyExists(farm);

        validFarms[farm] = true;
        emit FarmCreated(farm, underlyingAsset, rewardInfo.dstRewardFarm);
        return farm;
    }

    function _calcFarmBytes32(IFarm farm) internal pure returns (bytes32) {
        return bytes32(bytes20(uint160(address(farm))));
    }

    function _checkFarmBytes32IsValid(IFarm farm, bytes32 farmBytes32) internal pure {
        if (_calcFarmBytes32(farm) != farmBytes32) revert FarmBytes32Mismatch(farm, farmBytes32);
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
        require(_oApp == address(rewardInfo.rewardToken), "!oApp");
        require(msg.sender == lzConfig.endpoint, "!endpoint");
        // Extract the composed message from the delivered message using the MsgCodec
        (LZ_COMPOSE_OPT opt, bytes memory data) =
            abi.decode(OFTComposeMsgCodec.composeMsg(_message), (LZ_COMPOSE_OPT, bytes));
        if (opt == LZ_COMPOSE_OPT.DEPOSIT_REWARD_TOKEN) {
            uint256 _amountLD = OFTComposeMsgCodec.amountLD(_message);
            (DepositParams memory depositParams) = abi.decode(data, (DepositParams));
            require(_amountLD == depositParams.amount, "invalid receive amount");
            rewardInfo.rewardToken.approve(address(depositParams.farm), depositParams.amount);
            depositERC20(depositParams);
        } else {
            revert("Invalid opt");
        }
    }

    function isRewardFarmNative() public view returns (bool) {
        return lzConfig.eid == rewardInfo.dstEid;
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
            LZ_COMPOSE_OPT.DEPOSIT_REWARD_TOKEN, abi.encode(DepositParams(rewardInfo.dstRewardFarm, amount, receiver))
        );

        sendParam = SendParam(
            rewardInfo.dstEid,
            rewardInfo.dstRewardManagerBytes32,
            amount,
            amount,
            extraOptions,
            composeMsg,
            "" // oftCmd
        );
    }
}
