pragma solidity ^0.4.19;

contract ChiHuoBao {
    // 订单总价 单位角
    uint256 public orderPriceTotal;
    // 订单总数 单位角
    uint256 public orderNumTotal;
    // 订单均价 单位角
    uint256 public orderAveragePrice;
    // 菜品总数 份数
    uint256 public mealNumTotal;
    // 菜品均价 单位角
    uint256 public mealAveragePrice;

    uint256 public constant CONSTANT_VARIABLE = 999 * 1000000;
    
    struct Order {
        // 单个订单的总价
        uint256 _totalPrice;
        // 订单时间
        uint256 _time;
        // 单个订单的平均价
        uint256 _averagePrice;
        // 菜品的总数/份数
        uint128 _mealNumTotal;
        // 菜品种类
        uint128 _mealTypeNum;
    }
    
    struct Meal {
        uint128 _maxPrice;
        uint128 _minPrice;
        uint128 _avrPrice;
        // 销量
        uint128 _sales;
        uint8 _update_flag;
    }
    
    
    // 订单hash列表
    bytes32[] orderList;
    
    // map{tx -> 订单号} 
    mapping(bytes32 => string) mapTx2OrderNo;
    // map{订单号 -> tx}
    mapping(string => bytes32) mapOrderNo2Tx;
    // map{订单号 -> 订单详情}
    mapping(string => Order) mapNo2Order;
    // map{日期(时间戳) => 订单数量}
    mapping(uint256 => uint256) mapDate2OrderNum;
    // map{菜品id -> 菜品信息}
    mapping(uint256 => Meal) mapNo2Meal;
    
    
    // 发送订单
    function sendOrder(string orderNo, uint256 price, uint256 time, uint256 specificDate, string addr,
        uint256[] mealName, uint256[] mealPrice, uint256[] mealNum) public {
        
        require(mealNum.length == mealName.length 
            && mealName.length == mealPrice.length);
        
        uint256 totalMealNum = 0;
        uint256 tempPrice = 0;
        
        for(uint256 i = 0; i < mealNum.length; i++) {
            totalMealNum += mealNum[i];
            
            Meal memory meal = mapNo2Meal[mealName[i]];
            if (meal._update_flag != 1) {
                meal._maxPrice = 0;
                meal._minPrice = (uint128)(CONSTANT_VARIABLE);
            }
            
            tempPrice = mealPrice[i];
            if (tempPrice > meal._maxPrice) { // 更新最高价
                meal._maxPrice = (uint128)(tempPrice);
            }
            if (tempPrice < meal._minPrice) { // 更新最低价
                meal._minPrice = (uint128)(tempPrice);
            }
            // 更新均价
            meal._avrPrice = (meal._minPrice + meal._maxPrice) / 2;
            
            // 更新销量
            meal._sales += (uint128)(mealNum[i]);
            
            // _update_flag
            meal._update_flag = 1;
            
            mapNo2Meal[mealName[i]] = meal;
        }
        
        // 均价
        tempPrice = price/totalMealNum;
        uint256 mealType = mealName.length;
        
        Order memory order = Order({
            _totalPrice: price,
            _time: time,
            _averagePrice: tempPrice,
            _mealNumTotal: (uint128)(totalMealNum),
            _mealTypeNum: (uint128)(mealType)
        });
        
        // 记录订单信息
        mapNo2Order[orderNo] = order;
        
        // 当天的订单数量+1
        mapDate2OrderNum[specificDate] += 1;
        
        
        // 更新全局变量
        // todo safeMath
        orderPriceTotal += price;
        orderNumTotal += 1;
        orderAveragePrice = orderPriceTotal / orderNumTotal;
        mealNumTotal += totalMealNum;
        mealAveragePrice = orderPriceTotal / mealNumTotal;
    }
    
    // 记录某个Tx的订单号
    function recordTxOrderNo(bytes32 txHash, string orderNo) public {
        mapTx2OrderNo[txHash] = orderNo;
        mapOrderNo2Tx[orderNo] = txHash;
    }
    
    // 获得某个Tx的订单信息
    // returns(订单时间，订单总价，菜品种类)
    function getOrderOfTx(bytes32 _parm) public view returns(uint256, uint256, uint256){
        string memory orderNo = mapTx2OrderNo[_parm];
        
        Order memory order = mapNo2Order[orderNo];
        return (order._time, order._totalPrice, order._mealTypeNum);
    }
    
    // 得到某个日期的订单数量
    function getOrderNumOfDate(uint256 date) view public returns(uint256){
        
        return mapDate2OrderNum[date];// 0-非法
    }
    
    // 获得某个tx的订单总价
    function getOrderPriceTotalOfTx(bytes32 _txHash) public view returns(uint256){ 
        // 得到订单号
        string memory orderNo = mapTx2OrderNo[_txHash];
        
        return mapNo2Order[orderNo]._totalPrice;
    }
    
    // 获得某个Tx的菜品总数
    function getMealNumOfOrder(bytes32 _txHash) public view returns(uint256) {
        
        // 得到订单号
        string memory orderNo = mapTx2OrderNo[_txHash];
        
        return mapNo2Order[orderNo]._mealNumTotal;
    }
    
    // 获得某个Tx的菜品种类
    function getMealTypeNumOfOrder(bytes32 _txHash) public view returns(uint256) {
        // 得到订单号
        string memory orderNo = mapTx2OrderNo[_txHash];
        
        return mapNo2Order[orderNo]._mealTypeNum;
    }
    
    // 根据菜品ID得到相应的信息
    function getCorrespondingInfoByMealId(uint256 mealNo) public view returns(uint128, uint128, uint128, uint128, uint128){
        
        Meal memory meal = mapNo2Meal[mealNo];
        return (90, meal._avrPrice, meal._minPrice, meal._maxPrice, meal._sales);
    }
    
    // 根据订单序号取得相应数据
    function getElaborateInfoByNo(string orderNo) public view returns(uint256, uint256, uint256){//订单时间，订单总价，菜品种类
        
        Order memory order = mapNo2Order[orderNo];
        return (order._time, order._totalPrice, order._mealTypeNum);
    }
    
    // 根据订单号返回相应的 txHash
    function getTxhashByOrderNo(string orderNo) public view returns(bytes32) {
        return mapOrderNo2Tx[orderNo];
    }
}
