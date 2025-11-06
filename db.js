const { Pool } = require('pg');

const pool = new Pool({
    user: '',
    host: 'localhost',
    database: 'beauty_salon', 
    password: '',
    port: ,
});

module.exports = pool;
