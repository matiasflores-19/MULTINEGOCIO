-- =====================================================================
--  SISTEMA DE GESTIÓN MULTI-NEGOCIO  ·  base de datos única
--  Pegá TODO este archivo en Supabase > SQL Editor > New query > Run.
--  Se corre UNA sola vez, en un proyecto de Supabase nuevo.
-- =====================================================================

-- 1) NEGOCIOS Y USUARIOS --------------------------------------------------
create table negocios(
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  creado timestamptz not null default now()
);

-- Cada usuario pertenece a UN negocio. Un negocio puede tener varios usuarios.
create table miembros(
  user_id uuid primary key references auth.users(id) on delete cascade,
  negocio_id uuid not null references negocios(id) on delete cascade
);

-- Devuelve el negocio del usuario que está logueado (null si no tiene).
create function mi_negocio() returns uuid
language sql stable security definer set search_path = public as $$
  select negocio_id from miembros where user_id = auth.uid()
$$;

-- 2) DATOS DE CADA NEGOCIO -------------------------------------------------
-- El negocio se completa solo con el del usuario logueado (default mi_negocio()).
create table ordenes(
  id uuid primary key default gen_random_uuid(),
  negocio_id uuid not null default mi_negocio() references negocios(id) on delete cascade,
  num int,
  data jsonb not null default '{}',
  created_at timestamptz default now(),
  unique (negocio_id, num)
);
create index on ordenes(negocio_id);

create table repuestos(
  id uuid primary key default gen_random_uuid(),
  negocio_id uuid not null default mi_negocio() references negocios(id) on delete cascade,
  data jsonb not null default '{}',
  created_at timestamptz default now()
);
create index on repuestos(negocio_id);

-- Ajustes del negocio (nombre, logo, garantía, condiciones...). Una fila por negocio.
create table config(
  negocio_id uuid primary key default mi_negocio() references negocios(id) on delete cascade,
  data jsonb not null default '{}'
);

-- 3) NÚMERO DE ORDEN PROPIO DE CADA NEGOCIO (1, 2, 3...) ------------------
create table contadores(
  negocio_id uuid primary key references negocios(id) on delete cascade,
  ultimo int not null default 0
);

create function asignar_num() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.num is null then
    insert into contadores(negocio_id, ultimo) values (new.negocio_id, 1)
    on conflict (negocio_id) do update set ultimo = contadores.ultimo + 1
    returning ultimo into new.num;
  else
    insert into contadores(negocio_id, ultimo) values (new.negocio_id, new.num)
    on conflict (negocio_id) do update set ultimo = greatest(contadores.ultimo, new.num);
  end if;
  return new;
end $$;

create trigger ordenes_num before insert on ordenes
for each row execute function asignar_num();

-- 4) SEGURIDAD: cada usuario solo ve y toca lo de SU negocio ---------------
alter table negocios   enable row level security;
alter table miembros   enable row level security;
alter table ordenes    enable row level security;
alter table repuestos  enable row level security;
alter table config     enable row level security;
alter table contadores enable row level security;   -- sin reglas: nadie entra por la API

create policy "ver mi negocio"   on negocios for select to authenticated using (id = mi_negocio());
create policy "ver mi membresía" on miembros for select to authenticated using (user_id = auth.uid());

create policy "ordenes del negocio"   on ordenes   for all to authenticated
  using (negocio_id = mi_negocio()) with check (negocio_id = mi_negocio());
create policy "repuestos del negocio" on repuestos for all to authenticated
  using (negocio_id = mi_negocio()) with check (negocio_id = mi_negocio());
create policy "ajustes del negocio"   on config    for all to authenticated
  using (negocio_id = mi_negocio()) with check (negocio_id = mi_negocio());

-- Los usuarios anónimos (sin login) no pueden hacer nada con estas tablas.
revoke all on negocios, miembros, ordenes, repuestos, config, contadores from anon;
revoke all on contadores from authenticated;

-- 5) FOTOS Y LOGOS ---------------------------------------------------------
-- Cada negocio guarda en su propia carpeta: fotos/<id del negocio>/<archivo>.
-- Las imágenes se pueden ver con su link (nombres imposibles de adivinar),
-- pero solo el negocio dueño puede subir o borrar en su carpeta.
insert into storage.buckets (id, name, public) values ('fotos','fotos',true) on conflict do nothing;

create policy "subir fotos del negocio" on storage.objects for insert to authenticated
  with check (bucket_id = 'fotos' and (storage.foldername(name))[1] = mi_negocio()::text);
create policy "ver fotos del negocio" on storage.objects for select to authenticated
  using (bucket_id = 'fotos' and (storage.foldername(name))[1] = mi_negocio()::text);
create policy "borrar fotos del negocio" on storage.objects for delete to authenticated
  using (bucket_id = 'fotos' and (storage.foldername(name))[1] = mi_negocio()::text);

-- 6) ALTA DE CLIENTES (solo vos, desde el SQL Editor) ----------------------
-- Uso:  select alta_negocio('Gomería Pepe', 'pepe@mail.com');
-- Antes hay que crear el usuario en Authentication > Users > Add user.
create function alta_negocio(p_nombre text, p_email text) returns uuid
language plpgsql security definer set search_path = public, auth as $$
declare u uuid; n uuid;
begin
  select id into u from auth.users where lower(email) = lower(p_email);
  if u is null then
    raise exception 'No existe un usuario con el email %. Crealo antes en Authentication > Users.', p_email;
  end if;
  insert into negocios(nombre) values (p_nombre) returning id into n;
  insert into miembros(user_id, negocio_id) values (u, n);
  return n;
end $$;

-- Agregar otro usuario a un negocio que ya existe.
-- Uso:  select agregar_usuario('otro@mail.com', 'ID-DEL-NEGOCIO');
create function agregar_usuario(p_email text, p_negocio uuid) returns void
language plpgsql security definer set search_path = public, auth as $$
declare u uuid;
begin
  select id into u from auth.users where lower(email) = lower(p_email);
  if u is null then
    raise exception 'No existe un usuario con el email %.', p_email;
  end if;
  insert into miembros(user_id, negocio_id) values (u, p_negocio);
end $$;

-- Estas funciones NO pueden llamarse desde la app: solo desde el SQL Editor.
revoke execute on function alta_negocio(text, text)  from public, anon, authenticated;
revoke execute on function agregar_usuario(text, uuid) from public, anon, authenticated;
revoke execute on function asignar_num() from public, anon, authenticated;
