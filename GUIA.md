# Guía: poner en marcha el sistema multi-negocio

Un solo código, un solo Supabase, muchos negocios. Cada uno ve únicamente lo suyo.
Esto se arma en un proyecto NUEVO: no toca el de TecnoSpress.

## 1. Supabase (una sola vez)
1. supabase.com > New project (anotá la contraseña de la base).
2. SQL Editor > New query > pegá TODO `supabase-multi.sql` > Run.
3. Authentication > Providers > Email: desactivá "Allow new users to sign up" (solo vos das de alta).
4. Project Settings > API: copiá la **Project URL** y la **anon public key**.

## 2. Configurar la app
Abrí `config.js` y pegá esos dos datos. Nada más.

## 3. Subir a Cloudflare Pages
1. Creá un repositorio en GitHub y subí todos los archivos de esta carpeta (menos `supabase-multi.sql`, `alta-cliente.sql` y `GUIA.md` si preferís).
2. dash.cloudflare.com > Workers & Pages > Create > Pages > Connect to Git > elegí el repo.
3. Build command: vacío. Output directory: `/` (raíz). Deploy.
4. Después, en Custom domains, podés agregar el dominio de cada cliente.

## 4. Dar de alta un cliente
1. Authentication > Users > Add user (email + contraseña, "Auto Confirm User").
2. Corré `alta-cliente.sql` con el nombre y el email.
3. El cliente entra, y en ⚙️ Ajustes carga su logo, garantía y condiciones.

## 5. Probalo con dos negocios de prueba
Creá 2 usuarios y 2 negocios, cargá una orden en cada uno y comprobá que ninguno ve lo del otro.

## Cosas para saber
- **Fotos**: se ven con su link (nombre imposible de adivinar), pero no se pueden listar ni subir en la carpeta de otro negocio. No son privadas "de verdad".
- **Costos**: Cloudflare Pages gratis; Supabase Pro ~US$25/mes fijo para todos los clientes (el plan gratis pausa el proyecto por inactividad, no sirve para clientes).
- **App instalada con marca propia** (APK/.exe por cliente): requiere un proyecto de Pages aparte por cliente.
- **TecnoSpress**: se migra después como un negocio más. Su Supabase y su URL actuales no se tocan (el APK y el .exe apuntan ahí).
