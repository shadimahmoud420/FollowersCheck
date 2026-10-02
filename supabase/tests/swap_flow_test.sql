-- =====================================================================
-- اختبار دورة التبادل الكاملة + قواعد الأمان
-- A (أحمد) لديه لوح شمسي ويريد هاتفاً
-- B (بشرى) لديها هاتف وتريد طاقة
-- C (سامي) طرف ثالث يحاول التلاعب
-- =====================================================================
\set A '''aaaaaaaa-0000-0000-0000-000000000001'''
\set B '''bbbbbbbb-0000-0000-0000-000000000002'''
\set C '''cccccccc-0000-0000-0000-000000000003'''

insert into auth.users (id) values (:A), (:B), (:C);

-- أداة: تنفيذ جملة والتأكد أنها تفشل برسالة معيّنة
create function pg_temp_expect_error(p_sql text, p_fragment text) returns void
language plpgsql as $$
begin
  begin
    execute p_sql;
  exception when others then
    if position(p_fragment in sqlerrm) = 0 then
      raise exception 'expected error "%" but got "%"', p_fragment, sqlerrm;
    end if;
    return;
  end;
  raise exception 'expected error "%" but statement succeeded: %', p_fragment, p_sql;
end $$;
grant execute on function pg_temp_expect_error(text, text) to authenticated;

create function as_user(p uuid) returns void language sql as $$
  select set_config('request.jwt.claim.sub', p::text, false);
$$;
grant execute on function as_user(uuid) to authenticated;

set role authenticated;

-- ---------- إنشاء الملفات ----------
select as_user(:A);
insert into profiles (id, display_name, governorate_id, area_id)
  values (:A, 'أحمد', 2, (select id from areas where name_ar = 'الرمال'));
-- لا يمكن تعيين نفسك مشرفاً
select pg_temp_expect_error('update profiles set is_admin = true', 'permission denied');
select pg_temp_expect_error(
  'insert into profiles (id, display_name) values (''bbbbbbbb-0000-0000-0000-000000000002'', ''x'')',
  'row-level security');

select as_user(:B);
insert into profiles (id, display_name, governorate_id, area_id)
  values (:B, 'بشرى', 2, (select id from areas where name_ar = 'الرمال'));
select as_user(:C);
insert into profiles (id, display_name, governorate_id) values (:C, 'سامي', 4);

-- ---------- الإعلانات ----------
select as_user(:A);
insert into listings (id, owner_id, title, description, category_id, condition, governorate_id, area_id, estimated_value)
values ('10000000-0000-0000-0000-00000000000a', :A, 'لوح طاقة شمسية 300 واط', 'يعمل بشكل ممتاز', 1, 'good', 2,
        (select id from areas where name_ar = 'الرمال'), 400);
insert into listing_wants (listing_id, category_id, keyword) values ('10000000-0000-0000-0000-00000000000a', 2, null);
-- لا يمكن إنشاء إعلان باسم شخص آخر
select pg_temp_expect_error(format(
  'insert into listings (owner_id, title, category_id, condition, governorate_id) values (%L, ''x x'', 1, ''good'', 2)',
  'bbbbbbbb-0000-0000-0000-000000000002'), 'row-level security');

select as_user(:B);
insert into listings (id, owner_id, title, category_id, condition, governorate_id, area_id)
values ('20000000-0000-0000-0000-00000000000b', :B, 'هاتف سامسونج A54', 2, 'excellent', 2,
        (select id from areas where name_ar = 'الرمال'));
insert into listing_wants (listing_id, category_id, keyword) values ('20000000-0000-0000-0000-00000000000b', 1, 'شمسيه');

select as_user(:C);
insert into listings (id, owner_id, title, category_id, condition, governorate_id)
values ('30000000-0000-0000-0000-00000000000c', :C, 'خيمة عائلية', 5, 'good', 4);
-- C لا يستطيع تعديل إعلان A (RLS يخفيه عن التعديل)
update listings set title = 'مسروق' where id = '10000000-0000-0000-0000-00000000000a';
reset role;
do $$ begin
  assert (select title from listings where id = '10000000-0000-0000-0000-00000000000a') = 'لوح طاقة شمسية 300 واط',
    'C must not edit A listing';
end $$;
set role authenticated;

-- ---------- البحث بالعربية (تطبيع ة/ه وأ/ا) ----------
select as_user(:C);
do $$ begin
  assert (select count(*) from listings where search_text like '%' || normalize_ar('شمسيه') || '%') = 1,
    'arabic normalized search';
  assert (select count(*) from listings where search_text like '%' || normalize_ar('لوح طاقه') || '%') = 1,
    'taa marbuta normalization';
end $$;

