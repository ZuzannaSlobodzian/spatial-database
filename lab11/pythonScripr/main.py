import requests

url = 'http://FELICYJA:8081/fmedatadownload/Dashboards/fme.fmw?email=izabela.kukurydza%40gmail.com&emailKlient=izabela.kukurydza%40gmail.com&powiat=%C5%82osicki&haslo=aaaa&chmury=70&dataPoczatkowa=20230701000000&dataKoncowa=20230730000000&api=8f734d39-bd34-43e9-8bfb-1431ed378c4e%20&SourceDataset_SHAPEFILE=C%3A%5CUsers%5Czuzka%5CDocuments%5Cstudia%5CGEOINFA%5CBazy_danych_przestrzennych%5Clab9%5Cpowiaty%5Cpowiaty.shp&DestDataset_GEOTIFF=C%3A%5CUsers%5Czuzka%5CDocuments%5Cstudia%5CGEOINFA%5CBazy_danych_przestrzennych%5Clab9&opt_showresult=false&opt_servicemode=sync'

myobj = {'Authorization': 'fmetoken token=6f635c9da62009fa36586a5d913074f502afafd5'}

x = requests.post(url, headers=myobj)

print(x.text)
