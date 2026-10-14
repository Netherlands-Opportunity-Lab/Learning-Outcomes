"""Scope approval is separate from source coverage and scientific validation.

The October 14 user instruction requires item-by-item approval of substantive
additions. This overlay preserves all historical links without authorizing them.
It is also applied when regenerating the evidence audit.
"""
from copy import deepcopy

PENDING_DEPENDENCIES = {
    'S_LOW_PEER': ['A01'],
    'S_HOME_SES': ['A04'],
    'S_ABSOLUTE_SES': ['A05'],
    'S_SES_GENDER': ['A06'],
    'S_LANGUAGE_MIGRATION': ['A07'],
    'S_LEGACY_PANELS': ['A08', 'A09', 'A10'],
    'S_COHORT': ['A10'],
    'S_SORTING_SCORE': ['A11', 'A12'],
    'S_SORTING_SES': ['A13', 'A14'],
    'S_THEIL': ['A15', 'A16'],
}
PENDING_FAMILIES = {'GP_SES_HIGH': ['A02'], 'EN_PERFORMANCE_PEER': ['A03']}

def apply_scope_approval(definitions):
    d = deepcopy(definitions)
    d['scope_amendment'] = 'USER_SCOPE_AMENDMENT_20261014.md'
    d['country_membership_policy'] = 'BALANCED_REFERENCE_RULE_20261014.md'
    d['inventory_is_user_approval'] = False
    for r in d['requirements']:
        r.setdefault('historical_role', r['role'])
        # Means in the policy deck do not require producing the legacy rank panels.
        if r['requirement_id'] == 'POLICY_02':
            r['additional_dependencies'] = [x for x in r['additional_dependencies'] if x != 'S_LEGACY_PANELS']
        pending = sorted({a for x in r['additional_dependencies'] for a in PENDING_DEPENDENCIES.get(x, [])}
                         | {a for x in r['figure_families'] for a in PENDING_FAMILIES.get(x, [])})
        if r['requirement_id'] == 'SCIENCE_16':
            pending = sorted(set(pending) | {'A02'})
        r['approval_items'] = pending
        r['scope_approval'] = ('PARTLY_OR_FULLY_PENDING_USER_APPROVAL' if pending else
                               'SOURCE_INVENTORY_NOT_BLANKET_USER_APPROVAL')
        r['role'] = ('PENDING_SUBSTANTIVE_SCOPE_APPROVAL' if pending else
                     'SOURCE_INVENTORY' if r['product'] in ('SCIENTIFIC_SEMINAR', 'SCIENTIFIC_NOTE') else r['historical_role'])
        r['production_authorized_by_inventory'] = False
        if r['requirement_id'] in ('POLICY_06', 'POLICY_09'):
            r['active_presentation'] = 'BELOW_BASIC_BY_SES_Q1_Q4'
        if r['requirement_id'] == 'POLICY_10':
            r['active_presentation'] = 'EXCLUDED_FROM_DEFAULT_BY_USER; optional reinstatement needs A02'
        if r['requirement_id'] == 'POLICY_20':
            r['active_presentation'] = 'LOW_PEER_SWITCH_PENDING_A01; HIGH_PEER_RETENTION_PENDING_A03'
        if r['requirement_id'] == 'PRODUCT_DASHBOARD':
            r['title'] = 'Country eligibility 6x3; three production modes; configurable reference group; PPP20 candidates filtered by full focus support'
    for s in d['supplemental_requirements']:
        pending = PENDING_DEPENDENCIES.get(s['dependency_id'], [])
        s['approval_items'] = pending
        s['status'] = ('PENDING_USER_APPROVAL_NOT_REQUIRED_PRODUCTION' if pending else
                       'EDITORIAL_NO_CELLS' if s['dependency_id'] == 'S_TITLE' else
                       'QUALITY_OR_EXISTING_SCOPE_SPECIFICATION_NOT_CERTIFIED')
        s['production_authorized_by_inventory'] = False
        if s['dependency_id'] == 'S_DASHBOARD':
            s['definition'] = ('Three production modes; six age-domain combinations with >=3 verified cycles '
                'for country eligibility; PPP20 candidates filtered by full focus support including subgroup and peer cells; user checkbox reference; '
                'equal country weights, focus excluded, membership/availability disclosed; NL/EN and exports')
        if s['dependency_id'] == 'S_TREND':
            s['definition'] = ('Correct uncertainty for any retained change claim is mandatory QA; '
                'a new systematic suite of trend contrasts is not authorized by this inventory (A17)')
        if s['dependency_id'] == 'S_COHORT' and 'descriptive population/fieldwork disclosure' not in s['definition']:
            s['definition'] += '; descriptive population/fieldwork disclosure remains mandatory QA without new cross-age estimands'
    return d

def dependency_scope_status(dependency_id):
    return ('PENDING_USER_APPROVAL_NOT_REQUIRED_PRODUCTION' if dependency_id in PENDING_DEPENDENCIES
            else 'QUALITY_OR_EXISTING_SCOPE_NOT_CERTIFIED')
