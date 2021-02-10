const http = require("http");

process.on('SIGINT', () => {
  process.exit(0)
});

process.on('SIGTERM', () => {
  process.exit(0)
});

const server = http.createServer((req, res) => {
    const ua = req.headers['user-agent'];
    if (typeof ua != 'string') {
      process.stdout.write("Missing user agent header");
    }

    if (!ua.match(/^fluent-plugin-dynatrace v\d+\.\d+\.\d+$/)) {
      process.stdout.write("Invalid user agent header");
    }

    req.on('data', (chunk) => {
        process.stdout.write(chunk);
    });

    req.on("end", () => {
        res.end();
    });
})

server.listen(8080);