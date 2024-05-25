import https from 'https';
import fs from 'fs';

const options = {
  key: fs.readFileSync('./LAB.key'),
  cert: fs.readFileSync('./LAB.crt')
};

const server = https.createServer(options, (req, res) => {
  res.writeHead(200);
  res.end('Hello HTTPS World Maxim!');
});

server.listen(3443, () => {
  console.log('Server running on https://172.20.10.9:3443/');
});
