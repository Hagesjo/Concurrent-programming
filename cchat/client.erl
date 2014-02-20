-module(client).
-export([loop/2, initial_state/2]).

-include_lib("./defs.hrl").

%%-record(message, {pid, data}).
%%-record(user, {nick=""}).
%%-record(state, {server}).




loop(ST) ->
	receive
%%%%%%%%%%%%%%%
%%%% Connect
%%%%%%%%%%%%%%%
	
		{Pid, {connect, _Server}} ->
			Ref = make_ref(),
			Pid ! {connect, self(), Ref , _Server},
			receive
				{Ref, ok} ->
					From ! {ok};
					ok;
					%%%%TODO%%%%%
					%Fixa catcha%
					%%%%error%%%%
			end;		
					

%%%%%%%%%%%%%%%
%%%% Disconnect
%%%%%%%%%%%%%%%
		{Pid, disconnect} ->
			Ref = make_ref(),
			Pid ! {disconnect, self(), Ref},
			receive
				{Ref, ok} ->
					From ! {ok};
					ok;
					%%%%TODO%%%%%
					%Fixa catcha%
					%%%%error%%%%
			end;

%%%%%%%%%%%%%%
%%% Join
%%%%%%%%%%%%%%
		{Pid, {join,_Channel}} ->
			Ref = make_ref(),
			Pid ! {join, self(), Ref, _Channel},
			receive
				{Ref, ok} ->
					From ! {ok};
					ok;
					%%%%TODO%%%%%
					%Fixa catcha%
					%%%%error%%%%
			end;
			
%%%%%%%%%%%%%%%
%%%% Leave
%%%%%%%%%%%%%%%
		{Pid, {leave, _Channel}} ->
			Ref = make_ref(),
			Pid ! {leave, self(), Ref, _Channel},
			receive
				{Ref, ok} ->
					From ! {ok};
					ok;
					%%%%TODO%%%%%
					%Fixa catcha%
					%%%%error%%%%
			end;

%%%%%%%%%%%%%%%%%%%%%
%%% Sending messages
%%%%%%%%%%%%%%%%%%%%%
		{Pid, {msg_from_GUI, _Channel, _Msg}} ->
			Ref = make_ref(),
			Pid ! {msg_from_GUI, self(), Ref, _Channel, _Msg},
			receive
				{Ref, ok} ->
					From ! {ok};
					ok;
					%%%%TODO%%%%%
					%Fixa catcha%
					%%%%error%%%%
			end;


%%%%%%%%%%%%%%
%%% WhoIam
%%%%%%%%%%%%%%
		{Pid, whoiam} ->
			Ref = make_ref(),
			Pid ! {whoiam, self(), Ref},
			receive
				{Ref, ok} ->
					From ! {ok};
					ok;
					%%%%TODO%%%%%
					%Fixa catcha%
					%%%%error%%%%
			end;

%%%%%%%%%%
%%% Nick
%%%%%%%%%%
		{Pid, {nick, _Nick}} ->
			Ref = make_ref(),
			Pid ! {nick, self(), Ref, _Nick},
			receive
				{Ref, ok} ->
					From ! {ok};
					ok;
					%%%%TODO%%%%%
					%Fixa catcha%
					%%%%error%%%%
			end;

%%%%%%%%%%%%%
%%% Debug
%%%%%%%%%%%%%
		{Pid, debug} ->
			Ref = make_ref(),
			{St, St}
	end.

%%%%%%%%%%%%%%%%%%%%%
%%%% Incoming message
%%%%%%%%%%%%%%%%%%%%%
loop(St = #cl_st { gui = GUIName }, _MsgFromClient) ->
    {Channel, Name, Msg} = decompose_msg(_MsgFromClient),
    gen_server:call(list_to_atom(GUIName), {msg_to_GUI, Channel, Name++"> "++Msg}),
    {ok, St}.


% This function will take a message from the client and
% decomposed in the parts needed to tell the GUI to display
% it in the right chat room.
decompose_msg(_MsgFromClient) ->
    {"", "", ""}.


initial_state(Nick, GUIName) ->
	NewUser = orddict:store(Nick,#user{nick=nick}),
    #cl_st { gui = GUIName }.
