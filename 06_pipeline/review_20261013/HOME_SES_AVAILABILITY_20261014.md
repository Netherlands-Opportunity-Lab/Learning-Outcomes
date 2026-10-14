# A04 — officiële Home-SES in de appendix

Direct gebruikersbesluit 14 oktober: toevoegen in de appendix, consistente definitie over jaren en expliciet melden waar brondata ontbreken. Dit autoriseert geen verwisseling met boekenkwartielen of de oudere Home Resources for Learning-schaal. De bestaande boekenkwartielen blijven de lange IEA-basisreeks.

| Onderzoek / jaren uit Nederlands anker | Status officiële Home-SES | Consequentie |
|---|---|---|
| PIRLS 2001, 2006, 2011, 2016 | De nieuwe Home-SES-schaal is in PIRLS 2021 geïntroduceerd. Oudere Home Resources is een ander construct. | Geen officiële Home-SES-trend terugvullen. Eventuele reconstructie zou een afzonderlijk gevalideerde harmonisatie vereisen. |
| PIRLS 2021 | Gepubliceerd; Nederland is opgenomen. Het IEA-rapport vermeldt voor Nederland 47,7% respons op de SES-schaal. | Bronvariabelen, gewogen respons, selectiviteit en noemers eerst controleren; beschikbaarheid is geen representativiteitsbewijs. |
| TIMSS 2003, 2007, 2011, 2015, 2019 | Eerdere publicaties gebruiken Home Resources for Learning; de moderne Home-SES-definitie wordt niet als dezelfde lange reeks behandeld. | Geen automatische substitutie of doorlopende trend. |
| TIMSS 2023, Nederland | Oudervragenlijst niet afgenomen. | Home-SES ontbreekt; niet berekenen of imputeren uit een andere maat. |

Hetzelfde TIMSS-rapport noemt Australië, Engeland en de VS zonder oudervragenlijst. Engeland is een afzonderlijk onderwijssysteem: de code mag niet stilzwijgend als geheel Verenigd Koninkrijk worden gebruikt. De machineadapter markeert alleen eenduidige nationale codes NLD/AUS/USA; Engeland vereist de expliciete systeemmapping.

De audit schrijft `HOME_SES_YEAR_AVAILABILITY.csv` per geselecteerd land en jaar. Onbekende nationale beschikbaarheid blijft `REQUIRES_COUNTRY_SOURCE_RESPONSE_CHECK`; dat betekent niet dat de data aantoonbaar ontbreken. De producent vereist een gecertificeerd `HOME_SES_GROUP` en `home_ses_construct=IEA_OFFICIAL_HOME_SES`. Hij neemt geen numerieke broncodes als groepen aan zonder gecontroleerde mapping. Iedere resultaatcel blijft aan haar eigen survey/jaar/editie gebonden; een gezamenlijke trend vereist apart vergelijkbaarheidsbewijs.

Bronnen, gecontroleerd op 14 oktober 2026:

- [IEA, Socioeconomic Status in PIRLS 2021](https://files.eric.ed.gov/fulltext/ED676159.pdf), p. 1: nieuwe schaal; p. 15: Nederlandse SES-respons. [Officiële aankondiging](https://timssandpirls.bc.edu/latest-news/pirls-2021-insights-socioeconomic-status.html).
- [IEA, TIMSS 2023 School Climate Health](https://files.eric.ed.gov/fulltext/ED679640.pdf), p. 6 voetnoot b en p. 16: ontbrekende oudervragenlijst/SES voor Nederland en genoemde systemen.
- [TIMSS 2019 officiële contextschalen](https://timssandpirls.bc.edu/timss2019/methods/pdf/T19_MP_Ch16-AppA-context-scales-grade-4.pdf): Home Resources for Learning, gekoppeld aan de oudere schaal, geen moderne Home-SES.
- [ERC, Home learning environment, TIMSS 2023](https://www.erc.ie/wp-content/uploads/2026/02/Piccio-et-al.-2025_TIMSS-The-home-learning-environment-of-students-in-Ireland.pdf), p. 9: Home-SES uit ouderrapportage met drie categorieën.
