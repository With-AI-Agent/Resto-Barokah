-- PROBE SAYA — PR-15: hapus meja memutus tautan pesanan lunas
update public.pesanan set status='lunas' where id='eeee0000-0000-0000-0000-000000000010';
delete from public.meja where id='aaa00000-0000-0000-0000-000000000001';
select uji.sama((select meja_id from public.pesanan where id='eeee0000-0000-0000-0000-000000000010'),
                null::uuid, 'PR-15 NYATA: pesanan lunas kehilangan tautan mejanya');
