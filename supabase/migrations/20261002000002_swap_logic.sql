-- =====================================================================
-- بدّلها — منطق التبادل والصلاحيات
-- كل تغيير لحالة عرض أو إعلان محجوز يمر عبر دوال security definer
-- هنا، حتى لا يستطيع العميل تجاوز القواعد.
-- =====================================================================

-- ---------------------------------------------------------------------
-- دوال مساعدة
-- ---------------------------------------------------------------------
create function is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce((select is_admin from profiles where id = auth.uid()), false)
$$;

create function is_blocked_between(a uuid, b uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from blocks
    where (blocker_id = a and blocked_id = b) or (blocker_id = b and blocked_id = a)
  )
$$;

-- يتحقق من أن المستدعي مسجّل، له ملف، وغير محظور. يُرجع معرّفه.
create function require_active_user() returns uuid
language plpgsql stable security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_banned boolean;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  select is_banned into v_banned from profiles where id = v_uid;
  if not found then
    raise exception 'profile_required' using errcode = 'P0001';
  end if;
  if v_banned then
    raise exception 'account_banned' using errcode = 'P0001';
  end if;
  return v_uid;
end $$;

create function notify(p_user uuid, p_type text, p_payload jsonb)
returns void
language sql security definer set search_path = public as $$
  insert into notifications (user_id, type, payload) values (p_user, p_type, p_payload);
$$;

-- علامة داخلية تسمح لدوال RPC بتغيير حالات الإعلانات المحجوزة
create function in_internal_op() returns boolean
language sql stable as $$
  select coalesce(current_setting('badelha.internal', true), '') = 'on'
$$;

create function begin_internal_op() returns void
language sql as $$
  select set_config('badelha.internal', 'on', true);
$$;

-- ---------------------------------------------------------------------
-- حماية انتقالات حالة الإعلان من العميل
-- المالك يستطيع: active ↔ removed، و expired → active (تجديد).
-- reserved / swapped تأتي فقط من دوال التبادل.
-- ---------------------------------------------------------------------
create function guard_listing_status() returns trigger
language plpgsql as $$
begin
  if new.status is distinct from old.status and not in_internal_op() and not is_admin() then
    if not (
      (old.status = 'active'  and new.status = 'removed') or
      (old.status = 'expired' and new.status in ('active', 'removed')) or
      (old.status = 'removed' and new.status = 'active')
    ) then
      raise exception 'invalid_status_transition % -> %', old.status, new.status
        using errcode = 'P0001';
    end if;
  end if;
  if new.owner_id is distinct from old.owner_id then
    raise exception 'owner_immutable' using errcode = 'P0001';
  end if;
  return new;
end $$;

create trigger listings_guard_status before update on listings
  for each row execute function guard_listing_status();

-- ---------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------
alter table governorates     enable row level security;
alter table areas            enable row level security;
alter table categories       enable row level security;
alter table profiles         enable row level security;
alter table listings         enable row level security;
alter table listing_wants    enable row level security;
alter table favorites        enable row level security;
alter table blocks           enable row level security;
alter table swap_offers      enable row level security;
alter table swap_offer_items enable row level security;
alter table conversations    enable row level security;
alter table messages         enable row level security;
alter table ratings          enable row level security;
alter table reports          enable row level security;
alter table notifications    enable row level security;
alter table device_tokens    enable row level security;

-- البيانات المرجعية: قراءة للجميع (حتى صفحة الويب العامة للإعلان)
create policy ref_read on governorates for select using (true);
create policy ref_read on areas        for select using (true);
create policy ref_read on categories   for select using (true);
create policy admin_write on governorates for all using (is_admin()) with check (is_admin());
create policy admin_write on areas        for all using (is_admin()) with check (is_admin());
create policy admin_write on categories   for all using (is_admin()) with check (is_admin());

-- profiles
create policy profiles_read on profiles for select using (true);
create policy profiles_insert on profiles for insert
  with check (id = auth.uid());
