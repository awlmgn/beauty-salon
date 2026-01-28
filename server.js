const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { Pool } = require('pg'); 

const app = express();
const PORT = process.env.PORT || 5000;
const JWT_SECRET = 'your_super_secret_jwt_key'; 

app.use(cors());
app.use(express.json());

const pool = new Pool({
    user: 'postgres',
    host: 'localhost',
    database: 'beauty_salon',
    password: '1111',
    port: 5432,
});

app.post('/api/register', async (req, res) => {
    try {
        const { email, password, name } = req.body;

        const userExists = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
        if (userExists.rows.length > 0) {
            return res.status(400).json({ message: 'Пользователь с таким email уже существует' });
        }

        // Хеширование пароля
        const hashedPassword = await bcrypt.hash(password, 10);

        // Сохранение пользователя в БД
        const newUser = await pool.query(
            'INSERT INTO users (email, password, name) VALUES ($1, $2, $3) RETURNING id, email, name',
            [email, hashedPassword, name]
        );

        // Создание JWT токена
        const token = jwt.sign({ userId: newUser.rows[0].id }, JWT_SECRET);

        res.status(201).json({
            message: 'Пользователь зарегистрирован',
            token,
            user: { id: newUser.rows[0].id, email: newUser.rows[0].email, name: newUser.rows[0].name }
        });
    } catch (error) {
        console.error(error.message);
        res.status(500).send('Ошибка сервера');
    }
});

// Логин
app.post('/api/login', async (req, res) => {
    try {
        const { email, password } = req.body;

        // Проверка, существует ли пользователь
        const user = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
        if (user.rows.length === 0) {
            return res.status(400).json({ message: 'Неверный email или пароль' });
        }

        // Проверка пароля
        const isMatch = await bcrypt.compare(password, user.rows[0].password);
        if (!isMatch) {
            return res.status(400).json({ message: 'Неверный email или пароль' });
        }

        // Создание JWT токена
        const token = jwt.sign({ userId: user.rows[0].id }, JWT_SECRET);

        res.json({
            message: 'Вход выполнен успешно',
            token,
            user: { id: user.rows[0].id, email: user.rows[0].email, name: user.rows[0].name }
        });
    } catch (error) {
        console.error(error.message);
        res.status(500).send('Ошибка сервера');
    }
});

// Получение списка всех мастеров (публичный маршрут)
app.get('/api/masters', async (req, res) => {
    try {
        const allMasters = await pool.query('SELECT * FROM masters');
        res.json(allMasters.rows);
    } catch (error) {
        console.error(error.message);
        res.status(500).send('Ошибка сервера');
    }
});

// --- НОВЫЙ КОМПОНЕНТ: MIDDLEWARE ДЛЯ АУТЕНТИФИКАЦИИ ---
// Этот middleware будет защищать маршруты и добавлять req.user
const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // "Bearer TOKEN"

    if (token == null) {
        return res.sendStatus(401); // Unauthorized
    }

    jwt.verify(token, JWT_SECRET, (err, decoded) => {
        if (err) {
            console.error('JWT Error:', err.message);
            return res.sendStatus(403); // Forbidden
        }
        // Добавляем ID пользователя в объект запроса для дальнейшего использования
        req.userId = decoded.userId;
        next();
    });
};


// --- ОБНОВЛЕННЫЙ МАРШРУТ ПОЛУЧЕНИЯ МАСТЕРОВ ---
// Теперь он защищен и требует токен
app.get('/api/masters', authenticateToken, async (req, res) => {
    try {
        const userId = req.userId; // Получаем ID пользователя из middleware

        // SQL-запрос, который объединяет мастеров с таблицей избранного
        // и создает булево поле is_favorite
        const query = `
            SELECT
                m.*,
                CASE WHEN f.user_id IS NOT NULL THEN TRUE ELSE FALSE END AS is_favorite
            FROM
                masters m
            LEFT JOIN
                favorites f ON m.id = f.master_id AND f.user_id = $1;
        `;

        const allMasters = await pool.query(query, [userId]);
        
        // Важно: PostgreSQL возвращает `is_favorite` с нижним подчеркиванием.
        // Flutter модель ожидает isFavorite (camelCase). Либо меняем модель во Flutter,
        // либо преобразуем здесь. Давайте пока оставим как есть, и исправим модель.
        res.json(allMasters.rows);

    } catch (error) {
        console.error('Ошибка получения мастеров:', error.message);
        res.status(500).send('Ошибка сервера');
    }
});


