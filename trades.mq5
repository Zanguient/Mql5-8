#include <Trade\AccountInfo.mqh>
#include<Trade\SymbolInfo.mqh>
#include<Trade\Trade.mqh>

string symbol="Si-3.18";

input int MagicNumber = 3381127;
input int Volume = 1;
CTrade  trade;
int orderPrev = 0;
bool work = false;

int OnInit()
  {
//--- объект для работы со счетом
   CAccountInfo account;
   ENUM_ACCOUNT_TRADE_MODE account_type=account.TradeMode();
//--- если счет оказался реальным, прекращаем работу эксперта немедленно!

//--- выведем тип счета    
   Print("Тип счета: ",EnumToString(account_type));
   
//--- выясним, можно ли вообще торговать на данном счете
   if(account.TradeAllowed())
      Print("Торговля на данном счете разрешена");
   else
      Print("Торговля на счете запрещена: возможно, вход был совершен по инвест-паролю");
//--- выясним, разрешено ли торговать на счете с помощью эксперта
   if(account.TradeExpert())
      Print("Автоматическая торговля на счете разрешена  с помощью экспертов и скриптов");
   else
      Print("Запрещена автоматическая торговля с помощью экспертов и скриптов");
//--- допустимое количество ордеров задано или нет
//--- объект для получения свойств символа
   CSymbolInfo symbol_info;
//--- зададим имя символа, для которого будем получать информацию
   symbol_info.Name(_Symbol);
//--- получим текущие котировки и выведем
   symbol_info.RefreshRates();
   //Print(symbol_info.Name()," (",symbol_info.Description(),")","  Bid=",symbol_info.Bid(),"   Ask=",symbol_info.Ask());
//--- получим значения минимальных отступов для торговых операций
   Print("StopsLevel=",symbol_info.StopsLevel()," pips, FreezeLevel=",
         symbol_info.FreezeLevel()," pips");
//--- получим количество знаков после запятой и размер пункта
   Print("Digits=",symbol_info.Digits(),
         ", Point=",DoubleToString(symbol_info.Point(),symbol_info.Digits()));
//--- информация о спреде
   Print("SpreadFloat=",symbol_info.SpreadFloat(),", Spread(текущий)=",
         symbol_info.Spread()," pips");
//--- размер контрактов
   Print("Размер стандартного контракта: ",symbol_info.ContractSize(),
         " (",symbol_info.CurrencyBase(),")");
//--- минимальный, максимальный размеры объема в торговых операциях
   Print("Volume info: LotsMin=",symbol_info.LotsMin(),"  LotsMax=",symbol_info.LotsMax(),
         "  LotsStep=",symbol_info.LotsStep());
//--- какую функцию использовать для торговли: true - OrderSendAsync(), false - OrderSend()
   trade.SetAsyncMode(false);
   
   MarketBookAdd("Si-3.18");
   
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTrade()
  {
//---
   
  }
//+------------------------------------------------------------------+
//| BookEvent function                                               |
//+------------------------------------------------------------------+
void OnBookEvent(const string &symbol)
{
//---
   if (work == true) {     
      double buyPrice = SymbolInfoDouble(symbol,SYMBOL_BID);
      double sellPrice = SymbolInfoDouble(symbol,SYMBOL_ASK);
      
      double delta = sellPrice - buyPrice;
      bool flag = true;
      Print(delta);
      
      if (delta == 2) {
        Print(buyPrice);
        Print(sellPrice);
      }
      else if (delta <2) {
      
        while (delta != 2) {
            
          if (flag == true){
             sellPrice++;
             flag = false;
          }
          else {
             buyPrice--;
             flag = true;
          }
          delta = sellPrice - buyPrice;
      }
   }
   else {
   
     while (delta != 2) {
         
         if (flag == true){
         buyPrice++;
         flag = false;
         }
         else {
            sellPrice--;
            flag = true;
         }
         
         delta = sellPrice - buyPrice;
     }
   }
   double min = 3;
   double max = 10;
   int total=PositionsTotal(); // количество открытых позиций
   
   if ( total>min && total<max){
   
    double totalBuy = 0;
    double totalSell = 0; 
   
    for(int i=total; i>0; i--){
            
       ulong  position_ticket=PositionGetTicket(i);                                      // тикет позиции
       string position_symbol=PositionGetString(POSITION_SYMBOL);                        // символ 
       int    digits=(int)SymbolInfoInteger(position_symbol,SYMBOL_DIGITS);              // количество знаков после запятой
       ulong  magic=PositionGetInteger(POSITION_MAGIC);                                  // MagicNumber позиции
       double volume=PositionGetDouble(POSITION_VOLUME);                                 // объем позиции
       ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);    // тип позиции
                     
       if ( type == POSITION_TYPE_BUY ){
         totalBuy = totalBuy + volume;
                     
       }
       else if ( type == POSITION_TYPE_SELL ) {
                     
         totalSell = totalSell + volume;              
       }                
    }
    
    int totalOrders=OrdersTotal();
    double totalBuyLimit = 0;
    double totalSellLimit = 0;

    for(int i=totalOrders; i>0; i--)
    {
      bool  order_ticket=OrderSelect(i);   
      ENUM_ORDER_TYPE type=(ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE); 
      double volume = OrderGetDouble(ORDER_VOLUME_CURRENT);
                  
         if ( type == ORDER_TYPE_BUY_LIMIT ){             
            totalBuyLimit = totalBuy + volume;         
         }
         else if ( type == ORDER_TYPE_SELL_LIMIT ) {            
            totalSellLimit = totalSell + volume;
         }              
    }
    
    if (totalBuy == 0 && totalBuyLimit == 0 && totalSellLimit == 0) {
    
      BuyLimit(SymbolInfoDouble(symbol,SYMBOL_BID) + 1);
      SellLimit(SymbolInfoDouble(symbol,SYMBOL_ASK) - 1);
    }
    
   }
   }
}
  
