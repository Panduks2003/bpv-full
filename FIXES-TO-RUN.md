# Fixes to Run

## 1. Fix Customer Profile Updates
```
database/fix-customer-rls-policies.sql
```
**What it does:**
- Adds RLS policies so customers can update their own profiles
- Required for BPC004 to save profile changes

## 2. Fix BPVC04 Typo
```
database/fix-bpvc04-customer-id.sql
```
**What it does:**
- Checks if BPVC04 is a typo for BPC04
- Updates if needed

## After Running:
1. Clear browser cache
2. Test BPC004 profile updates
3. Try BPVC04 login (if should be BPC04)
