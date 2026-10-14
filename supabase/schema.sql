-- UstaTop: Supabase SQL Editor ichiga to‘liq nusxalab Run bosing.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  role text not null default 'customer' check (role in ('customer','master')),
  phone text default '',
  created_at timestamptz not null default now()
);
create table if not exists public.masters (
  id text primary key,
  user_id uuid unique references auth.users(id) on delete cascade,
  name text not null,
  job text not null default 'Usta',
  category text not null default 'Boshqa',
  price integer not null default 50000 check (price > 0),
  experience text not null default 'Tajriba ko‘rsatilmagan',
  rating numeric(2,1) not null default 4.8,
  reviews integer not null default 0,
  city text not null default 'Toshkent',
  bio text not null default '',
  services text[] not null default '{}',
  available boolean not null default true,
  emoji text not null default '🛠️',
  color text not null default '#ede9fe',
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);
create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references auth.users(id),
  master_id text not null references public.masters(id),
  customer_name text not null,
  customer_phone text not null,
  address text not null,
  desired_at timestamptz not null,
  service text not null,
  problem text not null,
  initial_price integer not null check (initial_price > 0),
  final_price integer check (final_price is null or final_price > 0),
  proposed_at timestamptz,
  status text not null default 'Yangi' check (status in ('Yangi','Taklif yuborildi','Kelishildi','Bajarilmoqda','Bajarildi','Rad etildi','Bekor qilindi')),
  rejection_reason text,
  history jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists orders_customer_idx on public.orders(customer_id, created_at desc);
create index if not exists orders_master_idx on public.orders(master_id, created_at desc);

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public
as $$
declare v_role text;
declare v_name text;
begin
  v_role := case when new.raw_user_meta_data->>'role' = 'master' then 'master' else 'customer' end;
  v_name := coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email,'@',1));
  insert into public.profiles(id, full_name, role, phone)
  values(new.id, v_name, v_role, coalesce(new.raw_user_meta_data->>'phone',''))
  on conflict (id) do nothing;
  if v_role = 'master' then
    insert into public.masters(id, user_id, name, job, category, price, experience, city, bio, services)
    values(new.id::text, new.id, v_name, 'Usta', 'Boshqa', 50000, 'Yangi usta', 'Toshkent', 'Profil tavsifini boshqaruv panelida to‘ldiring.', array['Umumiy xizmat'])
    on conflict (id) do nothing;
  end if;
  return new;
end;
$$;
drop trigger if exists on_auth_user_created_ustatop on auth.users;
create trigger on_auth_user_created_ustatop after insert on auth.users
for each row execute procedure public.handle_new_user();

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end; $$;
drop trigger if exists orders_updated_at on public.orders;
create trigger orders_updated_at before update on public.orders
for each row execute procedure public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.masters enable row level security;
alter table public.orders enable row level security;

drop policy if exists "profiles select own" on public.profiles;
create policy "profiles select own" on public.profiles for select to authenticated using (id = auth.uid());
drop policy if exists "profiles update own" on public.profiles;
create policy "profiles update own" on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

drop policy if exists "active masters are public" on public.masters;
create policy "active masters are public" on public.masters for select using (is_active = true);
drop policy if exists "master updates own profile" on public.masters;
create policy "master updates own profile" on public.masters for update to authenticated
using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists "master inserts own profile" on public.masters;
create policy "master inserts own profile" on public.masters for insert to authenticated with check (user_id = auth.uid());

drop policy if exists "customer sees own orders and master sees assigned" on public.orders;
create policy "customer sees own orders and master sees assigned" on public.orders for select to authenticated
using (customer_id = auth.uid() or exists (select 1 from public.masters m where m.id = orders.master_id and m.user_id = auth.uid()));
drop policy if exists "customer creates own orders" on public.orders;
create policy "customer creates own orders" on public.orders for insert to authenticated
with check (
 customer_id = auth.uid() and status = 'Yangi' and final_price is null and desired_at > now()
 and exists (select 1 from public.masters m where m.id = orders.master_id and m.is_active = true and m.available = true)
);
drop policy if exists "customer or assigned master updates order" on public.orders;
create policy "customer or assigned master updates order" on public.orders for update to authenticated
using (customer_id = auth.uid() or exists (select 1 from public.masters m where m.id = orders.master_id and m.user_id = auth.uid()))
with check (customer_id = auth.uid() or exists (select 1 from public.masters m where m.id = orders.master_id and m.user_id = auth.uid()));

insert into public.masters(id,name,job,category,price,experience,rating,reviews,city,bio,services,emoji,color,is_active)
values
('m1','Azizbek Karimov','Santexnik','Santexnik',80000,'8 yil',4.9,124,'Toshkent, Chilonzor','Suv quvurlari, kran va hammom jihozlarini sifatli ta’mirlash.',array['Kran ta’mirlash','Quvur o‘rnatish','Unitaz o‘rnatish'],'🔧','#e0f2fe',true),
('m2','Javohir Rasulov','Elektrik','Elektrik',100000,'6 yil',4.8,98,'Toshkent, Yunusobod','Uy elektr tarmoqlari, rozetka va yoritish tizimlari bo‘yicha mutaxassis.',array['Rozetka o‘rnatish','Sim tortish','Chiroq o‘rnatish'],'⚡','#fef3c7',true),
('m3','Sardor Usmonov','Usta-duradgor','Duradgor',120000,'10 yil',5.0,86,'Toshkent, Mirzo Ulug‘bek','Mebel yig‘ish, eshik sozlash va yog‘och buyumlar ta’miri.',array['Mebel yig‘ish','Eshik ta’miri','Tokcha o‘rnatish'],'🪚','#ffedd5',true),
('m4','Bekzod Aliyev','Konditsioner ustasi','Konditsioner',150000,'7 yil',4.9,112,'Toshkent, Yakkasaroy','Konditsionerlarni o‘rnatish, tozalash va mavsumiy tekshiruv.',array['Konditsioner o‘rnatish','Tozalash','Gaz tekshirish'],'❄️','#dcfce7',true),
('m5','Diyorbek Ismoilov','Bo‘yoqchi','Bo‘yoqchi',90000,'5 yil',4.7,73,'Toshkent, Sergeli','Devorlarni tayyorlash, bo‘yash va pardozlash ishlari.',array['Devor bo‘yash','Shpaklyovka','Oboy yopishtirish'],'🎨','#fce7f3',true),
('m6','Otabek Norboyev','Qurilish ustasi','Qurilish',180000,'12 yil',5.0,151,'Toshkent, Olmazor','Mayda qurilish, kafel terish va uy ta’mirlash ishlari.',array['Kafel terish','Mayda ta’mir','Gipsokarton'],'🧱','#ede9fe',true),
('m7','Kamron Ergashev','Maishiy texnika ustasi','Texnika',110000,'6 yil',4.8,65,'Toshkent, Shayxontohur','Maishiy texnikalarni tekshirish va ta’mirlash.',array['Kir yuvish mashinasi','Muzlatkich','Diagnostika'],'🧰','#dbeafe',true),
('m8','Muhammadali Sobirov','Payvandchi','Payvandchi',130000,'9 yil',4.9,91,'Toshkent, Uchtepa','Metall konstruksiya, panjara va eshiklarni payvandlash.',array['Panjara ta’miri','Metall ishlar','Darvoza ta’miri'],'🛠️','#fee2e2',true)
on conflict (id) do nothing;