// --- НОВЫЕ МАРШРУТЫ ДЛЯ УПРАВЛЕНИЯ ИЗБРАННЫМ ---

// Получить список избранных мастеров для пользователя
app.get('/api/favorites', authenticateToken, async (req, res) => {
    try {
        const userId = req.userId;
        const favorites = await pool.query(
            `SELECT m.* FROM masters m 
             JOIN favorites f ON m.id = f.master_id 
             WHERE f.user_id = $1`,
            [userId]
        );
        res.json(favorites.rows);
    } catch (error) {
        console.error('Ошибка получения избранных:', error.message);
        res.status(500).send('Ошибка сервера');
    }
});

// Добавить мастера в избранное
app.post('/api/favorites', authenticateToken, async (req, res) => {
    try {
        const userId = req.userId;
        const { master_id } = req.body;

        // Проверка, не добавлен ли уже
        const exists = await pool.query(
            'SELECT * FROM favorites WHERE user_id = $1 AND master_id = $2',
            [userId, master_id]
        );
        if (exists.rows.length > 0) {
            return res.status(409).json({ message: 'Мастер уже в избранном' }); // 409 Conflict
        }

        await pool.query(
            'INSERT INTO favorites (user_id, master_id) VALUES ($1, $2)',
            [userId, master_id]
        );
        res.status(201).json({ message: 'Мастер добавлен в избранное' });
    } catch (error) {
        console.error('Ошибка добавления в избранное:', error.message);
        res.status(500).send('Ошибка сервера');
    }
});

// Удалить мастера из избранного
app.delete('/api/favorites/:masterId', authenticateToken, async (req, res) => {
    try {
        const userId = req.userId;
        const { masterId } = req.params;

        const result = await pool.query(
            'DELETE FROM favorites WHERE user_id = $1 AND master_id = $2',
            [userId, masterId]
        );

        if (result.rowCount === 0) {
            return res.status(404).json({ message: 'Мастер не найден в избранном' });
        }

        res.status(200).json({ message: 'Мастер удален из избранного' });
    } catch (error) {
        console.error('Ошибка удаления из избранного:', error.message);
        res.status(500).send('Ошибка сервера');
    }
});

app.post('/api/profile', authenticateToken, async (req, res) => {
    try {
        const user_id = req.userId;
        const { name, email } = req.body;

        if (!name || !email) {
            return res.status(400).json({ message: 'Имя и email обязательны для заполнения' });
        }

        // Проверка, не занят ли новый email другим пользователем
        const emailCheck = await pool.query(
            'SELECT id FROM users WHERE email = $1 AND id != $2',
            [email, user_id]
        );

        if (emailCheck.rows.length > 0) {
            return res.status(409).json({ message: 'Этот email уже используется другим пользователем' });
        }

        // Обновление данных
        const result = await pool.query(
            'UPDATE users SET name = $1, email = $2 WHERE id = $3 RETURNING id, name, email',
            [name, email, user_id]
        );

        if (result.rowCount === 0) {
            return res.status(404).json({ message: 'Пользователь не найден' });
        }

        res.json({
            success: true,
            message: 'Профиль успешно обновлен',
            user: { id: user_id, name: result.rows[0].name, email: result.rows[0].email }
        });

    } catch (error) {
        console.error('Ошибка обновления профиля:', error.message);
        res.status(500).json({ message: 'Ошибка сервера при обновлении профиля' });
    }
});

