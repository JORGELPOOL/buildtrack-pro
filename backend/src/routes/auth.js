import { Router } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { pool } from '../db.js';
const router=Router();
router.post('/login',async(req,res)=>{
  const {email,password}=req.body;
  const q=await pool.query('SELECT id,name,email,password_hash,role FROM users WHERE lower(email)=lower($1) AND active=true',[email]);
  const user=q.rows[0];
  if(!user || !(await bcrypt.compare(password,user.password_hash))) return res.status(401).json({error:'Invalid email or password.'});
  const token=jwt.sign({id:user.id,email:user.email,role:user.role},process.env.JWT_SECRET,{expiresIn:'12h'});
  res.json({token,user:{id:user.id,name:user.name,email:user.email,role:user.role}});
});
export default router;
