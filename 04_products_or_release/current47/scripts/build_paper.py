"""Write the Dutch research paper from certified public aggregates and Q08.

The manuscript is an editable Markdown source plus a typeset PDF. All numeric
tables are generated from the same point/claim identities as the presentation
and dashboard. This builder calculates no pupil statistic or new test.
"""
import argparse
import csv
import hashlib
import json
import shutil
from pathlib import Path
from xml.sax.saxutils import escape

from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    BaseDocTemplate, Frame, PageTemplate, Paragraph, Spacer, PageBreak,
    Table, TableStyle, KeepTogether, Image,
)


def sha(p):
    with p.open('rb') as f:
        return hashlib.file_digest(f, 'sha256').hexdigest()


def fmt(x, places=1):
    return 'Niet beschikbaar' if x in ['', None] else f'{float(x):,.{places}f}'.replace(',', 'X').replace('.', ',').replace('X', '.')


DOMAIN = {'reading': 'Lezen', 'mathematics': 'Rekenen/wiskunde',
          'science': 'Natuurwetenschappen', 'all': 'Leeromgeving'}
TABLE_DOMAIN = {**DOMAIN, 'mathematics': 'Rekenen/wisk.', 'science': 'Natuurwet.'}
MODULE = {
    'ses_national': 'Boekenkwartielen', 'ses_harmonized': 'Cobreros-SES',
    'extension_ses_gender': 'SES × geslacht', 'extension_home_ses': 'Officiële Home-SES',
    'extension_performance_school': 'Prestaties: tussen scholen',
    'extension_performance_class': 'Prestaties: tussen klassen',
    'extension_ses_school': 'SES: tussen scholen',
    'extension_ses_class': 'SES: tussen klassen',
}
STAT = {'mean': 'Gemiddelde', 'below': 'Onder basisniveau (%)',
        'high': 'Hoog/gevorderd (%)', 'q1_high': 'Hoog/gevorderd (%)',
        'q4_high': 'Hoog/gevorderd (%)', 'between_variance_share': 'Aandeel variantie (%)'}
GROUP = {
    'total': 'Alle leerlingen', 'q1': 'Onderste kwart', 'q4': 'Bovenste kwart',
    'q4_minus_q1': 'Q4 min Q1', 'lower': 'Lage Home-SES', 'middle': 'Midden Home-SES',
    'higher': 'Hoge Home-SES', 'q1_girl': 'Onderste kwart, meisjes',
    'q4_girl': 'Bovenste kwart, meisjes', 'q1_boy': 'Onderste kwart, jongens',
    'q4_boy': 'Bovenste kwart, jongens',
}
MODE = {'PAPER_MAIN_SAMPLE': 'Papier', 'COMPUTER_MAIN_SAMPLE': 'Computer',
        'DIGITAL_MAIN_SAMPLE_WITH_OFFICIAL_TREND_LINK': 'Digitaal, officiële trendkoppeling'}
QUALITY = {
    'SCHOOL_RESPONSE_BELOW_85_BEFORE_REPLACEMENT': 'Schoolrespons vóór vervanging < 85%',
    'EXCLUSION_ABOVE_FIVE_PERCENT': 'Uitsluiting > 5%',
    'COMBINED_RESPONSE_BELOW_75_PERCENT': 'Gecombineerde respons < 75%',
    'TARGET_COVERAGE_BELOW_95_PERCENT': 'Doelpopulatiedekking < 95%',
    'STUDENT_RESPONSE_BELOW_STUDY_TARGET': 'Leerlingrespons onder de studiedrempel',
}


