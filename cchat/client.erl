-module(client).
%-export([loop/2, initial_state/2]).
-compile(export_all).

-include_lib("./defs.hrl").


%%%%%%%%%%%%%%%
%%%% Connect
%%%%%%%%%%%%%%%
loop(St, {connect, _Server}) ->
    case whereis(list_to_atom(_Server)) of
        undefined -> {{error,server_not_reached, "Server not reached"}, St};
        _ ->
            case genserver:request(list_to_atom(_Server), {connect, self(), St#cl_st.nick}) of
                ok ->
                    {ok, St#cl_st{server = _Server}};
                nick_exist ->
                    {{error, nick_exist, "Nick exist"}, St};			
                user_already_connected ->
                    {{error, user_already_connected, "User already connected"},St};
                server_not_reached ->
                    {{error, server_not_reached, "Server not reached"},St}
            end		
        end;
					

%%%%%%%%%%%%%%%
%%%% Disconnect
%%%%%%%%%%%%%%%
loop(St, disconnect) ->
    case St#cl_st.server of
        [] ->  
            {{error, user_not_connected, "User not connected"}, St};
        _ ->  
            case genserver:request(list_to_atom(St#cl_st.server),
                                     {disconnect,
                                      self(),
                                       St#cl_st.nick}) of
            ok ->
                St2 = St#cl_st{server = []},
                {ok,St2 };
            leave_channels_first ->
                {{error, leave_channels_first, "Leave all channels first"}, St}
        end
   end;
        
        

%%%%%%%%%%%%%%
%%% Join
%%%%%%%%%%%%%%
loop(St, {join,_Channel}) ->
    case St#cl_st.server of
    [] ->
        {{error, user_not_connected, "User not connected"}, St};
    _  -> 
        case genserver:request(list_to_atom(St#cl_st.server),
                                           {join, self(), _Channel, St#cl_st.nick}) of
            user_already_joined -> {{error, user_already_joined, "You are already connected to that channel!"}, St};
            _    -> {ok, St#cl_st{channels = [_Channel | St#cl_st.channels]}}
        end
    end;

			
%%%%%%%%%%%%%%%
%%%% Leave
%%%%%%%%%%%%%%%
loop(St, {leave,_Channel}) ->
        case genserver:request(list_to_atom(St#cl_st.server),
                                           {leave, self(), _Channel, St#cl_st.nick}) of
        ok ->  {ok, St#cl_st{channels = lists:delete(_Channel,St#cl_st.channels)}};
        _ -> {{error, user_not_joined, "You are not in that channel!"}, St}
    end;
	
%%%%%%%%%%%%%%%%%%%%%
%%% Sending messages
%%%%%%%%%%%%%%%%%%%%%
loop(St, {msg_from_GUI, _Channel, _Msg}) ->
    case genserver:request(list_to_atom(St#cl_st.server),
                           {msg_from_GUI, self(),make_ref(), _Channel, _Msg}) of
        ok  -> {ok, St};
        _ -> {{error, user_not_joined, "You are not in that channel!"}, St}
    end;



%%%%%%%%%%%%%%
%%% WhoIam
%%%%%%%%%%%%%%
loop(St, whoiam) ->
    {St#cl_st.nick, St};


%%%%%%%%%%
%%% Nick
%%%%%%%%%%
loop(St, {nick, _Nick}) ->
    case St#cl_st.server of 
        [] ->
            {ok, St#cl_st{nick = _Nick}};
        _  -> 
            {{error, nick_change_error, "You cannot change nickname while connected to the server"}, St}
    end;



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
    #cl_st { gui = GUIName ,server=[],nick=Nick, channels=[]}.
