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