def main(data_dir, fonts, out):
    data = json.loads((data_dir / 'RESEARCH_TABLES.json').read_text(encoding='utf-8'))
    figures = json.loads((data_dir / 'RESEARCH_PRODUCT_DATA.json').read_text(encoding='utf-8'))
    if data['provenance']['scientific_manifest_sha256'] != figures['provenance']['scientific_manifest_sha256']:
        raise ValueError('Paper and dashboard have different scientific versions')
    results = data['results']
    claims = {r['claim_id']: r for r in data['claims']}
    if len(claims) != 12:
        raise ValueError('Paper requires precisely the registered twelve claims')
    tested = [r for r in claims.values() if r['formal_test'] == 'TRUE']
    if (len(tested) != 3 or max(float(r['p_holm']) for r in tested) >= .001
            or any(float(r['estimate']) >= 0 for r in tested)):
        raise ValueError('Registered formal-test wording needs substantive review')
    ses_claims = [r for r in claims.values() if '_SES_GAP_' in r['claim_id']]
    if len(ses_claims) != 6 or any(float(r['estimate']) <= 0 for r in ses_claims):
        raise ValueError('The six positive SES-gap descriptions need substantive review')
    math_trend = claims['NLD_TREND_TIMSS_MATHEMATICS']
    if not float(math_trend['ci_low']) <= 0 <= float(math_trend['ci_high']):
        raise ValueError('The cautious TIMSS mathematics interpretation needs review')
    out.mkdir(parents=True, exist_ok=True)
    figure_manifest_path = data_dir / 'paper_figures' / 'PAPER_FIGURE_MANIFEST.json'
    figure_manifest = json.loads(figure_manifest_path.read_text(encoding='utf-8'))
    if figure_manifest['provenance'] != figures['provenance']:
        raise ValueError('Paper figure provenance is stale; rebuild the scientific figures')
    # The editable manuscript must travel with its actual, hash-verified figures.
    asset_dir = out / 'paper_figures'
    asset_dir.mkdir(exist_ok=True)
    shutil.copy2(figure_manifest_path, asset_dir / figure_manifest_path.name)
    pdfmetrics.registerFont(TTFont('Oswald', str(fonts / 'font2.ttf')))
    pdfmetrics.registerFont(TTFont('OswaldMedium', str(fonts / 'font3.ttf')))
    pdfmetrics.registerFontFamily('Oswald', normal='Oswald', bold='OswaldMedium', italic='Oswald', boldItalic='OswaldMedium')
    styles = {
        'body': ParagraphStyle('body', fontName='Oswald', fontSize=11.5, leading=16, allowWidows=0, allowOrphans=0,
                               textColor=colors.HexColor('#17242D'), spaceAfter=8),
        'h1': ParagraphStyle('h1', fontName='OswaldMedium', fontSize=19, leading=24, spaceBefore=18, spaceAfter=10, keepWithNext=True),
        'h2': ParagraphStyle('h2', fontName='OswaldMedium', fontSize=14, leading=19, spaceBefore=12, spaceAfter=7, keepWithNext=True),
        'title': ParagraphStyle('title', fontName='OswaldMedium', fontSize=30, leading=37, spaceAfter=18),
        'small': ParagraphStyle('small', fontName='Oswald', fontSize=9, leading=12, textColor=colors.HexColor('#59636A'), spaceAfter=7),
        'cell': ParagraphStyle('cell', fontName='Oswald', fontSize=9, leading=12),
    }
    story, md, trace, prose = [], [], [], []
    current_section = 'Titel'

    def p(text, style='body', claim_ids=()):
        story.append(Paragraph(escape(text).replace('\n', '<br/>'), styles[style]))
        text_id = f'PAPER_TEXT_{len(prose)+1:03d}'
        # IDs live next to the editable text and in the trace, without filling
        # the reader-facing PDF with internal identifiers.
        md.append(f'<!-- {text_id} -->')
        md.append(text + '\n')
        parent_rows = [r for r in data['claim_dependencies'] if r['claim_id'] in claim_ids]
        if claim_ids and {r['claim_id'] for r in parent_rows} != set(claim_ids):
            raise ValueError('A written result statement has no exact claim parents')
        prose.append(dict(claim_id=text_id, section=current_section, text=text,
            text_sha256=hashlib.sha256(text.encode('utf-8')).hexdigest(),
            registered_claim_ids=list(claim_ids), exact_parent_records=parent_rows,
            source_tables_sha256=sha(data_dir / 'RESEARCH_TABLES.json'),
            interpretation='existing_registered_results' if claim_ids else 'method_scope_or_context',
            new_formal_test=False))

    def heading(text, level=1):
        nonlocal current_section
        current_section = text
        story.append(Paragraph(escape(text), styles['h1' if level == 1 else 'h2']))
        md.append('#' * (level + 1) + ' ' + text + '\n')

    def table(title, headers, rows, widths=None, footnote='', dependencies=None):
        heading(title, 2)
        content = [[Paragraph(escape(str(v)), styles['cell']) for v in row] for row in [headers, *rows]]
        if footnote:
            # Keep the note with the final data row, including when the table
            # spans pages. A standalone flowable can otherwise fill a page alone.
            content.append([Paragraph(escape(footnote), styles['small'])] + [''] * (len(headers) - 1))
        t = Table(content, colWidths=widths, repeatRows=1, hAlign='LEFT')
        t.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#EDEEF9')),
            ('LINEBELOW', (0, 0), (-1, 0), .7, colors.HexColor('#59636A')),
            ('LINEBELOW', (0, 1), (-1, -1), .3, colors.HexColor('#D8D8D3')),
            ('VALIGN', (0, 0), (-1, -1), 'TOP'),
            ('LEFTPADDING', (0, 0), (-1, -1), 5), ('RIGHTPADDING', (0, 0), (-1, -1), 5),
            ('TOPPADDING', (0, 0), (-1, -1), 5), ('BOTTOMPADDING', (0, 0), (-1, -1), 5),
        ]))
        if footnote:
            t.setStyle(TableStyle([
                ('SPAN', (0, -1), (-1, -1)),
                ('NOSPLIT', (0, -2), (-1, -1)),
                ('LINEBELOW', (0, -1), (-1, -1), 0, colors.white),
                ('LEFTPADDING', (0, -1), (-1, -1), 0),
                ('TOPPADDING', (0, -1), (-1, -1), 8),
            ]))
        story.append(t); story.append(Spacer(1, 8))
        md.extend(['| ' + ' | '.join(map(str, headers)) + ' |',
                   '| ' + ' | '.join(['---'] * len(headers)) + ' |',
                   *['| ' + ' | '.join(str(v).replace('|', '/') for v in r) + ' |' for r in rows], ''])
        if footnote:
            md.append(footnote + '\n')
        trace.append(dict(claim_id=f'PAPER_TABLE_{sum("table" in x for x in trace)+1:02d}',
                          table=title, dependencies=dependencies or [],
                          displayed_headers=headers, displayed_rows=rows,
                          source_tables_sha256=sha(data_dir / 'RESEARCH_TABLES.json'),
                          result_or_definition_source='RESEARCH_TABLES.json / RESEARCH_PRODUCT_DATA.json',
                          formal_test_created=False))

    def figure(name, caption):
        path = data_dir / 'paper_figures' / (name + '.png')
        if not path.exists():
            raise ValueError('Missing verified scientific plot: ' + name)
        image = Image(str(path), width=487, height=274)
        story.append(KeepTogether([image, Paragraph(escape(caption), styles['small'])]))
        md.append(f'![{caption}](paper_figures/{name}.png)\n')
        record = figure_manifest['figures'][name]
        if sha(path) != record['png_sha256']:
            raise ValueError('Paper figure bytes do not match the reviewed manifest: ' + name)
        for suffix in ['.png', '.svg']:
            source = path.with_suffix(suffix)
            if sha(source) != record[suffix[1:] + '_sha256']:
                raise ValueError('Paper figure asset hash mismatch: ' + source.name)
            shutil.copy2(source, asset_dir / source.name)
        trace.append(dict(claim_id='PAPER_FIGURE_' + name.upper(), figure=name,
                          image_sha256=sha(path), figure_ids=record['figure_ids'],
                          dependency_register='PRODUCT_POINT_LINEAGE.json'))

    logo = data_dir / 'paper_figures' / 'leerprestaties-logo.png'
    if not logo.exists():
        raise ValueError('Approved outlined logo has not been rendered')
    shutil.copy2(logo, asset_dir / logo.name)
    story.append(Image(str(logo), width=212.8, height=58.4, hAlign='LEFT'))
    story.append(Spacer(1, 18))
    md.append('![Leerprestaties](paper_figures/leerprestaties-logo.png)\n')
    p('Nederlandse leerprestaties, sociale verschillen en leeromgevingen', 'title')
    p('PIRLS, TIMSS en PISA in een reproduceerbaar internationaal kader', 'h2')
    p('Kansenlab / Netherlands Opportunity Lab\nOnderzoeksversie oktober 2026. Selectie: huidige 47 landen en onderwijssystemen.', 'small')
    heading('Samenvatting')
    p('Dit onderzoek beschrijft de ontwikkeling van leerprestaties in Nederland, verschillen naar achtergrond en de samenstelling van de leeromgeving. Het combineert herhaalde internationale dwarsdoorsneden voor het vierde leerjaar (Nederlandse groep 6) en 15-jarigen. Lezen, rekenen/wiskunde en natuurwetenschappen worden per studie en populatie afzonderlijk geanalyseerd. Het pakket bevat een interactief dashboard, een beleidsgerichte presentatie en een volledig herleidbaar resultatengrid.')
    tr = lambda study, domain: claims[f'NLD_TREND_{study}_{domain.upper()}']
    p(f"De geschatte verandering in lezen in groep 6 tussen 2001 en 2021 bedraagt {fmt(tr('PIRLS','reading')['estimate'])} PIRLS-punten. In TIMSS bedragen de veranderingen tussen 2003 en 2023 {fmt(tr('TIMSS','mathematics')['estimate'])} punten voor rekenen en {fmt(tr('TIMSS','science')['estimate'])} punten voor natuurwetenschappen. Bij 15-jarigen bedragen de geregistreerde langetermijnveranderingen {fmt(tr('PISA','reading')['estimate'])} PISA-punten voor lezen, {fmt(tr('PISA','mathematics')['estimate'])} voor wiskunde en {fmt(tr('PISA','science')['estimate'])} voor natuurwetenschappen. Deze veranderingen betreffen verschillende perioden en schalen; zij worden niet onderling als leeftijdseffect vergeleken.",
      claim_ids=[k for k in claims if k.startswith('NLD_TREND_')])
    p('Sociale verschillen worden bij de jongere leerlingen gemeten met nationale boekenkwartielen en bij PISA met een vooraf gekozen, trendvergelijkbare SES-constructie. Die constructen zijn niet uitwisselbaar. Verschillen en peerblootstelling zijn beschrijvend. Steekproefrespons, uitsluitingen, afnamemodus, ontbrekende achtergrondkenmerken en meetonzekerheid begrenzen de interpretatie.')

    heading('1. Vraagstelling en onderzoeksopzet')
    p('De centrale vraag is hoe Nederlandse leerprestaties zich door de tijd ontwikkelen, voor welke groepen verschillen zichtbaar zijn en hoe leerlingen over leeromgevingen zijn verdeeld. Het doel is een controleerbare beschrijving die dezelfde uitkomsten, definities en onzekerheid in alle producten gebruikt. De interactieve vergelijking met andere landen biedt context; zij verandert de Nederlandse doelgroep of meetjaren niet.')
    p('De analyse volgt geen individuele leerlingen. Veranderingen kunnen naast onderwijs en leerprocessen ook samenhangen met veranderende populaties, selectieve deelname, meetomstandigheden en achtergrondmetingen. Het verschil tussen een jongere en oudere leeftijdsgroep is geen individuele ontwikkeling. De resultaten identificeren geen causaal beleidseffect, geen effect van ouderlijk inkomen en geen causaal effect van klasgenoten.')
    p('De huidige afrondingsversie omvat 47 expliciet gekozen landen en onderwijssystemen. Van de bredere bronmatig onderzochte selectie zijn 36 systemen uitgesteld tot een latere R-run. Dat is een fasering van productie en publicatie. De toelatingseisen en historische rijke kandidatenpool zijn niet aangepast om een vooraf bepaald aantal vergelijkingslanden te bereiken.')
    p('De analyse sluit aan bij de officiële PISA-, PIRLS- en TIMSS-rapportages over prestaties en verschillen tussen leerlinggroepen. Hun technische documentatie bepaalt de populaties, schalen en variantieberekening. Voor de vergelijkbaarheid van de PISA-SES-maat volgen we de expliciet gekozen methode van Cobreros en medeauteurs (2026); de numerieke overeenkomst met hun implementatie is afzonderlijk getoetst. Onze bijdrage is een consistente beschrijving van Nederland, met dezelfde definities en herleidbare cijfers in de tijdreeksen, internationale vergelijkingen en analyses van leeromgevingen. Een geharmoniseerde achtergrondmaat neemt de beperkingen van observationele vergelijkingen niet weg.')

    heading('2. Bronnen, populaties en meetjaren')
    years = [[r['survey'], 'Groep 6' if r['age_group'] == 'age10' else '15 jaar',
              {'reading': 'Lezen', 'mathematics': 'Rekenen/wiskunde', 'science': 'Natuurwetenschappen'}[r['domain']],
              r['years'].replace(';', ', ')] for r in data['netherlands_combinations']]
    table('Tabel 1. Nederlandse basisreeksen', ['Studie', 'Populatie', 'Domein', 'Meetjaren'], years,
          [55, 57, 104, 271], 'Meetgolven zijn afzonderlijke afnames, geen jaarlijkse waarnemingen. Het SES-anker bij PISA begint in 2015.')
    p('PIRLS meet lezen; TIMSS meet rekenen/wiskunde en natuurwetenschappen. De gebruikte IEA-populatie is het internationale vierde leerjaar, in Nederland groep 6. PISA betreft de officiële nationale doelpopulatie van schoolgaande 15-jarigen. Landen en regio’s worden niet gelijkgesteld: een subnationale steekproef wordt niet gebruikt als vervanging voor een nationale populatie in een andere studie.')
    p('De broncatalogus legt voor iedere editie het officiële bestand, de bronhash, doelgroep, landidentiteit, jaar, mode en relevante kwaliteitsdocumentatie vast. Een bestandsnaam met 2025 of een zichtbaar grafiekpunt is geen bewijs van beschikbaarheid. De gebruikte PISA 2025-gegevens zijn getoetst aan de officiële databank en bijbehorende release- en kwaliteitsdocumentatie. De nog voorlopige status van onderdelen van het technische rapport blijft vermeld in het bronregister.')
    p('Officiële uitsluitings- en responspercentages blijven afzonderlijk van de aantallen in onze analysegroepen. Een gewogen schatting corrigeert niet automatisch alle gevolgen van non-respons of veranderende populatiedekking. De Nederlandse cyclusgegevens staan in bijlage A en in NLD_OFFICIAL_SAMPLE_QUALITY.csv; de internationale gegevens staan in het wetenschappelijke brondossier.')

    heading('3. Uitkomsten, achtergrondkenmerken en leeromgevingen')
    p('De basis beschrijft gemiddelde prestaties, geselecteerde percentielen, de spreiding tussen het 90e en 10e percentiel, en aandelen onder het basisniveau en op hoog/gevorderd niveau. Een plausible value is een trekking uit een verdeling voor populatieschatting, geen individuele toetsscore. Alle vereiste plausible values worden daarom in iedere toepasselijke schatting verwerkt.')
    table('Tabel 2. Gehanteerde afkappunten', ['Studie / domein', 'Onder basisniveau', 'Hoog / gevorderd'],
          [['PIRLS / lezen', '< 475', '≥ 625'], ['TIMSS / beide domeinen', '< 475', '≥ 625'],
           ['PISA / lezen', '< 407,47', '≥ 625,61'], ['PISA / wiskunde', '< 420,07', '≥ 606,99'],
           ['PISA / natuurwetenschappen', '< 409,54', '≥ 633,33']], [227, 130, 130],
          'PISA: onder niveau 2 en vanaf niveau 5. IEA: onder het Intermediate International Benchmark en vanaf het Advanced International Benchmark. Dit zijn twee verschillende afkappunten; de lage en hoge staart zijn geen complementen.')
    p('Bij IEA gebruiken we het aantal boeken thuis om binnen elk land en meetjaar gewogen kwartielen te bepalen. Bij gelijke antwoorden aan een kwartielgrens worden leerlingen fractioneel toegewezen. Daardoor is het aantal leerlingen met positieve groepsdeelname niet noodzakelijk een kwart van de steekproef. De gewogen groepsmassa en de ongewogen aantallen worden afzonderlijk verantwoord.')
    p('Bij PISA gebruiken we uitsluitend de gekozen viergolvenvariant met dertien gemeenschappelijke items uit de implementatie van Cobreros en medeauteurs (2026). Auteurscode, kalibratiesteekproef, itemparameters, schaaltoepassing en regressie-imputatie zijn gepind en numeriek gecontroleerd. De vier golven zijn 2015, 2018, 2022 en 2025. De oudere tweegolfvariant en een extra officiële-ESCS-robuustheidsanalyse zijn niet gebruikt. Het kalibratiepanel van de auteurs bepaalt niet de dashboardlanden.')
    p('De vaste kalibratie wordt ook toegepast buiten de oorspronkelijke kalibratiesteekproef. Controle van veldkoppelingen, scoreberekening en ontbrekende waarden bewijst numerieke reproduceerbaarheid, maar bewijst geen meetinvariantie of willekeurige ontbrekendheid in die aanvullende landen. Onzekerheidsmarges zijn conditioneel op deze constructie en op de vastgezette kalibratieparameters.')
    p('Geslacht wordt aan de hand van de officiële veldlabels per broneditie gekoppeld. Afzonderlijke meisjes blijven afzonderlijk waar zij worden waargenomen. Alleen waar de openbare bron meisjes niet apart van “Other” bevat, wordt de expliciet goedgekeurde categorie “Meisjes + other” gebruikt. Die categorie houdt een eigen definitie en zichtbaar label; zij wordt niet als identiek aan een afzonderlijke meisjescategorie behandeld.')
    p('Migratieachtergrond heeft drie afzonderlijke definities: minstens één in het buitenland geboren ouder; beide ouders in het buitenland geboren; en eerste of tweede generatie afzonderlijk. De laatste definitie gebruikt ook de geboorteplaats van de leerling. Een derde generatie wordt niet afgeleid. De noemer is per definitie bepaald door de beschikbare geboorteplaatsen: onbekende geboorteplaatsen zijn geen geboorten in het land van afname.')
    p('Taalgebruik thuis wordt volgens de bronvraag onderscheiden. Een frequentie van de toetstaal thuis is een ander construct dan uitsluitend de opgegeven thuistaal. Labels en breuken in vergelijkbaarheid worden behouden. De afgewezen interactie tussen taal en migratie wordt niet toegevoegd.')
    p('Peerblootstelling is het leerlinggewogen aandeel van een kenmerk bij andere leerlingen in dezelfde beschikbare leeromgeving, met uitsluiting van de leerling zelf. IEA gebruikt de geïdentificeerde klas; PISA gebruikt waar beschikbaar het onderwijsprogramma binnen de school. Dat laatste is geen volledige klasidentificatie. De gehele school vormt een afzonderlijke uitkomst. Ontbrekende unitcodes en eenheden zonder andere geldige leerlingen leveren geen kunstmatig nulpercentage op.')
    p('Zowel peers onder basisniveau als hoog vaardige peers zijn opgenomen. De groepsindeling op eigen vaardigheid en de peeruitkomst worden per plausible value bepaald. De noemers gebruiken waargenomen kenmerken en de betreffende leerlinggewichten. De school- en klasvarianten van prestatie- en SES-variantie zijn beschrijvende spreidingsaandelen; zij worden niet als schoolkwaliteit of als schatting van een causaal schooleffect geïnterpreteerd.')

    heading('4. Weging, onzekerheid en vergelijkingen')
    p('PISA-schattingen gebruiken het studentgewicht en alle 80 BRR-replicatiegewichten, met Fay-factor 0,5 en de bijbehorende variantiefactor 1/20. Bij de oudere gebruikte cycli worden vijf plausible values verwerkt en vanaf 2015 tien. PIRLS en TIMSS gebruiken de officiële studentgewichten, vijf plausible values en het bijbehorende cyclusgebonden jackknife-ontwerp. Variantie wordt gepoold over de plausible values volgens de bronmethode.')
    p('Kloven worden binnen dezelfde replicaties en plausible values berekend. Hun standaardfout omvat daardoor de gezamenlijke covariantie van de twee groepen. Het optellen van afzonderlijke groepsvarianties zonder die covariantie is hier geen vervanging. Bij de SES-indeling worden de relevante gewogen groepen ook binnen de replicaties opgebouwd.')
    p('Getoonde puntintervallen zijn normaalbenaderingen van 95%: schatting plus of min 1,96 maal de gecertificeerde standaardfout. Zij beschrijven steekproef- en plausible-value-onzekerheid, geen spreiding van individuele leerlingen en geen volledige correctie voor non-respons of meetproblemen. Overlap van twee puntintervallen is geen toets van een verandering. Als een bronresultaat een proportie is, worden de schatting en standaardfout voor de procentweergave met 100 vermenigvuldigd. Resultaten die al percentages zijn, blijven ongewijzigd. Alle opgeslagen waarden behouden volledige precisie.')
    p('Voor de drie geregistreerde PISA-langetermijnveranderingen wordt de officiële extra onzekerheid van de koppeling tussen het begin- en eindjaar toegevoegd aan de variantie van het verschil. Die linking error betreft de vergelijkbaarheid van scores over afnames: ook als de steekproeven groot zijn, is de verbinding tussen twee meetschalen niet exact. Zij verandert de geschatte verandering niet, maar vergroot de onzekerheidsmarge. De drie p-waarden krijgen gezamenlijk een Holm-correctie.')
    p('Bij de IEA-langetermijnveranderingen is de beschikbare steekproef/PV-onzekerheid niet aangevuld met een volledig gekwantificeerde langetermijn-linkingvariantie. Deze veranderingen en hun conditionele intervallen worden uitsluitend beschrijvend gerapporteerd. Er wordt geen formele significantieclaim aan verbonden. De twaalf Nederlandse paperclaims zijn geregistreerd nadat resultaten beschikbaar waren, vóór het schrijven van de paper; dit is geen prospectieve preregistratie. Wijzigingen in claims of ouderschattingen vereisen een nieuwe Q08-controle.')
    p('Voor openbare figuren vereist het project ten minste dertig doelgroepleerlingen in elk noodzakelijk onderdeel en iedere vereiste plausible value. Waar schoolidentificaties worden waargenomen, zijn ten minste vijf waargenomen scholen vereist. Ontbrekende schoolidentificatie is geen waarneming van nul scholen en wordt afzonderlijk verantwoord. Een tekort blijft een kwaliteitsvoorbehoud: de taak en gecertificeerde schatting blijven bewaard, maar het punt komt niet in een figuur, referentiegemiddelde of rang. Voldoende aantallen zijn op zichzelf geen bewijs van representativiteit. Een geldige nul met voldoende ondersteuning blijft wel een resultaat.')
    p('Een land kan voor een bepaalde leeftijd-domeincombinatie worden toegelaten na minstens drie vergelijkbare meetgolven. Een referentieland moet bovendien alle jaren van het hoofdland en alle samen getoonde groepen en leeromgevingen in die figuur volledig dekken. De groep blijft binnen de figuur gelijk. Tussen figuren mogen groepen verschillen. Jaren, groepen of de hoofdlandpopulatie worden niet verkort om een vergelijking mogelijk te maken.')
    p('De standaard kiest de passende landen uit de historisch vastgelegde rijke OESO-kandidatenpool en sluit het hoofdland uit. Ieder referentieland telt even zwaar. Dit is een gemiddelde van landen, niet een gepoold leerlinggemiddelde. Een lege groep blijft leeg. De huidige 47-landenafbakening geldt ook voor referenties; uitgestelde landen tellen nu niet mee.')
    p('Rangen worden berekend op de ongeronde uitkomsten binnen het hoofdland plus dezelfde geselecteerde referentielanden. Exact gelijke waarden krijgen de gemiddelde rang. Voor scores en hoge vaardigheid komt de hoogste waarde eerst; voor het aandeel onder basisniveau, spreiding en de absolute grootte van een kloof de laagste. Het teken van een kloof blijft bewaard bij de bronwaarde. Rangen zijn beschrijvend en hebben geen overgenomen score-standaardfout. De internationale groep krijgt geen eigen ranglijn.')

    heading('5. Nederlandse resultaten')
    trend_rows = []
    gap_rows = []
    for c in data['claims']:
        label = c['survey'] + ' / ' + {'reading': 'lezen', 'mathematics': 'rekenen/wiskunde', 'science': 'natuurwetenschappen'}[c['domain']]
        if c['type'] == 'LONG_TERM_MEAN_CHANGE':
            trend_rows.append([label, c['start_year'] + '-' + c['end_year'], fmt(c['estimate']),
                               fmt(c['ci_low']) + ' tot ' + fmt(c['ci_high']),
                               'Inclusief linking' if c['formal_test'] == 'TRUE' else 'Conditioneel; beschrijvend'])
        else:
            gap_rows.append([label, c['end_year'], fmt(c['estimate']),
                             fmt(c['ci_low']) + ' tot ' + fmt(c['ci_high'])])
    table('Tabel 3. Geregistreerde langetermijnveranderingen', ['Studie / domein', 'Periode', 'Verandering', '95%-interval', 'Interpretatie'],
          trend_rows, [124, 66, 66, 106, 125], 'Eenheden: punten op de eigen studieschaal. PISA: drie tests, Holm-gecorrigeerde p < 0,001. IEA: geen formele trendtoets.',
          [x for x in claims if '_TREND_' in x])
    figure('mean_trends', 'Figuur 1. Gemiddelde Nederlandse scores. De passende internationale referentie is per paneel vast; de samenstelling staat in de meegeleverde referentietabel. Puntintervallen zijn geen trendtoets.')
    p('De leesprestaties dalen tussen begin- en eindjaar in beide geregistreerde Nederlandse leeftijdspopulaties. De TIMSS-puntverandering voor rekenen is klein vergeleken met de omvang van het conditionele interval. Dat laat geen stellige conclusie over een verandering toe. De drie PISA-trendtoetsen wijzen onder de gebruikte steekproef- en linkingveronderstellingen op lagere eindjaarsgemiddelden. Dit ontslaat de interpretatie niet van de nationale kwaliteitsvoorbehouden.',
      claim_ids=[k for k in claims if k.startswith('NLD_TREND_')])
    figure('basic_levels', 'Figuur 2. Aandeel leerlingen onder het gekozen basisniveau. Drempels en studieschalen blijven afzonderlijk; ontbrekende punten zijn niet geïnterpoleerd.')
    p('De aandelen onder basisniveau geven een andere samenvatting dan het gemiddelde. Een beweging van het gemiddelde legt niet vast hoeveel leerlingen een afkappunt passeren; dat hangt ook af van de verdeling. De tweede, hogere grens beschrijft de bovenste vaardigheidsgroep. Het aandeel onder basisniveau is daarom niet het complement van het aandeel hoog/gevorderd.')
    table('Tabel 4. SES-kloof in het laatste meetjaar', ['Studie / domein', 'Jaar', 'Q4 min Q1', '95%-interval'], gap_rows,
          [190, 52, 96, 149], 'Joint-PV/replicatie-intervallen. Boekenkwartielen (IEA) en de gekozen Cobreros-SES (PISA) meten verschillende constructen. Geen vergelijking van causale of leeftijdseffecten.',
          [x for x in claims if '_SES_GAP_' in x])
    figure('ses_levels', 'Figuur 3. Gemiddelde prestaties in het onderste en bovenste SES-kwartiel. Nederlandse boekenkwartielen bij groep 6; trendvergelijkbare Cobreros-SES bij 15-jarigen.')
    p('In alle zes laatste Nederlandse combinaties ligt de geschatte gemiddelde prestatie in het bovenste SES-kwartiel hoger dan in het onderste. De tabel kwantificeert dat verschil binnen de betreffende studie en gekozen maat. Zij laat niet zien wat de prestatie van een leerling zou zijn bij een ander gezinsinkomen, en de grotere PISA-puntverschillen zijn geen bewijs dat ongelijkheid tussen de twee leeftijden is toegenomen.',
      claim_ids=[k for k in claims if k.startswith('NLD_SES_GAP_')])
    figure('gender_levels', 'Figuur 4. Gemiddelde scores naar de waargenomen geslachtscategorie. Een gepoolde categorie meisjes + other krijgt een eigen label; een definitiebreuk blijft zichtbaar.')
    p('Uitsplitsingen naar geslacht, thuistaal en migratieachtergrond beschrijven groepen met verschillende samenstelling en soms verschillende respons. Zij worden niet als afzonderlijke verklarende effecten bij elkaar opgeteld. De definities voor minstens één buitenlandse ouder, beide buitenlandse ouders en migratiegeneratie blijven onderscheiden in dashboard en tabellen.')
    figure('migration_levels', 'Figuur 5. Gemiddelde scores naar migratiegeneratie, uitsluitend voor voldoende ondersteunde analysegroepen. Een ontbrekende generatiecategorie is geen waargenomen nul.')
    figure('peer_basic', 'Figuur 6. Aandeel peers onder basisniveau naar eigen vaardigheidsniveau, met zelfuitsluiting binnen de beschikbare directe leeromgeving.')
    p('Verschillen in peerblootstelling laten zien met welke andere leerlingen de waargenomen groepen dezelfde leeromgeving delen. Zelfuitsluiting voorkomt de mechanische bijdrage van het eigen kenmerk aan het peeraandeel. Zij lost selectie tussen scholen, programma’s en klassen niet op. Zowel de lage als de hoge vaardigheidsstaart is beschikbaar in de presentatie en het dashboard; de exacte cijfers per meetgolf staan in de resultaatbijlage.')
    heading('5.1. Verschillen tussen scholen', 2)
    school_latest = {}
    for r in data['extensions']:
        if r['module'] not in ['extension_performance_school', 'extension_ses_school']:
            continue
        key = (r['survey'], r['domain'], r['module'], r['definition'])
        if key not in school_latest or int(r['year']) > int(school_latest[key]['year']):
            school_latest[key] = r
    school_rows = sorted(school_latest.values(), key=lambda r: (r['module'], r['survey'], r['domain']))
    table('Tabel 5. Aandeel van de geobserveerde variantie tussen scholen', ['Studie / jaar', 'Uitkomst', 'Aandeel (%)', 'SE'],
          [[r['survey']+' '+r['year'], DOMAIN[r['domain']] if r['module']=='extension_performance_school'
            else ('Boeken thuis' if r['survey']!='PISA' else 'Cobreros-SES'),
            fmt(r['display_estimate']) if r['publication_eligible'] else 'Niet bruikbaar',
            fmt(r['display_standard_error']) if r['publication_eligible'] else '—'] for r in school_rows],
          [90, 220, 100, 77],
          'Laatste meetjaar per construct; A11 en A13. Gewogen beschrijvende decompositie. De brondefinitie en de schaal blijven per rij afzonderlijk. Volledige reeksen en klasvarianten staan in de resultaatbijlage.',
          [r['cell_id'] for r in school_rows])
    p('Deze aandelen beschrijven hoeveel van de geobserveerde spreiding samenhangt met verschillen tussen de gewogen schoolgemiddelden. Zij omvatten selectie van leerlingen en verschillen in samenstelling. Een groot aandeel is daarom geen schatting van het aandeel dat scholen veroorzaken en ook geen rangorde van schoolkwaliteit. Bij PISA kan de nationale indeling naar onderwijsprogramma samenhangen met de verdeling over scholen. De boekencategorieën bij IEA en de gekalibreerde PISA-SES zijn verschillende schalen; hun variantieaandelen worden niet als dezelfde grootheid door de leeftijden heen verbonden. Klasvarianten blijven beperkt tot bronnen met vergelijkbare echte klasidentificaties.')

    heading('6. Interpretatie en beperkingen')
    p('De beschrijving geeft aanleiding om de ontwikkeling van lezen en de aanhoudende verschillen tussen sociale groepen afzonderlijk te volgen. Zij biedt geen identificatie van de bijdrage van één hervorming, schooltype, digitale afname of bevolkingsverandering. Een passende internationale referentie helpt het Nederlandse verloop in context te plaatsen, maar is geen controlegroep in een causaal onderzoeksontwerp.')
    p('De belangrijkste beperkingen liggen in de doelpopulatie en deelname per cyclus, de constructie en ontbrekendheid van achtergrondkenmerken, de gekalibreerde SES-schaal buiten haar ontwikkelsteekproef en de onvolledig gekwantificeerde linking-onzekerheid bij lange IEA-vergelijkingen. Een kleine standaardfout of hoge rang corrigeert deze beperkingen niet. De verschillende IEA Home-SES-schalen zijn daarom niet tot een historische reeks samengevoegd.')
    p('Een volledig afgehandeld resultatengrid betekent dat elk gekozen doel óf een gecertificeerde schatting óf een onderbouwde onbeschikbaarheidsreden heeft. Het betekent niet dat alle 47 landen voor ieder uitkomsttype een complete reeks hebben. Bronafwezigheid, niet-afgenomen vragenlijsten, een nog niet bestaande schaal en een onbruikbare analysegroep zijn afzonderlijke hoofdredenen. Kwaliteitsbeperkingen worden daar niet mee vermengd.')

    heading('7. Reproduceerbaarheid')
    p('Code, keuzes, bronidentiteiten en resultaten worden als afzonderlijke maar gekoppelde versies bewaard. De exportcommit is niet automatisch de commit die een schatting produceerde. Iedere cel houdt haar taakcontract, broneditie, methode, producent, onzekerheidsregels en resultaat- en certificaathash. Afgeleide kloven, complementen, landenmiddelen en rangen houden hun exacte ouderschattingen.')
    p('De R-keten gebruikt START.R en RUN.R met de bestaande volgorde fixed-audit, fixed-produce en fixed-finalize. Een identieke hervatting hergebruikt geldige cellen; een gewijzigde bron, methode of relevante configuratie maakt de betreffende afhankelijkheden ongeldig. Bronreplicatie, inspectie van opgeslagen resultaten en reconstructie van producten uit aggregaten zijn verschillende routes. De README rapporteert welke routes werkelijk op Windows en Linux zijn uitgevoerd.')
    p('De getallen in deze paper zijn gebonden aan resultaatcommit ' + data['provenance']['primary_result_commit'] +
      '. De bijgeleverde PRODUCT_POINT_LINEAGE.json en PAPER_PRODUCT_TRACE.json koppelen figuren, tabellen en claims aan de gebruikte resultaten. Volledige numerieke precisie blijft in de gegevens; tabellen ronden alleen voor leesbaarheid af.')

    story.append(PageBreak()); md.append('\n---\n')
    heading('Bijlage A. Steekproeven en analysegroepen')
    quality_rows = [[r['survey'], r['year'], MODE.get(r.get('assessment_mode'), r.get('assessment_mode', '')),
                     fmt(r.get('school_before_pct'), 1), fmt(r.get('overall_exclusion_pct'), 1),
                     '; '.join(QUALITY.get(x, x) for x in r.get('quality_notes', '').split(';') if x)
                     or 'Geen aanvullend label'] for r in data['official_quality']]
    table('A1. Officiële Nederlandse cycluskenmerken', ['Studie', 'Jaar', 'Mode', 'Schoolrespons vóór vervanging (%)', 'Uitsluiting (%)', 'Kwaliteitsnotitie'],
          quality_rows, [43, 33, 100, 83, 62, 166],
          'Blanco officiële velden betekenen niet gerapporteerd in de gebruikte bron. De volledige respons- en populatiegegevens staan in NLD_OFFICIAL_SAMPLE_QUALITY.csv.')
    coverage = []
    seen = set()
    for r in data['ses_coverage']:
        if r['module'] not in ['ses_national', 'ses_harmonized']:
            continue
        key = (r['survey'], r['year'], r['domain'], r['group'])
        if key in seen:
            continue
        seen.add(key)
        coverage.append([r['survey'], r['year'], TABLE_DOMAIN[r['domain']], r['group'].upper().replace('_MINUS_', ' min '),
                         fmt(r['ses_valid_n'], 0), fmt(100 * float(r['weighted_ses_coverage'])),
                         fmt(r['group_n'], 0), fmt(r['group_complete_pv_n'], 0)])
    table('A2. SES-dekking en groepen', ['Studie', 'Jaar', 'Domein', 'Groep', 'Geldige SES (n)', 'Gewogen dekking (%)', 'Groep (n)', 'Complete PV (n)'],
          coverage, [45, 34, 79, 38, 69, 77, 65, 80],
          'Q1: onderste kwart; Q4: bovenste kwart. Natuurwet.: natuurwetenschappen. n is ongewogen; positieve fractionele boekenlidmaatschappen kunnen op twee grensgroepen meetellen. Volledige gewogen massa’s, bronhashes en noemerdefinities staan in NLD_SES_ANALYSIS_COVERAGE.csv.')

    heading('Bijlage B. Goedgekeurde wetenschappelijke uitbreidingen')
    p('A02 (hoog vaardigheidsniveau naar SES), A04 (officiële IEA Home-SES), A06 (SES × geslacht) en A14 (SES-variantie tussen klassen) zijn appendixonderdelen. A11 en A13 beschrijven spreiding tussen scholen; A12 wordt alleen gebruikt waar klassen vergelijkbaar zijn. De onderstaande compacte tabellen tonen per reeks het laatste beschikbare jaar. Alle gekozen jaren, exacte definities, eventuele kwaliteitsbeperkingen en resultaatidentiteiten staan in PAPER_APPENDIX_POINT_LINEAGE.csv.')
    appendix_groups = [
        ('B1. Hoog vaardigheidsniveau naar SES', lambda r: r['module'] in ['ses_national', 'ses_harmonized']),
        ('B2. SES en geslacht', lambda r: r['module'] == 'extension_ses_gender'),
        ('B3. Officiële Home-SES', lambda r: r['module'] == 'extension_home_ses'),
        ('B4. Variantie tussen scholen en klassen', lambda r: r['module'] in
         ['extension_performance_school', 'extension_performance_class', 'extension_ses_school', 'extension_ses_class']),
    ]
    for title, predicate in appendix_groups:
        candidates = [r for r in data['extensions'] if predicate(r)]
        grouped = {}
        for r in candidates:
            key = tuple(r[k] for k in ['survey', 'domain', 'module', 'stat', 'subgroup', 'definition'])
            if key not in grouped or int(r['year']) > int(grouped[key]['year']):
                grouped[key] = r
        display = []
        for r in sorted(grouped.values(), key=lambda r: (r['survey'], r['domain'], r['module'], r['stat'], r['subgroup'])):
            value = fmt(r['display_estimate']) + ' (' + fmt(r['display_standard_error']) + ')' if r['publication_eligible'] else r['publication_restriction']
            raw_label = r.get('subgroup_label_nl') or r['subgroup']
            label = GROUP.get(raw_label, raw_label)
            if 'other' in label.lower():
                label = label.replace('q1', 'Onderste kwart').replace('q4', 'Bovenste kwart')
            display.append([r['survey'] + ' ' + r['year'], TABLE_DOMAIN[r['domain']], MODULE[r['module']],
                            STAT[r['stat']] + ' / ' + label, value])
        table(title, ['Studie / jaar', 'Domein', 'Construct', 'Uitkomst / groep', 'Schatting (SE)'],
              display or [['-', '-', '-', 'Geen geschikte waarneming', '-']], [65, 78, 100, 142, 102],
              'Punten voor gemiddelde prestaties; percentages voor aandelen en variantieaandelen. De eigen schaal en definitie per rij zijn bindend. Een kwaliteitsbeperking is geen nul.',
              [r['cell_id'] for r in grouped.values()])
    p('Home-SES is niet beschikbaar vóór PIRLS 2021 en TIMSS 2023: de eerdere Home Resources-schalen zijn andere constructen. Bovendien is de Nederlandse TIMSS-oudervragenlijst in 2023 niet afgenomen. Die Nederlandse Home-SES-cellen zijn daarom niet berekenbaar. Dit is een afnamebeperking en wordt niet met een andere vragenlijst of imputatie aangevuld.')

    heading('Bijlage C. Landenrangen en referenties')
    p('Deze tabellen gebruiken de Nederlandse standaardreferentie, met volledige Nederlandse jaren en alle gezamenlijk getoonde groepen. De rangbasis bestaat uit Nederland plus de vermelde passende rijke landen binnen de huidige afrondingsselectie. Het zijn puntordeningen; kleine rangverschillen hoeven geen statistisch onderscheid te betekenen. De basis mag tussen tabellen verschillen.')
    for i, rank in enumerate(figures['rankTables'], 1):
        panel = next(p for p in figures['panels'] if p['id'] == rank['figure_id'])
        measure = 'SES-kloof' if rank['figure_id'].startswith('GP_SES_GAP_') else 'Gemiddelde score'
        title = f"{measure} · {DOMAIN[panel['domain']]} · " + ('groep 6' if panel['age'] == 'age10' else '15 jaar')
        rows = rank['rows']
        if not rows:
            p(f"C{i}. {title}: geen passende volledige standaardreferentie; er wordt geen rang verzonnen.", 'small')
            continue
        display = [[figures.get('country_names', {}).get(r['country_id'].replace('iso3:', ''), {}).get('nl', r['country_id'].replace('iso3:', '')), str(r['year']), GROUP.get(r.get('parent_series_id'), r.get('parent_series_id', '')),
                    fmt(r['source_estimate']), fmt(r['estimate'])] for r in sorted(rows, key=lambda r: (r.get('parent_series_id',''), float(r['estimate'])))]
        table(f"C{i}. {title}", ['Land', 'Jaar', 'Groep', 'Bronwaarde', 'Rang'], display,
              [65, 55, 130, 125, 112],
              'Vaste basis: ' + ', '.join(rank['basis']) + '. Anker: ' + ', '.join(map(str, rank['full_year_anchor'])) +
              '. Rang 1: ' + ('kleinste absolute kloof' if rank['rules']['transform'] == 'absolute' else 'hoogste score') +
              '. Geen groepsrang of ranginterval.',
              [r.get('cell_id') for r in rows])

    heading('Bronnen en bijbehorende bestanden')
    sources = [
        'OECD. PISA Data and Methodology en de gebruikte cyclusbestanden, technische rapporten en Reader’s Guides. https://www.oecd.org/en/about/programmes/pisa/pisa-data.html',
        'IEA / TIMSS & PIRLS International Study Center. PIRLS 2021 Methods and Procedures, hoofdstuk 13 over standaardfouten. https://pirls2021.org/wp-content/uploads/2023/08/P21_MP_Ch13-standard-errors.pdf',
        'IEA / TIMSS & PIRLS International Study Center. TIMSS 2023 Technical Report, hoofdstuk 13. https://timss2023.org/wp-content/uploads/2024/12/T23_TR_Chap13.pdf',
        'Cobreros, L., Colomer, M., Correig-Fraga, E., Gortazar, L. en Sayol, I. (2026). Explaining the learning decline in PISA 2025 by socioeconomic quartiles through methodological changes. Versie 24 september 2026. https://www.innovamat.com/wp-content/uploads/2026/09/PISA2025_WP.pdf',
        'Innovamat Research Lab. pisa_2025, gepinde auteurscode 1da4b26097e84e732973af672355a1c3103d5d33. https://github.com/Innovamat-Research-Lab/pisa_2025',
        'NCES. PISA 2025 Technical Notes, tabel met linking errors voor vergelijking met eerdere cycli. https://nces.ed.gov/surveys/pisa/pisa2025/technical-notes/index.asp',
        'Learning Outcomes. Wetenschappelijke Q01-Q08-dossiers, broncatalogus, besluiten, resultaatmanifest en resultaatgrid. https://github.com/Netherlands-Opportunity-Lab/Learning-Outcomes',
    ]
    for source in sources:
        p(source, 'small')
    (out / 'BIBLIOGRAPHY.md').write_text('\n\n'.join(sources) + '\n', encoding='utf-8')

    def page(canvas, doc):
        canvas.saveState()
        canvas.setStrokeColor(colors.HexColor('#D8D8D3'))
        canvas.line(54, 39, A4[0] - 54, 39)
        canvas.setFont('Oswald', 8)
        canvas.setFillColor(colors.HexColor('#59636A'))
        canvas.drawString(54, 27, 'Kansenlab | Nederlandse leerprestaties | huidige 47 landen')
        canvas.drawRightString(A4[0] - 54, 27, str(doc.page))
        canvas.restoreState()
    pdf = out / 'Leerprestaties_paper_current47.pdf'
    doc = BaseDocTemplate(str(pdf), pagesize=A4, title='Nederlandse leerprestaties, sociale verschillen en leeromgevingen',
                         author='Kansenlab / Netherlands Opportunity Lab', leftMargin=54, rightMargin=54,
                         topMargin=48, bottomMargin=56, invariant=1)
    doc.addPageTemplates(PageTemplate(id='normal', frames=Frame(54, 56, A4[0]-108, A4[1]-104, leftPadding=0, rightPadding=0, topPadding=0, bottomPadding=0), onPage=page))
    doc.build(story)
    (out / 'Leerprestaties_paper_current47.md').write_text('\n'.join(md), encoding='utf-8')
    (out / 'PAPER_PRODUCT_TRACE.json').write_text(json.dumps(dict(provenance=data['provenance'],
        figures_provenance=figures['provenance'], sections=trace, prose_statements=prose,
        manuscript_sha256=sha(out / 'Leerprestaties_paper_current47.md'),
        bibliography_sha256=sha(out / 'BIBLIOGRAPHY.md'), builder_sha256=sha(Path(__file__)),
        pdf_sha256=sha(pdf)), ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(dict(status='PAPER_BUILT_FROM_CERTIFIED_AGGREGATES', pdf=str(pdf), formal_claims=3, registered_claims=12)))


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--data', type=Path, required=True)
    p.add_argument('--fonts', type=Path, required=True)
    p.add_argument('--out', type=Path, required=True)
    a = p.parse_args()
    main(a.data.resolve(), a.fonts.resolve(), a.out.resolve())