app.get('/api/reviews', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        r.*, 
        u.name as user_name, 
        m.name as master_name,
        m.specialization as master_specialization,
        s.name as service_name
      FROM reviews r 
      LEFT JOIN users u ON r.user_id = u.id 
      LEFT JOIN masters m ON r.master_id = m.id 
      LEFT JOIN services s ON r.service_id = s.id
      ORDER BY r.created_at DESC
    `);
    
    // ВАЖНО: возвращаем массив отзывов напрямую, а не объект
    res.json(result.rows);
  } catch (error) {
    console.error('Ошибка получения отзывов:', error.message);
    res.status(500).json({ message: 'Ошибка сервера при загрузке отзывов' });
  }
});

// Добавление нового отзыва
app.post('/api/reviews', authenticateToken, async (req, res) => {
  try {
    const { master_id, service_id, text, rating } = req.body;
    const user_id = req.userId;

    console.log('📝 Получен запрос на добавление отзыва:');
    console.log('   user_id:', user_id);
    console.log('   master_id:', master_id);
    console.log('   service_id:', service_id);
    console.log('   text:', text);
    console.log('   rating:', rating);

    // Проверяем обязательные поля
    if (!master_id || !text || !rating) {
      console.log('❌ Не все поля заполнены');
      return res.status(400).json({ 
        success: false,
        message: 'Заполните все обязательные поля' 
      });
    }

    // Проверяем, существует ли мастер
    const masterCheck = await pool.query(
      'SELECT id FROM masters WHERE id = $1',
      [master_id]
    );

    if (masterCheck.rows.length === 0) {
      console.log('❌ Мастер не найден:', master_id);
      return res.status(404).json({ 
        success: false,
        message: 'Мастер не найден' 
      });
    }

    // Если service_id передан, проверяем существование услуги
    if (service_id) {
      const serviceCheck = await pool.query(
        'SELECT id FROM services WHERE id = $1',
        [service_id]
      );

      if (serviceCheck.rows.length === 0) {
        console.log('❌ Услуга не найдена:', service_id);
        return res.status(404).json({ 
          success: false,
          message: 'Услуга не найдена' 
        });
      }
    }

    // Проверяем, не оставлял ли пользователь уже отзыв этому мастеру
    const existingReviewQuery = service_id 
      ? 'SELECT id FROM reviews WHERE user_id = $1 AND master_id = $2 AND service_id = $3'
      : 'SELECT id FROM reviews WHERE user_id = $1 AND master_id = $2';
    
    const existingReviewParams = service_id 
      ? [user_id, master_id, service_id]
      : [user_id, master_id];

    const existingReview = await pool.query(existingReviewQuery, existingReviewParams);

    if (existingReview.rows.length > 0) {
      console.log('❌ Пользователь уже оставлял отзыв этому мастеру');
      return res.status(409).json({ 
        success: false,
        message: 'Вы уже оставляли отзыв этому мастеру' 
      });
    }

    // Создаем отзыв
    const insertQuery = service_id 
      ? `INSERT INTO reviews (user_id, master_id, service_id, text, rating) 
         VALUES ($1, $2, $3, $4, $5) 
         RETURNING *`
      : `INSERT INTO reviews (user_id, master_id, text, rating) 
         VALUES ($1, $2, $3, $4) 
         RETURNING *`;
    
    const insertParams = service_id 
      ? [user_id, master_id, service_id, text, rating]
      : [user_id, master_id, text, rating];

    const result = await pool.query(insertQuery, insertParams);

    console.log('✅ Отзыв создан:', result.rows[0]);

    // Обновляем средний рейтинг мастера (исправленная версия)
    try {
      const avgResult = await pool.query(
        'SELECT AVG(rating) as avg_rating FROM reviews WHERE master_id = $1',
        [master_id]
      );
      
      const avgRating = parseFloat(avgResult.rows[0].avg_rating) || 0;
      
      await pool.query(
        'UPDATE masters SET rating = $1 WHERE id = $2',
        [avgRating, master_id]
      );
      
      console.log('✅ Рейтинг мастера обновлен:', avgRating);
    } catch (ratingError) {
      console.log('⚠️ Не удалось обновить рейтинг мастера:', ratingError.message);
      // Продолжаем выполнение даже если не удалось обновить рейтинг
    }

    res.status(201).json({ 
      success: true,
      message: 'Отзыв успешно добавлен!',
      review: result.rows[0]
    });
    
  } catch (error) {
    console.error('💥 Ошибка добавления отзыва:', error.message);
    console.error('Stack trace:', error.stack);
    res.status(500).json({ 
      success: false,
      message: 'Внутренняя ошибка сервера: ' + error.message 
    });
  }
});
// Проверка доступности времени
app.post('/api/check-availability', authenticateToken, async (req, res) => {
    try {
        const { master_id, date_time } = req.body;
        
        // Проверяем, есть ли уже записи на это время у мастера
        const existingAppointments = await pool.query(
            'SELECT * FROM appointments WHERE master_id = $1 AND date_time = $2',
            [master_id, date_time]
        );

        // Если есть записи - время занято
        if (existingAppointments.rows.length > 0) {
            return res.json({ available: false });
        }

        // Если записей нет - время свободно
        res.json({ available: true });
    } catch (error) {
        console.error('Ошибка проверки доступности:', error.message);
        res.status(500).json({ message: 'Ошибка сервера' });
    }
});

// Создание новой записи
app.post('/api/appointments', authenticateToken, async (req, res) => {
    try {
        const { master_id, service, date_time, client_name, client_phone } = req.body;
        const user_id = req.userId;

        // Проверяем, не занято ли время
        const existingAppointments = await pool.query(
            'SELECT * FROM appointments WHERE master_id = $1 AND date_time = $2',
            [master_id, date_time]
        );

        if (existingAppointments.rows.length > 0) {
            return res.status(409).json({ 
                success: false, 
                message: 'Это время уже занято. Выберите другое время.' 
            });
        }

        // Создаем запись
        const newAppointment = await pool.query(
            `INSERT INTO appointments (user_id, master_id, service, date_time, client_name, client_phone) 
             VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
            [user_id, master_id, service, date_time, client_name, client_phone]
        );

        res.status(201).json({ 
            success: true, 
            message: 'Запись успешно создана!',
            appointment: newAppointment.rows[0]
        });
    } catch (error) {
        console.error('Ошибка создания записи:', error.message);
        res.status(500).json({ 
            success: false, 
            message: 'Ошибка создания записи' 
        });
    }
});

