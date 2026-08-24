import bcrypt from 'bcryptjs'; import 'dotenv/config'; import { pool } from './db.js';
const hash=await bcrypt.hash('Admin123!',12);
await pool.query(`INSERT INTO users(name,email,password_hash,role) VALUES('System Administrator','admin@buildtrack.com',$1,'admin') ON CONFLICT(email) DO UPDATE SET password_hash=EXCLUDED.password_hash`,[hash]);
await pool.query(`INSERT INTO projects(name,client_name,location,status,progress,start_date,end_date) VALUES
('Adum Office Complex','Asante Holdings','Adum, Kumasi','In Progress',72,CURRENT_DATE-60,CURRENT_DATE+90),
('Ahodwo Residence','Private Client','Ahodwo, Kumasi','In Progress',46,CURRENT_DATE-30,CURRENT_DATE+120)
ON CONFLICT DO NOTHING`);
console.log('Seed complete: admin@buildtrack.com / Admin123!'); await pool.end();
