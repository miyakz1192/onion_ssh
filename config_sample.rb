######################################################################
#SAMPLE OF LOADING SERVER INFORMATION FROM FILE
#loading server information from file
#supported format is /etc/hosts format and IPv4 only.
######################################################################
load_from "/etc/hosts"
######################################################################
#SAMPLE OF ACCOUNT GROUP
#this configuration defines server1,2,3 have "login_user_name" 
#and "passwd"
######################################################################
account_group "login_user_name", "passwd" {
  "server1",
  "server2",
  "server3"
}
######################################################################
#SAMPLE OF SERVER GROUP
#this configuration defines server1,2,3 are in group "sv_group1" 
######################################################################
#sample of sv_group1
server_group "sv_group1" {
  "server1",
  "server2",
  "server3"
}
#sample of sv_group2
server_group "sv_gruop2" {
  "server*",
}
######################################################################
#SAMPLE OF SERVER CONNECTIONS 
#defines server's connection relationship.
#connection pair are able to drow in [].
#these patterns are ,
#1) one server and another server(ex: server1 , server2)
#2) one server and server group
#3) server group and server group
######################################################################
server_connections {
  ["server1", "server2"],
  ["server1", "sv_group2"],
  ["sv_group1", "sv_group2"],
}