void OnChartEvent(const int id, 
                  const long &lparam, 
                  const double &dparam, 
                  const string &sparam)
{
   if (id == CHARTEVENT_KEYDOWN) {
   
      if (lparam == 37 ){
         orderClose();
      }
      else if (lparam==38){
      
         BuyLimit(SymbolInfoDouble(symbol,SYMBOL_BID)+ 1);
      }
      else if (lparam==39){
      
         BuyLimit(SymbolInfoDouble(symbol,SYMBOL_BID)+ 1);
         SellLimit(SymbolInfoDouble(symbol,SYMBOL_ASK) -1);    
      }
      else if (lparam==40){
         SellLimit(SymbolInfoDouble(symbol,SYMBOL_ASK) -1);
      }
      else if (lparam==83){
         if(work==true){
            work = false;
         }
         else {
            work = true;
         }
      }
      else if (lparam==107){
         //Volume++;
         Print(Volume);
      }
      else if (lparam==109){
         //Volume--;
         Print(Volume);
      }
      Print(lparam);
   }                  
}
//+------------------------------------------------------------------+
void BuyLimit(double price) 
{
   if(!trade.BuyLimit(Volume,price))
     {
      //--- сообщим о неудаче
      Print("Метод BuyLimit() потерпел неудачу. Код возврата=",trade.ResultRetcode(),
            ". Описание кода: ",trade.ResultRetcodeDescription());
     }
   else
     {
      Print("Метод BuyLimit() выполнен успешно. Код возврата=",trade.ResultRetcode(),
            " (",trade.ResultRetcodeDescription(),")");
     }
     
    Print("BuyLimit"); 
}

