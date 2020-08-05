/// @param buffer
/// @param ...
var buffer = argument[0];
var msgId = buffer_read(buffer, buffer_u8);// find the tag

switch(msgId)
{
    case 1: // latency response
        var time = buffer_read(buffer, buffer_u32);// read in the time from the server
        global.latency = current_time - time;// update our latency
    break;
    
    case 2: // registration response
        var response = buffer_read(buffer, buffer_u8);
        
        switch(response)
        {
            case 0://failure
                scr_showNotification("Registration failed! Username already exists!");
            break;
            
            case 1://success
                global.playerX = buffer_read(buffer, buffer_u32);
                global.playerY = buffer_read(buffer, buffer_u32);
                global.playerRoom = buffer_read(buffer, buffer_u8);
                
                // todo: let's send the player to the correct room
                room_goto(rm_menu);
            break;
        }
    break;
    
    case 3: // login response
        var response = buffer_read(buffer, buffer_u8);
        
        switch(response)
        {
            case 0:// failure
                scr_showNotification("Login failed! Username doesn't exist or password is incorrect!");
            break;
            
            case 1://success
                global.playerX = buffer_read(buffer, buffer_u32);
                global.playerY = buffer_read(buffer, buffer_u32);
                global.playerRoom = buffer_read(buffer, buffer_u8);
                
                // todo: let's send the player to the correct room
                room_goto(rm_menu);
            break;
        }
        case 4: // player ID response
        global.playerId = buffer_read(buffer, buffer_u32);
        scr_showNotification("Our playerId has been received!");
    break;

    case 7: //player movement update response
        var pId = buffer_read(buffer, buffer_u32);
        var xx = buffer_read(buffer, buffer_f32);
        var yy = buffer_read(buffer, buffer_f32);
        var spriteNumber = buffer_read(buffer, buffer_u8);
        var imageIndex = buffer_read(buffer, buffer_u8);
        var d = buffer_read(buffer, buffer_u8);
        
        with (obj_remoteplayer)
        {
            if (remotePlayerId == pId)
            {
                x = xx;
                y = yy;
                sprite_index = spriteNumber;
                image_index = imageIndex;
                
                //decode our direction
                switch (d)
                {
                    case 1:
                        image_xscale = -1;
                    break;
                    
                    case 2:
                        image_xscale = 1;
                    break;
                }
            }
        }
    break;
   
   case 8: // chat message response
        var pId = buffer_read(buffer, buffer_u32);
        var text = buffer_read(buffer, buffer_string);
        
        // find the owner of the message
        with (obj_remoteplayer)
        {
            if (remotePlayerId == pId)
            {
                //create the chat object to follow this remote player
                var chat = instance_create(x, y, obj_chat);
                chat.text = text;
                chat.owner = id;
            }
        }
    break;
    
    case 9:  
        var xx = buffer_read(buffer, buffer_f32);
        var yy = buffer_read(buffer, buffer_f32);

    break;
    
    case 10: 
        var pId = buffer_read(buffer, buffer_u32);
        var latency = buffer_read(buffer, buffer_u32);
        
        // find the owner of the message
        with (obj_remoteplayer)
        {
            if (remotePlayerId == pId)
            {
                remotePlayerLatency = latency;
            }
        }
    break;
    
    case 11: 
        var pId = buffer_read(buffer, buffer_u32);
        var projectileId = buffer_read(buffer, buffer_u32);
        var xx = buffer_read(buffer, buffer_f32);
        var yy = buffer_read(buffer, buffer_f32);
        
        var projectile = noone;
        
        with (obj_remoteProjectile)
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
            var p = instance_create(xx, yy, obj_remoteProjectile);
            p.owner = pId;
            p.projectileId = projectileId;
        }
    break;
}