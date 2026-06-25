import 'dotenv/config';
import { Pool } from 'pg';
import bcrypt from 'bcrypt';

async function main() {
  const pool = new Pool({ connectionString: process.env.DATABASE_URL });
  const hashed = await bcrypt.hash('test123456', 10);

  try {
    // Delete if exists
    await pool.query("DELETE FROM users WHERE email = 'testmobile@test.com'");
    // Insert
    const res = await pool.query(
      "INSERT INTO users (nama, email, password, role, is_verified) VALUES ($1, $2, $3, $4, $5) RETURNING id, email, is_verified, role",
      ['Test Mobile', 'testmobile@test.com', hashed, 'customer', true]
    );
    console.log('User created:', res.rows[0]);
  } catch (e) {
    console.error('Error:', e.message);
  } finally {
    await pool.end();
  }
}

main();
