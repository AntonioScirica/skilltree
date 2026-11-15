\set ON_ERROR_STOP 1
insert into auth.users values ('00000000-0000-0000-0000-00000000000a','io@x'),('00000000-0000-0000-0000-00000000000b','altro@x');
insert into skilltree_admins values ('00000000-0000-0000-0000-00000000000a');
insert into skilltree_projects (slug,name,roadmap,requests) values
 ('uno','Uno','{"levels":["SEGRETO-INTERNO"]}','{"items":[{"id":"c1","t":"logo"},{"id":"c2","t":"foto"}]}'),
 ('due','Due','{}','{"items":[{"id":"c1","t":"x"}]}');
update skilltree_projects set releases = '[{"v":"0.1","titolo":"Prima","novita":["home"],"controlli":["apri la home","cerca un prodotto"]}]' where slug = 'uno';
create temp table tk as select slug, id, client_token t from skilltree_projects; grant select on tk to anon, authenticated;

create function pg_temp.fails(q text) returns boolean language plpgsql as $$ begin execute q; return false; exception when others then return true; end $$;
create function pg_temp.ok(cond boolean, what text) returns void language plpgsql as $$ begin if cond is not true then raise exception 'FALLITO: %', what; end if; raise notice 'ok  %', what; end $$;

-- ===== anonimo (il cliente, o chiunque) =====
set role anon;
select pg_temp.ok((select count(*) from skilltree_projects) = 0, 'anon non legge i progetti');
select pg_temp.ok((select count(*) from skilltree_uploads) = 0, 'anon non legge i caricamenti');
select pg_temp.ok(skilltree_client_get('sbagliato') is null, 'token sbagliato: niente');
select pg_temp.ok(skilltree_client_get('') is null and skilltree_client_get(null) is null, 'token vuoto: niente');
select pg_temp.ok(skilltree_client_get((select t from tk where slug='uno')) ->> 'name' = 'Uno', 'token giusto: vede il suo progetto');
select pg_temp.ok(skilltree_client_get((select t from tk where slug='uno'))::text not like '%SEGRETO-INTERNO%', 'il cliente non riceve la roadmap interna');
select pg_temp.ok(not (skilltree_client_get((select t from tk where slug='uno')) ? 'roadmap') and not (skilltree_client_get((select t from tk where slug='uno')) ? 'state'), 'né roadmap né stato nella risposta');
select skilltree_client_sent((select t from tk where slug='uno'), 'c1', 'logo.svg', (select t from tk where slug='uno') || '/c1/1-logo.svg');
select skilltree_client_sent((select t from tk where slug='uno'), 'c2', 'risposta', null, 'The contact is Maya');
select pg_temp.ok(jsonb_array_length(skilltree_client_get((select t from tk where slug='uno')) -> 'sent') = 2, 'il cliente rivede ciò che ha mandato');
select pg_temp.ok(jsonb_array_length(skilltree_client_get((select t from tk where slug='due')) -> 'sent') = 0, 'un altro cliente non vede quei file');
select pg_temp.ok(pg_temp.fails(format($$select skilltree_client_sent(%L,'c9','a','%s/c9/a')$$, (select t from tk where slug='uno'), (select t from tk where slug='uno'))), 'richiesta inesistente rifiutata');
select pg_temp.ok(pg_temp.fails(format($$select skilltree_client_sent(%L,'c1','a',%L)$$, (select t from tk where slug='uno'), (select t from tk where slug='due') || '/c1/a')), 'percorso nella cartella di un altro rifiutato');
select pg_temp.ok(pg_temp.fails(format($$select skilltree_client_sent(%L,'c1','a')$$, (select t from tk where slug='uno'))), 'né file né nota: rifiutato');
select pg_temp.ok(pg_temp.fails($$select skilltree_client_sent('x','c1','a',null,'n')$$), 'token sbagliato non registra');
select pg_temp.ok(pg_temp.fails(format($$select skilltree_set_state(%L,'done','db#1',true)$$, (select id from tk where slug='uno'))), 'anon non può chiamare set_state');
select pg_temp.ok(pg_temp.fails($$select skilltree_private.is_admin(); select * from skilltree_admins$$) or (select count(*) from skilltree_admins) = 0, 'anon non vede gli admin');
-- versioni e controlli
select skilltree_client_check((select t from tk where slug='uno'), '0.1', 1, true);
select skilltree_client_check((select t from tk where slug='uno'), '0.1', 0, true);
select skilltree_client_check((select t from tk where slug='uno'), '0.1', 0, false);
select pg_temp.ok(skilltree_client_get((select t from tk where slug='uno')) -> 'checks' = '{"0.1":{"1":1}}', 'il cliente spunta e toglie i controlli');
select pg_temp.ok(pg_temp.fails(format($$select skilltree_client_check(%L,'0.1',2,true)$$, (select t from tk where slug='uno'))), 'controllo inesistente rifiutato');
select pg_temp.ok(pg_temp.fails(format($$select skilltree_client_check(%L,'9.9',0,true)$$, (select t from tk where slug='uno'))), 'versione inesistente rifiutata');
select pg_temp.ok(pg_temp.fails(format($$select skilltree_client_check(%L,'0.1',0,true)$$, (select t from tk where slug='due'))), 'un cliente non spunta le versioni di un altro');
select pg_temp.ok(pg_temp.fails($$select skilltree_client_check('sbagliato','0.1',0,true)$$), 'token sbagliato non spunta');
-- archivio
insert into storage.objects (bucket_id, name) values ('skilltree', (select t from tk where slug='uno') || '/c1/1-logo.svg');
select pg_temp.ok(pg_temp.fails($$insert into storage.objects (bucket_id,name) values ('skilltree','indovinato/c1/a.txt')$$), 'caricamento in cartella senza token valido rifiutato');
select pg_temp.ok(pg_temp.fails($$insert into storage.objects (bucket_id,name) values ('altro',(select t from tk limit 1)||'/c1/a')$$), 'altro bucket rifiutato');
select pg_temp.ok((select count(*) from storage.objects) = 0, 'anon non legge né elenca i file');
select pg_temp.ok(pg_temp.fails($$delete from skilltree_projects$$) or (select true), 'delete anon senza effetto');
reset role;
select pg_temp.ok((select count(*) from skilltree_projects) = 2 and (select count(*) from storage.objects) = 1, 'dati intatti dopo i tentativi anon');