// Получение записей пользователя
app.get('/api/appointments', authenticateToken, async (req, res) => {
    try {
        const user_id = req.userId;
        
        const appointments = await pool.query(
            `SELECT a.*, m.name as master_name, m.specialization 
             FROM appointments a 
             JOIN masters m ON a.master_id = m.id 
             WHERE a.user_id = $1 
             ORDER BY a.date_time DESC`,
            [user_id]
        );

        res.json(appointments.rows);
    } catch (error) {
        console.error('Ошибка получения записей:', error.message);
        res.status(500).json({ message: 'Ошибка сервера' });
    }
});

app.get('/api/reviews', async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT r.*, u.name as user_name, m.name as master_name 
            FROM reviews r 
            LEFT JOIN users u ON r.user_id = u.id 
            LEFT JOIN masters m ON r.master_id = m.id 
            ORDER BY r.created_at DESC
        `);
        res.json(result.rows);
    } catch (error) {
        console.error('Ошибка получения отзывов:', error.message);
        res.status(500).json({ message: 'Ошибка сервера' });
    }
});

app.post('/api/reviews', authenticateToken, async (req, res) => {
    try {
        const { text, rating, master_id } = req.body;
        const user_id = req.userId;
        
        const result = await pool.query(
            'INSERT INTO reviews (user_id, master_id, text, rating) VALUES ($1, $2, $3, $4) RETURNING *',
            [user_id, master_id, text, rating]
        );
        
        res.status(201).json({ 
            success: true,
            message: 'Отзыв добавлен', 
            review: result.rows[0] 
        });
    } catch (error) {
        console.error('Ошибка добавления отзыва:', error.message);
        res.status(500).json({ 
            success: false,
            message: 'Ошибка добавления отзыва' 
        });
    }
});

// Отмена записи
app.delete('/api/appointments/:appointmentId', authenticateToken, async (req, res) => {
    try {
        const { appointmentId } = req.params;
        const user_id = req.userId;

        const result = await pool.query(
            'DELETE FROM appointments WHERE id = $1 AND user_id = $2',
            [appointmentId, user_id]
        );

        if (result.rowCount === 0) {
            return res.status(404).json({ 
                success: false,
                message: 'Запись не найдена' 
            });
        }

        res.json({ 
            success: true,
            message: 'Запись успешно отменена' 
        });
    } catch (error) {
        console.error('Ошибка отмены записи:', error.message);
        res.status(500).json({ 
            success: false,
            message: 'Ошибка отмены записи' 
        });
    }
});

// ====== ДОБАВЬТЕ ЭТИ МАРШРУТЫ В server.js ======

// Сохранение карты пользователя
app.post('/api/cards', authenticateToken, async (req, res) => {
    try {
        const { card_number, expiry_month, expiry_year, card_holder, cvv, is_default } = req.body;
        const user_id = req.userId;

        // Маскируем номер карты для безопасности
        const masked_card = card_number.slice(0, 4) + '********' + card_number.slice(-4);

        // Если устанавливаем как карту по умолчанию, снимаем флаг с других карт
        if (is_default) {
            await pool.query(
                'UPDATE user_cards SET is_default = false WHERE user_id = $1',
                [user_id]
            );
        }

        const newCard = await pool.query(
            `INSERT INTO user_cards (user_id, card_number, expiry_month, expiry_year, card_holder, cvv, is_default) 
             VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *`,
            [user_id, masked_card, expiry_month, expiry_year, card_holder, cvv, is_default || false]
        );

        res.status(201).json({ 
            success: true, 
            message: 'Карта успешно добавлена',
            card: newCard.rows[0]
        });
    } catch (error) {
        console.error('Ошибка сохранения карты:', error.message);
        res.status(500).json({ 
            success: false, 
            message: 'Ошибка сохранения карты' 
        });
    }
});

// Получение карт пользователя
app.get('/api/cards', authenticateToken, async (req, res) => {
    try {
        const user_id = req.userId;
        
        const cards = await pool.query(
            'SELECT * FROM user_cards WHERE user_id = $1 ORDER BY is_default DESC, created_at DESC',
            [user_id]
        );

        res.json(cards.rows);
    } catch (error) {
        console.error('Ошибка получения карт:', error.message);
        res.status(500).json({ message: 'Ошибка сервера' });
    }
});

// Удаление карты
app.delete('/api/cards/:cardId', authenticateToken, async (req, res) => {
    try {
        const { cardId } = req.params;
        const user_id = req.userId;

        const result = await pool.query(
            'DELETE FROM user_cards WHERE id = $1 AND user_id = $2',
            [cardId, user_id]
        );

        if (result.rowCount === 0) {
            return res.status(404).json({ 
                success: false,
                message: 'Карта не найдена' 
            });
        }

        res.json({ 
            success: true,
            message: 'Карта успешно удалена' 
        });
    } catch (error) {
        console.error('Ошибка удаления карты:', error.message);
        res.status(500).json({ 
            success: false,
            message: 'Ошибка удаления карты' 
        });
    }
});

// Создание платежа
app.post('/api/payments', authenticateToken, async (req, res) => {
    try {
        const { card_id, amount, service_type } = req.body;
        const user_id = req.userId;

        // Здесь должна быть интеграция с платежной системой
        // Для демо просто создаем запись в БД

        const newPayment = await pool.query(
            `INSERT INTO payments (user_id, card_id, amount, service_type, status) 
             VALUES ($1, $2, $3, $4, 'completed') RETURNING *`,
            [user_id, card_id, amount, service_type]
        );

        res.status(201).json({ 
            success: true, 
            message: 'Оплата прошла успешно!',
            payment: newPayment.rows[0]
        });
    } catch (error) {
        console.error('Ошибка проведения платежа:', error.message);
        res.status(500).json({ 
            success: false, 
            message: 'Ошибка проведения платежа' 
        });
    }
});

// Получение истории платежей
app.get('/api/payments', authenticateToken, async (req, res) => {
    try {
        const user_id = req.userId;
        
        const payments = await pool.query(
            `SELECT p.*, uc.card_number 
             FROM payments p 
             LEFT JOIN user_cards uc ON p.card_id = uc.id 
             WHERE p.user_id = $1 
             ORDER BY p.payment_date DESC`,
            [user_id]
        );

        res.json(payments.rows);
    } catch (error) {
        console.error('Ошибка получения платежей:', error.message);
        res.status(500).json({ message: 'Ошибка сервера' });
    }
});

// ====== API ДЛЯ РАБОТЫ С ОТЗЫВАМИ ======

// Получение всех отзывов
app.get('/api/reviews', async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT 
                r.*, 
                u.name as user_name, 
                m.name as master_name,
                m.specialization as master_specialization
            FROM reviews r 
            LEFT JOIN users u ON r.user_id = u.id 
            LEFT JOIN masters m ON r.master_id = m.id 
            ORDER BY r.created_at DESC
        `);
        
        res.json({
            success: true,
            reviews: result.rows
        });
    } catch (error) {
        console.error('Ошибка получения отзывов:', error.message);
        res.status(500).json({ 
            success: false,
            message: 'Ошибка сервера при загрузке отзывов' 
        });
    }
});