void SellLimit(double price) 
{
   if(!trade.SellLimit(Volume,price))
     {
      //--- сообщим о неудаче
      Print("Метод BuyLimit() потерпел неудачу. Код возврата=",trade.ResultRetcode(),
            ". Описание кода: ",trade.ResultRetcodeDescription());
     }
   else
     {
      Print("Метод BuyLimit() выполнен успешно. Код возврата=",trade.ResultRetcode(),
            " (",trade.ResultRetcodeDescription(),")");
     }   
}

void ClosePosition() {

   MqlTradeRequest request;
   MqlTradeResult  result;
   int total=PositionsTotal(); // количество открытых позиций   
//--- перебор всех открытых позиций
   for(int i=total-1; i>=0; i--)
     {
      //--- параметры ордера
      ulong  position_ticket=PositionGetTicket(i);                                      // тикет позиции
      string position_symbol=PositionGetString(POSITION_SYMBOL);                        // символ 
      int    digits=(int)SymbolInfoInteger(position_symbol,SYMBOL_DIGITS);              // количество знаков после запятой
      ulong  magic=PositionGetInteger(POSITION_MAGIC);                                  // MagicNumber позиции
      double volume=PositionGetDouble(POSITION_VOLUME);                                 // объем позиции
      ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);    // тип позиции
      //--- вывод информации о позиции
      PrintFormat("#%I64u %s  %s  %.2f  %s [%I64d]",
                  position_ticket,
                  position_symbol,
                  EnumToString(type),
                  volume,
                  DoubleToString(PositionGetDouble(POSITION_PRICE_OPEN),digits),
                  magic);
      //--- если MagicNumber совпадает
      //if(magic==MagicNumber)
        //{

         //--- обнуление значений запроса и результата
         ZeroMemory(request);
         ZeroMemory(result);
         //--- установка параметров операции
         request.action   =TRADE_ACTION_DEAL;        // тип торговой операции
         request.position =position_ticket;          // тикет позиции
         request.symbol   =position_symbol;          // символ 
         request.volume   =volume;                   // объем позиции
         request.deviation=5;                        // допустимое отклонение от цены
         request.magic    =MagicNumber;             // MagicNumber позиции
         //--- установка цены и типа ордера в зависимости от типа позиции
         if(type==POSITION_TYPE_BUY)
           {
            request.price=SymbolInfoDouble(position_symbol,SYMBOL_BID);
            request.type =ORDER_TYPE_SELL;
           }
         else
           {
            request.price=SymbolInfoDouble(position_symbol,SYMBOL_ASK);
            request.type =ORDER_TYPE_BUY;
           }
         //--- вывод информации о закрытии
         PrintFormat("Close #%I64d %s %s",position_ticket,position_symbol,EnumToString(type));
         //--- отправка запроса
         if(!OrderSend(request,result))
            PrintFormat("OrderSend error %d",GetLastError());  // если отправить запрос не удалось, вывести код ошибки
         //--- информация об операции   
         PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
         //---
        //}
     }  
}

void orderClose()
   {
    //-- объявление и инициализация запроса и результата
    MqlTradeRequest request={0};
    MqlTradeResult  result={0};
    int total=OrdersTotal(); // количество установленных отложенных ордеров
    
    //--- перебор всех установленных отложенных ордеров
    for(int i=total-1; i>=0; i--)
      {
       ulong  order_ticket=OrderGetTicket(i);                   // тикет ордера
       ulong  magic=OrderGetInteger(ORDER_MAGIC);               // MagicNumber ордера
       //--- если MagicNumber совпадает

          //--- обнуление значений запроса и результата
          ZeroMemory(request);
          ZeroMemory(result);
          //--- установка параметров операции     
          request.action=TRADE_ACTION_REMOVE;                   // тип торговой операции
          request.order = order_ticket;                         // тикет ордера
          //--- отправка запроса
          if(!OrderSend(request,result))
             PrintFormat("OrderSend error %d",GetLastError());  // если отправить запрос не удалось, вывести код ошибки
          //--- информация об операции   
          PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
         }
      
   }