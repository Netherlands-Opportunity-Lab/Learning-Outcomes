"""One documentation template for the reviewed current47 NL/EN website."""
import argparse
from html import escape
from pathlib import Path

COPY = {
    "nl": {
        "title": "Methode, bronnen en replicatie", "back": "Terug naar het dashboard",
        "other": "English", "package": "Replicatiepakket (ZIP)", "products": "Paper en presentatie",
        "sections": [
            ("Huidige selectie",
             "Deze versie bevat 47 landen en onderwijsstelsels. De overige 36 volgen in een latere R-run. Alle 90.829 gekozen doelen zijn verantwoord: 82.142 gevalideerde resultaten en 8.687 onderbouwd onbeschikbare doelen. Dat betekent niet dat iedere combinatie overal bestaat. Een open meetpunt is geen nul."),
            ("Leerlingen en uitkomsten",
             "PIRLS meet lezen en TIMSS rekenen/wiskunde en natuurwetenschappen in het internationale vierde leerjaar: Nederlandse groep 6. PISA meet de drie domeinen bij 15-jarigen. De studies behouden hun eigen schalen. Meetgolven zijn geen jaarlijkse waarnemingen; de studies volgen geen individuele leerlingcohorten."),
            ("Vaste internationale vergelijking",
             "Toelating geldt per leeftijd en uitkomst, met minstens drie vergelijkbare meetgolven. Een referentieland moet alle jaren van het hoofdland en alle gezamenlijk getoonde groepen en leeromgevingen dekken. Binnen één figuur blijft de groep vast; tussen figuren mag zij verschillen. Standaard gebruiken we de passende landen uit de vastgelegde rijke OESO-kandidatenpool, zonder het hoofdland. Ieder land telt even zwaar. Niet-passende landen zijn niet selecteerbaar en een lege groep blijft leeg. De eerdere tijdelijke vergelijking met wisselende beschikbare landen is vervallen."),
            ("Rangen en onzekerheid",
             "Een rang gebruikt het hoofdland plus dezelfde geselecteerde referentiegroep. Gelijke waarden krijgen de gemiddelde rang; de richting staat bij de figuur. Er is geen groepsranglijn. Eén ander land kan op dezelfde rangbasis worden getoond. De schakelaar Onzekerheidsmarge staat standaard aan voor hoofdlandschattingen: schatting plus/min 1,96 standaardfout. Deze 95%-intervallen gebruiken de gecertificeerde weging, plausible values en replicaties; kloven gebruiken gezamenlijke replicaties. Ze zijn geen spreiding van leerlingen, omvatten niet alle vertekeningen en hun overlap is geen trendtoets. Rangen en referentiegemiddelden krijgen geen interval."),
            ("Groepen en definities",
             "PISA-SES gebruikt de gekozen viergolvenmethode van Cobreros en coauteurs; PIRLS/TIMSS gebruiken nationale boekenkwartielen. Officiële Home-SES en SES × geslacht staan volgens besluit in de appendix. Deze constructen worden niet verwisseld. Afzonderlijke meisjes blijven behouden; uitsluitend waar de bron hen samenvoegt wordt meisjes + other getoond met een eigen label en definitiebreuk. Migratie kent minstens één buitenlandse ouder, beide buitenlandse ouders, en eerste/tweede generatie afzonderlijk. Onbekende geboorteplaatsen worden niet als binnenlands ingevuld; derde generatie wordt niet afgeleid."),
            ("Leeromgeving en ontbrekende waarden",
             "Peeruitkomsten sluiten de leerling zelf uit. IEA gebruikt de waargenomen klas; PISA gebruikt het onderwijsprogramma binnen de school waar beschikbaar. Dat laatste is geen volledige klasidentificatie. De gehele school is een afzonderlijke uitkomst. Lage en hoge prestatiegroepen gebruiken verschillende afkappunten. Gebrek aan bronvelden, niet-afgenomen vragenlijsten, niet-bestaande schalen en onbruikbare groepen blijven onderscheiden. Kleine groepen met onvoldoende ondersteuning worden niet geplot. Geldige nullen blijven resultaten."),
            ("Replicatie en beperkingen",
             "Q01–Q08 zijn op deze resultaatbasis beoordeeld. Dashboard, paper en bewerkbare presentatie gebruiken dezelfde gecontroleerde aggregaten. Hun reconstructie is onderscheiden van nieuwe schattingen uit leerlingbestanden. De openbare bronroute bevat nu de benodigde historische engine en verwijst naar gepinde auteurscode; de oorspronkelijke private ZIP is daarvoor niet vereist. Een volledige nieuwe 47-landenbronreplicatie zonder oude resultaatcaches is nog niet gecertificeerd. De bewezen gerichte bronproeven, Windows/Linux-softwarecontroles en herstelcontrole staan afzonderlijk in het dossier. Dit is geen AEA-certificering."),
            ("Herkomst en gebruik",
             "SVG-, CSV- en JSON-downloads bewaren de selectie, cellen, definities, bron-, code- en resultaathashes. De onderzoekswaarden behouden hun precisie; afronding is alleen voor weergave. Nederlandse en Engelse versies delen één applicatie. OECD/IEA-bronvoorwaarden en merk- en fontlicenties blijven gelden. Er worden geen leerling- of schoolmicrodata gepubliceerd."),
        ],
    },
    "en": {
        "title": "Methods, sources and replication", "back": "Back to the dashboard",
        "other": "Nederlands", "package": "Replication package (ZIP)", "products": "Paper and presentation",
        "sections": [
            ("Current selection",
             "This version contains 47 countries and education systems. The other 36 are deferred to a later R run. All 90,829 selected targets are accounted for: 82,142 validated results and 8,687 documented unavailable targets. This does not mean that every combination exists everywhere. An absent point is not zero."),
            ("Populations and outcomes",
             "PIRLS assesses reading and TIMSS mathematics and science in international grade 4, Dutch group 6. PISA assesses the three domains among 15-year-olds. Study scales remain separate. Survey waves are not annual observations, and the studies do not follow individual pupil cohorts."),
            ("Fixed international comparison",
             "Admission is per age and domain, requiring at least three comparable waves. Each reference country must cover every focus-country year and all jointly displayed groups and learning environments. Membership is fixed within a figure but may differ between figures. The default uses eligible members of the recorded high-income OECD candidate pool, excluding the focus country. Countries receive equal weight. Ineligible countries cannot be selected; an empty group stays empty. The earlier temporary comparison with changing available countries no longer applies."),
            ("Ranks and uncertainty",
             "Ranks use the focus country plus the same selected reference group. Exact ties receive average ranks; the direction is specified with the figure. There is no group-rank line. One other country may share this rank basis. The default-on Uncertainty range switch shows focus estimates plus/minus 1.96 certified standard errors. These 95% intervals use the applicable weights, plausible values and replications; gaps use joint replications. They are not pupil dispersion, do not cover every bias, and overlap is not a trend test. Ranks and reference means receive no interval."),
            ("Groups and definitions",
             "PISA SES uses the selected four-wave Cobreros method; PIRLS/TIMSS use national books quartiles. Official Home SES and SES × gender retain their approved appendix placement. Constructs are not interchangeable. Separate girls are preserved; girls + other is used only where the source combines them, with its own label and definition break. Migration retains at least one foreign-born parent, both parents foreign-born, and first/second generation separately. Unknown birthplaces are not recoded as domestic; third generation is not inferred."),
            ("Learning environment and missingness",
             "Peer measures exclude the pupil. IEA uses the observed class; PISA uses the education programme within the school where available, which is not complete class identification. The whole school is a separate measure. Low and high attainment use different thresholds. Missing source fields, questionnaires not administered, scales not defined and unusable groups remain distinct. Insufficiently supported small groups are not plotted. Valid zeros remain results."),
            ("Replication and limitations",
             "Q01–Q08 have been reviewed on this result basis. The dashboard, paper and editable presentation use the same checked aggregates. Their reconstruction is distinct from fresh pupil-source estimation. The public source route now supplies the required historical engine and identifies pinned author code; the original private ZIP is not required for that route. A complete new 47-country source replication without old result caches has not yet been certified. Targeted source probes, Windows/Linux software checks and the completed restore test are separately documented. This is not AEA certification."),
            ("Provenance and use",
             "SVG, CSV and JSON downloads retain selection, cells, definitions, source, code and result hashes. Research values retain precision; rounding is for display only. Dutch and English share one application. OECD/IEA terms and brand/font licences remain applicable. No pupil or school microdata are published."),
        ],
    },
}


