-module(hotload).
-export([server/1, upgrade/1]).


server(State) ->
	receive
		update ->
			NewState = ?MODULE:upgrade(State),
			?MODULE:server(NewState);
		SomeMessage ->
			server(State)
	end.

upgrade(OldState) ->

start() ->
	register(?MODULE, Pid=spawn(?MODULE, init, [])),
	Pid.

start_link ->
	register(?MODULE, Pid=spawn(?MODULE, init, [])),
	Pid.

terminate() ->
	?MODULE ! shutdown
