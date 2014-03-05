-module(client).
%-export([loop/2, initial_state/2]).
-compile(export_all).

-include_lib("./defs.hrl").


%%%%%%%%%%%%%%%
%%%% Connect
%%%%%%%%%%%%%%%

loop(St, {connect, {Server, Machine}}) ->
    case St#cl_st.server of 
        [] ->    case catch genserver:request({list_to_atom(Server), list_to_atom(Machine)}, {connect, self(), St#cl_st.nick}) of
            ok ->
                {ok, St#cl_st{server = Server, machine = Machine}};
            nick_exist ->
                {{error, nick_exist, "Nick exist"}, St};			
            user_already_connected ->
                {{error, user_already_connected, "User already connected"},St};
            _ ->
                {{error, server_not_reached, "Server not reached"},St}
        end;	
        _ -> {{error, user_already_connected, "User already connected"}, St}

    end;

loop(St, {connect, _Server}) ->
    case St#cl_st.server of
    [] -> case catch genserver:request({list_to_atom(_Server), node()}, {connect, self(), St#cl_st.nick}) of
            ok ->
                {ok, St#cl_st{server = _Server, machine = atom_to_list(node())}};
            nick_exist ->
                {{error, nick_exist, "Nick exist"}, St};			
            user_already_connected ->
                {{error, user_already_connected, "User already connected"},St};
            _ ->
                {{error, server_not_reached, "Server not reached"},St}
            end;
    _ -> {{error, user_already_connected, "User already connected"}, St}
    end;
					

%%%%%%%%%%%%%%%
%%%% Disconnect
%%%%%%%%%%%%%%%
loop(St=#cl_st{server = Server, machine = Machine, nick= Nick, channels = Channel}, disconnect) ->
    case Server of
        [] ->  
            {{error, user_not_connected, "User not connected"}, St};
        _ ->  
            case Channel of
            [] ->
                genserver:request({list_to_atom(Server), list_to_atom(Machine)}, {disconnect, self(), Nick}),
                {ok, St#cl_st{server = [], machine = []}};
            _ ->
                {{error, leave_channels_first, "Leave all channels first"}, St}
        end
   end;
        
        
        

%%%%%%%%%%%%%%
%%% Join
%%%%%%%%%%%%%%
loop(St=#cl_st{server = Server, machine = Machine}, {join,_Channel}) ->
    case St#cl_st.server of
    [] ->
        {{error, user_not_connected, "User not connected"}, St};
    _  -> 
        case genserver:request({list_to_atom(Server), list_to_atom(Machine)},
                                           {join, self(), _Channel, St#cl_st.nick}) of
            ok    -> 
                {ok, St#cl_st{channels = [_Channel | St#cl_st.channels]}};
            user_already_joined ->
                {{error, user_already_joined, "You are already connected to that channel!"}, St}
        end
    end;

			
%%%%%%%%%%%%%%%
%%%% Leave
%%%%%%%%%%%%%%%
loop(St=#cl_st{server = Server, machine = Machine}, {leave,_Channel}) ->
        case genserver:request({list_to_atom(Server), list_to_atom(Machine)},
                                           {leave, self(), _Channel, St#cl_st.nick}) of
        ok ->  {ok, St#cl_st{channels = lists:delete(_Channel,St#cl_st.channels)}};
        _ -> {{error, user_not_joined, "You are not in that channel!"}, St}
    end;
	
%%%%%%%%%%%%%%%%%%%%%
%%% Sending messages
%%%%%%%%%%%%%%%%%%%%%
loop(St=#cl_st{server = Server, machine = Machine, channels = Channels}, {msg_from_GUI, _Channel, _Msg}) ->
    case lists:member(_Channel, Channels) of
        true -> genserver:request({list_to_atom(Server), list_to_atom(Machine)},
                           {msg_from_GUI, self(), _Channel, St#cl_st.nick, _Msg}),
            {ok, St};
        false -> {{error, user_not_joined, "You are not in that channel!"}, St}
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

%%%%%%%%%%%%%%%%%%%%%
%%%% Incoming message
%%%%%%%%%%%%%%%%%%%%%
loop(St = #cl_st { gui = GUIName }, _MsgFromClient) ->
    {Channel, Name, Msg} = _MsgFromClient,
    gen_server:call(list_to_atom(GUIName), {msg_to_GUI, Channel, Name++"> "++Msg}),
    {ok, St}.


initial_state(Nick, GUIName) ->
    #cl_st { gui = GUIName ,server=[], machine=[],nick=Nick, channels=[]}.
