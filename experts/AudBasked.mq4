//+------------------------------------------------------------------+
//|                                                    AudBasked 1.0 |
//|                                  Copyright © 2013, Roman Rudenko |
//|                                             ra.rudenko@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2013, Roman Rudenko"

extern double	Lot				= 0.01;
extern int		TakeProfit		= 0;
extern int		StopLoss		= 0;
/*extern*/ int	TrailingStop	= 0;
extern int		SlipPage		= 3;
extern int		MagicNumber		= 34321477;
extern string	CommentStr		= "AudBasked";

extern double	RsiOpenLevel	= 280;
extern double	RsiCloseLevel	= 420;

extern double	Step			= 10;

extern int		RsiTimeFrame	= PERIOD_M30;
extern int		RsiPeriod		= 14;
extern int		RsiAppliedPrice	= PRICE_CLOSE;

double	_basketRSI				= 0;
double	_prevBasketRSI			= 0;
double	_basketProfit			= 0;
double	_nextOrdersVolume		= 0;
double	_currentOrdersVolume	= 0;
double	_rsiAUDUSD				= 0;
double	_rsiAUDNZD				= 0;
double	_rsiAUDCAD				= 0;
double	_rsiAUDJPY				= 0;
double	_rsiAUDCHF				= 0;
double	_rsiEURAUD				= 0;
double	_rsiGBPAUD				= 0;
datetime _lastBar				= 0;

int init()
{
	_basketRSI = GetBasketRSI(0);
	return(0);
}

int deinit()
{
	return(0);
}

int start()
{
	if (_lastBar != Time[0])
	{
		_prevBasketRSI = _basketRSI;
		_lastBar = Time[0];
	}
	
	_basketRSI = GetBasketRSI(0);
	_basketProfit = GetBasketProfit();
	
	CalculateOrdersLots();
	CloseOrders();
	OpenNextStep();

	Visualize();

	return(0);
}

double GetBasketProfit()
{
	double result = 0;
	int total = OrdersTotal();
	for (int i = 0; i < total; i++)
	{
		OrderSelect(i, SELECT_BY_POS);
		if (OrderMagicNumber() == MagicNumber)
		{
			result += OrderProfit() + OrderSwap() + OrderCommission();
		}
	}
	return (result);
}

double GetOrdersVolume(string symbol)
{
	double result = 0;
	int total = OrdersTotal();
	for (int i = 0; i < total; i++)
	{
		if (OrderSelect(i, SELECT_BY_POS)
			&& OrderMagicNumber() == MagicNumber
			&& OrderSymbol() == symbol)
		{
			result += OrderLots();
		}
	}
	return (result);
}

void CalculateOrdersLots()
{
	if (_basketProfit > 0)
	{
		if (RsiCloseLevel > 0 && _prevBasketRSI > RsiCloseLevel && _basketRSI <= RsiCloseLevel)
		{
			_currentOrdersVolume = 0;
			_nextOrdersVolume = 0;
		}
	}
	else
	{
		double drawDownLevel = MathMax(1, (MathSqrt(((- _basketProfit) / Step) * 8 + 1) - 1) / 2);
		_nextOrdersVolume = MathMax(drawDownLevel * Lot, _currentOrdersVolume);

		if (_nextOrdersVolume > _currentOrdersVolume
			&& _prevBasketRSI < RsiOpenLevel
			&& _basketRSI >= RsiOpenLevel)
		{
			_currentOrdersVolume = _nextOrdersVolume;
		}
	}
}

void OpenNextStep()
{
	if (_basketProfit > 0) return;
	OpenNextStepBySymbol("AUDUSD");
	OpenNextStepBySymbol("AUDNZD");
	OpenNextStepBySymbol("AUDCAD");
	OpenNextStepBySymbol("AUDJPY");
	OpenNextStepBySymbol("AUDCHF");
	OpenNextStepBySymbol("EURAUD");
	OpenNextStepBySymbol("GBPAUD");
}

void OpenNextStepBySymbol(string symbol)
{
	
	double ordersVolume = GetOrdersVolume(symbol);
	
	if (_currentOrdersVolume > ordersVolume)
	{
		double newOrdersVolume = MathMax(Lot, _nextOrdersVolume - ordersVolume);
		OpenOrder(symbol, newOrdersVolume);
	}
}

