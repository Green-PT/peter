# Security gate — OWASP Top 10:2025

The 2025 list (8th installment). Two new categories vs 2021: **A03 Software
Supply Chain Failures** (expanded from Vulnerable & Outdated Components) and
**A10 Mishandling of Exceptional Conditions**. SSRF folded into A01.

Audit every clause. Report a finding only with file:line evidence — no
"consider reviewing" prose. Absence of evidence is `pass`, not a finding.

## A01 Broken Access Control (incl. SSRF)

- Every state-changing endpoint checks authorization server-side, not only in UI.
- Object access is scoped to the caller (no IDOR: `/orders/:id` verifies owner).
- Deny by default; new routes are not implicitly public.
- No privilege elevation via client-supplied role/tenant fields.
- CORS not `*` on credentialed endpoints.
- Server-side fetches of user-supplied URLs are allowlisted (SSRF).

## A02 Security Misconfiguration

- No debug/verbose mode, stack traces, or dev endpoints reachable in production.
- Default credentials, sample routes, admin consoles removed.
- Security headers present: CSP, HSTS, `X-Content-Type-Options`,
  `Referrer-Policy`, and frame-ancestors control.
- Cookies: `Secure`, `HttpOnly`, `SameSite` set appropriately.
- Cloud/storage buckets and DB not publicly reachable; least-privilege IAM.

## A03 Software Supply Chain Failures

- Lockfile committed; dependencies pinned, not floating ranges.
- No known-vulnerable versions (`npm audit` / `pip-audit` / equivalent — run it).
- No unvetted new transitive dependency added for a trivial function.
- Build/CI does not execute untrusted scripts or fetch unpinned remote code.
- Install scripts from new dependencies reviewed.

## A04 Cryptographic Failures

- Secrets never in source, logs, or client bundles — env/secret manager only.
- TLS enforced in transit; no downgrade path.
- Passwords hashed with argon2id/bcrypt/scrypt — never MD5, SHA-1, or plain SHA-256.
- Modern AEAD ciphers; no ECB, no hand-rolled crypto, no static IVs.
- Tokens and IDs from a CSPRNG, not `Math.random()`.
- Sensitive data at rest encrypted; PII minimized.

## A05 Injection

- SQL/NoSQL via parameterized queries or an ORM — never string concatenation.
- OS commands avoid shell interpolation of user input.
- XSS: output encoded by context; no `dangerouslySetInnerHTML`/`innerHTML` with
  user data; no `eval`. CSP is defense-in-depth, not the fix.
- Path traversal blocked on any user-controlled file path.
- Template/LDAP/header injection where applicable.

## A06 Insecure Design

- Rate limiting and lockout on auth, password reset, and expensive endpoints.
- Business-logic abuse considered (negative quantities, replay, race on balance).
- Trust boundaries explicit; client is never trusted for price, role, or quota.

## A07 Authentication Failures

- Session tokens rotated on login and privilege change; invalidated on logout.
- Sessions expire; refresh tokens revocable.
- Password reset tokens single-use, expiring, and not leaked in URLs/referrers.
- Credential stuffing defenses; no user enumeration in error messages or timing.
- MFA supported where the spec calls for it.

## A08 Software or Data Integrity Failures

- No deserialization of untrusted data into executable objects.
- CI/CD artifacts and updates integrity-checked.
- Third-party scripts pinned with SRI where loaded from CDNs.
- Auto-update or plugin paths verify signatures.

## A09 Security Logging & Alerting Failures

- Auth successes/failures, access-control denials, and admin actions logged.
- Logs carry correlation IDs and timestamps; enough to reconstruct an incident.
- **Logs never contain** passwords, tokens, full card numbers, or session IDs.
- Alertable on threshold breaches, not just written to disk.

## A10 Mishandling of Exceptional Conditions

- Errors handled explicitly — no empty catch blocks that swallow failures.
- Failure is closed, not open: an auth check that throws must deny, not allow.
- Client-facing errors are generic; details stay server-side.
- Partial failure leaves no half-written state (transactions, cleanup).
- Timeouts, retries, and resource cleanup on every external call.

## Verdict

ESON, per the return contract in your agent file:

```eson
!eson/1
verdict=fail
score=6
failures[1]{id,cat,severity,clause,evidence,fix,owner}
F1	A05	high	parameterized queries	api/users.ts:42 — template literal in query	use a parameterized query	backend
not_checked[0]
zone_facts[0]
```

`fail` if any `critical` or `high` exists. Report only what you can evidence.
