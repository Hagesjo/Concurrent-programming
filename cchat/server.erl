-module(server).
-compile(export_all).
%-export([loop/2, initial_state/1]).

-include_lib("./defs.hrl").



loop(St, {connect, From, _Nick}) -> 
        St2 = St#server_st{users = [From | St#server_st.users], nicks = [_Nick | St#server_st.nicks]},
		case lists:member(From, St#server_st.users) of
			true ->
                {user_already_connected, St};
            false ->
                case lists:member( _Nick, St#server_st.nicks) of
                    true ->
                        {nick_exist, St};
                    false -> 
                        erlang:display(St2),
                        {ok, St2}
                end
		end;

loop(St, {disconnect, From, _Nick}) -> 
        case lists:member(From, St#server_st.users) of
            true ->
                    St2 = St#server_st{users = lists:delete(From, St#server_st.users),
                                        nicks = lists:delete(_Nick,St#server_st.nicks)},
                    {ok, St2}
        end;

		
loop(St, {join, From, _Channel, _Nick}) ->
        case lists:member(_Channel, St#server_st.channels) of
            false ->
                 io:format("~n~n~n~n~nFALSE",[]),
                 Pid = spawn(fun() -> channel([_Nick]) end),
                 Pid ! {join, self(),  _Nick},
                 put(_Channel, Pid), 
                 {ok, St#server_st{channels = [_Channel | St#server_st.channels]}};
            true -> 
                 Ref = make_ref(),
                 get(_Channel) ! {join,Ref, self(), _Nick},
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

        
loop(St,{msg_from_GUI, From, Ref, _Channel, _Msg}) ->
    {ok, St}.
		%%%%%%TODO%%%%%

channel(Nicks) -> 
    receive 
       {join, Ref, From, Nick} -> 
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
            end
    end.

initial_state(_Server) ->
    #server_st{name = _Server, users = [], nicks = [], channels=[]}.