void OpenOrder(string symbol, double volume)
{
	double bid = MarketInfo(symbol, MODE_BID);
	double ask = MarketInfo(symbol, MODE_ASK);
	
	double stopLoss = 0;
	double takeProfit = 0;
	if (symbol == "AUDUSD" || symbol == "AUDNZD" || symbol == "AUDCAD" || symbol == "AUDJPY" || symbol == "AUDCHF")
	{
		if (StopLoss > 0) stopLoss = ask - StopLoss * Point;
		if (TakeProfit > 0) takeProfit = ask + TakeProfit * Point;
		OrderSend(symbol, OP_BUY, volume, ask, SlipPage, stopLoss, takeProfit, CommentStr, MagicNumber);
	}
	else if (symbol == "EURAUD" || symbol == "GBPAUD")
	{
		if (StopLoss > 0) stopLoss = bid + StopLoss * Point;
		if (TakeProfit > 0) takeProfit = bid - TakeProfit * Point;
		OrderSend(symbol, OP_SELL, volume, bid, SlipPage, stopLoss, takeProfit, CommentStr, MagicNumber);
	}
}

void CloseOrders()
{
	if (_basketProfit <= 0) return;

	if (_currentOrdersVolume == 0)
	{
		int ordersTotal = OrdersTotal();
	
		for (int pos = ordersTotal - 1; pos >= 0; pos--)
		{
			if (OrderSelect(pos, SELECT_BY_POS) == true
				&& OrderMagicNumber() == MagicNumber)
			{
				int orderType = OrderType();
				string orderSymbol = OrderSymbol();
				double closePrice = 0;
				if (orderType == OP_BUY) closePrice = MarketInfo(orderSymbol, MODE_BID);
				else if (orderType == OP_SELL) closePrice = MarketInfo(orderSymbol, MODE_ASK);
				OrderClose(OrderTicket(), OrderLots(), closePrice, SlipPage);
			}
		}
	}
}

double GetBasketRSI(int shift)
{
	double rsiAUDUSD = iRSI("AUDUSD", RsiTimeFrame, RsiPeriod, PRICE_CLOSE, shift);
	double rsiAUDNZD = iRSI("AUDNZD", RsiTimeFrame, RsiPeriod, PRICE_CLOSE, shift);
	double rsiAUDCAD = iRSI("AUDCAD", RsiTimeFrame, RsiPeriod, PRICE_CLOSE, shift);
	double rsiAUDJPY = iRSI("AUDJPY", RsiTimeFrame, RsiPeriod, PRICE_CLOSE, shift);
	double rsiAUDCHF = iRSI("AUDCHF", RsiTimeFrame, RsiPeriod, PRICE_CLOSE, shift);
	double rsiEURAUD = iRSI("EURAUD", RsiTimeFrame, RsiPeriod, PRICE_CLOSE, shift);
	double rsiGBPAUD = iRSI("GBPAUD", RsiTimeFrame, RsiPeriod, PRICE_CLOSE, shift);
	
	if (shift == 0)
	{
		_rsiAUDUSD = rsiAUDUSD;
		_rsiAUDNZD = rsiAUDNZD;
		_rsiAUDCAD = rsiAUDCAD;
		_rsiAUDJPY = rsiAUDJPY;
		_rsiAUDCHF = rsiAUDCHF;
		_rsiEURAUD = rsiEURAUD;
		_rsiGBPAUD = rsiGBPAUD;
	}

	return (rsiAUDUSD + rsiAUDNZD + rsiAUDCAD + rsiAUDJPY + rsiAUDCHF + (100 - rsiEURAUD) + (100 - rsiGBPAUD));
}

void Visualize()
{
	if (IsTesting() && !IsVisualMode()) return;
	
	Comment("\n AudBasked 1.0",
		"\n ----------------------------------------------------", 
		"\n Next orders volume:  ", _nextOrdersVolume,
		"\n Basket profit:     ", _basketProfit,
		"\n RSI of Basket:     ", _basketRSI,
		"\n RSI of AUDUSD:     ", _rsiAUDUSD,
		"\n RSI of AUDNZD:     ", _rsiAUDNZD,
		"\n RSI of AUDCAD:     ", _rsiAUDCAD,
		"\n RSI of AUDJPY:     ", _rsiAUDJPY,
		"\n RSI of AUDCHF:     ", _rsiAUDCHF,
		"\n RSI of EURAUD:     ", _rsiEURAUD,
		"\n RSI of GBPAUD:     ", _rsiGBPAUD,
		"\n ----------------------------------------------------");
}

