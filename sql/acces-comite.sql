-- Pitchoun' Volley : accès Comité avec le MOT DE PASSE COMMUN (celui du TIP, des stages, de la facturation…).
-- À lancer une fois dans Supabase › SQL Editor (même projet). Relançable sans risque.
-- Principe : le compte Supabase du Pitchoun' reste en coulisse, mais son mot de passe est
-- toujours recopié depuis le mot de passe commun (private_config / admin_password).
-- Le site ne demande donc plus d'adresse mail : seulement le mot de passe commun.

-- 1) Retenir l'adresse du compte Supabase utilisé par le Pitchoun' (le premier compte créé).
--    Vérifie le résultat de la requête 4 : si ce n'est pas le bon compte, corrige la valeur dans private_config.
insert into private_config(key, value)
select 'pitchoun_auth_email', (select email from auth.users order by created_at limit 1)
where not exists (select 1 from private_config where key = 'pitchoun_auth_email');

-- 2) Recopier automatiquement le mot de passe commun sur ce compte à chaque changement.
create or replace function pitchoun_sync_auth_pwd() returns trigger
language plpgsql security definer set search_path = public, extensions as $$
begin
  if new.key = 'admin_password' then
    update auth.users
       set encrypted_password = extensions.crypt(new.value, extensions.gen_salt('bf')), updated_at = now()
     where email = (select value from public.private_config where key = 'pitchoun_auth_email');
  end if;
  return new;
end $$;
drop trigger if exists pitchoun_sync_auth_pwd on private_config;
create trigger pitchoun_sync_auth_pwd after insert or update of value on private_config
  for each row execute function pitchoun_sync_auth_pwd();

-- Mise à jour immédiate avec le mot de passe commun actuel.
update auth.users
   set encrypted_password = extensions.crypt((select value from private_config where key = 'admin_password'), extensions.gen_salt('bf')),
       updated_at = now()
 where email = (select value from private_config where key = 'pitchoun_auth_email');

-- 3) Connexion : renvoie l'adresse du compte seulement si le mot de passe commun est juste.
create or replace function pitchoun_login_email(pwd text) returns text
language sql security definer set search_path = public as $$
  select value from private_config
   where key = 'pitchoun_auth_email'
     and exists (select 1 from private_config where key = 'admin_password' and value = pwd);
$$;
revoke all on function pitchoun_login_email(text) from public;
grant execute on function pitchoun_login_email(text) to anon, authenticated;

-- 4) Contrôle : le compte retenu
select value as compte_pitchoun from private_config where key = 'pitchoun_auth_email';
