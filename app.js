// ============================================================
// BWAPMS — app.js
// Supabase Auth + Tier-based redirect logic
// ============================================================

// ── 1. Supabase সংযোগ ──────────────────────────────────────
const SUPABASE_URL  = 'https://lznqbrynniziquzawpfs.supabase.co';
const SUPABASE_ANON = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx6bnFicnlubml6aXF1emF3cGZzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODIyNzQ3NTMsImV4cCI6MjA5Nzg1MDc1M30.LBCQP8cH0QJYZqF4ieu3rMGObslTSI2lpW9pjkuYfmc';

const { createClient } = supabase;
const db = createClient(SUPABASE_URL, SUPABASE_ANON);

// ── 2. Page লোড হলে: আগে থেকে login করা থাকলে redirect করো ─
window.addEventListener('DOMContentLoaded', async () => {

  // Password toggle button
  document.getElementById('togglePw').addEventListener('click', togglePassword);

  // Enter key দিয়েও login হবে
  document.getElementById('passwordInput').addEventListener('keydown', (e) => {
    if (e.key === 'Enter') handleLogin();
  });
  document.getElementById('emailInput').addEventListener('keydown', (e) => {
    if (e.key === 'Enter') handleLogin();
  });

  // Session আছে কিনা চেক করো
  const { data: { session } } = await db.auth.getSession();
  if (session) {
    // আগে থেকে login করা আছে — সরাসরি dashboard-এ পাঠাও
    await redirectByTier();
  }
});

// ── 3. Login ফাংশন ─────────────────────────────────────────
async function handleLogin() {
  const email    = document.getElementById('emailInput').value.trim();
  const password = document.getElementById('passwordInput').value;

  // Basic validation
  if (!email || !password) {
    showError('ইমেইল এবং পাসওয়ার্ড দুটোই দিতে হবে।');
    return;
  }

  // Loading state চালু করো
  setLoading(true);
  hideError();

  try {
    // Supabase-এ login করো
    const { data, error } = await db.auth.signInWithPassword({ email, password });

    if (error) {
      // Login ব্যর্থ হয়েছে
      handleAuthError(error);
      setLoading(false);
      return;
    }

    // Login সফল — tier দেখে redirect করো
    await redirectByTier();

  } catch (err) {
    showError('সংযোগে সমস্যা হয়েছে। ইন্টারনেট চেক করুন এবং আবার চেষ্টা করুন।');
    setLoading(false);
  }
}

// ── 4. Tier অনুযায়ী Dashboard-এ পাঠানো ───────────────────
async function redirectByTier() {
  try {
    // Supabase helper function call করো
    const { data, error } = await db.rpc('get_my_tier');

    if (error || data === null) {
      // Tier পাওয়া গেল না — employee_master-এ রেকর্ড নেই বা সমস্যা
      await db.auth.signOut();
      showError(
        'আপনার অ্যাকাউন্ট সিস্টেমে নেই বা নিষ্ক্রিয়। ' +
        'System Administrator-এর সাথে যোগাযোগ করুন।'
      );
      setLoading(false);
      return;
    }

    const tier = parseInt(data);

    // Tier অনুযায়ী সঠিক পেজে পাঠাও
    if (tier === 1) {
      window.location.href = 'dashboard-tier1.html';   // Tier 1: Executive Dashboard
    } else if (tier === 2) {
      window.location.href = 'dashboard-tier2.html';   // Tier 2: Admin Dashboard
    } else if (tier === 3) {
      window.location.href = 'dashboard-tier3.html';   // Tier 3: Senior Staff Dashboard
    } else if (tier === 4) {
      window.location.href = 'dashboard-tier4.html';   // Tier 4: Staff Dashboard
    } else {
      await db.auth.signOut();
      showError('অপরিচিত Tier। Administrator-কে জানান।');
      setLoading(false);
    }

  } catch (err) {
    showError('Tier যাচাই করতে সমস্যা হয়েছে। আবার চেষ্টা করুন।');
    setLoading(false);
  }
}

// ── 5. Error বার্তা সুন্দরভাবে দেখানো ─────────────────────
function handleAuthError(error) {
  const msg = error.message || '';

  if (
    msg.includes('Invalid login credentials') ||
    msg.includes('invalid_credentials')
  ) {
    showError('ইমেইল বা পাসওয়ার্ড ভুল। আবার চেক করুন।');
  } else if (msg.includes('Email not confirmed')) {
    showError('আপনার ইমেইল এখনো নিশ্চিত করা হয়নি। Administrator-কে জানান।');
  } else if (msg.includes('Too many requests')) {
    showError(
      'অনেকবার ভুল চেষ্টার কারণে অ্যাকাউন্ট সাময়িক বন্ধ। ' +
      'কিছুক্ষণ পরে আবার চেষ্টা করুন।'
    );
  } else if (msg.includes('User not found')) {
    showError('এই ইমেইলে কোনো অ্যাকাউন্ট নেই।');
  } else {
    showError('Login করা যায়নি: ' + msg);
  }
}

// ── 6. UI Helper ফাংশন ─────────────────────────────────────

function showError(message) {
  const box  = document.getElementById('errorBox');
  const text = document.getElementById('errorText');
  text.textContent = message;
  box.style.display = 'block';
}

function hideError() {
  document.getElementById('errorBox').style.display = 'none';
}

function setLoading(isLoading) {
  const btn     = document.getElementById('loginBtn');
  const btnText = document.getElementById('btnText');
  const spinner = document.getElementById('btnSpinner');

  if (isLoading) {
    btn.disabled       = true;
    btnText.style.display  = 'none';
    spinner.style.display  = 'flex';
  } else {
    btn.disabled       = false;
    btnText.style.display  = 'inline';
    spinner.style.display  = 'none';
  }
}

function togglePassword() {
  const input = document.getElementById('passwordInput');
  const isHidden = input.type === 'password';
  input.type = isHidden ? 'text' : 'password';

  // Icon পরিবর্তন
  const icon = document.getElementById('eyeIcon');
  if (isHidden) {
    // Eye-off icon (password দেখা যাচ্ছে)
    icon.innerHTML = `
      <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94"/>
      <path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19"/>
      <line x1="1" y1="1" x2="23" y2="23"/>
    `;
  } else {
    // Eye icon (password লুকানো)
    icon.innerHTML = `
      <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/>
      <circle cx="12" cy="12" r="3"/>
    `;
  }
}
