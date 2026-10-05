-- ALTA DE UN CLIENTE NUEVO (corré esto en Supabase > SQL Editor)
-- Antes: Authentication > Users > Add user > Create new user
--        (poné su email y una contraseña, y tildá "Auto Confirm User").

select alta_negocio('Nombre del negocio', 'email@delcliente.com');

-- Agregar otro empleado al mismo negocio (copiá el ID que devolvió la línea de arriba):
-- select agregar_usuario('empleado@mail.com', 'ID-DEL-NEGOCIO');

-- Ver todos tus clientes:
-- select n.nombre, n.creado, u.email from negocios n join miembros m on m.negocio_id=n.id join auth.users u on u.id=m.user_id order by n.creado;
