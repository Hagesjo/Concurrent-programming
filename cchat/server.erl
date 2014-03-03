-module(server).
-compile(export_all).

-include_lib("./defs.hrl").


loop(St=#server_st{users = Users}, {connect, From, _Nick}) -> 
    case lists:keyfind(_Nick, 2, Users) of
        false -> 
            St2 = St#server_st{users = [{From, _Nick} | Users]},
            {ok, St2};
        _ ->
            {user_already_connected, St}
    end;

loop(St=#server_st{users = Users}, {disconnect, From, _Nick}) -> 
    case lists:member({From, _Nick}, Users) of
        true ->
                St2 = St#server_st{users = lists:delete({From,_Nick}, Users)},
                {ok, St2}
    end;
		
loop(St=#server_st{channels = Channels}, {join, From,  _Channel, _Nick}) ->
    case lists:member(_Channel, Channels) of
        false ->
             catch(unregister(list_to_atom(_Channel))),
             genserver:start(list_to_atom(_Channel), channel:initial_state(From),
                            fun channel:loop/2),
             {ok, St#server_st{channels = [_Channel | Channels]}};
        true -> 
             {genserver:request(whereis(list_to_atom(_Channel)), {join, From}), St}
    end;

loop(St=#server_st{channels = Channels}, {leave, From, _Channel, _Nick}) ->
     case lists:member(_Channel, Channels) of
         true ->
             {genserver:request(list_to_atom(_Channel), {leave, From}), St};
         false ->
             {user_not_joined, St}
     end;

        
loop(St,{msg_from_GUI, From, _Channel, _Nick, _Msg}) ->
    genserver:request(whereis(list_to_atom(_Channel)), {msg_from_GUI, From,
          _Channel,
          _Nick,
           _Msg}),
    {ok,St}.

initial_state(_Server) ->
    #server_st{name = _Server, users = [], channels=[]}.
