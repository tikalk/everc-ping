const promBundle = require('express-prom-bundle');
const express = require('express');
const asyncRedis = require('async-redis');
const cors = require('cors');
const bodyParser = require('body-parser');

const app = express();

const wsInstance = require('express-ws')(app);

var config = require('./config/config.js');

const redis_pass = config.get('redis_pass')
var cache_host = 'redis://' + config.get('redis_host') + ':' + config.get('redis_port');

if (process.env.REDIS_URL != null) {
    var cache_host = process.env.REDIS_URL;
}

// enable prometheus stats
const metricsMiddleware = promBundle({
    includeMethod: true,
    includePath: true,
    customLabels: { app_version: process.env.npm_package_version },
    promClient: {
        collectDefaultMetrics: { timeout: 1000 },
    },
});

app.set(
    'redis',
    asyncRedis.createClient({
        url: cache_host,
        password: redis_pass
    })
);

// add metrics to express app
app.use(metricsMiddleware);
app.use(cors());
app.use(bodyParser());

// routes
app.get('/', async (req, res, next) => {
    const client = app.get('redis');
    try {
        result = await client.get('pings');
        res.send('Current ping count: ' + result + '\n');
    } catch (err) {
        next(err);
    }
});

app.get('/pinger', async (req, res, next) => {
    const client = app.get('redis');
    try {
        await client.incrby('pings', '1');
        res.status(204).send('Ping + 1');
    } catch (err) {
        next(err);
    }
});

app.post('/ping', async (req, res, next) => {
    const client = app.get('redis');
    try {
        const result = await client.incrby('pings', '1');
        res.sendStatus(204);

        // notify connected sockets
        const wss = wsInstance.getWss();
        wss.clients.forEach(function each(client) {
            client.send(JSON.stringify({ result }));
        });
    } catch (err) {
        next(err);
    }
});

app.get('/isAlive', function (req, res) {
    res.send("It's aaaalive!\n");
});

app.get('/probe/liveness', function (req, res) {
    res.sendStatus(200);
});

app.get('/probe/readiness', async (req, res, next) => {
    const client = app.get('redis');
    try {
        await client.ping();
        res.senStatus(200);
    } catch (err) {
        next(err);
    }
});

app.listen(config.get('listen_port'), function () {
    console.log('Connecting to cache_host: ' + cache_host);
    console.log('Server running on port ' + config.get('listen_port') + '!');
});

// Default socket route
app.ws('/', function (ws, req) {
    ws.on('message', function (msg) {
        console.log(msg);
    });
});
