export const API='http://127.0.0.1:4000';
export async function api(path, opts={}){
  const res = await fetch(API+path,{credentials:'include',...opts});
  if (!res.ok)
    throw await res.json().catch(() => ({ error: res.statusText }));
  return res.json();
}
export const qs=(s)=>document.querySelector(s);
export const qsa=(s)=>[...document.querySelectorAll(s)];
export function toast(msg, type='ok', ms=2000){
  const el=document.createElement('div');
  el.className=`toast ${type}`;
  el.textContent=typeof msg==='string'?msg:(msg.error||'เกิดข้อผิดพลาด');
  document.body.appendChild(el);
  setTimeout(()=>{el.style.opacity='0'; setTimeout(()=>el.remove(),300)}, ms);
}
export function bust(url){ const u=new URL(url, location.origin); u.searchParams.set('ts', Date.now()); return u.toString(); }
export async function logout(){ try{ await api('/api/auth/logout',{method:'POST'}); location.href='home.html'; }catch(e){ location.href='home.html'; } }

export async function confirmDialog(message){
  return new Promise((resolve)=>{
    const wrap=document.createElement('div'); wrap.className='modal-backdrop show';
    wrap.innerHTML=`<div class="modal"><div style="margin-bottom:12px">${message}</div>
      <div class="row"><span class="spacer"></span><button class="btn-secondary" id="cCancel">ปิด</button><button id="cOk">ยืนยัน</button></div></div>`;
    document.body.appendChild(wrap);
    wrap.onclick=(e)=>{ if(e.target===wrap) {document.body.removeChild(wrap); resolve(false);} };
    wrap.querySelector('#cCancel').onclick=()=>{document.body.removeChild(wrap); resolve(false);};
    wrap.querySelector('#cOk').onclick=()=>{document.body.removeChild(wrap); resolve(true);};
  });
}

export function imgUrl(u){
  if(!u) return '';
  if(/^https?:\/\//i.test(u)) return u;
  if(u.startsWith('/')) return API + u;
  return API + '/uploads/posts/' + u.replace(/^\/+/,'');
}

export function avatarUrl(u){
  // Robustly build avatar URL and provide a safe fallback
  const fallback = 'https://www.pngall.com/wp-content/uploads/5/Profile-PNG-File.png';
  if(!u || String(u).trim()==='' || String(u).toLowerCase()==='null') return fallback;
  const s = String(u).trim();
  if(/^https?:\/\//i.test(s)) return s;
  if(s.startsWith('/')) return API + s; // already absolute path from backend
  // If contains 'avatars' directory, strip leading segments and prefix uploads/avatars
  if(/avatars/i.test(s)){
    const fname = s.split(/[/\\]/).pop();
    return API + '/uploads/avatars/' + fname;
  }
  // Default: treat as filename stored for avatar
  const fname = s.split(/[/\\]/).pop();
  return API + '/uploads/avatars/' + fname;
}
export function imageList(val){
  if(!val) return [];
  try{
    if(Array.isArray(val)) return val;
    if(typeof val === 'string' && val.trim().startsWith('[')) return JSON.parse(val);
  }catch(e){}
  if(typeof val === 'string'){
    if(val.includes(',')) return val.split(',').map(s=>s.trim()).filter(Boolean);
    return [val];
  }
  return [];
}


export async function getMe() {
  try { return await api('/api/profile/me'); } catch(e){ return null; }
}
export function requireLoginOrToast(me){
  if(!me){ toast('กรุณา login','err'); return false; }
  return true;
}
