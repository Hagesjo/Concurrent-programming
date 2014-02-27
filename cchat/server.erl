-module(server).
-compile(export_all).
%-export([loop/2, initial_state/1]).

-include_lib("./defs.hrl").



loop(St, {connect, From, _Nick}) -> 
        St2 = St#server_st{users = [{From, _Nick} | St#server_st.users]},
		case lists:member({From, _Nick}, St#server_st.users) of
            false ->
                case lists:keyfind(_Nick, 2, St#server_st.users) of
                    false -> 
                        {ok, St2};
                    _ ->
                        {user_already_connected, St}
                end;
			_ ->
                {user_already_connected, St}
		end;

loop(St, {disconnect, From, _Nick}) -> 
        case lists:member({From, _Nick}, St#server_st.users) of
            true ->
                    St2 = St#server_st{users = lists:delete({From,_Nick}, St#server_st.users)},
                    {ok, St2}
        end;
		
loop(St, {join, From,  _Channel, _Nick}) ->
        case lists:member(_Channel, St#server_st.channels) of
            false ->
                 catch(unregister(list_to_atom(_Channel))),
                 genserver:start(list_to_atom(_Channel), channel:initial_state(From),
                                fun channel:loop/2),
                 {ok, St#server_st{channels = [_Channel | St#server_st.channels]}};
            true -> 
                 case genserver:request(whereis(list_to_atom(_Channel)), {join, From}) of 
                     ok -> 
                        {ok, St};
                     user_already_joined -> 
                        {user_already_joined, St}
                 end
        end;

loop(St, {leave, From, _Channel, _Nick}) ->
     case lists:member(_Channel, St#server_st.channels) of
         true ->
         case genserver:request(list_to_atom(_Channel), {leave, From}) of
             ok -> 
                {ok, St};
             user_not_joined -> 
                {user_not_joined, St}
         end;
     false ->
         {user_not_joined, St}
     end;

        
loop(St,{msg_from_GUI, From, _Channel, _Nick, _Msg}) ->
    genserver:request(whereis(list_to_atom(_Channel)), {msg_from_GUI, From,
          _Channel,
          _Nick,
           _Msg}),
    {ok,St}.

%send_messages([], _, _, _) ->
    %ok;
%send_messages([Client | Clients], From, _Msg, _Channel) ->
    %case Client of
        %From -> send_messages(Clients, From, _Msg, _Channel);
        %_ -> genserver:request(Client, {_Channel, erlang:element(2,lists:keyfind(From, 2, St#server_st.users))}),
             %send_messages(Clients, From, _Msg)
    %end.

initial_state(_Server) ->
    #server_st{name = _Server, users = [], channels=[]}.
