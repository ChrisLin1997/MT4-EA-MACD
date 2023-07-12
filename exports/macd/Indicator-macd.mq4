#property indicator_chart_window  // 将指标绘制在价格图表窗口中

// 初始化函数
int init()
{
    IndicatorShortName("MACD");  // 指标名称

    SetIndexStyle(0, DRAW_LINE);  // MACD 指标线的绘制样式
    SetIndexBuffer(0, CustomMACD());  // 设置 MACD 指标线的数据缓冲区

    return 0;
}

// 自定义 MACD 指标计算函数
double CustomMACD()
{
    double value = iMACD(NULL, 0, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 0);

    return value;
}
