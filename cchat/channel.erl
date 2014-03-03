-module(channel).
-compile(export_all).

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
    spawn(fun() -> send_messages(Pids, From, _Nick, _Msg, _Channel) end),
    {ok, St}.


send_messages([], _, _, _, _) ->
    ok;
send_messages([Client | Clients], From, _Nick, _Msg, _Channel) ->
    case Client of
        From -> send_messages(Clients, From, _Nick, _Msg, _Channel);
        _ -> genserver:request(Client, {_Channel, _Nick, _Msg}),
             send_messages(Clients, From, _Nick, _Msg, _Channel)
    end.

initial_state(_Pid) -> 
   #channel_st{pids = [_Pid]}. 
