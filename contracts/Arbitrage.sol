//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces/WBNB.sol";
import "./interfaces/IChiToken.sol";

import "./libraries/PancakeLibrary.sol";

import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router02.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Arbitrage is Ownable {
    using SafeMath for uint;
    
    event gotGordoned(address tokenBorrow, uint amountIn, uint amount0, uint amount1);
    
    IChiToken public chiToken;
    
    receive() payable external {}

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "EXPIRED");
        _;
    }
    modifier gasTokenRefund {
        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
        chiToken.freeUpTo((gasSpent + 14154) / 41947);
    }

    constructor (address _gasToken) {
        chiToken = IChiToken(_gasToken);
    }
    function mintGasToken(uint amount) public {
        chiToken.mint(amount);
    }
    function safeTransferFrom(address token,address from,address to,uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))),"TransferHelper: TRANSFER_FROM_FAILED");
    }
    function _swap(uint256[] memory amounts,address[] memory path,address[] memory pairPath,address _to) internal virtual {
        for (uint256 i; i < pairPath.length; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = PancakeLibrary.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0 ? (uint256(0), amountOut) : (amountOut, uint256(0));
            address to = i < pairPath.length - 1 ? pairPath[i + 1] : _to;
            IUniswapV2Pair(pairPath[i]).swap(
                amount0Out,
                amount1Out,
                to,
                new bytes(0)
            );
        }
    }
    function vSwap(
        uint256 amountIn,
        address[] memory path,
        address[] memory pairPath,
        uint256[] memory fee,
        address to,
        uint256 deadline
    ) public virtual ensure(deadline) returns (uint) {
        uint256[] memory amounts = PancakeLibrary.getAmountsOut(amountIn,path,pairPath,fee);
        safeTransferFrom(path[0], address(this), pairPath[0], amounts[0]);
        _swap(amounts, path, pairPath, to);
        return amounts[amounts.length - 1];
    }
    function getAmountsOut(uint _amountIn, address[] memory _path, address[] memory _pairPath, uint[] _fee) returns (uint[] amounts) {
        uint256[] memory amounts = PancakeLibrary.getAmountsOut(_amountIn, _path, _pairPath, _fee);
    }
    function gordon(uint _amountIn, address _loanFactory,address[] memory _loanPair, address[] memory _path, address[] memory _pairPath, uint[] memory _swapFees) external payable onlyOwner gasTokenRefund {
        if (msg.value > 0) {
            WBNB(_path[0]).deposit{value:msg.value, gas:50000}();
        }
        address flashToken0 = _loanPair[0];
        address flashToken1 = _loanPair[1];
        address flashFactory = _loanFactory;
        
        address pairAddress = IUniswapV2Factory(flashFactory).getPair(flashToken0, flashToken1);
        require(pairAddress != address(0), "Pool does not exist");

        address token0 = IUniswapV2Pair(pairAddress).token0();
        address token1 = IUniswapV2Pair(pairAddress).token1();

        uint amount0Out = flashToken0 == token0 ? _amountIn : 0;
        uint amount1Out = flashToken0 == token1 ? _amountIn : 0;

        bytes memory data = abi.encode(_amountIn,_path,_pairPath,flashFactory,_swapFees);

        IUniswapV2Pair(pairAddress).swap(
            amount0Out,
            amount1Out,
            address(this),
            data
        );
    }
    function pancakeCall(address _sender, uint _amount0, uint _amount1, bytes calldata _data) external {
        (uint amountIn, address[] memory path, address[] memory pairPath, address flashFactory, uint[] memory swapFees) = abi.decode(_data, (uint, address[], address[], address, uint[]));

        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        address pair = IUniswapV2Factory(flashFactory).getPair(token0, token1);
        require(msg.sender == pair, "Sender not pair");
        require(_sender == address(this), "Not sender");

        emit gotGordoned(path[0], amountIn, _amount0, _amount1);

        uint amountReceived = vSwap(amountIn, path, pairPath, swapFees, address(this), block.timestamp + 60);

        // Pay back flashloan
        uint fee = ((amountIn * 3)/ 997) +1;
        uint amountToRepay = amountIn+fee;

        // amountReceived = IERC20(path[0]).balanceOf(address(this)); //To test even if it's not profitable (we send WBNB to cover fees)
        require(amountReceived>amountIn,"Not profitable");
        require(amountReceived>amountToRepay,"Could not afford loan fees");
        IERC20(path[0]).transfer(msg.sender, amountToRepay);
    }
    function withdraw(uint _amount, address _token, bool isBNB) public onlyOwner {
        if (isBNB){
            _amount > 0 ? payable(msg.sender).send(_amount) : payable(msg.sender).send(address(this).balance);
        } else{
            _amount > 0 ? IERC20(_token).transfer(msg.sender, _amount) : IERC20(_token).transfer(msg.sender, IERC20(_token).balanceOf(address(this)));
        }
    }
}
