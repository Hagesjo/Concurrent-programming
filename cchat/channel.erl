-module(channel).
-compile(export_all).
%-export([loop/2, initial_state/1]).

-include_lib("./defs.hrl").

loop(St=#channel_st{pids = Pids}, {disconnect, From, _Nick}) ->
    case lists:member(From, Pids) of
        true -> {leave_channels_first, St};
        false -> {ok, St}
    end;

loop(St=#channel_st{pids = Pids}, {join, From}) -> 
    case lists:member(From, Pids) of
        true -> 
            {user_already_joined, St};
        false -> 
            {ok, St#channel_st{pids= [From | Pids]}}
    end;

loop(St=#channel_st{pids = Pids}, {leave, From}) ->
    case lists:member(From, Pids ) of
        false -> 
            {user_not_joined, St};
        true -> 
            {ok, St#channel_st{pids = lists:delete(From, Pids)}}
    end;

loop(St=#channel_st{pids = Pids}, {msg_from_GUI, From, _Channel, _Nick, _Msg}) -> 
    [genserver:request(F, {_Channel, _Nick, _Msg}) || F <- lists:delete(From, Pids)],
    {ok, St}.

initial_state(_Pid) -> 
   #channel_st{pids = [_Pid]}. 