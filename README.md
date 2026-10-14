# UstaTop — Usta topish platformasi

React + Vite + Tailwind CSS asosidagi responsive o‘quv loyihasi.

## Ishga tushirish
1. ZIPni oching.
2. Shu papkada terminal oching.
3. `npm install`
4. `npm run dev`
5. Terminal ko‘rsatgan localhost manzilini brauzerda oching.

## Demo akkauntlar
- Mijoz: `mijoz@demo.uz`
- Usta: `usta@demo.uz`
- Parol: `demo123`

Supabase sozlanmagan paytda demo ma’lumotlar shu brauzerda saqlanadi. Bu rejim ko‘p qurilmali sinxronlashni bermaydi.

## Haqiqiy baza va ikki qurilma
1. Supabase loyihasi yarating.
2. Dashboard → SQL Editor ichida `supabase/schema.sql` faylini ishga tushiring.
3. Project Settings → API dan Project URL va `anon`/publishable key oling.
4. `.env.example` faylidan `.env` nusxa yarating va qiymatlarni kiriting:
   ```
   VITE_SUPABASE_URL=https://YOUR_PROJECT.supabase.co
   VITE_SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_KEY
   ```
5. `npm install` va `npm run dev`ni qayta ishga tushiring.
6. Saytda alohida mijoz va usta akkauntlarini ro‘yxatdan o‘tkazing.

**Xavfsizlik:** `service_role` yoki maxfiy server kalitini frontendga qo‘ymang. Faqat public `anon`/publishable key ishlatiladi.

## Eslatma
Bu topshirishga mo‘ljallangan o‘quv prototipi. Demo rejimida haqiqiy auth va server ruxsat tekshiruvi yo‘q. Haqiqiy Supabase rejimida RLS siyosatlari buyurtmani mijoz va tegishli ustaga cheklaydi. Ishlab chiqarishga chiqarishdan oldin holat o‘tishlarini, vaqt to‘qnashuvlarini va yakuniy narxni server tomonda atomik tekshiradigan RPC/trigger qo‘shib, update siyosatlarini toraytirish zarur.

## Asosiy fayllar
- `src/App.jsx` — katalog, qidiruv, profil, auth, buyurtmalar va panellar
- `src/index.css` — Tailwind va responsive dizayn
- `src/supabase.js` — backend ulanishi
- `supabase/schema.sql` — jadval, RLS va demo katalog