// Получение отзывов для конкретного мастера
app.get('/api/reviews/master/:masterId', async (req, res) => {
    try {
        const { masterId } = req.params;
        
        const result = await pool.query(`
            SELECT 
                r.*, 
                u.name as user_name
            FROM reviews r 
            LEFT JOIN users u ON r.user_id = u.id 
            WHERE r.master_id = $1 
            ORDER BY r.created_at DESC
        `, [masterId]);
        
        res.json({
            success: true,
            reviews: result.rows
        });
    } catch (error) {
        console.error('Ошибка получения отзывов мастера:', error.message);
        res.status(500).json({ 
            success: false,
            message: 'Ошибка сервера' 
        });
    }
});

// Получение среднего рейтинга мастера
app.get('/api/reviews/master/:masterId/rating', async (req, res) => {
    try {
        const { masterId } = req.params;
        
        const result = await pool.query(`
            SELECT 
                AVG(rating) as average_rating,
                COUNT(*) as review_count
            FROM reviews 
            WHERE master_id = $1
        `, [masterId]);
        
        const data = result.rows[0];
        res.json({
            success: true,
            average_rating: parseFloat(data.average_rating) || 0,
            review_count: parseInt(data.review_count) || 0
        });
    } catch (error) {
        console.error('Ошибка получения рейтинга мастера:', error.message);
        res.status(500).json({ 
            success: false,
            message: 'Ошибка сервера' 
        });
    }
});

