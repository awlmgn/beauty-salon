const { Pool } = require('pg');

const pool = new Pool({
    user: 'postgres',
    host: 'localhost',
    database: 'beauty_salon', 
    password: '1111',
    port: 5432,
});

module.exports = pool;