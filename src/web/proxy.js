let AXIOS = require('axios');
let HTTP = require('http');

HTTP.createServer(function(request, response) {
    try {
        if (request.url.startsWith('/discord/')) {
            let url = request.url.split('/discord/')[1].split('?');
            if (url.length > 2000) {
                response.writeHead(413);
                response.end('Request violates Discord\'s length limit.');
                return;
            }
    
            AXIOS.post(`https://discord.com/api/webhooks/${url[0]}`,{
                content: decodeURIComponent(
                    (decodeURI(url[1])).split('Message=')[1]
                )
            });
    
            response.writeHead(200);
            response.end('Successfully sent to Discord.');
        };
    } catch (error) {
        console.log(error);
    }
}).listen(49152);