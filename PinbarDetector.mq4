//+------------------------------------------------------------------+
//|                                               PinbarDetector.mq4 |
//|                             Copyright © 2011-2022, EarnForex.com |
//|                                       https://www.earnforex.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011-2022, EarnForex"
#property link      "https://www.earnforex.com/metatrader-indicators/Pinbar-Detector/"
#property version   "1.03"
#property strict

#property description "Pinbar Detector - detects Pinbars on charts."
#property description "Fully modifiable parameters of Pinbar pattern."
#property description "Usage instructions:"
#property description "https://www.earnforex.com/forex-strategy/pinbar-trading-system/"

#property indicator_chart_window
#property indicator_buffers 2
#property indicator_color1 clrRed
#property indicator_width1 2
#property indicator_color2 clrLime
#property indicator_width2 2

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
double Down[];
double Up[];

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
double LeftEyeDepth = 0.2;
int    MinimumCandlestickLength = 1;

void OnInit()
{
    SetIndexBuffer(0, Down);
    SetIndexBuffer(1, Up);

    SetIndexStyle(0, DRAW_ARROW);
    SetIndexArrow(0, 74);
    SetIndexStyle(1, DRAW_ARROW);
    SetIndexArrow(1, 74);

    SetIndexEmptyValue(0, EMPTY_VALUE);
    SetIndexEmptyValue(1, EMPTY_VALUE);

    SetIndexLabel(0, "Bearish Pinbar");
    SetIndexLabel(1, "Bullish Pinbar");

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
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
    int NeedBarsCounted;
    double NoseLength, NoseBody, LeftEyeBody, LeftEyeLength;

    if (LastBars == Bars) return 0;
    NeedBarsCounted = Bars - LastBars;
    if ((CountBars > 0) && (NeedBarsCounted > CountBars)) NeedBarsCounted = CountBars;
    LastBars = Bars;
    if (NeedBarsCounted == Bars) NeedBarsCounted--;

    for (int i = NeedBarsCounted; i >= 1; i--)
    {
        // Won't have Left Eye for the left-most bar.
        if (i == Bars - 1) continue;

        // Left Eye and Nose bars' parameters.
        NoseLength = High[i] - Low[i];
        if (NoseLength < MinimumCandlestickLength * Point) continue; // Nose candlestick too short.
        if (NoseLength == 0) NoseLength = Point;
        LeftEyeLength = High[i + 1] - Low[i + 1];
        if (LeftEyeLength == 0) LeftEyeLength = Point;
        NoseBody = MathAbs(Open[i] - Close[i]);
        if (NoseBody == 0) NoseBody = Point;
        LeftEyeBody = MathAbs(Open[i + 1] - Close[i + 1]);
        if (LeftEyeBody == 0) LeftEyeBody = Point;

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
                                                    Down[i] = High[i] + DisplayDistance * Point + NoseLength / 5;
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
                                                    Up[i] = Low[i] - DisplayDistance * Point - NoseLength / 5;
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
    string per = TimeframeToString((ENUM_TIMEFRAMES)Period());
    if (UseAlerts)
    {
        Alert(dir + " Pinbar on ", Symbol(), " @ ", per);
        PlaySound("alert.wav");
    }
    if (UseEmailAlerts)
        SendMail(Symbol() + " @ " + per + " - " + dir + " Pinbar", dir + " Pinbar on " + Symbol() + " @ " + per + " as of " + TimeToString(TimeCurrent()));
    if (UseNotificationAlerts)
        SendNotification(dir + " Pinbar on " + Symbol() + " @ " + per + " as of " + TimeToString(TimeCurrent()));
}
//+------------------------------------------------------------------+