create policy profiles_update on profiles for update
  using (id = auth.uid() or is_admin()) with check (id = auth.uid() or is_admin());

-- listings: الإعلانات النشطة مرئية للجميع، إلا إذا كان بينك وبين صاحبها حظر.
create policy listings_read on listings for select using (
  owner_id = auth.uid()
  or is_admin()
  or (
    status = 'active'
    and (auth.uid() is null or not is_blocked_between(auth.uid(), owner_id))
  )
  -- الأطراف في عرض تبادل يرون الإعلانات المحجوزة/المتبادلة الخاصة به
  or exists (
    select 1 from swap_offer_items i join swap_offers o on o.id = i.offer_id
    where i.listing_id = listings.id and auth.uid() in (o.sender_id, o.receiver_id)
  )
);
create policy listings_insert on listings for insert with check (
  owner_id = auth.uid()
  and status = 'active'
  and not exists (select 1 from profiles where id = auth.uid() and is_banned)
);
create policy listings_update on listings for update
  using (owner_id = auth.uid() or is_admin())
  with check (owner_id = auth.uid() or is_admin());

create policy wants_read on listing_wants for select using (true);
create policy wants_write on listing_wants for all
  using (exists (select 1 from listings l where l.id = listing_id and l.owner_id = auth.uid()))
  with check (exists (select 1 from listings l where l.id = listing_id and l.owner_id = auth.uid()));

create policy favorites_own on favorites for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy blocks_own on blocks for all
  using (blocker_id = auth.uid()) with check (blocker_id = auth.uid());

-- العروض: للأطراف فقط. لا إدخال/تعديل مباشر (عبر RPC فقط).
create policy offers_read on swap_offers for select
  using (auth.uid() in (sender_id, receiver_id) or is_admin());
create policy offer_items_read on swap_offer_items for select using (
  exists (select 1 from swap_offers o where o.id = offer_id
          and (auth.uid() in (o.sender_id, o.receiver_id) or is_admin()))
);

create policy conversations_read on conversations for select
  using (auth.uid() in (user_a, user_b) or is_admin());

create policy messages_read on messages for select using (
  exists (select 1 from conversations c where c.id = conversation_id
          and (auth.uid() in (c.user_a, c.user_b) or is_admin()))
);
create policy messages_insert on messages for insert with check (
  sender_id = auth.uid()
  and exists (
    select 1 from conversations c join swap_offers o on o.id = c.offer_id
    where c.id = conversation_id
      and auth.uid() in (c.user_a, c.user_b)
      and o.status in ('accepted', 'completed')
      and not is_blocked_between(c.user_a, c.user_b)
  )
  and not exists (select 1 from profiles where id = auth.uid() and is_banned)
);
create policy messages_mark_read on messages for update using (
  sender_id <> auth.uid()
  and exists (select 1 from conversations c where c.id = conversation_id
              and auth.uid() in (c.user_a, c.user_b))
);

create policy ratings_read on ratings for select using (true);

create policy reports_insert on reports for insert with check (reporter_id = auth.uid());
create policy reports_read on reports for select using (reporter_id = auth.uid() or is_admin());
create policy reports_admin on reports for update using (is_admin()) with check (is_admin());

create policy notifications_own on notifications for select using (user_id = auth.uid());
create policy notifications_mark on notifications for update using (user_id = auth.uid());

create policy device_tokens_own on device_tokens for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---------------------------------------------------------------------
-- صلاحيات الأعمدة: العميل لا يستطيع تعديل التقييم/الحظر/الإدارة
-- ---------------------------------------------------------------------
revoke insert, update on profiles from authenticated, anon;
grant insert (id, display_name, avatar_path, governorate_id, area_id, bio) on profiles to authenticated;
grant update (display_name, avatar_path, governorate_id, area_id, bio) on profiles to authenticated;

revoke update on listings from authenticated, anon;
grant update (title, description, category_id, condition, estimated_value, images,
              governorate_id, area_id, wants_anything, wants_note,
              accepts_cash_difference, expires_at, status) on listings to authenticated;

