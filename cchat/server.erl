-module(server).
-export([loop/2, initial_state/1]).

-include_lib("./defs.hrl").

%%-record(state, {server}).

loop(St) -> 
    receive
	{connect, From, Ref, _Server} ->
				

	{disconnect, From, Ref} ->
		%%%%%TODO%%%%%
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
