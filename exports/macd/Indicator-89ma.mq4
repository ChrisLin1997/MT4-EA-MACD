#property indicator_chart_window  // 将指标绘制在价格图表窗口中

// 初始化函数
int init()
{
    IndicatorShortName("89 MA");  // 指标名称

    SetIndexStyle(0, DRAW_LINE);  // 89 MA 指标线的绘制样式
    SetIndexBuffer(0, CustomMA());  // 设置 89 MA 指标线的数据缓冲区

    return 0;
}

// 自定义 89 MA 指标计算函数
double CustomMA()
{
    double value = iMA(NULL, 0, 89, 0, MODE_SMA, PRICE_CLOSE, 0);

    return value;
}