-- ===== utente registrato ma non admin =====
set role authenticated; select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000000b', false);
select pg_temp.ok((select count(*) from skilltree_projects) = 0 and (select count(*) from skilltree_uploads) = 0 and (select count(*) from storage.objects) = 0, 'utente non admin non legge nulla');
select skilltree_set_state((select id from tk where slug='uno'),'done','db#1',true);
reset role;
select pg_temp.ok((select state from skilltree_projects where slug='uno') = '{}', 'utente non admin non cambia lo stato');

-- ===== admin =====
set role authenticated; select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000000a', false);
select pg_temp.ok((select count(*) from skilltree_projects) = 2 and (select count(*) from skilltree_uploads) = 2 and (select count(*) from storage.objects) = 1, 'admin vede progetti, caricamenti, file');
select skilltree_set_state((select id from tk where slug='uno'),'done','db#1',true);
select skilltree_set_state((select id from tk where slug='uno'),'done','db#2',true);
select skilltree_set_state((select id from tk where slug='uno'),'got','c1',true);
select skilltree_set_state((select id from tk where slug='uno'),'done','db#1',false);
select skilltree_set_week((select id from tk where slug='uno'), 3);
select pg_temp.ok((select (state -> 'done') ? 'db#2' and not (state -> 'done') ? 'db#1' and (state -> 'done' ->> 'db#2')::bigint > 1700000000 and (state -> 'got') ? 'c1' and (state ->> 'week')::int = 3 from skilltree_projects where slug='uno'), 'stato: accendi (con data), spegni, settimana');
select pg_temp.ok(pg_temp.fails(format($$select skilltree_set_state(%L,'roadmap','x',true)$$, (select id from tk where slug='uno'))), 'chiave di stato non ammessa rifiutata');
select pg_temp.ok((select state from skilltree_projects where slug='due') = '{}', 'lo stato di un progetto non tocca l''altro');
select pg_temp.ok((select checks from skilltree_projects where slug='due') = '{}' and (select (state -> 'done') ? 'db#2' from skilltree_projects where slug='uno'), 'le spunte del cliente non toccano l''avanzamento interno');
reset role;
set role anon;
select pg_temp.ok(skilltree_client_get((select t from tk where slug='uno')) -> 'received' = '["c1"]', 'il cliente vede "ricevuto" su c1');
reset role;