revoke insert, update, delete on swap_offers, swap_offer_items, conversations, ratings
  from authenticated, anon;
revoke update on messages from authenticated, anon;
grant update (read_at) on messages to authenticated;
revoke update on notifications from authenticated, anon;
grant update (read_at) on notifications to authenticated;
revoke update on reports from authenticated, anon;
grant update (status, admin_note, handled_by, handled_at) on reports to authenticated;
revoke delete on listings, messages, reports from authenticated, anon;

-- ---------------------------------------------------------------------
-- الإشعارات التلقائية
-- ---------------------------------------------------------------------
create function on_favorite_added() returns trigger
language plpgsql security definer set search_path = public as $$
declare v_owner uuid; v_title text;
begin
  select owner_id, title into v_owner, v_title from listings where id = new.listing_id;
  if v_owner is not null and v_owner <> new.user_id then
    perform notify(v_owner, 'listing_saved',
      jsonb_build_object('listing_id', new.listing_id, 'title', v_title));
  end if;
  return new;
end $$;

create trigger favorites_notify after insert on favorites
  for each row execute function on_favorite_added();

create function on_message_sent() returns trigger
language plpgsql security definer set search_path = public as $$
declare v_conv conversations;
begin
  update conversations set last_message_at = new.created_at
    where id = new.conversation_id returning * into v_conv;
  perform notify(
    case when v_conv.user_a = new.sender_id then v_conv.user_b else v_conv.user_a end,
    'new_message',
    jsonb_build_object('conversation_id', new.conversation_id,
                       'preview', left(coalesce(nullif(new.body, ''), '📷'), 80)));
  return new;
end $$;

create trigger messages_after_insert after insert on messages
  for each row execute function on_message_sent();

create function on_rating_added() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  update profiles p set
    rating_count = s.cnt,
    rating_avg   = s.avg
  from (select count(*) cnt, round(avg(stars)::numeric, 2) avg
        from ratings where to_user = new.to_user) s
  where p.id = new.to_user;
  perform notify(new.to_user, 'rating_received',
    jsonb_build_object('offer_id', new.offer_id, 'stars', new.stars));
  return new;
end $$;

create trigger ratings_after_insert after insert on ratings
  for each row execute function on_rating_added();

