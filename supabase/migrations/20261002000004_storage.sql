-- =====================================================================
-- بدّلها — التخزين
-- listing-images: عام للقراءة. كل مستخدم يكتب فقط داخل مجلد باسم معرّفه.
-- chat-images: خاص، للأطراف عبر روابط موقّعة من التطبيق.
-- =====================================================================

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('listing-images', 'listing-images', true,  1048576, array['image/jpeg', 'image/webp']),
  ('avatars',        'avatars',        true,   524288, array['image/jpeg', 'image/webp']),
  ('chat-images',    'chat-images',    false, 1048576, array['image/jpeg', 'image/webp'])
on conflict (id) do nothing;

create policy "own folder upload" on storage.objects for insert to authenticated
  with check (
    bucket_id in ('listing-images', 'avatars', 'chat-images')
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "own folder delete" on storage.objects for delete to authenticated
  using (
    bucket_id in ('listing-images', 'avatars', 'chat-images')
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- صور المحادثة: المسار {sender_id}/{conversation_id}/{file}.jpg
create policy "chat images participants" on storage.objects for select to authenticated
  using (
    bucket_id = 'chat-images'
    and exists (
      select 1 from public.conversations c
      where c.id::text = (storage.foldername(name))[2]
        and auth.uid() in (c.user_a, c.user_b)
    )
  );
