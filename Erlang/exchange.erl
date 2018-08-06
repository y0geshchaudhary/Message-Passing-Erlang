%%%-------------------------------------------------------------------
%%% @author Naresh
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 08. Jun 2018 8:01 AM
%%%-------------------------------------------------------------------
-module(exchange).
-import(calling,[people/2]).

%% API
-export([start/0,forToPrintIntro/3,master/1,forToStartThreads/5,forToConverse/4]).

start() ->
  FileData = file:consult("calls.txt"),
  SenRecData = element(2,FileData),
  Pid = spawn(exchange, master,[SenRecData]),
  Pid ! {data,"start"}.

forToPrintIntro(Max,Min,_) when Min > Max -> ok;
forToPrintIntro(Max,Min,SenRecData) when Max >= Min ->
  Row = lists:nth(Min, SenRecData),
  Sender = element(1, Row),
  Receivers = element(2,Row),
  io:fwrite("~p: ~p~n", [Sender,Receivers]),
  forToPrintIntro(Max,Min+1, SenRecData).

forToStartThreads(Max,Min,_,TempMap,_) when Min > Max -> TempMap;
forToStartThreads(Max,Min,SenRecData,TempMap,MasterPid) when Min =< Max ->
    Row = lists:nth(Min, SenRecData),
    Sender = element(1, Row),
    %io:format("~p~n", [Sender]),
    Pid = spawn(calling, people, [Sender,MasterPid]),
    UpdatedMap = maps:put(Sender,Pid,TempMap),
    forToStartThreads(Max,Min+1,SenRecData,UpdatedMap,MasterPid).

forToConverse(Max,Min,_,_) when Min > Max -> ok;
forToConverse(Max,Min,SenRecData,NameToPidMap) when Min =< Max ->
  Row = lists:nth(Min, SenRecData),
  Sender = element(1, Row),
  Receivers = element(2,Row),
  Pid = maps:get(Sender,NameToPidMap),
  Pid ! {initiate,Receivers,NameToPidMap},
  forToConverse(Max,Min+1,SenRecData,NameToPidMap).


master(SenRecData) ->
  receive
    {data,"start"} ->
      io:format("** Calls to be made **~n",[]),
      forToPrintIntro(length(SenRecData),1, SenRecData),
      NameToPidMap = forToStartThreads(length(SenRecData),1, SenRecData,#{},self()),
      forToConverse(length(SenRecData),1,SenRecData,NameToPidMap),
      master(SenRecData);
    {message,SenName, RecName, MessageType, Time} ->
      io:format("~w received ~w message from ~w [~w]~n",[RecName,MessageType,SenName,Time]),
      master(SenRecData)
  after 1500 ->
    io:fwrite("Master has received no replies for 1.5 seconds, ending...~n")
  end.