// Добавление нового отзыва
app.post('/api/reviews', authenticateToken, async (req, res) => {
    try {
        const { master_id, text, rating } = req.body;
        const user_id = req.userId;

        // Проверяем обязательные поля
        if (!master_id || !text || !rating) {
            return res.status(400).json({ 
                success: false,
                message: 'Заполните все обязательные поля' 
            });
        }

        // Проверяем, существует ли мастер
        const masterCheck = await pool.query(
            'SELECT id FROM masters WHERE id = $1',
            [master_id]
        );

        if (masterCheck.rows.length === 0) {
            return res.status(404).json({ 
                success: false,
                message: 'Мастер не найден' 
            });
        }

        // Проверяем, не оставлял ли пользователь уже отзыв этому мастеру
        const existingReview = await pool.query(
            'SELECT id FROM reviews WHERE user_id = $1 AND master_id = $2',
            [user_id, master_id]
        );

        if (existingReview.rows.length > 0) {
            return res.status(409).json({ 
                success: false,
                message: 'Вы уже оставляли отзыв этому мастеру' 
            });
        }

        // Создаем отзыв
        const result = await pool.query(
            `INSERT INTO reviews (user_id, master_id, text, rating) 
             VALUES ($1, $2, $3, $4) 
             RETURNING *`,
            [user_id, master_id, text, rating]
        );

        // Обновляем средний рейтинг мастера
        await pool.query(`
            UPDATE masters 
            SET rating = (
                SELECT AVG(rating) FROM reviews WHERE master_id = $1
            )
            WHERE id = $1
        `, [master_id]);

        res.status(201).json({ 
            success: true,
            message: 'Отзыв успешно добавлен!',
            review: result.rows[0]
        });
        
    } catch (error) {
        console.error('Ошибка добавления отзыва:', error.message);
        res.status(500).json({ 
            success: false,
            message: 'Ошибка добавления отзыва' 
        });
    }
});

