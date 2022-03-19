//+------------------------------------------------------------------+
//|                                               PinbarDetector.mq5 |
//|                             Copyright © 2011-2022, EarnForex.com |
//|                                       https://www.earnforex.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011-2022, EarnForex"
#property link      "https://www.earnforex.com/metatrader-indicators/Pinbar-Detector/"
#property version   "1.03"

#property description "Pinbar Detector - detects Pinbars on charts."
#property description "Fully modifiable parameters of Pinbar pattern."
#property description "Usage instructions:"
#property description "https://www.earnforex.com/forex-strategy/pinbar-trading-system/"

#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   1
#property indicator_type1   DRAW_COLOR_ARROW
#property indicator_color1  clrLime, clrRed
#property indicator_width1  2

input int  CountBars = 0; // CountBars - number of bars to count on, 0 = all.
input int  DisplayDistance = 5; // DisplayDistance - the higher it is the the distance from faces to candles.
input bool UseAlerts = true; // Use Alerts
input bool UseEmailAlerts = false; // Use Email Alerts (configure SMTP parameters in Tools->Options->Emails)
input bool UseNotificationAlerts = false; // Use Notification Alerts (configure push-notifications in Tools->Options->Notifications)
input bool UseCustomSettings = false; // Use Custom Settings - if true = use below parameters:
input double CustomMaxNoseBodySize = 0.33; // Max. Body / Candle length ratio of the Nose Bar
input double CustomNoseBodyPosition = 0.4; // Body position in Nose Bar (e.g. top/bottom 40%)
input bool   CustomLeftEyeOppositeDirection = true; // true = Direction of Left Eye Bar should be opposite to pattern (bearish bar for bullish Pinbar pattern and vice versa)
input bool   CustomNoseSameDirection = false; // true = Direction of Nose Bar should be the same as of pattern (bullish bar for bullish Pinbar pattern and vice versa)
input bool   CustomNoseBodyInsideLeftEyeBody = false; // true = Nose Body should be contained inside Left Eye Body
input double CustomLeftEyeMinBodySize = 0.1; // Min. Body / Candle length ratio of the Left Eye Bar
input double CustomNoseProtruding = 0.5; // Minimum protrusion of Nose Bar compared to Nose Bar length
input double CustomNoseBodyToLeftEyeBody = 1; // Maximum relative size of the Nose Bar Body to Left Eye Bar Body
input double CustomNoseLengthToLeftEyeLength = 0; // Minimum relative size of the Nose Bar Length to Left Eye Bar Length
input double CustomLeftEyeDepth = 0.1; // Minimum relative depth of the Left Eye to its length; depth is difference with Nose's back
input int    CustomMinimumNoseLength = 1; // Minimum nose candlestick length in points

// Indicator buffers
double UpDown[];
double Color[];

// Global variables
int    LastBars = 0;
double MaxNoseBodySize = 0.33;
double NoseBodyPosition = 0.4;
bool   LeftEyeOppositeDirection = true;
bool   NoseSameDirection = false;
bool   NoseBodyInsideLeftEyeBody = false;
double LeftEyeMinBodySize = 0.1;
double NoseProtruding = 0.5;
double NoseBodyToLeftEyeBody = 1;
double NoseLengthToLeftEyeLength = 0;
double LeftEyeDepth = 0.1;
int    MinimumCandlestickLength = 1;

