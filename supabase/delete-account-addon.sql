-- Optional hard-delete helper for the delete-account Edge Function.
create or replace function public.delete_my_couple_data_as_admin(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare c uuid;
begin
  select couple_id into c from public.profiles where user_id = p_user_id limit 1;
  if c is not null then delete from public.couples where id = c; end if;
end;
$$;
revoke all on function public.delete_my_couple_data_as_admin(uuid) from public;
