// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StakingRewards {
    IERC20 private immutable i_stakingToken;
    IERC20 private immutable i_rewardsToken;

    address private immutable i_owner;
    uint256 private s_duration;
    uint256 private s_finshedAt;
    uint256 private s_updatedAt;
    uint256 private s_rewardRate;
    uint256 private s_RewardperTokenStored;

    mapping(address => uint256) private UserRewardPerToken;
    mapping(address => uint256) private rewards;

    uint256 private totalSupply;
    mapping(address => uint256) private balanceOf;

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert();
        }
        _;
    }

    modifier updateReward(address _account) {
        s_RewardperTokenStored = rewardperToken();
        s_updatedAt = lastTimeRewardsApplicable();
        if (_account == address(0)) {
            revert();
        }
        rewards[_account] = earned(_account);
        UserRewardPerToken[_account] = s_RewardperTokenStored;
        _;
    }

    constructor(address _stakingtoken, address _rewardstoken) {
        i_owner = msg.sender;
        i_stakingToken = IERC20(_stakingtoken);
        i_rewardsToken = IERC20(_rewardstoken);
    }

    function setRewardsDuration(uint256 _duration) external onlyOwner {
        // before the previous rewards period is over, owner cannot set a new duration 
        if (s_finshedAt > block.timestamp) {
            revert();
        }
        s_duration = _duration;
    }

    // This function is used by the woner to send the rewards amount to this contrct and set the rewards rate 
    function notifyRewrdsAmount(uint256 _amount) external onlyOwner updateReward(address(0)){
        // if no ongoing staking going on then set the rewards rate directly, else we get the current remaining rewards 
        // and add the new rewards to it which increse the current reward rate 
        if (s_finshedAt > block.timestamp) {
            s_rewardRate = _amount/s_duration;
        }
        else {
            uint256 remainingRewards = s_rewardRate * (s_finshedAt - block.timestamp);
            s_rewardRate = (remainingRewards + _amount) / s_duration;
        }

        if (s_rewardRate == 0) {
            revert();
        }
        if (s_rewardRate * s_duration > i_rewardsToken.balanceOf(address(this))) {
            revert();
        }

        unchecked {
            s_finshedAt = block.timestamp + s_duration;
            s_updatedAt = block.timestamp;
        }
    }

    function stake(uint256 _amount) external updateReward(msg.sender) {
        if (_amount <= 0) {
            revert();
        }

        i_stakingToken.transferFrom(msg.sender, address(this), _amount);

        unchecked {
            balanceOf[msg.sender] += _amount;
            totalSupply = totalSupply + _amount;
        }
    }

    function withdraw(uint256 _amount) external updateReward(msg.sender) {
         if (_amount <= 0) {
            revert();
        }

        unchecked {
            balanceOf[msg.sender] -= _amount;
            totalSupply = totalSupply - _amount;
        }

        i_stakingToken.transfer(msg.sender, _amount);

    }

    function lastTimeRewardsApplicable() public view returns (uint256) {
        return min(block.timestamp,s_finshedAt);
    }

    function rewardperToken() public view returns (uint256) {
        if (totalSupply == 0) {
            return s_RewardperTokenStored;
        }
        return (s_RewardperTokenStored * (s_rewardRate * (lastTimeRewardsApplicable() - s_updatedAt) * 1e18 ))/totalSupply;
    }

    function earned(address _account) public view returns(uint256) {
        return (balanceOf[_account] * (rewardperToken() - UserRewardPerToken[_account])) / 1e18 + rewards[_account];
    }

    function getReward() external updateReward(msg.sender){
        uint256 reward = rewards[msg.sender];
        if (reward != 0){
            rewards[msg.sender] = 0;
            i_rewardsToken.transfer(msg.sender, reward);
        }

    }

    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        if (x <= y) {
            return x;
        }
        return y;
    }
}