def build(site):
    for lang, text in COPY.items():
        other = "en" if lang == "nl" else "nl"
        sections = "".join(f"<h2>{escape(h)}</h2><p>{escape(p)}</p>" for h, p in text["sections"])
        html = f"""<!doctype html><html lang="{lang}"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{text['title']} · Kansenlab</title>
<link rel="stylesheet" href="../../assets/brand/fonts.css">
<link rel="stylesheet" href="../../assets/styles.css"></head>
<body data-kl-brand="leerprestaties"><header class="site-header">
<a class="brand-title" href="../../{lang}/"><img src="../../assets/brand/leerprestaties_{lang}.svg" alt="Kansenlab" width="290" height="76"></a>
<a href="../{other}/" lang="{other}">{text['other']}</a></header><main class="docs-content">
<h1>{text['title']}</h1><p><a href="../../{lang}/">{text['back']}</a> ·
<a href="../../replication/learning-outcomes-replication.zip" download>{text['package']}</a></p>
{sections}<h2>{text['products']}</h2><ul>
<li><a href="../../products/Leerprestaties_beleid_current47.pptx">PowerPoint</a> · <a href="../../products/Leerprestaties_beleid_current47.pdf">PDF</a></li>
<li><a href="../../products/Leerprestaties_paper_current47.pdf">Paper (PDF, Nederlands)</a></li></ul>
<p><a href="../../data/snapshot_provenance.json">Snapshot / provenance</a> ·
<a href="../../GUIDED_QA.json">QA</a> · <a href="../../BUILD_SHA256_MANIFEST.json">SHA-256</a> ·
<a href="../../archive/2026-09-28/">2026-09-28</a> ·
<a href="https://github.com/Netherlands-Opportunity-Lab/Learning-Outcomes">GitHub</a></p>
</main></body></html>\n"""
        dest = site / "info" / lang / "index.html"
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(html, encoding="utf-8")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("site", type=Path)
    build(parser.parse_args().site)
