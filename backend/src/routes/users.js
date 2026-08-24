import { Router } from 'express';
import bcrypt from 'bcryptjs';
import { pool } from '../db.js';
import { auth,adminOnly } from '../middleware/auth.js';
const router=Router(); router.use(auth,adminOnly);
router.get('/',async(_req,res)=>res.json((await pool.query('SELECT id,name,email,role,active,created_at FROM users ORDER BY created_at DESC')).rows));
router.post('/',async(req,res)=>{
 const {name,email,password,role='staff'}=req.body;
 if(!name||!email||!password) return res.status(400).json({error:'Name, email and password are required.'});
 const hash=await bcrypt.hash(password,12);
 try { const q=await pool.query('INSERT INTO users(name,email,password_hash,role) VALUES($1,$2,$3,$4) RETURNING id,name,email,role,active,created_at',[name,email,hash,role]); res.status(201).json(q.rows[0]); }
 catch(e){ if(e.code==='23505') return res.status(409).json({error:'A user with that email already exists.'}); throw e; }
});
export default router;
