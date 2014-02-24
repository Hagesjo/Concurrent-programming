-module(client).
%-export([loop/2, initial_state/2]).
-compile(export_all).

-include_lib("./defs.hrl").






%%%%%%%%%%%%%%%
%%%% Connect
%%%%%%%%%%%%%%%
loop(St, {connect, _Server}) ->
			Ref = genserver:request(list_to_atom(_Server), {connect, self(), St#cl_st.nick}), 
			case Ref of
				ok ->
					{ok, St#cl_st{server = _Server}};
				nick_exist ->
					{{error, nick_exist, "Nick exist"}, St};			
				user_already_connected ->
					{{error, user_already_connected, "User already connected"},St};
				server_not_reached ->
					{{error, server_not_reached, "Server not reached"},St}
			end;		
					

%%%%%%%%%%%%%%%
%%%% Disconnect
%%%%%%%%%%%%%%%
loop(St, disconnect) ->
	Ref = genserver:request(St#cl_st.server, {disconnect, self(), St#cl_st.nick}),
	case Ref of
		ok ->
			St2 = St#cl_st{server = []},
			{ok,St2 };
		user_not_connected ->
			{{error, user_not_connected, "User not connected"}, St};
		leave_channels_first ->
			{{error, leave_channels_first, "Leave all channels first"}, St}
    end;
        

%%%%%%%%%%%%%%
%%% Join
%%%%%%%%%%%%%%
%		{St, {join,_Channel}} ->

			
%%%%%%%%%%%%%%%
%%%% Leave
%%%%%%%%%%%%%%%
%		{St, {leave, _Channel}} ->
	
%%%%%%%%%%%%%%%%%%%%%
%%% Sending messages
%%%%%%%%%%%%%%%%%%%%%
%		{St, {msg_from_GUI, _Channel, _Msg}} ->



%%%%%%%%%%%%%%
%%% WhoIam
%%%%%%%%%%%%%%
%		{St, whoiam} ->


%%%%%%%%%%
%%% Nick
%%%%%%%%%%
%		{St, {nick, _Nick}} ->


%%%%%%%%%%%%%
%%% Debug
%%%%%%%%%%%%%
%		{St, debug} ->

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
