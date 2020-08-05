var buffer = argument[0];
var socket = argument[1];
var msgId = buffer_read(buffer, buffer_u8);//find the tag

switch (msgId)
{
    case 1: // latency request
        var time = buffer_read(buffer, buffer_u32)//read in the time from the client
        buffer_seek(global.buffer, buffer_seek_start, 0);//seek to the beginning of the read buffer
        buffer_write(global.buffer, buffer_u8, 1);//write a tag to the global write buffer
        buffer_write(global.buffer, buffer_u32, time);//write the time receieved the the global write buffer
        // send back to player who sent this message
        network_send_packet(socket, global.buffer, buffer_tell(global.buffer));
    break;
    
    case 2:// registration request
        var playerUsername = buffer_read(buffer, buffer_string);
        var passwordHash = buffer_read(buffer, buffer_string);
        var response = 0;
        
        // check if player already exists
        if (!file_exists(playerUsername + ".ini"))
        {
            // register a new player
            ini_open(playerUsername + ".ini");
            ini_write_string("credentials", "username", playerUsername);
            ini_write_string("credentials", "password", passwordHash);
            ini_write_real("position", "room", 1);
            ini_write_real("position", "x", 224);
            ini_write_real("position", "y", 160);
            ini_close();
            
            response = 1;
            scr_showNotification("A new player has registered!");
        }
          // send response to the client
        buffer_seek(global.buffer, buffer_seek_start, 0);//seek to the beginning of the read buffer
        buffer_write(global.buffer, buffer_u8, 2);//write a tag to the global write buffer
        buffer_write(global.buffer, buffer_u8, response);
        buffer_write(global.buffer, buffer_u32, 224);
        buffer_write(global.buffer, buffer_u32, 160);
        buffer_write(global.buffer, buffer_u8, 1);
        network_send_packet(socket, global.buffer, buffer_tell(global.buffer));
    break;
    
    case 3: // login request
        var pId = buffer_read(buffer, buffer_u32);
        var playerUsername = buffer_read(buffer, buffer_string);
        var passwordHash = buffer_read(buffer, buffer_string);
        var response = 0;
        var positionX = 0;
        var positionY = 0
        var currentRoom = 0;
        
        // check if player already exists
        if (file_exists(playerUsername + ".ini"))
        {
            ini_open(playerUsername + ".ini");
            var playerStoredPassword = ini_read_string("credentials", "password", "");
            positionX = ini_read_real("position", "x", 0);
            positionY = ini_read_real("position", "y", 0);
            currentRoom = ini_read_real("position", "room", 0);
            ini_close();
            
            if (passwordHash == playerStoredPassword)
            {
                response = 1;
                
                with (obj_player)
                {
                    if (playerIdentifier == pId)
                    {
                        playerName = playerUsername;
                    }
                } 
            }
        }
        
        // send a response
        buffer_seek(global.buffer, buffer_seek_start, 0);//seek to the beginning of the read buffer
        buffer_write(global.buffer, buffer_u8, 3);//write a tag to the global write buffer
        buffer_write(global.buffer, buffer_u8, response);
        buffer_write(global.buffer, buffer_u32, positionX);
        buffer_write(global.buffer, buffer_u32, positionY);
        buffer_write(global.buffer, buffer_u8, currentRoom);
        network_send_packet(socket, global.buffer, buffer_tell(global.buffer));
    break;

     case 6: // player room change request
        var pId = buffer_read(buffer, buffer_u32);
        var type = buffer_read(buffer, buffer_u8);
        var pX = buffer_read(buffer, buffer_u32);
        var pY = buffer_read(buffer, buffer_u32);
        var roomId = buffer_read(buffer, buffer_u8);
        var pName = "";
        
        with (obj_player)
        {
            if (playerIdentifier == pId)
            {
                if (roomId == 0)
                {
                    playerInGame = false;
                }
                else
                {
                    playerInGame = true;
                }
                pName = playerName;
                playerType = type;
                playerX = pX;
                playerY = pY;
                playerRoom = roomId;
            }
        }

    case 8: // chat request
        var pId = buffer_read(buffer, buffer_u32);
        var text = buffer_read(buffer, buffer_string);
        var roomId = buffer_read(buffer, buffer_u8);
        
        //tell other players about this change
        for (var i = 0; i < ds_list_size(global.players);i++)
        {
            var storedPlayerSocket = ds_list_find_value(global.players, i);
            
            if (storedPlayerSocket != socket)
            {
                var player = noone;
                
                with (obj_player)
                {
                    if (self.playerSocket == storedPlayerSocket)
                    {
                        player = id;
                    }
                }
                
                if (player != noone)
                {
                    if (player.playerInGame && player.playerRoom == roomId)
                    {
                        buffer_seek(global.buffer, buffer_seek_start, 0);
                        buffer_write(global.buffer, buffer_u8, 8);
                        buffer_write(global.buffer, buffer_u32, pId);
                        buffer_write(global.buffer, buffer_string, text);
                        network_send_packet(storedPlayerSocket, global.buffer, buffer_tell(global.buffer));
                    }
                }
            }
        }
    break;
    
     case 10:
        var latency = buffer_read(buffer, buffer_u32);
        var player = noone;
        
        with (obj_player)
        {
            if (self.playerSocket == socket)
            {
                player = id;
            }
        }
        
        if (player != noone)
        {
            player.playerLatency = latency;
        }
        
        // tell other players about this change
        for (var i = 0; i < ds_list_size(global.players);i++)
        {
            var storedPlayerSocket = ds_list_find_value(global.players, i);
            
            if (storedPlayerSocket != socket)// don't send a packet to the client we got this requst from
            {
                buffer_seek(global.buffer, buffer_seek_start, 0);
                buffer_write(global.buffer, buffer_u8, 10);
                buffer_write(global.buffer, buffer_u32, player.playerIdentifier);
                buffer_write(global.buffer, buffer_u32, player.playerLatency);
                network_send_packet(storedPlayerSocket, global.buffer, buffer_tell(global.buffer));
            }
        }

 case 11: // create/move request
        var pId = buffer_read(buffer, buffer_u32);
        var projectileId = buffer_read(buffer, buffer_u32);
        var xx = buffer_read(buffer, buffer_f32);
        var yy = buffer_read(buffer, buffer_f32);
        var roomId = buffer_read(buffer, buffer_u8);
        
        var projectile = noone;
        
        with (obj_projectile)
        {
            if (self.owner == pId && self.projectileId == projectileId)
            {
                projectile = id;
            }
        }
        
        if (projectile != noone)
        {
            projectile.x = xx;
            projectile.y = yy;
        }
        else
        {
            var p = instance_create(xx, yy, obj_projectile);
            p.owner = pId;
            p.projectileId = projectileId;
        }
}
// tell other players about this change
        for (var i = 0; i < ds_list_size(global.players);i++)
        {
            var storedPlayerSocket = ds_list_find_value(global.players, i);
        
            if (storedPlayerSocket != socket)//don't send a packet to the client we got this request from
            {
                var player = noone;
                
                with (obj_player)
                {
                    if (self.playerSocket == storedPlayerSocket)
                    {
                        player = id;
                    }
                    
                    if (player != noone)
                    {
                        if (player.playerInGame && player.playerRoom == roomId)
                        {
                            buffer_seek(global.buffer, buffer_seek_start, 0);
                            buffer_write(global.buffer, buffer_u8, 11);
                            buffer_write(global.buffer, buffer_u32, pId);
                            buffer_write(global.buffer, buffer_u32, projectileId);
                            buffer_write(global.buffer, buffer_f32, xx);
                            buffer_write(global.buffer, buffer_f32, yy);
                            network_send_packet(storedPlayerSocket, global.buffer, buffer_tell(global.buffer));
                        }
                    }
                }
            }
        }
    break;
    }
        