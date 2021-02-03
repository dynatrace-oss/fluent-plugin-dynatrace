const http = require("http");

process.on('SIGINT', () => {
  process.exit(0)
});

process.on('SIGTERM', () => {
  process.exit(0)
});

const server = http.createServer((req, res) => {
    req.on('data', (chunk) => {
        process.stdout.write(chunk);
    });

    req.on("end", () => {
        res.end();
    });
})

server.listen(8080);