-- Trip Splitter: ตั้งค่าฐานข้อมูลกลาง
-- วิธีใช้: Supabase → SQL Editor → New query → วางทั้งหมดนี้ → กด Run (รันซ้ำได้ ไม่เสียหาย)

-- ตารางเดียวเก็บข้อมูลทุกประเภท (ผู้ใช้ ทริป บิล การโอน แชท ของที่ต้องหิ้ว)
create table if not exists public.rows (
  tbl        text        not null,
  id         bigint      not null,
  data       jsonb       not null,
  updated_at timestamptz not null default now(),
  primary key (tbl, id)
);

-- อัปเดตเวลาแก้ไขล่าสุดให้เอง
create or replace function public.rows_touch() returns trigger language plpgsql as $$
begin new.updated_at := now(); return new; end $$;
drop trigger if exists rows_touch on public.rows;
create trigger rows_touch before update on public.rows for each row execute function public.rows_touch();

-- สิทธิ์: ทุกคนที่มีลิงก์แอปอ่านและเขียนได้ (เหมาะกับกลุ่มเพื่อน)
alter table public.rows enable row level security;
drop policy if exists "rows read"   on public.rows;
drop policy if exists "rows insert" on public.rows;
drop policy if exists "rows update" on public.rows;
drop policy if exists "rows delete" on public.rows;
create policy "rows read"   on public.rows for select using (true);
create policy "rows insert" on public.rows for insert with check (true);
create policy "rows update" on public.rows for update using (true) with check (true);
create policy "rows delete" on public.rows for delete using (true);
grant select, insert, update, delete on public.rows to anon, authenticated;

-- เปิด Realtime ให้เครื่องเพื่อนเห็นการเปลี่ยนแปลงทันที
do $$ begin
  alter publication supabase_realtime add table public.rows;
exception when duplicate_object then null;
end $$;
