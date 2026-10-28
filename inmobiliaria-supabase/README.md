# Hogar Urbano · Web inmobiliaria (versión compartida con Supabase)

Sitio estático (HTML + Tailwind + JavaScript) con backend en **Supabase**:

- **Datos compartidos:** las propiedades viven en PostgreSQL, no en el navegador.
- **Login real:** Supabase Auth (correo y contraseña) para el equipo.
- **Fotos en la nube:** Supabase Storage (bucket público con CDN).
- **Tiempo real:** cuando alguien del equipo edita, los visitantes con la página abierta ven el cambio al instante.
- **Seguridad:** cualquiera puede *ver* el catálogo; solo los usuarios de la tabla `admins` pueden crear, editar o borrar (políticas RLS).

## 1. Crear el proyecto en Supabase (≈10 min)

1. Crea una cuenta y un proyecto en [supabase.com](https://supabase.com).
2. Ve a **SQL Editor → New query**, pega el contenido de `supabase/schema.sql` y pulsa **Run**.
3. Ve a **Authentication → Users → Add user** y crea un usuario (correo + contraseña, marcando *Auto Confirm User*) por cada miembro del equipo.
4. En **Authentication → Sign In / Providers** desactiva **Allow new users to sign up** (así nadie más puede registrarse).
5. En el **SQL Editor** autoriza a tu equipo como administradores:
   ```sql
   insert into public.admins (user_id)
   select id from auth.users where email in ('persona1@empresa.com','persona2@empresa.com')
   on conflict do nothing;
   ```
6. (Opcional) Ejecuta `supabase/seed.sql` para cargar 4 propiedades de ejemplo.

## 2. Conectar la web

En **Project Settings → API** copia el **Project URL** y la clave **anon public**, y pégalos en `config.js`:

```js
window.APP_CONFIG = {
  SUPABASE_URL: 'https://xxxx.supabase.co',
  SUPABASE_ANON_KEY: 'eyJ...',
  WHATSAPP: '5491100000000'
};
```

> La `anon key` es pública por diseño y puede estar en GitHub: la protección la dan las políticas RLS del paso 1. **Nunca** pegues la clave `service_role`.

## 3. Probar en local

```bash
npx serve .
```

Abre la URL, entra en **Administración** con uno de los usuarios del paso 3 y crea una propiedad.

## 4. GitHub y Vercel

```bash
git init
git add .
git commit -m "Web inmobiliaria con Supabase"
git branch -M main
git remote add origin https://github.com/TU_USUARIO/TU_REPOSITORIO.git
git push -u origin main
```

En [vercel.com/new](https://vercel.com/new) importa el repositorio, deja el preset en **Other** y pulsa **Deploy**. No requiere build ni variables de entorno.

## Cómo trabaja el equipo

- Cada persona entra con su propio correo en **Administración**.
- Los cambios (alta, edición, cambio de estado, borrado, fotos) se guardan en Supabase y se reflejan para todos.
- Para dar de alta a alguien nuevo: créalo en *Authentication → Users* y agrégalo a `admins` (paso 5).

## Notas

- Si un usuario inicia sesión pero no está en `admins`, verá el catálogo pero al guardar recibirá "tu usuario no tiene permisos de administrador".
- Los proyectos del plan gratuito de Supabase se pausan tras una semana sin actividad; se reactivan desde el panel.
- Al borrar una propiedad se eliminan también sus fotos del Storage.
- Tailwind se carga desde su CDN (válido para prototipos). Para producción conviene compilarlo.

