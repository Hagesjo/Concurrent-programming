-module(server).
-compile(export_all).
%-export([loop/2, initial_state/1]).

-include_lib("./defs.hrl").



loop(St, {connect, From, _Nick}) -> 
        St2 = St#server_st{users = [From | St#server_st.users], nick = [_Nick | St#server_st.nick]},
		case lists:member(From, St#server_st.users) of
			true ->
                {user_already_connected, St};
            false ->
                case lists:member( _Nick, St#server_st.nick) of
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
                                        nick = lists:delete(_Nick,St#server_st.nick)},
                    {ok, St2}
        end.

		
	%{join, From, Ref, _Channel} ->
		%%%%%%TODO%%%%%
	%{leave, From, Ref, _Channel} ->
		%%%%%%TODO%%%%%
	%{msg_from_GUI, From, Ref, _Channel, _Msg} ->
		%%%%%%TODO%%%%%
	%{nick, From, Ref, _Nick} ->
		%%%%%%TODO%%%%%
initial_state(_Server) ->
    #server_st{name = _Server, users = [], nick = [], channels=[]}.
