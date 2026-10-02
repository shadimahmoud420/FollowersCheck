-- =====================================================================
-- بدّلها (Badelha) — المخطط الأساسي
-- منصة تبادل الأغراض في قطاع غزة.
--
-- مبادئ:
--   * لا نخزّن أي إحداثيات GPS. الموقع = محافظة + منطقة يختارها المستخدم.
--   * الهاتف والبريد يبقيان في auth.users ولا يظهران في profiles.
--   * كل انتقالات الحالة (عرض، قبول، إتمام...) تتم عبر دوال RPC
--     في 20261002000002_swap_logic.sql وليس عبر تعديل مباشر للجداول.
-- =====================================================================

create extension if not exists pg_trgm;

-- ---------------------------------------------------------------------
-- تطبيع النص العربي للبحث: أ إ آ ← ا ، ة ← ه ، ى ← ي ، وإزالة التشكيل
-- يجب أن يطابق normalizeArabic() في التطبيق.
-- ---------------------------------------------------------------------
create function normalize_ar(t text) returns text
language sql immutable parallel safe as $$
  select lower(translate(coalesce(t, ''),
    'أإآٱةىًٌٍَُِّْـ',
    'ااااهي'))
$$;

-- ---------------------------------------------------------------------
-- الأنواع
-- ---------------------------------------------------------------------
create type item_condition as enum (
  'new', 'like_new', 'excellent', 'good', 'used', 'needs_repair'
);

create type listing_status as enum (
  'active',    -- معروض
  'reserved',  -- تم قبول عرض عليه وبانتظار التسليم
  'swapped',   -- تم التبادل
  'expired',
  'removed'    -- حذفه صاحبه أو المشرف
);

create type offer_status as enum (
  'pending',
  'accepted',
  'rejected',
  'countered',  -- رُدّ عليه بعرض معاكس (العرض الجديد يشير إليه parent_offer_id)
  'cancelled',
  'completed'
);

create type cash_payer as enum ('none', 'sender', 'receiver');

create type offer_side as enum ('sender', 'receiver');

create type report_reason as enum (
  'fraud', 'fake_item', 'not_as_described', 'prohibited_item',
  'inappropriate_content', 'suspicious_account', 'price_gouging', 'other'
);

create type report_status as enum ('open', 'reviewing', 'actioned', 'dismissed');

-- ---------------------------------------------------------------------
-- المناطق (محافظات + مناطق) — يديرها المشرف
-- ---------------------------------------------------------------------
create table governorates (
  id         smallint primary key,
  slug       text not null unique,
  name_ar    text not null,
  name_en    text not null,
  sort_order smallint not null default 0
);

create table areas (
  id             serial primary key,
  governorate_id smallint not null references governorates(id),
  name_ar        text not null,
  name_en        text,
  sort_order     smallint not null default 0,
  is_active      boolean not null default true,
  unique (governorate_id, name_ar)
);

create table categories (
  id         smallint primary key,
  slug       text not null unique,
  name_ar    text not null,
  name_en    text not null,
  icon       text not null,          -- اسم أيقونة Material في التطبيق
  sort_order smallint not null default 0,
  is_active  boolean not null default true
);

