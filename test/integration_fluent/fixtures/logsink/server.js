/**
 * Copyright 2021 Dynatrace LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

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

    if (!ua.match(/^fluent-plugin-dynatrace\/\d+\.\d+\.\d+$/)) {
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