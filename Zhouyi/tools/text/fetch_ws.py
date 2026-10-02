import json,urllib.request,urllib.parse,time,os
d=json.load(open('ref/freizl_zh-TW_64gua.json'))
os.makedirs('ref/ws',exist_ok=True)
for i,g in enumerate(d,1):
    t='周易/'+{25:'无妄',31:'咸'}.get(i,g['name'])
    p=f'ref/ws/{i:02d}.txt'
    if os.path.exists(p): continue
    u='https://zh.wikisource.org/w/api.php?action=query&prop=revisions&rvprop=content&rvslots=main&format=json&titles='+urllib.parse.quote(t)
    for k in range(4):
        try:
            r=urllib.request.urlopen(urllib.request.Request(u,headers={'User-Agent':'verify-script lswang6@gmail.com'}),timeout=30).read()
            pg=list(json.loads(r)['query']['pages'].values())[0]
            open(p,'w').write(pg['revisions'][0]['slots']['main']['*']);break
        except Exception as e: print(i,t,e);time.sleep(2)
    time.sleep(.3)