-- ---------------------------------------------------------------------
-- الملفات الشخصية
-- ---------------------------------------------------------------------
create table profiles (
  id               uuid primary key references auth.users(id) on delete cascade,
  display_name     text not null check (char_length(display_name) between 2 and 40),
  avatar_path      text,
  governorate_id   smallint references governorates(id),
  area_id          int references areas(id),
  bio              text check (char_length(bio) <= 300),
  rating_avg       numeric(3,2) not null default 0,
  rating_count     int not null default 0,
  completed_swaps  int not null default 0,
  is_admin         boolean not null default false,
  is_banned        boolean not null default false,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- الإعلانات (الأغراض المعروضة للتبادل)
-- ---------------------------------------------------------------------
create table listings (
  id              uuid primary key default gen_random_uuid(),
  owner_id        uuid not null references profiles(id) on delete cascade,
  title           text not null check (char_length(title) between 2 and 80),
  description     text not null default '' check (char_length(description) <= 2000),
  category_id     smallint not null references categories(id),
  condition       item_condition not null,
  -- القيمة التقريبية بالشيكل (اختيارية)
  estimated_value numeric(10,2) check (estimated_value is null or estimated_value >= 0),
  -- مسارات الصور داخل bucket listing-images: {owner_id}/{uuid}.jpg
  images          text[] not null default '{}' check (cardinality(images) <= 8),
  governorate_id  smallint not null references governorates(id),
  area_id         int references areas(id),
  -- ماذا يريد مقابله
  wants_anything  boolean not null default false,
  wants_note      text not null default '' check (char_length(wants_note) <= 300),
  accepts_cash_difference boolean not null default true,
  status          listing_status not null default 'active',
  expires_at      timestamptz,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  search_text     text generated always as (
                    normalize_ar(title || ' ' || description || ' ' || wants_note)
                  ) stored
);

create index listings_feed_idx on listings (status, created_at desc);
create index listings_owner_idx on listings (owner_id, status);
create index listings_geo_idx on listings (governorate_id, area_id, status);
create index listings_category_idx on listings (category_id, status);
create index listings_search_trgm_idx on listings using gin (search_text gin_trgm_ops);

-- الرغبات المنظّمة: «أريد مقابله شيئاً من فئة X (وكلمة مفتاحية اختيارية)».
-- هذا ما يجعل المطابقة الآلية ممكنة بدون AI.
create table listing_wants (
  id          bigserial primary key,
  listing_id  uuid not null references listings(id) on delete cascade,
  category_id smallint not null references categories(id),
  keyword     text check (keyword is null or char_length(keyword) between 1 and 40),
  unique (listing_id, category_id, keyword)
);

create index listing_wants_category_idx on listing_wants (category_id);

create table favorites (
  user_id    uuid not null references profiles(id) on delete cascade,
  listing_id uuid not null references listings(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, listing_id)
);

create table blocks (
  blocker_id uuid not null references profiles(id) on delete cascade,
  blocked_id uuid not null references profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);

-- ---------------------------------------------------------------------
-- عروض التبادل
-- العرض له طرفان: ما يقدّمه المرسل (side=sender) وما يطلبه من
-- المستقبل (side=receiver). العرض المعاكس هو عرض جديد بالاتجاه
-- المعاكس يشير إلى الأصل عبر parent_offer_id.
-- ---------------------------------------------------------------------
create table swap_offers (
  id                     uuid primary key default gen_random_uuid(),
  sender_id              uuid not null references profiles(id) on delete cascade,
  receiver_id            uuid not null references profiles(id) on delete cascade,
  parent_offer_id        uuid references swap_offers(id) on delete set null,
  status                 offer_status not null default 'pending',
  cash_amount            numeric(10,2) not null default 0 check (cash_amount >= 0),
  cash_payer             cash_payer not null default 'none',
  message                text not null default '' check (char_length(message) <= 500),
  sender_confirmed_at    timestamptz,
  receiver_confirmed_at  timestamptz,
  responded_at           timestamptz,
  completed_at           timestamptz,
  created_at             timestamptz not null default now(),
  check (sender_id <> receiver_id),
  check ((cash_payer = 'none') = (cash_amount = 0))
);

create index swap_offers_sender_idx on swap_offers (sender_id, created_at desc);
create index swap_offers_receiver_idx on swap_offers (receiver_id, created_at desc);

create table swap_offer_items (
  offer_id   uuid not null references swap_offers(id) on delete cascade,
  listing_id uuid not null references listings(id) on delete cascade,
  side       offer_side not null,
  primary key (offer_id, listing_id)
);

create index swap_offer_items_listing_idx on swap_offer_items (listing_id);

-- ---------------------------------------------------------------------
-- المحادثات (تُفتح فقط بعد قبول العرض)
-- ---------------------------------------------------------------------
create table conversations (
  id         uuid primary key default gen_random_uuid(),
  offer_id   uuid not null unique references swap_offers(id) on delete cascade,
  user_a     uuid not null references profiles(id) on delete cascade,
  user_b     uuid not null references profiles(id) on delete cascade,
  last_message_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create index conversations_user_a_idx on conversations (user_a, last_message_at desc);
create index conversations_user_b_idx on conversations (user_b, last_message_at desc);

create table messages (
  id              bigserial primary key,
  conversation_id uuid not null references conversations(id) on delete cascade,
  sender_id       uuid not null references profiles(id) on delete cascade,
  body            text not null default '' check (char_length(body) <= 2000),
  image_path      text,
  -- منطقة تقريبية فقط (اسم منطقة/مكان عام)، وليس إحداثيات
  meeting_point   text check (char_length(meeting_point) <= 120),
  created_at      timestamptz not null default now(),
  read_at         timestamptz,
  check (body <> '' or image_path is not null or meeting_point is not null)
);

create index messages_conversation_idx on messages (conversation_id, id desc);

-- ---------------------------------------------------------------------
-- التقييمات
-- ---------------------------------------------------------------------
create table ratings (
  id         bigserial primary key,
  offer_id   uuid not null references swap_offers(id) on delete cascade,
  from_user  uuid not null references profiles(id) on delete cascade,
  to_user    uuid not null references profiles(id) on delete cascade,
  stars      smallint not null check (stars between 1 and 5),
  -- committed, honest, fast_reply, on_time, as_described
  tags       text[] not null default '{}',
  comment    text not null default '' check (char_length(comment) <= 500),
  created_at timestamptz not null default now(),
  unique (offer_id, from_user),
  check (from_user <> to_user)
);

create index ratings_to_user_idx on ratings (to_user, created_at desc);

-- ---------------------------------------------------------------------
-- البلاغات
-- ---------------------------------------------------------------------
create table reports (
  id               bigserial primary key,
  reporter_id      uuid not null references profiles(id) on delete cascade,
  reported_user_id uuid references profiles(id) on delete cascade,
  listing_id       uuid references listings(id) on delete set null,
  message_id       bigint references messages(id) on delete set null,
  reason           report_reason not null,
  details          text not null default '' check (char_length(details) <= 1000),
  status           report_status not null default 'open',
  admin_note       text,
  handled_by       uuid references profiles(id),
  created_at       timestamptz not null default now(),
  handled_at       timestamptz,
  check (reported_user_id is not null or listing_id is not null)
);

create index reports_status_idx on reports (status, created_at desc);

-- ---------------------------------------------------------------------
-- الإشعارات داخل التطبيق (Push لاحقاً عبر Edge Function تقرأ هذا الجدول)
-- type: offer_received | offer_accepted | offer_rejected | offer_countered
--       | offer_cancelled | swap_completed | new_message | listing_saved
--       | rating_received | match_found
-- ---------------------------------------------------------------------
create table notifications (
  id         bigserial primary key,
  user_id    uuid not null references profiles(id) on delete cascade,
  type       text not null,
  payload    jsonb not null default '{}',
  read_at    timestamptz,
  created_at timestamptz not null default now()
);

create index notifications_user_idx on notifications (user_id, created_at desc);

-- رموز FCM للأجهزة
create table device_tokens (
  token      text primary key,
  user_id    uuid not null references profiles(id) on delete cascade,
  platform   text not null check (platform in ('android', 'ios', 'web')),
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- updated_at تلقائي
-- ---------------------------------------------------------------------
create function touch_updated_at() returns trigger
language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

create trigger profiles_touch before update on profiles
  for each row execute function touch_updated_at();
create trigger listings_touch before update on listings
  for each row execute function touch_updated_at();
