"""The effect counts of the article (Section 9, "What is not implemented"): rows of RSiena 1.6.6's
effects table (getEffects() over twelve data configurations), how many nwsaom implements, and how many are
not implemented. Reads results/coverage/SAOM_EFFECTS_INVENTORY.csv, a copy of docs/SAOM_EFFECTS_INVENTORY.csv
of the nwsaom repository at tag v1.5.2 (built by docs/inventory_tools there; one row per RSiena short name,
variable type and context, with the nwsaom option, its roles and whether it was compared with siena07).
Run from the replication folder: python3 tools/count_effects.py"""
import csv, collections, os
rows = list(csv.DictReader(open(os.path.join("results", "coverage", "SAOM_EFFECTS_INVENTORY.csv"))))
st = collections.Counter(r["nwsaom_status"].split(" (")[0] for r in rows)
impl = sum(1 for r in rows if r["nwsaom_status"].startswith("IMPLEMENTED"))
missing = sum(1 for r in rows if r["nwsaom_roles"] == "")
print("rows of RSiena's effects table (effTotal):", len(rows))
print("implemented by nwsaom (effImpl):          ", impl)
print("not planned, continuous behavior (effNotPlanned):", st["NOT PLANNED"])
print("rows nwsaom does not offer (effMissing):  ", missing)
print("by status:", dict(st))
print("compared with siena07 (validated_against_RSiena):", dict(collections.Counter(r["validated_against_RSiena"] or "(none)" for r in rows)))
