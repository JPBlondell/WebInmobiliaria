-- ============================================================
-- Hogar Urbano · esquema Supabase
-- Pégalo completo en: Supabase > SQL Editor > New query > Run
-- ============================================================

-- 1) Tabla de propiedades
create table if not exists public.properties (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null default '',
  price numeric not null check (price >= 0),
  currency text not null default 'USD' check (currency in ('USD','EUR','local')),
  address text not null default '',
  city text not null default '',
  state text not null default '',
  bedrooms integer not null default 0,
  bathrooms integer not null default 0,
  area_sqm numeric not null default 0,
  parking_spaces integer not null default 0,
  images text[] not null default '{}',
  featured_image text,
  status text not null default 'disponible' check (status in ('disponible','reservada','vendida')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 2) Lista de administradores (usuarios autorizados a editar)
create table if not exists public.admins (
  user_id uuid primary key references auth.users(id) on delete cascade
);

create or replace function public.is_admin()
returns boolean language sql security definer stable set search_path = public as $$
  select exists (select 1 from public.admins where user_id = auth.uid());
$$;

-- 3) updated_at automático
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end; $$;

drop trigger if exists trg_touch_properties on public.properties;
create trigger trg_touch_properties before update on public.properties
for each row execute function public.touch_updated_at();

-- 4) Seguridad (RLS): cualquiera lee, solo administradores escriben
alter table public.properties enable row level security;
alter table public.admins enable row level security;  -- sin políticas: nadie la lee por la API

drop policy if exists "lectura publica" on public.properties;
create policy "lectura publica" on public.properties for select using (true);

drop policy if exists "admins insertan" on public.properties;
create policy "admins insertan" on public.properties for insert to authenticated with check (public.is_admin());

drop policy if exists "admins actualizan" on public.properties;
create policy "admins actualizan" on public.properties for update to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "admins eliminan" on public.properties;
create policy "admins eliminan" on public.properties for delete to authenticated using (public.is_admin());

-- 5) Tiempo real: los cambios llegan al instante a todos los visitantes
do $$ begin
  alter publication supabase_realtime add table public.properties;
exception when duplicate_object then null; end $$;

-- 6) Almacenamiento de imágenes (bucket público)
insert into storage.buckets (id, name, public) values ('property-images','property-images', true)
on conflict (id) do nothing;

drop policy if exists "imagenes lectura" on storage.objects;
create policy "imagenes lectura" on storage.objects for select using (bucket_id = 'property-images');

drop policy if exists "imagenes subir" on storage.objects;
create policy "imagenes subir" on storage.objects for insert to authenticated
  with check (bucket_id = 'property-images' and public.is_admin());

drop policy if exists "imagenes actualizar" on storage.objects;
create policy "imagenes actualizar" on storage.objects for update to authenticated
  using (bucket_id = 'property-images' and public.is_admin());

drop policy if exists "imagenes borrar" on storage.objects;
create policy "imagenes borrar" on storage.objects for delete to authenticated
  using (bucket_id = 'property-images' and public.is_admin());

-- 7) Autoriza a tu equipo (DESPUÉS de crear sus usuarios en Authentication > Users)
-- insert into public.admins (user_id)
-- select id from auth.users where email in ('persona1@empresa.com','persona2@empresa.com')
-- on conflict do nothing;