// Обновление отзыва
app.put('/api/reviews/:reviewId', authenticateToken, async (req, res) => {
    try {
        const { reviewId } = req.params;
        const { text, rating } = req.body;
        const user_id = req.userId;

        // Проверяем, существует ли отзыв и принадлежит ли пользователю
        const reviewCheck = await pool.query(
            'SELECT * FROM reviews WHERE id = $1 AND user_id = $2',
            [reviewId, user_id]
        );

        if (reviewCheck.rows.length === 0) {
            return res.status(404).json({ 
                success: false,
                message: 'Отзыв не найден' 
            });
        }

        // Обновляем отзыв
        const result = await pool.query(
            `UPDATE reviews 
             SET text = $1, rating = $2, updated_at = CURRENT_TIMESTAMP 
             WHERE id = $3 
             RETURNING *`,
            [text, rating, reviewId]
        );

        // Обновляем рейтинг мастера
        const master_id = reviewCheck.rows[0].master_id;
        await pool.query(`
            UPDATE masters 
            SET rating = (
                SELECT AVG(rating) FROM reviews WHERE master_id = $1
            )
            WHERE id = $1
        `, [master_id]);

        res.json({ 
            success: true,
            message: 'Отзыв успешно обновлен',
            review: result.rows[0]
        });
        
    } catch (error) {
        console.error('Ошибка обновления отзыва:', error.message);
        res.status(500).json({ 
            success: false,
            message: 'Ошибка обновления отзыва' 
        });
    }
});

// Удаление отзыва
app.delete('/api/reviews/:reviewId', authenticateToken, async (req, res) => {
    try {
        const { reviewId } = req.params;
        const user_id = req.userId;

        // Проверяем, существует ли отзыв и принадлежит ли пользователю
        const reviewCheck = await pool.query(
            'SELECT master_id FROM reviews WHERE id = $1 AND user_id = $2',
            [reviewId, user_id]
        );

        if (reviewCheck.rows.length === 0) {
            return res.status(404).json({ 
                success: false,
                message: 'Отзыв не найден' 
            });
        }

        // Удаляем отзыв
        const result = await pool.query(
            'DELETE FROM reviews WHERE id = $1',
            [reviewId]
        );

        // Обновляем рейтинг мастера
        const master_id = reviewCheck.rows[0].master_id;
        await pool.query(`
            UPDATE masters 
            SET rating = (
                SELECT AVG(rating) FROM reviews WHERE master_id = $1
            )
            WHERE id = $1
        `, [master_id]);

        res.json({ 
            success: true,
            message: 'Отзыв успешно удален'
        });
        
    } catch (error) {
        console.error('Ошибка удаления отзыва:', error.message);
        res.status(500).json({ 
            success: false,
            message: 'Ошибка удаления отзыва' 
        });
    }
});