-- ---------- المطابقة ----------
select as_user(:A);
do $$ begin
  assert (select count(*) from find_matches(10)) = 1, 'A should have exactly one match';
  assert (select their_listing_id from find_matches(10)) = '20000000-0000-0000-0000-00000000000b', 'A matches B phone';
  assert (select score from find_matches(10)) = 43, 'explicit both ways (40) + same area (3)';
end $$;

-- ---------- عرض التبادل ----------
select as_user(:A);
-- لا يمكن تقديم غرض لا تملكه
select pg_temp_expect_error($q$
  select create_offer(array['20000000-0000-0000-0000-00000000000b']::uuid[],
                      array['30000000-0000-0000-0000-00000000000c']::uuid[])$q$, 'offered_items_unavailable');
-- مبلغ نقدي بدون دافع غير صالح
select pg_temp_expect_error($q$
  select create_offer(array['20000000-0000-0000-0000-00000000000b']::uuid[],
                      array['10000000-0000-0000-0000-00000000000a']::uuid[], 50, 'none')$q$, 'invalid_cash');
-- لا يمكن إدخال عرض مباشرة في الجدول
select pg_temp_expect_error(format(
  'insert into swap_offers (sender_id, receiver_id) values (%L, %L)',
  'aaaaaaaa-0000-0000-0000-000000000001', 'bbbbbbbb-0000-0000-0000-000000000002'), 'permission denied');

select create_offer(array['20000000-0000-0000-0000-00000000000b']::uuid[],
                    array['10000000-0000-0000-0000-00000000000a']::uuid[],
                    0, 'none', 'مرحبا، يناسبك؟') as offer1 \gset
select pg_temp_expect_error($q$
  select create_offer(array['20000000-0000-0000-0000-00000000000b']::uuid[],
                      array['10000000-0000-0000-0000-00000000000a']::uuid[])$q$, 'duplicate_pending_offer');

-- C لا يرى العرض
select as_user(:C);
do $$ begin assert (select count(*) from swap_offers) = 0, 'C must not see offers'; end $$;
-- C لا يستطيع قبول عرض ليس له
select pg_temp_expect_error(format('select respond_offer(%L, true)', :'offer1'), 'offer_not_found');

-- B ترد بعرض معاكس: تريد اللوح + 50 شيكل من أحمد
select as_user(:B);
do $$ begin
  assert (select count(*) from notifications where type = 'offer_received') = 1, 'B notified';
end $$;
select create_offer(array['10000000-0000-0000-0000-00000000000a']::uuid[],
                    array['20000000-0000-0000-0000-00000000000b']::uuid[],
                    50, 'receiver', 'أريد فرق 50 شيكل', :'offer1') as offer2 \gset
do $$ begin
  assert (select status from swap_offers where parent_offer_id is null) = 'countered', 'parent countered';
end $$;
-- لا يمكن قبول عرض أُرسل منك
select pg_temp_expect_error(format('select respond_offer(%L, true)', :'offer2'), 'offer_not_found');

-- A يقبل العرض المعاكس
select as_user(:A);
select respond_offer(:'offer2', true) as conv \gset
do $$ begin
  assert (select count(*) from listings where status = 'reserved') = 2, 'both listings reserved';
end $$;

-- ---------- المحادثة ----------
insert into messages (conversation_id, sender_id, body) values (:'conv', :A, 'نلتقي عند دوار الشاطئ؟');
select as_user(:B);
insert into messages (conversation_id, sender_id, body, meeting_point) values (:'conv', :B, 'تمام', 'دوار الشاطئ');
select as_user(:C);
do $$ begin assert (select count(*) from messages) = 0, 'C cannot read chat'; end $$;
select pg_temp_expect_error(format(
  'insert into messages (conversation_id, sender_id, body) values (%L, %L, ''hi'')',
  :'conv', 'cccccccc-0000-0000-0000-000000000003'), 'row-level security');

-- إعلان محجوز لا يمكن لصاحبه إعادته نشطاً يدوياً
select as_user(:A);
select pg_temp_expect_error(
  'update listings set status = ''active'' where id = ''10000000-0000-0000-0000-00000000000a''',
  'invalid_status_transition');

-- لا تقييم قبل الإتمام
select pg_temp_expect_error(format('select rate_swap(%L, 5::smallint)', :'offer2'), 'swap_not_completed');

-- ---------- الإتمام ----------
do $$ begin assert confirm_swap((select id from swap_offers where status = 'accepted')) = 'accepted'; end $$;
select as_user(:B);
do $$ begin assert confirm_swap((select id from swap_offers where status = 'accepted')) = 'completed'; end $$;

