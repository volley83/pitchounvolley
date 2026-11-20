-- Pitchoun' Volley : nombre d'enfants et de clubs inscrits par plateau, affiché dans le bandeau « Prochain plateau ».
-- À lancer une fois dans Supabase › SQL Editor. Relançable sans risque. Ne renvoie que des totaux (aucun nom).
create or replace function pitchoun_compte_inscrits()
returns table(plateau_id bigint, nb_enfants bigint, nb_clubs bigint)
language sql stable security definer set search_path = public as $$
  select i.plateau_id::bigint, count(*)::bigint, count(distinct i.club)::bigint
    from pitchoun_inscriptions i
   group by i.plateau_id;
$$;
revoke all on function pitchoun_compte_inscrits() from public;
grant execute on function pitchoun_compte_inscrits() to anon, authenticated;
