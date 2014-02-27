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
                        {nick_exist, St}
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

		
loop(St, {join,  _Channel, _Nick}) ->
        case lists:member(_Channel, St#server_st.channels) of
            false ->
                 Pid = spawn(fun() -> channel([_Nick]) end),
                 put(_Channel, Pid), 
                 {ok, St#server_st{channels = [_Channel | St#server_st.channels]}};
            true -> 
                 get(_Channel)!{join, self(), _Nick}, 
                 receive
                     ok -> 
                        {ok, St};
                     user_already_joined -> 
                        {user_already_joined, St}
                 end
                 %get(_Channel) ! {join,Ref, self(), _Nick},
                 %receive 
                     %{ok,Ref} -> 
                        %{ok, St};
                     %{user_already_joined,Ref} -> 
                        %{user_already_joined, St}
                 %end
        end;

loop(St, {leave, _Channel, _Nick}) ->
     case lists:member(_Channel, St#server_st.channels) of
     true ->
         get(_Channel) ! {leave, self(), _Nick}, 
         receive
             ok -> 
                {ok, St};
             user_not_joined -> 
                {user_not_joined, St}
         end;
     false ->
         {user_not_joined, St}
     end;

        
loop(St,{msg_from_GUI, From, _Channel, _Msg}) ->
    get(_Channel)! 
        {msg_from_GUI,
        lists:keyfind(From, 1, St#server_st.users),
          %erlang:element(2, lists:keyfind(From, 1, St#server_st.users)),
          _Channel,
          self(), _Msg, St},
    receive
        ok -> {ok, St}
    end.

channel(Nicks) -> 

    receive 
       {join, From, Nick} -> 
            case lists:member(Nick, Nicks) of
                true -> 
                    From ! user_already_joined,
                    channel(Nicks);
                false -> 
                    From ! ok,
                    channel([Nick | Nicks])
            end;

       {leave, From, Nick} ->
            case lists:member(Nick, Nicks) of
                false -> 
                    From ! user_not_joined,
                    channel(Nicks);
                true -> 
                    From ! ok,
                    channel(lists:delete(Nick, Nicks))
            end;
       {msg_from_GUI, From, _Channel, Server, _Msg, St} -> 
            lists:delete(erlang:element(2, From), Nicks),
            %[genserver:request((erlang:element(1, N)), {_Channel, From, _Msg}) || N <- Nicks],
            [genserver:request(erlang:element(1, lists:keyfind(N, 2, St#server_st.users)), {_Channel, From, _Msg}) || N <- Nicks],
            Server ! ok;
            %spawn(fun() -> send_messages(Nicks, From, _Msg, _Channel) end),
        LOL -> erlang:display(LOL)
    end.

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