reset role;
do $$ begin
  assert (select count(*) from listings where status = 'swapped') = 2, 'listings swapped';
  assert (select completed_swaps from profiles where display_name = 'أحمد') = 1, 'A count';
  assert (select completed_swaps from profiles where display_name = 'بشرى') = 1, 'B count';
end $$;
set role authenticated;

-- ---------- التقييم ----------
select as_user(:B);
select rate_swap(:'offer2', 5::smallint, array['honest','on_time'], 'شخص محترم');
select pg_temp_expect_error(format('select rate_swap(%L, 4::smallint)', :'offer2'), 'already_rated');
select pg_temp_expect_error(format('select rate_swap(%L, 4::smallint, array[''hacker''])', :'offer2'), 'invalid_tags');
select as_user(:A);
select rate_swap(:'offer2', 4::smallint);
do $$ begin
  assert (select rating_avg from profiles where display_name = 'أحمد') = 5.00, 'A rating';
  assert (select rating_count from profiles where display_name = 'بشرى') = 1, 'B rating count';
end $$;

-- ---------- الحظر ----------
select as_user(:C);
insert into listings (id, owner_id, title, category_id, condition, governorate_id)
values ('30000000-0000-0000-0000-0000000000c2', :C, 'باور بانك 20000', 1, 'good', 4);
select as_user(:A);
insert into listings (id, owner_id, title, category_id, condition, governorate_id)
values ('10000000-0000-0000-0000-0000000000a2', :A, 'كتب توجيهي', 9, 'good', 2);
insert into blocks (blocker_id, blocked_id) values (:A, :C);
do $$ begin
  assert (select count(*) from listings where owner_id = 'cccccccc-0000-0000-0000-000000000003') = 0,
    'blocked user listings hidden';
end $$;
select as_user(:C);
do $$ begin
  assert (select count(*) from listings where owner_id = 'aaaaaaaa-0000-0000-0000-000000000001') = 0,
    'blocking hides both ways';
end $$;
select pg_temp_expect_error($q$
  select create_offer(array['10000000-0000-0000-0000-0000000000a2']::uuid[],
                      array['30000000-0000-0000-0000-0000000000c2']::uuid[])$q$, 'requested_items_unavailable');

-- ---------- البلاغات والإشراف ----------
insert into reports (reporter_id, reported_user_id, reason, details)
  values (:C, :B, 'fraud', 'اختبار');
select pg_temp_expect_error('select admin_stats()', 'forbidden');
select pg_temp_expect_error(format('select admin_set_ban(%L, true)', :B), 'forbidden');

reset role;
update profiles set is_admin = true where id = :A;
set role authenticated;
select as_user(:A);
do $$ begin
  assert (admin_stats()->>'swaps_completed')::int = 1, 'stats';
  assert (admin_stats()->>'open_reports')::int = 1, 'reports';
end $$;
select admin_set_ban(:C, true);
reset role;
do $$ begin
  assert (select count(*) from listings where owner_id = 'cccccccc-0000-0000-0000-000000000003' and status = 'active') = 0,
    'banned user listings removed';
end $$;
set role authenticated;
select as_user(:C);
select pg_temp_expect_error(
  'insert into listings (owner_id, title, category_id, condition, governorate_id) values (''cccccccc-0000-0000-0000-000000000003'', ''abc'', 1, ''good'', 4)',
  'row-level security');

-- ---------- إلغاء صفقة مقبولة يعيد الأغراض ----------
reset role;
insert into auth.users (id) values ('dddddddd-0000-0000-0000-000000000004');
set role authenticated;
select as_user('dddddddd-0000-0000-0000-000000000004');
insert into profiles (id, display_name, governorate_id) values ('dddddddd-0000-0000-0000-000000000004', 'دينا', 3);
insert into listings (id, owner_id, title, category_id, condition, governorate_id)
values ('40000000-0000-0000-0000-00000000000d', 'dddddddd-0000-0000-0000-000000000004', 'جالون مياه', 8, 'good', 3);
select create_offer(array['10000000-0000-0000-0000-0000000000a2']::uuid[],
                    array['40000000-0000-0000-0000-00000000000d']::uuid[]) as offer3 \gset
select as_user(:A);
select respond_offer(:'offer3', true);
select cancel_offer(:'offer3');
reset role;
do $$ begin
  assert (select status from listings where id = '10000000-0000-0000-0000-0000000000a2') = 'active', 'restored A';
  assert (select status from listings where id = '40000000-0000-0000-0000-00000000000d') = 'active', 'restored D';
end $$;

-- ---------- الانتهاء ----------
update listings set expires_at = now() - interval '1 minute' where id = '40000000-0000-0000-0000-00000000000d';
select expire_stale();
do $$ begin
  assert (select status from listings where id = '40000000-0000-0000-0000-00000000000d') = 'expired', 'expired';
end $$;
