//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.12;

import "./interfaces/WBNB.sol";
import "./interfaces/IChiToken.sol";

import "./libraries/SafeMath.sol";
import "./libraries/PancakeLibrary.sol";

import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IERC20.sol";

import "./Ownable.sol";

contract Arbitrage is Ownable {
    
    event Gordon(address tokenBorrow, uint amountIn, uint amount0, uint amount1);
    
    IChiToken public chiToken;
    mapping(address => bool) public arbWallets;

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
    modifier onlyArbs {
        require(arbWallets[msg.sender] == true, "No Soup You");
        _;
    }

    constructor (address _gasToken, address[] memory _arbWallets) public {
        chiToken = IChiToken(_gasToken);
        arbWallets[msg.sender] = true;
        if (_arbWallets.length > 0) {
            for (uint i=0;i<_arbWallets.length;i++) {
                arbWallets[_arbWallets[i]] = true;
            }
        }
    }
    function mintGasToken(uint amount) public {
        chiToken.mint(amount);
    }
    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        IERC20(token).approve(address(this), value);
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))),"TransferHelper: TRANSFER_FROM_FAILED");
    }
    function _swap(uint256[] memory amounts, address[] memory path, address[] memory pairPath, address _to) internal {
        for (uint256 i=0; i < pairPath.length; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = PancakeLibrary.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0 
                ? (uint256(0), amountOut) 
                : (amountOut, uint256(0));
            address to = i < pairPath.length - 1 ? pairPath[i + 1] : _to;
            IUniswapV2Pair(pairPath[i]).swap(
                amount0Out,
                amount1Out,
                to,
                new bytes(0)
            );
        }
    }
    function getAmountsOut(uint _amountIn, address[] memory _path, address[] memory _pairPath, uint[] memory _fee) external view returns (uint[] memory) {
        return PancakeLibrary.getAmountsOut(_amountIn, _path, _pairPath, _fee);
    }
    // hawk is a simple minded desk trader that does exactly what he is told, using funds held by this contract
    function hawk(uint _amountIn, uint _amountOutMin, address _tokenFrom, address _tokenTo, address _router, uint[] memory _swapFees, uint deadline) external payable ensure(deadline) onlyArbs gasTokenRefund returns (bool success) {
        if (msg.value > 0) {
            // Assumes _tokenFrom is WBNB 
            WBNB(_tokenFrom).deposit{value:msg.value, gas:50000}();
        }
        address factory = IUniswapV2Router01(_router).factory();
        address pairAddress = IUniswapV2Factory(factory).getPair(_tokenFrom, _tokenTo);
        require(pairAddress != address(0), "Pool does not exist");

        address[] memory path = new address[](2);
        address[] memory pairPath = new address[](1);
        path[0] = _tokenFrom;
        path[1] = _tokenTo;
        pairPath[0] = pairAddress;
        
        uint256[] memory amounts = PancakeLibrary.getAmountsOut(_amountIn, path, pairPath, _swapFees);
        success = true;
        if (amounts[amounts.length - 1] < _amountOutMin) return success;
        safeTransferFrom(_tokenFrom, address(this), pairAddress, amounts[0]);
        _swap(amounts, path, pairPath, address(this));
    }
    // budFox does advanced trades using funds held by this contract
    function budFox(uint _amountIn, uint _amountOutMin, address[] calldata _path, address[] calldata _pairPath, uint[] calldata _swapFees, uint deadline) external payable ensure(deadline) onlyArbs gasTokenRefund returns (bool success) { 
        if (msg.value > 0) {
            // Assumes _path[0] is WBNB
            WBNB(_path[0]).deposit{value:msg.value, gas:50000}();
        }
        
        uint256[] memory amounts = PancakeLibrary.getAmountsOut(_amountIn, _path, _pairPath, _swapFees);
        success = true;
        if (amounts[amounts.length - 1] < _amountOutMin) return success;
        safeTransferFrom(_path[0], address(this), _pairPath[0], amounts[0]);
        _swap(amounts, _path, _pairPath, address(this));
    }
    // gordon uses funds loaned to him to perform advanced trades
    function gordon(uint _amountIn, address _loanFactory, address[] memory _loanPair, address[] memory _path, address[] memory _pairPath, uint[] memory _swapFees, uint deadline) external payable ensure(deadline) onlyArbs gasTokenRefund {
        address pairAddress = IUniswapV2Factory(_loanFactory).getPair(_loanPair[0], _loanPair[1]);
        require(pairAddress != address(0), "Pool does not exist");
        if (msg.value > 0) {
            // Assumes _path[0] is WBNB
            WBNB(_path[0]).deposit{value:msg.value, gas:50000}();
        }
        uint amount0Out = _loanPair[0] == IUniswapV2Pair(pairAddress).token0() ? _amountIn : 0;
        uint amount1Out = _loanPair[1] == IUniswapV2Pair(pairAddress).token1() ? _amountIn : 0;
        bytes memory data = abi.encode(_amountIn,_path,_pairPath,_loanFactory,_swapFees);
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

        emit Gordon(path[0], amountIn, _amount0, _amount1);

        uint256[] memory amounts = PancakeLibrary.getAmountsOut(amountIn,path,pairPath,swapFees);
        safeTransferFrom(path[0], address(this), pairPath[0], amounts[0]);
        _swap(amounts, path, pairPath, address(this));

        uint amountReceived = amounts[amounts.length - 1];

        // Pay back flashloan
        uint fee = ((amountIn * 3)/ 997) +1;
        uint amountToRepay = amountIn+fee;

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
    function addArbWallets(address[] memory _newArbs) public onlyOwner {
        for (uint i=0;i<_newArbs.length;i++) {
            arbWallets[_newArbs[i]] = true;
        }
    }
    function removeArbWallets(address[] memory _oldArbs) public onlyOwner {
        for (uint i=0;i<_oldArbs.length;i++) {
            delete arbWallets[_oldArbs[i]];
        }
    }
}
