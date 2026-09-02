// Przepięcie filmów demo do właściwych branż (klasyfikacja klatek 2026-09-02).
const path=require('path'),fs=require('fs');
const {initializeApp,cert}=require('firebase-admin/app');
const {getFirestore}=require('firebase-admin/firestore');
initializeApp({credential:cert(path.join('..',fs.readdirSync('..').find(f=>f.includes('adminsdk'))))});
const db=getFirestore();
const PLAN={
 'Barber':['bar1w','den4w','den9w','e11w','re7w','sp1w','sro1w','sto2w','w9w','bar1w'],
 'Catering':['e8w','nie3w','opz10w','re12w','se5w'],
 'Dentyści':['ca2w','e7w','nie2w','se1w','se2w','sp7w','sro5w','sto7w','w6w'],
 'Elektryk':['bar4w','den7w','e4w','na1w','opz1w','opz2w','opz3w','opz6w','pr2w','re5w','re13w','w10w'],
 'Hydraulik':['e5w','e10w','h3w','h9w','nie8w','re6w','sro4w','u1w','w5w'],
 'Naprawa telefonów':['ca5w','opz8w','se4w','u4w','w4w'],
 'Nieruchomości':['ca4w','den2w','nie1w','opz4w','pr11w','re4w','re11w','se6w','w2w'],
 'Opieka nad zwierzętami':['den6w','e6w','opz5w','re8w','sto4w','sto5w','sto9w','u2w','u3w','u8w'],
 'Kancelaria prawnicza':['bar3w','h1w','h2w','h5w','h6w','pr4w','pr5w','pr7w','re3w','sp8w','sto6w','u5w','pr9w'],
 'Restauracja':['bar9w','e2w','na5w','nie6w','pr6w','pr8w','sp9w','sro8w','u6w','w3w','w8w','nie5w','opz9w'],
 'Serwis RTV AGD':['den5w','na2w','na3w','nie4w','u7w','sto8w'],
 'Sprzątanie':['den3w','h4w','re10w','sp4w','sto1w','w1w','w11w','pr1w'],
 'Sklep rowerowy':['bar10w','ca3w','den1w','nie7w','pr3w','se3w','sp3w'],
 'Stolarz':['bar5w','bar7w','e1w','e3w','e9w','e12w','opz7w','pr10w','sp6w'],
 'Ubezpieczenia':['den8w','nie10w','pr13w','re1w','re2w','sp2w','sro7w','w12w','bar2w'],
 'Mechanik samochodowy':['bar6w','bar8w','h10w','na4w','pr12w','re9w','sro2w','sro6w','sto10w','bar6w','h10w'],
};
const num=s=>parseInt(s.replace(/\D/g,''))||0;
(async()=>{
  const snap=await db.collection('promos').get();
  const files={};                       // nazwa pliku -> {fileUrl,thumbUrl}
  const bySector={};
  for(const d of snap.docs){const x=d.data();const fn=(x.fileName||'').replace('.mp4','');
    if(!/^[a-z]+\d+w$/.test(fn))continue;        // tylko pliki seedu, uploady z apki zostają
    files[fn]={fileUrl:x.fileUrl,thumbUrl:x.thumbUrl};
    (bySector[x.sector]=bySector[x.sector]||[]).push({id:d.id,fn,name:x.companyName});}
  const missing=Object.values(PLAN).flat().filter(f=>!files[f]);
  if(missing.length){console.log('BRAK W BAZIE:',missing);process.exit(1);}
  let batch=db.batch(),n=0,changed=0;
  for(const [sector,videos] of Object.entries(PLAN)){
    const firms=(bySector[sector]||[]).sort((a,b)=>num(a.fn)-num(b.fn));
    if(firms.length!==videos.length){console.log('ROZJAZD',sector,firms.length,'firm vs',videos.length,'filmów');process.exit(1);}
    firms.forEach((f,i)=>{const v=videos[i];if(v===f.fn)return;
      batch.update(db.collection('promos').doc(f.id),{fileUrl:files[v].fileUrl,thumbUrl:files[v].thumbUrl,fileName:v+'.mp4'});
      console.log(sector.padEnd(22),(f.name||'').slice(0,34).padEnd(35),f.fn,'->',v);changed++;
      if(++n>=400){}});
  }
  await batch.commit();
  console.log('zmienionych prezentacji:',changed);process.exit(0);
})();
