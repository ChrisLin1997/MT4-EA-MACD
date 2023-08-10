#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
// 设置变量
extern double lotSize = 0.01;  // 下單手數
extern int stopLossPoint = 20; // 止損加點
extern int stopLossMode = 1; // 止損方式，1為當根K棒設置止損，2為近期X根K棒的最高價或最低價
extern int recentBars = 5;   // 止損方式：近幾根K棒

int lastBar = 0;  // 上一次处理的K线序号

int OnInit()
{
    return(INIT_SUCCEEDED);
}

void OnTick()
{
    // 获取当前K线序号
    int currentBar = Bars - 1;

    // 判断是否是新K线的开始
    if (currentBar != lastBar)
    {
        lastBar = currentBar;  // 更新上一次处理的K线序号

        // 在这里执行您的交易逻辑
        ExecuteTradingLogic();
    }
}

// 执行交易逻辑函数
void ExecuteTradingLogic()
{
    // 獲取持倉信息
    int positions = OrdersTotal();

    // 定義MACD參數
    int fastEMA = 12;
    int slowEMA = 26;
    int signalSMA = 9;

    // 獲取MACD值
    double macdCurrent = iMACD(NULL, 0, fastEMA, slowEMA, signalSMA, PRICE_CLOSE, MODE_MAIN, 0);
    double macdPrevious = iMACD(NULL, 0, fastEMA, slowEMA, signalSMA, PRICE_CLOSE, MODE_MAIN, 1);

    // 止損價格
    double stopLossLevel;

    // 有持倉時
    if (positions > 0)
    {
        for (int i = 0; i < positions; i++)
        {
            if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            {
                // OP_BUY表示多單（買入交易）
                if (OrderType() == OP_BUY && macdCurrent > 0 && macdCurrent < macdPrevious)
                {
                    // 獲取當前持倉交易的相關信息
                    double positionVolume = OrderLots();
                    int ticket = OrderTicket();
                    int closeResult = OrderClose(ticket, positionVolume, Bid, 3, Blue);
                    if (closeResult < 0)
                    {
                        Print("平倉失敗，錯誤碼：" + closeResult);
                    }
                }

                // OP_SELL表示空單（賣出交易）
                else if (OrderType() == OP_SELL && macdCurrent < 0 && macdCurrent > macdPrevious)
                {
                    // 獲取當前持倉交易的相關信息
                    double positionVolume = OrderLots();
                    int ticket = OrderTicket();
                    int closeResult = OrderClose(ticket, positionVolume, Ask, 3, Red);
                    if (closeResult < 0)
                    {
                        Print("平倉失敗，錯誤碼：" + closeResult);
                    }
                }
            }
        }
    }

    // 未持倉時
    else
    {
        // 當 MACD 的快線由負轉正時 並且 快線高於慢線 並且 當時K 棒收盤價高於 89MA 時入場做多
        if (macdCurrent >= 0 && macdPrevious < 0 &&
            Close[0] > iMA(NULL, 0, 89, 0, MODE_SMA, PRICE_CLOSE, 0))
        {
            // 止損方式
            if (stopLossMode == 1) {
              stopLossMode = Low[0] - stopLossPoint * Point;
            }
            if (stopLossMode == 2) {
              stopLossMode = Low[iLowest(NULL, 0, MODE_LOW, recentBars, 1)]; 
            }

            // 發送訂單
            OrderSend(Symbol(), OP_BUY, lotSize, Ask, 0, stopLossLevel, 0.0, "Long Trade", 0, 0, Green);
            return;
        }

        // 當 MACD 的快線由正轉負時 並且 快線低於慢線 並且 當時K棒收盤價低於 89MA 時入場做空
        if (macdCurrent <= 0 && macdPrevious > 0 &&
            Close[0] < iMA(NULL, 0, 89, 0, MODE_SMA, PRICE_CLOSE, 0))
        {
            // 止損方式
            if (stopLossMode == 1) {
              stopLossMode = High[0] + stopLossPoint * Point;
            }
            if (stopLossMode == 2) {
              stopLossMode = High[iHighest(NULL, 0, MODE_HIGH, recentBars, 1)];
            }

            // 發送訂單
            OrderSend(Symbol(), OP_SELL, lotSize, Bid, 0, stopLossLevel, 0.0, "Short Trade", 0, 0, Red);
            return;
        }
    }
}