void OnInit()
{
    SetIndexBuffer(0, UpDown, INDICATOR_DATA);
    SetIndexBuffer(1, Color, INDICATOR_COLOR_INDEX);
    ArraySetAsSeries(UpDown, true);
    ArraySetAsSeries(Color, true);

    PlotIndexSetInteger(0, PLOT_ARROW, 74);
    PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, EMPTY_VALUE);
    PlotIndexSetString(0, PLOT_LABEL, "Pinbar");

    if (UseCustomSettings)
    {
        MaxNoseBodySize = CustomMaxNoseBodySize;
        NoseBodyPosition = CustomNoseBodyPosition;
        LeftEyeOppositeDirection = CustomLeftEyeOppositeDirection;
        NoseSameDirection = CustomNoseSameDirection;
        LeftEyeMinBodySize = CustomLeftEyeMinBodySize;
        NoseProtruding = CustomNoseProtruding;
        NoseBodyToLeftEyeBody = CustomNoseBodyToLeftEyeBody;
        NoseLengthToLeftEyeLength = CustomNoseLengthToLeftEyeLength;
        LeftEyeDepth = CustomLeftEyeDepth;
        MinimumCandlestickLength = CustomMinimumNoseLength;
    }
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &Open[],
                const double &High[],
                const double &Low[],
                const double &Close[],
                const long &tickvolume[],
                const long &volume[],
                const int &spread[])
{
    int NeedBarsCounted;
    double NoseLength, NoseBody, LeftEyeBody, LeftEyeLength;

    ArraySetAsSeries(Open, true);
    ArraySetAsSeries(High, true);
    ArraySetAsSeries(Low, true);
    ArraySetAsSeries(Close, true);

    if (LastBars == rates_total) return rates_total;
    NeedBarsCounted = rates_total - LastBars;
    if ((CountBars > 0) && (NeedBarsCounted > CountBars)) NeedBarsCounted = CountBars;
    LastBars = rates_total;
    if (NeedBarsCounted == rates_total) NeedBarsCounted--;

    UpDown[0] = EMPTY_VALUE;

    for (int i = NeedBarsCounted; i >= 1; i--)
    {
        // Prevents bogus indicator arrows from appearing (looks like PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, EMPTY_VALUE); is not enough.)
        UpDown[i] = EMPTY_VALUE;

        // Won't have Left Eye for the left-most bar.
        if (i == rates_total - 1) continue;

        // Left Eye and Nose bars' parameters.
        NoseLength = High[i] - Low[i];
        if (NoseLength < MinimumCandlestickLength * _Point) continue; // Nose candlestick too short.
        if (NoseLength == 0) NoseLength = _Point;
        LeftEyeLength = High[i + 1] - Low[i + 1];
        if (LeftEyeLength == 0) LeftEyeLength = _Point;
        NoseBody = MathAbs(Open[i] - Close[i]);
        if (NoseBody == 0) NoseBody = _Point;
        LeftEyeBody = MathAbs(Open[i + 1] - Close[i + 1]);
        if (LeftEyeBody == 0) LeftEyeBody = _Point;

        // Bearish Pinbar
        if (High[i] - High[i + 1] >= NoseLength * NoseProtruding) // Nose protrusion
        {
            if (NoseBody / NoseLength <= MaxNoseBodySize) // Nose body to candle length ratio
            {
                if (1 - (High[i] - MathMax(Open[i], Close[i])) / NoseLength < NoseBodyPosition) // Nose body position in bottom part of the bar
                {
                    if ((!LeftEyeOppositeDirection) || (Close[i + 1] > Open[i + 1])) // Left Eye bullish if required
                    {
                        if ((!NoseSameDirection) || (Close[i] < Open[i])) // Nose bearish if required
                        {
                            if (LeftEyeBody / LeftEyeLength  >= LeftEyeMinBodySize) // Left eye body to candle length ratio
                            {
                                if ((MathMax(Open[i], Close[i]) <= High[i + 1]) && (MathMin(Open[i], Close[i]) >= Low[i + 1])) // Nose body inside Left Eye bar
                                {
                                    if (NoseBody / LeftEyeBody <= NoseBodyToLeftEyeBody) // Nose body to Left Eye body ratio
                                    {
                                        if (NoseLength / LeftEyeLength >= NoseLengthToLeftEyeLength) // Nose length to Left Eye length ratio
                                        {
                                            if (Low[i] - Low[i + 1] >= LeftEyeLength * LeftEyeDepth)  // Left Eye low is low enough
                                            {
                                                if ((!NoseBodyInsideLeftEyeBody) || ((MathMax(Open[i], Close[i]) <= MathMax(Open[i + 1], Close[i + 1])) && (MathMin(Open[i], Close[i]) >= MathMin(Open[i + 1], Close[i + 1])))) // Nose body inside Left Eye body if required
                                                {
                                                    UpDown[i] = High[i] + DisplayDistance * _Point + NoseLength / 5;
                                                    Color[i] = 1;
                                                    if (i == 1) SendAlert("Bearish"); // Send alerts only for the latest fully formed bar
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Bullish Pinbar
        if (Low[i + 1] - Low[i] >= NoseLength * NoseProtruding) // Nose protrusion
        {
            if (NoseBody / NoseLength <= MaxNoseBodySize) // Nose body to candle length ratio
            {
                if (1 - (MathMin(Open[i], Close[i]) - Low[i]) / NoseLength < NoseBodyPosition) // Nose body position in top part of the bar
                {
                    if ((!LeftEyeOppositeDirection) || (Close[i + 1] < Open[i + 1])) // Left Eye bearish if required
                    {
                        if ((!NoseSameDirection) || (Close[i] > Open[i])) // Nose bullish if required
                        {
                            if (LeftEyeBody / LeftEyeLength >= LeftEyeMinBodySize) // Left eye body to candle length ratio
                            {
                                if ((MathMax(Open[i], Close[i]) <= High[i + 1]) && (MathMin(Open[i], Close[i]) >= Low[i + 1])) // Nose body inside Left Eye bar
                                {
                                    if (NoseBody / LeftEyeBody <= NoseBodyToLeftEyeBody) // Nose body to Left Eye body ratio
                                    {
                                        if (NoseLength / LeftEyeLength >= NoseLengthToLeftEyeLength) // Nose length to Left Eye length ratio
                                        {
                                            if (High[i + 1] - High[i] >= LeftEyeLength * LeftEyeDepth) // Left Eye high is high enough
                                            {
                                                if ((!NoseBodyInsideLeftEyeBody) || ((MathMax(Open[i], Close[i]) <= MathMax(Open[i + 1], Close[i + 1])) && (MathMin(Open[i], Close[i]) >= MathMin(Open[i + 1], Close[i + 1])))) // Nose body inside Left Eye body if required
                                                {
                                                    UpDown[i] = Low[i] - DisplayDistance * _Point - NoseLength / 5;
                                                    Color[i] = 0;
                                                    if (i == 1) SendAlert("Bullish"); // Send alerts only for the latest fully formed bar
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    return rates_total;
}

string TimeframeToString(ENUM_TIMEFRAMES P)
{
    return StringSubstr(EnumToString(P), 7);
}

void SendAlert(string dir)
{
    string per = TimeframeToString(_Period);
    if (UseAlerts)
    {
        Alert(dir + " Pinbar on ", _Symbol, " @ ", per);
        PlaySound("alert.wav");
    }
    if (UseEmailAlerts)
        SendMail(_Symbol + " @ " + per + " - " + dir + " Pinbar", dir + " Pinbar on " + _Symbol + " @ " + per + " as of " + TimeToString(TimeCurrent()));
    if (UseNotificationAlerts)
        SendNotification(dir + " Pinbar on " + _Symbol + " @ " + per + " as of " + TimeToString(TimeCurrent()));
}
//+------------------------------------------------------------------+