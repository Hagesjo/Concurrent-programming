% This record defines the structure of the 
% client process. 
% 
% It contains the following fields: 
%
% gui: it stores the name (or Pid) of the GUI process.
%
-record(cl_st, {gui, nick, message, channels, server, machine}).
    
% This record defines the structure of the 
% server process. 
% 
-record(server_st, {name, users, channels}).

-record(channel_st, {pids}).
