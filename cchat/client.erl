-module(client).
-export([loop/2, initial_state/2]).

-include_lib("./defs.hrl").






loop(St) ->
	receive
%%%%%%%%%%%%%%%
%%%% Connect
%%%%%%%%%%%%%%%
		{St, {connect, _Server}} ->
			Ref = genserver:request(list_to_atom(_Server), connect, self(), St#cl_st.nick), 
			case Ref of
				ok ->
					St2 = St#cl_st(servers = [_Server | St#cl_st.servers]),
					{St2, ok};
				nick_exist ->
					{{error, nick_exist, "Nick exist"}, St};			
				user_already_connected ->
					{{error, user_already_connected, "User already connected"},St};
				server_not_reached ->
					{{error, server_not_reached, "Server not reaced"},St}
			end;		
					

%%%%%%%%%%%%%%%
%%%% Disconnect
%%%%%%%%%%%%%%%
		{St, disconnect} ->
			Ref = genserver:request(disconnect, self(), St#cl_st.nick)
			
			case Ref of
				ok ->
					St2 = St#cl_st( servers = lists:delete(_Nick, St#server_st.users)), 
					{St2, ok};
				user_not_connected ->
					{{error, user_not_connected, "User not connected"}, St};
				leave_channels_first ->
					{{error, leave_channels_first, "Leave all channels first"}, St}
				
			end;

%%%%%%%%%%%%%%
%%% Join
%%%%%%%%%%%%%%
		{St, {join,_Channel}} ->
			Ref = make_ref(),
			Pid ! {join, self(), Ref, _Channel},
			receive
				{Ref, ok} ->
					From ! {ok},
					ok
					%%%%TODO%%%%%
					%Fixa catcha%
					%%%%error%%%%
			end;
			
%%%%%%%%%%%%%%%
%%%% Leave
%%%%%%%%%%%%%%%
		{St, {leave, _Channel}} ->
			Ref = make_ref(),
			Pid ! {leave, self(), Ref, _Channel},
			receive
				{Ref, ok} ->
					From ! {ok},
					ok
					%%%%TODO%%%%%
					%Fixa catcha%
					%%%%error%%%%
			end;

%%%%%%%%%%%%%%%%%%%%%
%%% Sending messages
%%%%%%%%%%%%%%%%%%%%%
		{St, {msg_from_GUI, _Channel, _Msg}} ->
			Ref = make_ref(),
			Pid ! {msg_from_GUI, self(), Ref, _Channel, _Msg},
			receive
				{Ref, ok} ->
					From ! {ok},
					ok
					%%%%TODO%%%%%
					%Fixa catcha%
					%%%%error%%%%
			end;


%%%%%%%%%%%%%%
%%% WhoIam
%%%%%%%%%%%%%%
		{St, whoiam} ->
			Ref = make_ref(),
			Pid ! {whoiam, self(), Ref},
			receive
				{Ref, ok} ->
					From ! {ok},
					ok
					%%%%TODO%%%%%
					%Fixa catcha%
					%%%%error%%%%
			end;

%%%%%%%%%%
%%% Nick
%%%%%%%%%%
		{St, {nick, _Nick}} ->
			Ref = make_ref(),
			Pid ! {nick, self(), Ref, _Nick},
			receive
				{Ref, ok} ->
					From ! {ok},
					ok
					%%%%TODO%%%%%
					%Fixa catcha%
					%%%%error%%%%
			end;

%%%%%%%%%%%%%
%%% Debug
%%%%%%%%%%%%%
		{St, debug} ->
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
    #cl_st { gui = GUIName }.