-- ---------------------------------------------------------------------
-- RPC: إنشاء عرض تبادل (أو عرض معاكس عند تمرير p_parent_offer_id)
-- ---------------------------------------------------------------------
create function create_offer(
  p_requested_listing_ids uuid[],
  p_offered_listing_ids   uuid[],
  p_cash_amount           numeric default 0,
  p_cash_payer            cash_payer default 'none',
  p_message               text default '',
  p_parent_offer_id       uuid default null
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_uid       uuid := require_active_user();
  v_receiver  uuid;
  v_parent    swap_offers;
  v_offer_id  uuid;
  v_bad       int;
begin
  if coalesce(cardinality(p_requested_listing_ids), 0) = 0
     or coalesce(cardinality(p_offered_listing_ids), 0) = 0 then
    raise exception 'items_required' using errcode = 'P0001';
  end if;
  if cardinality(p_requested_listing_ids) > 5 or cardinality(p_offered_listing_ids) > 5 then
    raise exception 'too_many_items' using errcode = 'P0001';
  end if;
  if (coalesce(p_cash_amount, 0) = 0) <> (p_cash_payer = 'none') then
    raise exception 'invalid_cash' using errcode = 'P0001';
  end if;

  -- كل الأغراض المطلوبة نشطة ولصاحب واحد
  select min(owner_id::text)::uuid, count(distinct owner_id)
         + count(*) filter (where status <> 'active')
         + (cardinality(p_requested_listing_ids) - count(*))
    into v_receiver, v_bad
  from listings where id = any(p_requested_listing_ids);
  if v_receiver is null or v_bad <> 1 then
    raise exception 'requested_items_unavailable' using errcode = 'P0001';
  end if;
  if v_receiver = v_uid then
    raise exception 'cannot_offer_to_self' using errcode = 'P0001';
  end if;

  -- كل الأغراض المقدَّمة نشطة ويملكها المرسل
  select (cardinality(p_offered_listing_ids) - count(*))
         + count(*) filter (where owner_id <> v_uid or status <> 'active')
    into v_bad
  from listings where id = any(p_offered_listing_ids);
  if v_bad <> 0 then
    raise exception 'offered_items_unavailable' using errcode = 'P0001';
  end if;

  -- لا نكشف وجود الحظر: نفس رسالة «غير متاح»
  if is_blocked_between(v_uid, v_receiver)
     or exists (select 1 from profiles where id = v_receiver and is_banned) then
    raise exception 'requested_items_unavailable' using errcode = 'P0001';
  end if;

  -- حد للعروض المعلّقة لكل مستخدم (ضد الإزعاج)
  if (select count(*) from swap_offers where sender_id = v_uid and status = 'pending') >= 30 then
    raise exception 'too_many_pending_offers' using errcode = 'P0001';
  end if;

  if p_parent_offer_id is not null then
    select * into v_parent from swap_offers where id = p_parent_offer_id for update;
    if not found or v_parent.status <> 'pending' or v_parent.receiver_id <> v_uid
       or v_parent.sender_id <> v_receiver then
      raise exception 'invalid_counter_offer' using errcode = 'P0001';
    end if;
    update swap_offers set status = 'countered', responded_at = now()
      where id = p_parent_offer_id;
  elsif exists (
    select 1 from swap_offers o join swap_offer_items i on i.offer_id = o.id
    where o.sender_id = v_uid and o.status = 'pending'
      and i.side = 'receiver' and i.listing_id = any(p_requested_listing_ids)
  ) then
    raise exception 'duplicate_pending_offer' using errcode = 'P0001';
  end if;

  insert into swap_offers (sender_id, receiver_id, parent_offer_id,
                           cash_amount, cash_payer, message)
  values (v_uid, v_receiver, p_parent_offer_id,
          coalesce(p_cash_amount, 0), p_cash_payer, left(coalesce(p_message, ''), 500))
  returning id into v_offer_id;

  insert into swap_offer_items (offer_id, listing_id, side)
    select v_offer_id, unnest(p_offered_listing_ids), 'sender'::offer_side
    union
    select v_offer_id, unnest(p_requested_listing_ids), 'receiver'::offer_side;

  perform notify(v_receiver,
    case when p_parent_offer_id is null then 'offer_received' else 'offer_countered' end,
    jsonb_build_object('offer_id', v_offer_id, 'from', v_uid));

  return v_offer_id;
end $$;

-- ---------------------------------------------------------------------
-- RPC: قبول / رفض عرض
-- ---------------------------------------------------------------------
create function respond_offer(p_offer_id uuid, p_accept boolean)
returns uuid  -- معرّف المحادثة عند القبول
language plpgsql security definer set search_path = public as $$
declare
  v_uid    uuid := require_active_user();
  v_offer  swap_offers;
  v_conv   uuid;
  v_ids    uuid[];
  v_other  record;
begin
  select * into v_offer from swap_offers where id = p_offer_id for update;
  if not found or v_offer.receiver_id <> v_uid then
    raise exception 'offer_not_found' using errcode = 'P0001';
  end if;
  if v_offer.status <> 'pending' then
    raise exception 'offer_not_pending' using errcode = 'P0001';
  end if;

  if not p_accept then
    update swap_offers set status = 'rejected', responded_at = now() where id = p_offer_id;
    perform notify(v_offer.sender_id, 'offer_rejected', jsonb_build_object('offer_id', p_offer_id));
    return null;
  end if;

  if is_blocked_between(v_offer.sender_id, v_offer.receiver_id) then
    raise exception 'blocked' using errcode = 'P0001';
  end if;

  select array_agg(listing_id) into v_ids from swap_offer_items where offer_id = p_offer_id;

  -- قفل الإعلانات والتأكد أنها ما زالت متاحة
  perform 1 from listings where id = any(v_ids) for update;
  if exists (select 1 from listings where id = any(v_ids) and status <> 'active') then
    raise exception 'items_no_longer_available' using errcode = 'P0001';
  end if;

  perform begin_internal_op();
  update listings set status = 'reserved' where id = any(v_ids);
  update swap_offers set status = 'accepted', responded_at = now() where id = p_offer_id;

  insert into conversations (offer_id, user_a, user_b)
    values (p_offer_id, v_offer.sender_id, v_offer.receiver_id)
    returning id into v_conv;

  -- إلغاء العروض المعلّقة الأخرى التي تتضمن أياً من هذه الأغراض
  for v_other in
    update swap_offers o set status = 'cancelled', responded_at = now()
    where o.status = 'pending' and o.id <> p_offer_id
      and exists (select 1 from swap_offer_items i
                  where i.offer_id = o.id and i.listing_id = any(v_ids))
    returning o.id, o.sender_id, o.receiver_id
  loop
    perform notify(v_other.sender_id, 'offer_cancelled',
      jsonb_build_object('offer_id', v_other.id, 'reason', 'items_reserved'));
    perform notify(v_other.receiver_id, 'offer_cancelled',
      jsonb_build_object('offer_id', v_other.id, 'reason', 'items_reserved'));
  end loop;

  perform notify(v_offer.sender_id, 'offer_accepted',
    jsonb_build_object('offer_id', p_offer_id, 'conversation_id', v_conv));
  return v_conv;
end $$;

-- ---------------------------------------------------------------------
-- RPC: إلغاء عرض
--   pending  → المرسل فقط
--   accepted → أي طرف (الصفقة لم تتم)، وتعود الأغراض متاحة
-- ---------------------------------------------------------------------
create function cancel_offer(p_offer_id uuid)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_uid   uuid := auth.uid();
  v_offer swap_offers;
begin
  select * into v_offer from swap_offers where id = p_offer_id for update;
  if not found or v_uid not in (v_offer.sender_id, v_offer.receiver_id) then
    raise exception 'offer_not_found' using errcode = 'P0001';
  end if;

  if v_offer.status = 'pending' and v_uid = v_offer.sender_id then
    update swap_offers set status = 'cancelled', responded_at = now() where id = p_offer_id;
  elsif v_offer.status = 'accepted' then
    perform begin_internal_op();
    update listings l set status =
        case when l.expires_at is not null and l.expires_at < now()
             then 'expired'::listing_status else 'active'::listing_status end
      where l.status = 'reserved'
        and l.id in (select listing_id from swap_offer_items where offer_id = p_offer_id);
    update swap_offers set status = 'cancelled' where id = p_offer_id;
  else
    raise exception 'cannot_cancel' using errcode = 'P0001';
  end if;

  perform notify(
    case when v_uid = v_offer.sender_id then v_offer.receiver_id else v_offer.sender_id end,
    'offer_cancelled', jsonb_build_object('offer_id', p_offer_id));
end $$;

-- ---------------------------------------------------------------------
-- RPC: تأكيد إتمام التبادل. يكتمل عندما يؤكد الطرفان.
-- ---------------------------------------------------------------------
create function confirm_swap(p_offer_id uuid)
returns offer_status
language plpgsql security definer set search_path = public as $$
declare
  v_uid   uuid := require_active_user();
  v_offer swap_offers;
begin
  select * into v_offer from swap_offers where id = p_offer_id for update;
  if not found or v_uid not in (v_offer.sender_id, v_offer.receiver_id) then
    raise exception 'offer_not_found' using errcode = 'P0001';
  end if;
  if v_offer.status <> 'accepted' then
    raise exception 'offer_not_accepted' using errcode = 'P0001';
  end if;

  if v_uid = v_offer.sender_id then
    update swap_offers set sender_confirmed_at = coalesce(sender_confirmed_at, now())
      where id = p_offer_id returning * into v_offer;
  else
    update swap_offers set receiver_confirmed_at = coalesce(receiver_confirmed_at, now())
      where id = p_offer_id returning * into v_offer;
  end if;

  if v_offer.sender_confirmed_at is not null and v_offer.receiver_confirmed_at is not null then
    perform begin_internal_op();
    update swap_offers set status = 'completed', completed_at = now() where id = p_offer_id;
    update listings set status = 'swapped'
      where id in (select listing_id from swap_offer_items where offer_id = p_offer_id);
    update profiles set completed_swaps = completed_swaps + 1
      where id in (v_offer.sender_id, v_offer.receiver_id);
    perform notify(v_offer.sender_id, 'swap_completed', jsonb_build_object('offer_id', p_offer_id));
    perform notify(v_offer.receiver_id, 'swap_completed', jsonb_build_object('offer_id', p_offer_id));
    return 'completed';
  end if;

  return 'accepted';
end $$;

-- ---------------------------------------------------------------------
-- RPC: تقييم الطرف الآخر بعد الإتمام
-- ---------------------------------------------------------------------
create function rate_swap(
  p_offer_id uuid, p_stars smallint, p_tags text[] default '{}', p_comment text default ''
) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_uid   uuid := require_active_user();
  v_offer swap_offers;
  v_allowed text[] := array['committed','honest','fast_reply','on_time','as_described'];
begin
  select * into v_offer from swap_offers where id = p_offer_id;
  if not found or v_uid not in (v_offer.sender_id, v_offer.receiver_id) then
    raise exception 'offer_not_found' using errcode = 'P0001';
  end if;
  if v_offer.status <> 'completed' then
    raise exception 'swap_not_completed' using errcode = 'P0001';
  end if;
  if not (coalesce(p_tags, '{}') <@ v_allowed) then
    raise exception 'invalid_tags' using errcode = 'P0001';
  end if;

  insert into ratings (offer_id, from_user, to_user, stars, tags, comment)
  values (p_offer_id, v_uid,
          case when v_uid = v_offer.sender_id then v_offer.receiver_id else v_offer.sender_id end,
          p_stars, coalesce(p_tags, '{}'), left(coalesce(p_comment, ''), 500));
exception when unique_violation then
  raise exception 'already_rated' using errcode = 'P0001';
end $$;

-- ---------------------------------------------------------------------
-- RPC: المطابقة المباشرة (بدون AI)
-- زوج (غرضي M ، غرضه T) يتطابق إذا:
--   M يريد T  (wants_anything أو رغبة بنفس فئة T وكلمتها إن وُجدت)
--   و T يريد M بنفس الطريقة
--   ولا يكون الطرفان «أي شيء» فقط.
-- الأولوية للمنطقة نفسها ثم المحافظة نفسها.
-- ---------------------------------------------------------------------
create function find_matches(p_limit int default 50)
returns table (
  my_listing_id    uuid,
  their_listing_id uuid,
  score            int
)
language sql stable security definer set search_path = public as $$
  with me as (select auth.uid() as uid),
  mine as (
    select l.* from listings l, me where l.owner_id = me.uid and l.status = 'active'
  ),
  theirs as (
    select l.* from listings l
    join profiles p on p.id = l.owner_id, me
    where l.status = 'active' and l.owner_id <> me.uid and not p.is_banned
      and not is_blocked_between(me.uid, l.owner_id)
  ),
  pairs as (
    select m.id as my_id, t.id as their_id,
      -- هل أريد غرضه؟ 2 = رغبة صريحة، 1 = أي شيء
      case
        when exists (select 1 from listing_wants w
                     where w.listing_id = m.id and w.category_id = t.category_id
                       and (w.keyword is null
                            or t.search_text like '%' || normalize_ar(w.keyword) || '%'))
          then 2
        when m.wants_anything then 1
        else 0 end as i_want,
      case
        when exists (select 1 from listing_wants w
                     where w.listing_id = t.id and w.category_id = m.category_id
                       and (w.keyword is null
                            or m.search_text like '%' || normalize_ar(w.keyword) || '%'))
          then 2
        when t.wants_anything then 1
        else 0 end as they_want,
      case when m.area_id is not null and m.area_id = t.area_id then 3
           when m.governorate_id = t.governorate_id then 1
           else 0 end as near
    from mine m cross join theirs t
  )
  select my_id, their_id, (i_want + they_want) * 10 + near
  from pairs
  where i_want > 0 and they_want > 0 and (i_want + they_want) > 2
  order by 3 desc
  limit least(greatest(p_limit, 1), 200)
$$;

-- ---------------------------------------------------------------------
-- RPC: الإشراف
-- ---------------------------------------------------------------------
create function admin_set_ban(p_user uuid, p_banned boolean)
returns void
language plpgsql security definer set search_path = public as $$
begin
  if not is_admin() then raise exception 'forbidden' using errcode = '42501'; end if;
  update profiles set is_banned = p_banned where id = p_user;
  if p_banned then
    perform begin_internal_op();
    update listings set status = 'removed' where owner_id = p_user and status = 'active';
    update swap_offers set status = 'cancelled'
      where status = 'pending' and p_user in (sender_id, receiver_id);
  end if;
end $$;

create function admin_stats()
returns jsonb
language plpgsql stable security definer set search_path = public as $$
begin
  if not is_admin() then raise exception 'forbidden' using errcode = '42501'; end if;
  return jsonb_build_object(
    'users',            (select count(*) from profiles),
    'banned_users',     (select count(*) from profiles where is_banned),
    'active_listings',  (select count(*) from listings where status = 'active'),
    'listings_7d',      (select count(*) from listings where created_at > now() - interval '7 days'),
    'offers_total',     (select count(*) from swap_offers),
    'offers_pending',   (select count(*) from swap_offers where status = 'pending'),
    'offers_accepted',  (select count(*) from swap_offers where status = 'accepted'),
    'swaps_completed',  (select count(*) from swap_offers where status = 'completed'),
    'open_reports',     (select count(*) from reports where status = 'open'),
    'top_categories',   (select coalesce(jsonb_agg(x), '[]') from (
                           select c.name_ar, count(*) n from listings l
                           join categories c on c.id = l.category_id
                           group by c.name_ar order by n desc limit 5) x),
    'top_governorates', (select coalesce(jsonb_agg(x), '[]') from (
                           select g.name_ar, count(*) n from listings l
                           join governorates g on g.id = l.governorate_id
                           group by g.name_ar order by n desc) x)
  );
end $$;

-- ---------------------------------------------------------------------
-- مهمة دورية: انتهاء الإعلانات والعروض القديمة
-- ---------------------------------------------------------------------
create function expire_stale() returns void
language plpgsql security definer set search_path = public as $$
begin
  perform begin_internal_op();
  update listings set status = 'expired'
    where status = 'active' and expires_at is not null and expires_at < now();
  update swap_offers set status = 'cancelled', responded_at = now()
    where status = 'pending' and created_at < now() - interval '14 days';
  -- العروض المعلّقة على أغراض لم تعد نشطة
  update swap_offers o set status = 'cancelled', responded_at = now()
    where o.status = 'pending' and exists (
      select 1 from swap_offer_items i join listings l on l.id = i.listing_id
      where i.offer_id = o.id and l.status <> 'active');
end $$;

revoke execute on function expire_stale() from public, anon, authenticated;
revoke execute on function notify(uuid, text, jsonb) from public, anon, authenticated;
revoke execute on function begin_internal_op() from public, anon, authenticated;

do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.schedule('badelha-expire-stale', '*/15 * * * *', 'select public.expire_stale()');
  end if;
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    alter publication supabase_realtime add table messages, notifications, swap_offers;
  end if;
end $$;
