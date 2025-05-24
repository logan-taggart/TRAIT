#!/bin/bash

# === FRONTEND ===
echo "🔁 Starting Frontend setup..."
cd TRAIT-Front

# Check and install dependencies if needed
if [ ! -d "node_modules" ]; then
  echo "📦 Installing frontend dependencies..."
  npm install
else
  echo "✅ Frontend dependencies already installed."
fi

# Start frontend
echo "🚀 Starting frontend..."
npm run start &
FRONT_PID=$!
cd - > /dev/null

# === BACKEND ===
echo "🔁 Starting Backend setup..."
cd TRAIT-Back

# Check for virtual environment
if [ ! -d "venv" ]; then
  echo "🐍 Creating virtual environment for backend..."
  python3 -m venv venv
fi

# Activate venv
source venv/bin/activate

# Install Python dependencies only if not already installed
if [ ! -d "venv/lib" ] || ! pip freeze | grep -qF "$(head -n 1 requirements.txt)"; then
  echo "📦 Installing backend Python dependencies..."
  pip install -r requirements.txt
else
  echo "✅ Backend dependencies already installed."
fi

# Start backend
echo "🚀 Starting backend..."
python3 run.py &
BACK_PID=$!
cd - > /dev/null

# === WAIT FOR INPUT ===
echo ""
echo "🕹️  Press [Enter] to stop both servers..."
read

# === STOP BOTH ===
echo "🛑 Stopping frontend and backend..."
kill $FRONT_PID $BACK_PID

echo "✅ Both processes stopped. Goodbye!"