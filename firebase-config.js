// ============================================================
//  ポーカーチップ管理 - 共通設定・ユーティリティ
// ============================================================

const FIREBASE_CONFIG = {
  apiKey:            "AIzaSyBJiK4ehCuVW0-eRFH5Ew7L-e2KcKGKfZo",
  authDomain:        "warikan-app-c48cb.firebaseapp.com",
  projectId:         "warikan-app-c48cb",
  storageBucket:     "warikan-app-c48cb.firebasestorage.app",
  messagingSenderId: "68284401289",
  appId:             "1:68284401289:web:3bd22bfd8788bf95b52858",
};

const ROOMS_COLLECTION  = 'poker_rooms';
const HISTORY_KEY       = 'poker_rooms_history';

let _db   = null;
let _auth = null;

function initFirebase() {
  if (firebase.apps.length === 0) firebase.initializeApp(FIREBASE_CONFIG);
  _db   = _db   || firebase.firestore();
  _auth = _auth || firebase.auth();
  return { db: _db, auth: _auth };
}

// 匿名認証済みユーザーを返す（未認証なら匿名ログイン実行）
async function ensureAuth() {
  const { auth } = initFirebase();
  return new Promise((resolve, reject) => {
    const unsub = auth.onAuthStateChanged(async (user) => {
      unsub();
      if (user) { resolve(user); return; }
      try {
        const cred = await auth.signInAnonymously();
        resolve(cred.user);
      } catch (err) {
        reject(err);
      }
    });
  });
}

// 6桁英数字コード生成（紛らわしい文字を除外）
function generateRoomCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let code = '';
  for (let i = 0; i < 6; i++) code += chars[Math.floor(Math.random() * chars.length)];
  return code;
}

function esc(str) {
  return String(str)
    .replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;')
    .replace(/"/g,'&quot;').replace(/'/g,'&#39;');
}

const AVATAR_COLORS = [
  '#16a34a','#0ea5e9','#7c3aed','#dc2626',
  '#d97706','#0891b2','#db2777','#65a30d',
];

function colorFor(str) {
  let h = 0;
  for (let i = 0; i < str.length; i++) h = str.charCodeAt(i) + ((h << 5) - h);
  return AVATAR_COLORS[Math.abs(h) % AVATAR_COLORS.length];
}

function initials(name) { return name.slice(0, 1).toUpperCase(); }

function renderIcons() {
  if (window.lucide) lucide.createIcons();
}

function showToast(msg) {
  const t = document.getElementById('toast');
  if (!t) return;
  t.textContent = msg;
  t.classList.add('show');
  setTimeout(() => t.classList.remove('show'), 2500);
}

// 直近ルーム履歴（localStorage）
function loadHistory() {
  try { return JSON.parse(localStorage.getItem(HISTORY_KEY)) || []; } catch { return []; }
}
function saveHistory(room) {
  const list = loadHistory().filter(r => r.id !== room.id);
  list.unshift({ ...room, lastAt: new Date().toISOString() });
  localStorage.setItem(HISTORY_KEY, JSON.stringify(list.slice(0, 20)));
}
function deleteHistory(id) {
  localStorage.setItem(HISTORY_KEY, JSON.stringify(loadHistory().filter(r => r.id !== id)));
}
