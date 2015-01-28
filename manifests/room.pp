# == Class: openfire::room
# Copyright 2014 Hewlett-Packard Development Company, L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
#
define openfire::room (
  $room_id               = $name,
  $room_name             = '',
  $description           = '',
  $broadcast_moderator   = true,
  $broadcast_participant = true,
  $broadcast_visitor     = true,
  $log_conversations     = false,
) {

  if $room_id == '' {
    fail('Room ID is required.')
  }
  if $room_name == '' {
    fail('Room name is required.')
  }
  if $description == '' {
    fail('Room description is required.')
  }

  validate_bool($broadcast_moderator, $broadcast_participant, $broadcast_visitor, $log_conversations)

  ## Broadcast settings
  if $broadcast_moderator{
    $bc_mod = '<broadcastPresenceRole>moderator</broadcastPresenceRole>'
  }
  if $broadcast_participant {
    $bc_par = '<broadcastPresenceRole>participant</broadcastPresenceRole>'
  }
  if $broadcast_visitor {
    $bc_vis = '<broadcastPresenceRole>visitor</broadcastPresenceRole>'
  }
  $broadcast = "<broadcastPresenceRoles>${bc_mod}${bc_par}${bc_vis}</broadcastPresenceRoles>"

  exec { "Waiting for Openfire service: ${room_id}":
    command   => "wget --spider http://${::ipaddress}:${openfire::of_port} && sleep 10",
    path      => '/usr/local/bin:/usr/bin:/bin',
    timeout   => 30,
    tries     => 20,
    try_sleep => 5,
    require   => Class['::openfire::service'],
    unless    => "wget --spider http://${::ipaddress}:${openfire::of_port}"
  } ->
  exec { "CreateRoom:${room_id}":
    command   => join([
      'curl -X POST ',
      "-u admin:${::openfire::of_admin_pass}",
      '--header "Content-Type: application/xml"',
      "-d '<chatRoom><naturalName>${room_name}</naturalName><roomName>${room_id}</roomName><description>${description}</description><persistent>true</persistent><publicRoom>true</publicRoom><registrationEnabled>true</registrationEnabled><canChangeNickname>true</canChangeNickname><logEnabled>${log_conversations}</logEnabled>${broadcast}</chatRoom>'",
      "http://${::ipaddress}:${openfire::of_port}/plugins/mucservice/chatrooms",
    ], ' '),
    path      => '/usr/local/bin:/usr/bin:/bin',
    logoutput => 'on_failure',
    onlyif    => "curl -s http://${::ipaddress}:${openfire::of_port}/plugins/mucservice/chatrooms/${room_id} -u admin:${::openfire::of_admin_pass} | grep 'Chat room could be not found'"
  }
}