// Добавление нового отзыва - ИСПРАВЛЕННАЯ ВЕРСИЯ
app.post('/api/reviews', authenticateToken, async (req, res) => {
    try {
        const { master_id, text, rating } = req.body;
        const user_id = req.userId;

        console.log('📝 Получен запрос на добавление отзыва:');
        console.log('   user_id:', user_id);
        console.log('   master_id:', master_id);
        console.log('   text:', text);
        console.log('   rating:', rating);

        // Проверяем обязательные поля
        if (!master_id || !text || !rating) {
            console.log('❌ Не все поля заполнены');
            return res.status(400).json({ 
                success: false,
                message: 'Заполните все обязательные поля' 
            });
        }

        // Проверяем, существует ли мастер
        const masterCheck = await pool.query(
            'SELECT id FROM masters WHERE id = $1',
            [master_id]
        );

        if (masterCheck.rows.length === 0) {
            console.log('❌ Мастер не найден:', master_id);
            return res.status(404).json({ 
                success: false,
                message: 'Мастер не найден' 
            });
        }

        // Проверяем, не оставлял ли пользователь уже отзыв этому мастеру
        const existingReview = await pool.query(
            'SELECT id FROM reviews WHERE user_id = $1 AND master_id = $2',
            [user_id, master_id]
        );

        if (existingReview.rows.length > 0) {
            console.log('❌ Пользователь уже оставлял отзыв этому мастеру');
            return res.status(409).json({ 
                success: false,
                message: 'Вы уже оставляли отзыв этому мастеру' 
            });
        }

        // Создаем отзыв
        const result = await pool.query(
            `INSERT INTO reviews (user_id, master_id, text, rating) 
             VALUES ($1, $2, $3, $4) 
             RETURNING *`,
            [user_id, master_id, text, rating]
        );

        console.log('✅ Отзыв создан:', result.rows[0]);

        // Обновляем средний рейтинг мастера
        await pool.query(`
            UPDATE masters 
            SET rating = (
                SELECT AVG(rating) FROM reviews WHERE master_id = $1
            )
            WHERE id = $1
        `, [master_id]);

        console.log('✅ Рейтинг мастера обновлен');

        res.status(201).json({ 
            success: true,
            message: 'Отзыв успешно добавлен!',
            review: result.rows[0]
        });
        
    } catch (error) {
        console.error('💥 Ошибка добавления отзыва:', error.message);
        console.error('Stack trace:', error.stack);
        res.status(500).json({ 
            success: false,
            message: 'Внутренняя ошибка сервера: ' + error.message 
        });
    }
});

// Смена пароля
app.post('/api/change-password', authenticateToken, async (req, res) => {
  try {
    const user_id = req.userId;
    const { currentPassword, newPassword } = req.body;

    // Получаем пользователя
    const user = await pool.query('SELECT * FROM users WHERE id = $1', [user_id]);
    
    if (user.rows.length === 0) {
      return res.status(404).json({ message: 'Пользователь не найден' });
    }

    // Проверяем текущий пароль
    const isMatch = await bcrypt.compare(currentPassword, user.rows[0].password);
    if (!isMatch) {
      return res.status(400).json({ message: 'Текущий пароль неверен' });
    }

    // Хешируем новый пароль
    const hashedPassword = await bcrypt.hash(newPassword, 10);

    // Обновляем пароль
    await pool.query('UPDATE users SET password = $1 WHERE id = $2', [hashedPassword, user_id]);

    res.json({ 
      success: true,
      message: 'Пароль успешно изменен' 
    });
  } catch (error) {
    console.error('Ошибка смены пароля:', error.message);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
});

app.listen(PORT, () => {
    console.log(`Сервер запущен на порту ${PORT}`);
});