-module(calling).

-export([people/2,forSendMessages/5,writeMessage/1]).

forSendMessages(Max,Min,_,_,_) when Min > Max -> ok;
forSendMessages(Max,Min,Receivers,NameToPidMap,Name) when Max >= Min ->
  ReceiverName = lists:nth(Min, Receivers),
  ReciverPid = maps:get(ReceiverName,NameToPidMap),
  {A,B,C}=now(),
  random:seed(A,B,C),
  SleepTime = random:uniform(100),
  timer:sleep(SleepTime),
  ReciverPid ! {request, self(), Name},
  forSendMessages(Max,Min+1,Receivers,NameToPidMap,Name).

people(Name,MasterPid) ->
  receive
    {initiate,Receivers,NameToPidMap} ->
      forSendMessages(length(Receivers),1,Receivers, NameToPidMap,Name),
      people(Name,MasterPid);
    {request, SenderId,SenderName} ->
      Time = element(3,now()),
      MasterPid ! {message, SenderName, Name,intro,Time},
      {A,B,C}=now(),
      random:seed(A,B,C),
      SleepTime = random:uniform(100),
      timer:sleep(SleepTime),
      SenderId ! {response,Name,Time},
      people(Name,MasterPid);
    {response, SenderName, Time} ->
      MasterPid ! {message, SenderName, Name,reply,Time},
      people(Name,MasterPid)
  after 1000 ->
    writeMessage(Name)
  end.

writeMessage(Name) ->
  io:fwrite("Process ~p has received no calls for 1 second, ending...~n",[Name]).