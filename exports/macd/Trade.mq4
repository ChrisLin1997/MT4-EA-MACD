// 设置变量
extern int period = 15;  // K线周期
extern double lotSize = 0.01;  // 下单手数
extern double stopLossPercentage = 1.0;  // 止损百分比

// 读取设置文件中的参数
void ReadSettings()
{
    string fileName = "settings.txt";
    ResetLastError();

    int fileHandle = FileOpen(fileName, FILE_READ);
    if (fileHandle != INVALID_HANDLE)
    {
        string line;
        while (!FileIsEnding(fileHandle))
        {
            line = FileReadString(fileHandle);
            string[] parameter = StringSplit(line, "=");
            if (ArraySize(parameter) == 2)
            {
                if (StringTrim(parameter[0]) == "period")
                    period = StrToInteger(parameter[1]);
                else if (StringTrim(parameter[0]) == "lotSize")
                    lotSize = StrToDouble(parameter[1]);
                else if (StringTrim(parameter[0]) == "stopLossPercentage")
                    stopLossPercentage = StrToDouble(parameter[1]);
            }
        }
        FileClose(fileHandle);
    }
}

// 初始化函数
int OnInit()
{
    ReadSettings();
    return(INIT_SUCCEEDED);
}

// 全局变量
int lastMacdDirection = 0;  // 上一次MACD的方向，初始化为0表示未知
int tradePosition = 0;  // 当前持仓的交易方向，1为多头，-1为空头，0为无持仓

// 交易策略代码
void OnTick()
{
    // 在此处编写交易策略的代码

    // 监听每根K线
    if (Period() == period)
    {
        // 当 MACD 的快线由负转正时且当前为多头持仓，执行平仓操作
        if (lastMacdDirection < 0 && tradePosition == 1)
        {
            if (iMACD(NULL, 0, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 0) > iMACD(NULL, 0, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 1))
            {
                CloseTrade();
                return;
            }
        }

        // 当 MACD 的快线由正转负时且当前为空头持仓，执行平仓操作
        if (lastMacdDirection > 0 && tradePosition == -1)
        {
            if (iMACD(NULL, 0, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 0) < iMACD(NULL, 0, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 1))
            {
                CloseTrade();
                return;
            }
        }

        // 當 MACD 的快線由負轉正時 並且 快線高於慢線 並且 當時K 棒收盤價高於 89MA 時入場做多
        if (iMACD(NULL, 0, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 0) > 0 &&
            iMACD(NULL, 0, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 0) > iMACD(NULL, 0, 12, 26, 9, PRICE_CLOSE, MODE_SIGNAL, 0) &&
            Close[0] > iMA(NULL, 0, 89, 0, MODE_SMA, PRICE_CLOSE, 0))
        {
            // 当MACD的方向由负转正时进行买入
            if (lastMacdDirection < 0)
            {
                CloseTrade();  // 平空头
            }

            // 执行买入逻辑
            OpenTrade(1);  // 开多头
            lastMacdDirection = 1;  // 更新MACD的方向为正
        }

        // 當 MACD 的快線由正轉負時 並且 快線低於慢線 並且 當時K棒收盤價低於 89MA 時入場做空
        if (iMACD(NULL, 0, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 0) < 0 &&
            iMACD(NULL, 0, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 0) < iMACD(NULL, 0, 12, 26, 9, PRICE_CLOSE, MODE_SIGNAL, 0) &&
            Close[0] < iMA(NULL, 0, 89, 0, MODE_SMA, PRICE_CLOSE, 0))
        {
            // 当MACD的方向由正转负时进行卖出
            if (lastMacdDirection > 0)
            {
                CloseTrade();  // 平多头
            }

            // 执行卖出逻辑
            OpenTrade(-1);  // 开空头
            lastMacdDirection = -1;  // 更新MACD的方向为负
        }
    }
}

// 执行开仓操作
void OpenTrade(int direction)
{
    if (tradePosition == 0)
    {
        double stopLossLevel = 0.0;  // 不设置止损
        double takeProfitLevel = 0.0;  // 不设置止盈

        if (direction == 1)
        {
            stopLossLevel = Close[0] - (Close[0] * stopLossPercentage / 100.0);  // 止损价位为当前收盘价的指定百分比
            OrderSend(Symbol(), OP_BUY, lotSize, Ask, 0, stopLossLevel, takeProfitLevel, "Long Trade", 0, 0, Green);
            tradePosition = 1;  // 更新持仓方向为多头
        }
        else if (direction == -1)
        {
            stopLossLevel = Close[0] + (Close[0] * stopLossPercentage / 100.0);  // 止损价位为当前收盘价的指定百分比
            OrderSend(Symbol(), OP_SELL, lotSize, Bid, 0, stopLossLevel, takeProfitLevel, "Short Trade", 0, 0, Red);
            tradePosition = -1;  // 更新持仓方向为空头
        }
    }
}

// 执行平仓操作
void CloseTrade()
{
    if (tradePosition != 0)
    {
        for (int i = OrdersTotal() - 1; i >= 0; i--)
        {
            if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            {
                if (OrderType() == OP_BUY && tradePosition == 1)
                {
                    OrderClose(OrderTicket(), OrderLots(), Bid, 0, Red);
                    tradePosition = 0;  // 更新持仓方向为无持仓
                }
                else if (OrderType() == OP_SELL && tradePosition == -1)
                {
                    OrderClose(OrderTicket(), OrderLots(), Ask, 0, Green);
                    tradePosition = 0;  // 更新持仓方向为无持仓
                }
            }
        }
    }
}