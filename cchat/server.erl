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
            false -> {ok, St#server_st{channels = [_Channel | St#server_st.channels]}};
            %nedan är fel
            true -> {user_already_connected, St}
        end;
		%%%%%%TODO: ALLT%%%%%
loop(St, {leave, From, _Channel, _Nick}) ->
		%%%%%%TODO: ALLT%%%%%
    {ok, St}.
		%%%%%%TODO%%%%%
	%{msg_from_GUI, From, Ref, _Channel, _Msg} ->
		%%%%%%TODO%%%%%
initial_state(_Server) ->
    #server_st{name = _Server, users = [], nicks = [], channels=[]}.
