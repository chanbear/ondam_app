-- document-photos: private Storage bucket for document_scan's original photo
-- upload, per technical-decisions.md §1-8 ("사진/문서 원본 → 즉시 삭제") and §2
-- item 7 ("업로드된 사진은 분석 완료 전까지만 짧게 존재해야 하며, Storage
-- 버킷 정책도 '업로드한 본인 + 처리 중인 서버 함수'만 접근 가능하도록
-- 제한"). Objects are named `${auth.uid()}/<file>` so a single RLS predicate
-- (folder name = caller's own uid) grants exactly the owner's own objects.
--
-- No SELECT/UPDATE policy for `authenticated`, and no DELETE policy either:
-- the client only ever uploads (write-once). The `analyze-document` Edge
-- Function reads and deletes the object itself using the service role,
-- which bypasses RLS entirely — that is the "처리 중인 서버 함수" access
-- path, not a client-facing policy.

insert into storage.buckets (id, name, public)
values ('document-photos', 'document-photos', false)
on conflict (id) do nothing;

create policy "document_photos_insert_own"
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'document-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
