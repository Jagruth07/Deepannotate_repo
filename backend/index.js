const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const { Server } = require('socket.io');
const http = require('http');
require('dotenv').config();

const app = express();
const server = http.createServer(app);
const io = new Server(server, { cors: { origin: '*' } });

app.use(cors());
app.use(express.json());

// Initialize PostgreSQL Pool
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.DATABASE_URL?.includes('supabase') ? { rejectUnauthorized: false } : false
});

// Initialize AWS S3 Client
const s3Client = new S3Client({
  region: process.env.AWS_REGION || 'us-east-1',
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID || '',
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || '',
  }
});

io.on('connection', (socket) => {
  console.log('A client connected for real-time updates');
});

// 1. Setup Database Tables Endpoint (Run once)
app.get('/init-db', async (req, res) => {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS tasks (
        id SERIAL PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
      CREATE TABLE IF NOT EXISTS submissions (
        id SERIAL PRIMARY KEY,
        task_id INTEGER REFERENCES tasks(id) ON DELETE CASCADE,
        file_url TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);
    res.json({ message: 'Database initialized successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// 2. Create Task
app.post('/task', async (req, res) => {
  try {
    const { title, description } = req.body;
    const result = await pool.query(
      'INSERT INTO tasks (title, description) VALUES ($1, $2) RETURNING *',
      [title, description]
    );
    const newTask = result.rows[0];
    io.emit('new_task', newTask); // Real-time emit to Flutter Admin
    res.status(201).json(newTask);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// 3. Get All Tasks
app.get('/tasks', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM tasks ORDER BY created_at DESC');
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// 4. Create Submission
app.post('/submission', async (req, res) => {
  try {
    const { task_id, file_url } = req.body;
    const result = await pool.query(
      'INSERT INTO submissions (task_id, file_url) VALUES ($1, $2) RETURNING *',
      [task_id, file_url]
    );
    const newSubmission = result.rows[0];
    
    // Also fetch the task title to emit complete info to admin dashboard
    const taskTitleRes = await pool.query('SELECT title FROM tasks WHERE id = $1', [task_id]);
    const fullSubmissionData = {
      ...newSubmission,
      task_title: taskTitleRes.rows[0] ? taskTitleRes.rows[0].title : 'Unknown Task'
    };
    
    io.emit('new_submission', fullSubmissionData); // Real-time emit to Flutter Admin
    res.status(201).json(newSubmission);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// 5. Get All Submissions (For Admin View)
app.get('/submissions', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT s.*, t.title as task_title 
      FROM submissions s 
      JOIN tasks t ON s.task_id = t.id 
      ORDER BY s.created_at DESC
    `);
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// 6. Generate AWS S3 Pre-signed URL
app.get('/s3-upload-url', async (req, res) => {
  try {
    const { fileName, fileType } = req.query;
    if (!fileName || !fileType) {
      return res.status(400).json({ error: 'fileName and fileType query parameters required' });
    }

    const key = `submissions/${Date.now()}_${fileName}`;
    const command = new PutObjectCommand({
      Bucket: process.env.AWS_S3_BUCKET,
      Key: key,
      ContentType: fileType,
    });
    
    // URL valid for 1 hour
    const uploadUrl = await getSignedUrl(s3Client, command, { expiresIn: 3600 });
    const publicUrl = `https://${process.env.AWS_S3_BUCKET}.s3.${process.env.AWS_REGION}.amazonaws.com/${key}`;
    
    res.json({ uploadUrl, publicUrl });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`Backend server running on port ${PORT}`);
});
