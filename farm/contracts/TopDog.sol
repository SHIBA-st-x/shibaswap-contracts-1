  TopDogsol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./BoneToken.sol";

// BoneMasterChef is the master of Bone. He can make Bone and he is a fair guy.
// The biggest change made is using per second instead of per block for rewards
// This is due to Fantoms extremely inconsistent block times
// The other biggest change was the removal of the migration functions
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once BONE is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract BoneMasterChef is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of BONEs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accTokenPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accTokenPerShare` (and `lastRewardTime`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. BONEs to distribute per block.
        uint256 lastRewardTime;  // Last block number that BONEs distribution occurs.
        uint256 accTokenPerShare; // Accumulated BONEs per share, times 1e12. See below.
        uint16 depositFee;      // Deposit fee in basis points
    }

    // Block reward plan
    struct BlockRewardInfo {
        uint256 firstBlock;           // First block number
        uint256 lastBlock;            // Last block number
        uint256 reward;               // Block reward amount
    }

    // Yield TOKEN BONE!
    BoneToken public bone;
    // Dev address.
    address public devAddr;
    // Fee address.
    address public feeAddr;
    // BONE tokens created per second.
    uint256 public tokenPerSecond;
    // Bonus muliplier for early bone makers.
    uint256 public BONUS_MULTIPLIER = 1;


    // Info of each pool.
    PoolInfo[] public poolInfo;
    BlockRewardInfo[] public rewardInfo;

    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block time when BONE mining starts.
    uint256 public startTime;
    // The block time when BONE mining ends because it has total supply.
    uint256 public endTime;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SetFeeAddress(address indexed user, address indexed newAddress);
    event SetDevAddress(address indexed user, address indexed newAddress);

    constructor(
        BoneToken _bone,
        address _devAddr,
        address _feeAddr,
        uint256 _bonePerSecond,
        uint256 _startTime
    ) {
        bone = _bone;
        devAddr = _devAddr;
        feeAddr = _feeAddr;
        tokenPerSecond = _bonePerSecond;
        startTime = _startTime;

        endTime = _startTime.add(uint256(7200000 ether).div(tokenPerSecond.mul(110).div(100)));

        // staking pool
        poolInfo.push(PoolInfo({
            lpToken: _bone,
            allocPoint: 0,
            lastRewardTime: startTime,
            accTokenPerShare: 0,
            depositFee: 0
        }));

        totalAllocPoint = 0;
    }

    function updateMultiplier(uint256 multiplierNumber) external onlyOwner {
        BONUS_MULTIPLIER = multiplierNumber;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IERC20 _lpToken, uint16 _depositFee, bool _withUpdate) external onlyOwner {
        require(_depositFee <= 10000, "set: invalid deposit fee basis points");

        if (_withUpdate) {
            massUpdatePools();
        }

        uint256 lastRewardTime = block.timestamp > startTime ? block.timestamp : startTime;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardTime: lastRewardTime,
            accTokenPerShare: 0,
            depositFee: _depositFee
        }));
        
        updateStakingPool();
    }

    // Update the given pool's BONE allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFee, bool _withUpdate) external onlyOwner {
        require(_depositFee <= 10000, "set: invalid deposit fee basis points");

        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 prevAllocPoint = poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFee = _depositFee;
        if (prevAllocPoint != _allocPoint) {
            totalAllocPoint = totalAllocPoint.sub(prevAllocPoint).add(_allocPoint);
            updateStakingPool();
        }
    }

    function updateStakingPool() internal {
        uint256 length = poolInfo.length;
        uint256 points = 0;
        for (uint256 pid = 1; pid < length; ++pid) {
            points = points.add(poolInfo[pid].allocPoint);
        }
        if (points != 0) {
            points = points.div(3);
            totalAllocPoint = totalAllocPoint.sub(poolInfo[0].allocPoint).add(points);
            poolInfo[0].allocPoint = points;
        }
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        _from = _from > startTime ? _from : startTime;
        _to = _to > endTime ? endTime: _to;

        if (_to < startTime || _from > endTime) return 0;
        return _to - _from;
    }

    // View function to see pending BONEs on frontend.
    function pendingToken(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accTokenPerShare = pool.accTokenPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.timestamp > pool.lastRewardTime && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardTime, block.timestamp);
            uint256 boneReward = multiplier.mul(tokenPerSecond).mul(pool.allocPoint).div(totalAllocPoint);            
            accTokenPerShare = accTokenPerShare.add(boneReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accTokenPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }


    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardTime, block.timestamp);
        uint256 boneReward = multiplier.mul(tokenPerSecond).mul(pool.allocPoint).div(totalAllocPoint);

        bone.mint(devAddr, boneReward.div(10)); // 10% is dev reward
        bone.mint(address(this), boneReward);

        pool.accTokenPerShare = pool.accTokenPerShare.add(boneReward.mul(1e12).div(lpSupply));
        pool.lastRewardTime = block.timestamp;
    }

    // Deposit LP tokens to BoneMasterChef for BONE allocation.
    function deposit(uint256 _pid, uint256 _amount) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accTokenPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                safeTokenTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            if (pool.depositFee > 0) {
                uint256 depositFee = _amount.mul(pool.depositFee).div(10000);
                pool.lpToken.safeTransfer(feeAddr, depositFee);
                user.amount = user.amount.add(_amount).sub(depositFee);
            } else {
                user.amount = user.amount.add(_amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from BoneMasterChef.
    function withdraw(uint256 _pid, uint256 _amount) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");

        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accTokenPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            safeTokenTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Safe bone transfer function, just in case if rounding error causes pool to not have enough BONEs.
    function safeTokenTransfer(address _to, uint256 _amount) internal {
        uint256 boneBal = bone.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > boneBal) {
            transferSuccess = bone.transfer(_to, boneBal);
        } else {
            transferSuccess = bone.transfer(_to, _amount);
        }
        require(transferSuccess, "safeTokenTransfer: transfer failed");
    }

    // Update dev address by the previous dev.
    function dev(address _devAddr) external {
        require(msg.sender == devAddr, "dev: wut?");
        devAddr = _devAddr;

        emit SetDevAddress(msg.sender, _devAddr);
    }
    
    // Update fee address by the previous fee manager.
    function setFeeAddress(address _feeAddr) external {
        require(msg.sender == feeAddr, "setFeeAddress: Forbidden");
        feeAddr = _feeAddr;

        emit SetFeeAddress(msg.sender, _feeAddr);
    }

    function updateStartTime(uint256 _startTime) external onlyOwner {
        require(block.timestamp < startTime, "Staking was started already");
        require(block.timestamp < _startTime);
        
        startTime = _startTime;
        endTime = _startTime.add(uint256(7200000 ether).div(tokenPerSecond.mul(110).div(100)));
    }
}
