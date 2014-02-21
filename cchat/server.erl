-module(server).
-export([loop/2, initial_state/1]).

-include_lib("./defs.hrl").



loop(St) -> 
    receive
	{connect, From, _Nick,} ->
		St2 = St#server_st( users = [{From, _Nick} | St#server_st.users]),
		case lists:member({_, _Nick}, St#server_st.users) of
			true ->
				{nick_exist, St}
		end;
			
		case lists:member({From, _Nick}, St#server_st.users) of
			true ->
				{user_already_connected, St};
			false -> 
				{ok, St2}
		end;
	{disconnect, From, _Nick} ->
		case lists:member({From, _Nick}, St#server_st.users) of
			true ->
				case St#cl_st.channels == Empty
					true ->
						St2 = St#server_st(users = lists:delete({From, _Nick}, St#server_st.users)),
						{ok, St2};
					false ->
						{leave_channels_first, St}
				end;
			false ->
				{user_not_connected, St}
		end;

		
	{join, From, Ref, _Channel} ->
		%%%%%TODO%%%%%
	{leave, From, Ref, _Channel} ->
		%%%%%TODO%%%%%
	{msg_from_GUI, From, Ref, _Channel, _Msg} ->
		%%%%%TODO%%%%%
	{nick, From, Ref, _Nick} ->
		%%%%%TODO%%%%%
initial_state(_Server) ->
    #server_st{}.
