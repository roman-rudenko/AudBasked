//+------------------------------------------------------------------+
//|                                                 AudBaskedRSI 1.0 |
//|                                  Copyright © 2013, Roman Rudenko |
//|                                             ra.rudenko@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2013, Roman Rudenko"

#property indicator_separate_window
#property indicator_minimum 200
#property indicator_maximum 500
#property indicator_buffers 1
#property indicator_color1 DeepSkyBlue
#property indicator_level1 280
#property indicator_level2 420

extern int		RsiTimeFrame	= PERIOD_M30;
extern int		RsiPeriod		= 14;
extern int		RsiAppliedPrice	= PRICE_CLOSE;

double RsiBasket[];

int init()
{
	SetIndexStyle(0, DRAW_LINE);
	SetIndexBuffer(0, RsiBasket);
	return(0);
}

int deinit()
{
	return(0);
}

int start()
{
	int unCountedBars = Bars - IndicatorCounted();
	
	for (int i = unCountedBars - 1; i >= 0; i--)
	{
		double rsiAUDUSD = iRSI("AUDUSD", RsiTimeFrame, RsiPeriod, PRICE_CLOSE, i);
		double rsiAUDNZD = iRSI("AUDNZD", RsiTimeFrame, RsiPeriod, PRICE_CLOSE, i);
		double rsiAUDCAD = iRSI("AUDCAD", RsiTimeFrame, RsiPeriod, PRICE_CLOSE, i);
		double rsiAUDJPY = iRSI("AUDJPY", RsiTimeFrame, RsiPeriod, PRICE_CLOSE, i);
		double rsiAUDCHF = iRSI("AUDCHF", RsiTimeFrame, RsiPeriod, PRICE_CLOSE, i);
		double rsiEURAUD = iRSI("EURAUD", RsiTimeFrame, RsiPeriod, PRICE_CLOSE, i);
		double rsiGBPAUD = iRSI("GBPAUD", RsiTimeFrame, RsiPeriod, PRICE_CLOSE, i);
		RsiBasket[i] = rsiAUDUSD + rsiAUDNZD + rsiAUDCAD + rsiAUDJPY + rsiAUDCHF + (100 - rsiEURAUD) + (100 - rsiGBPAUD);
	}
	return(0);
}

