-module(server).
-compile(export_all).
%-export([loop/2, initial_state/1]).

-include_lib("./defs.hrl").



loop(St, {connect, From, _Nick}) -> 
        St2 = St#server_st{users = [{From, _Nick} | St#server_st.users]},
		case lists:keyfind(From, 1, St#server_st.users) of
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
                    St2 = St#server_st{users = lists:delete({From, _Nick}, St#server_st.users)},
                    {ok, St2}
        end;

		
loop(St, {join, From, _Channel, _Nick}) ->
        Ref = make_ref(),
        case lists:member(_Channel, St#server_st.channels) of
            false ->
                 Pid = spawn(fun() -> channel([_Nick]) end),
                 Pid ! {join, self(),  _Nick},
                 put(_Channel, Pid), 
                 {ok, St#server_st{channels = [_Channel | St#server_st.channels]}};
            true -> 
                 get(_Channel) ! {join, From, Ref, _Nick},
                 receive 
                     {ok,Ref} -> 
                        {ok, St};
                     {user_already_joined,Ref} -> 
                        {user_already_joined, St}
                 end
        end;

loop(St, {leave, From, _Channel, _Nick}) ->
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

        
loop(St,{msg_from_GUI, From, Nick, _Channel, _Msg}) ->
    get(_Channel) ! {msg_from_GUI, Nick, From, _Msg},
    {ok, St}.

channel(Nicks) -> 
    receive 
       {join, From, Ref, Nick} -> 
            case lists:member(Nick, Nicks) of
                true -> 
                    From ! {user_already_joined, Ref},
                    channel(Nicks);
                false -> 
                    From ! {ok, Ref},
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

        {msg_from_GUI, Nick, From, _Msg} -> 
           SendTo = lists:delete(Nick, Nicks),
           [genserver:request(From, {self(), N, _Msg}) || N <- SendTo]
    end.

initial_state(_Server) ->
    #server_st{name = _Server, users = [], channels=[]}.
