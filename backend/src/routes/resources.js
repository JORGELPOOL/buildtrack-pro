import { Router } from 'express';
import { pool } from '../db.js';
import { auth } from '../middleware/auth.js';
const router=Router(); router.use(auth);
const configs={
 projects:['projects',['name','client_name','location','status','progress','start_date','end_date']],
 budgets:['budgets',['project_id','category','budget_amount','actual_amount']],
 attendance:['attendance',['project_id','worker_name','attendance_date','status','check_in','check_out']],
 materials:['materials',['project_id','name','unit','quantity_received','quantity_used','reorder_level']],
 photos:['progress_photos',['project_id','photo_url','caption','taken_at']],
 reports:['client_reports',['project_id','title','summary','report_date']]
};
for(const [path,[table,fields]] of Object.entries(configs)){
 router.get('/'+path,async(_req,res)=>res.json((await pool.query(`SELECT * FROM ${table} ORDER BY id DESC`)).rows));
 router.post('/'+path,async(req,res)=>{
  const vals=fields.map(f=>req.body[f]??null); const nums=fields.map((_,i)=>'$'+(i+1)).join(',');
  const q=await pool.query(`INSERT INTO ${table}(${fields.join(',')}) VALUES(${nums}) RETURNING *`,vals); res.status(201).json(q.rows[0]);
 });
}
export default router;
