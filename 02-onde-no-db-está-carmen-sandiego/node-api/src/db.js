// ADR-005: Mongoose 8. MONGO_URL vem do compose (rede interna: mongo:27017).
import mongoose from 'mongoose';

export async function conectar() {
  const url = process.env.MONGO_URL || 'mongodb://127.0.0.1:27017/carmen';
  await mongoose.connect(url);
  console.log(`[db] conectado: ${url}`);
  return mongoose.connection;
}